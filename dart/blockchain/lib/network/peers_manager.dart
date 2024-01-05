import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain/blockchain.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/consensus/chain_selection.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/ledger/mempool.dart';
import 'package:blockchain/network/framing.dart';
import 'package:blockchain/network/handshake.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:rational/rational.dart';
import 'package:rxdart/rxdart.dart';

class PeersManager {
  final ConnectedPeer localPeer;
  final Ed25519KeyPair localPeerKeyPair;
  final Uint8List magicBytes;
  final BlockchainCore blockchain;

  PeersManager({
    required this.localPeer,
    required this.localPeerKeyPair,
    required this.magicBytes,
    required this.blockchain,
  });

  static Resource<PeersManager> make({
    required ConnectedPeer localPeer,
    required Ed25519KeyPair localPeerKeyPair,
    required Uint8List magicBytes,
    required BlockchainCore blockchain,
    required void Function(String, int) connect,
  }) =>
      Resource.pure(PeersManager(
              localPeer: localPeer,
              localPeerKeyPair: localPeerKeyPair,
              magicBytes: magicBytes,
              blockchain: blockchain))
          .tapLogFinalize(log, "Terminating")
          .flatTap(
              (manager) => Resource.onFinalize(() async => manager.close()))
          .flatTap((manager) => Resource.backgroundStream(
              manager.connectionInitializer(connect)));

  final connectedPeers = <PeerId, PeerState>{};
  final closeSignal = Completer();

  static final log = Logger("Blockchain.P2P.PeersManager");

  PeerId get localPeerId => PeerId(value: localPeerKeyPair.vk);

  void close() {
    closeSignal.complete();
    for (final peer in connectedPeers.values) {
      peer.sendCloseSignal();
      peer.socket.destroy();
    }
  }

  Stream<Unit> connectionInitializer(Function(String, int) connect) =>
      Stream.periodic(Duration(seconds: 30), (_) {
        log.info(
            "Connected peers count=${connectedPeers.length} ids=${connectedPeers.keys.map((id) => id.show).join(",")}");
        final targets = Map.fromEntries(connectedPeers.values
            .expand((s) => s.publicState.peers)
            .where((p) => p.hasHost() && p.hasPort())
            .map((p) => MapEntry(p.peerId, p)));

        targets.remove(localPeer.peerId);

        for (final connectedId in connectedPeers.keys)
          targets.remove(connectedId);
        final targetsList = targets.values.toList();
        if (targetsList.isNotEmpty) {
          final selected = targetsList[Random().nextInt(targetsList.length)];
          connect(selected.host.value, selected.port.value);
        }
        return unit;
      });

  Future<void> handleConnection(Socket socket) async {
    log.info(
        "Initializing handshake with remote=${socket.remoteAddress.address}:${socket.remotePort}");
    final chunkedReader = ChunkedStreamReader(socket);
    final handshakeResult = await handshake(chunkedReader.readBytes,
        (data) async => socket.add(data), localPeerKeyPair, magicBytes);

    final peerId = handshakeResult.peerId;

    final state = PeerState(
      socket: socket,
      publicState: PublicP2PState(localPeer: ConnectedPeer(peerId: peerId)),
    );

    connectedPeers[peerId] = state;

    log.info("Handshake success with peerId=${peerId.show}");

    final exchange = MultiplexedDataExchange(
        MultiplexedIOForFramedIO(SocketBasedFramedIO(socket, chunkedReader)));

    await Resource.onFinalize(() async {
      log.info("Connection closed with peerId=${peerId.show}");
      connectedPeers.remove(peerId);
      state.sendCloseSignal();
    })
        .flatMap((_) => PeerBlockchainInterface.make(
              blockchain: blockchain,
              remotePeerState: state,
              exchange: exchange,
              peersManager: this,
            ))
        .flatMap(
          (interfaceWithBackground) => Resource.backgroundStream(
            PeerHandler(
                    blockchain: blockchain,
                    remotePeerId: peerId,
                    exchange: exchange,
                    peersManager: this,
                    interface: interfaceWithBackground.$1)
                .run(),
          ).tap((sub) => state.addCloseSignal(sub.$2)).map(
                (sub) => Future.any([
                  interfaceWithBackground.$2,
                  sub.$1,
                  socket.done,
                  closeSignal.future,
                ]),
              ),
        )
        .use((f) => f);
  }

  PublicP2PState get publicState => PublicP2PState(
        localPeer: localPeer,
        peers: connectedPeers.entries.map((e) => e.value.publicState.localPeer),
      );

  void onPeerStateGossiped(PeerId peerId, PublicP2PState publicState) {
    connectedPeers[peerId]!.publicState = publicState;
  }
}

class PeerState {
  final Socket socket;
  PublicP2PState publicState;
  Future<void> Function() sendCloseSignal = () async {};
  PeerState({required this.socket, required this.publicState});

  void addCloseSignal(Future<void> Function() f) {
    final previous = sendCloseSignal;
    sendCloseSignal = () => previous().then((_) => f());
  }
}

class PeerBlockchainInterface {
  final BlockchainCore blockchain;
  final PeerState remotePeerState;
  final MultiplexedDataExchange exchange;
  final Logger log;
  final PeersManager peersManager;

  PeerBlockchainInterface({
    required this.blockchain,
    required this.remotePeerState,
    required this.exchange,
    required this.peersManager,
  }) : log = Logger(
            "Blockchain.P2P.Peer(${remotePeerState.publicState.localPeer.peerId.show})");

  static Resource<(PeerBlockchainInterface interface, Future<void> doneSignal)>
      make({
    required BlockchainCore blockchain,
    required PeerState remotePeerState,
    required MultiplexedDataExchange exchange,
    required PeersManager peersManager,
  }) =>
          Resource.pure(PeerBlockchainInterface(
                  blockchain: blockchain,
                  remotePeerState: remotePeerState,
                  exchange: exchange,
                  peersManager: peersManager))
              .tap((interface) => remotePeerState.addCloseSignal(() async {
                    if (!interface.asyncErrorCompleter.isCompleted)
                      interface.asyncErrorCompleter.complete();
                  }))
              .flatMap((interface) =>
                  Resource.backgroundStream(interface.background)
                      .tap((sub) => remotePeerState.addCloseSignal(sub.$2))
                      .map((sub) => (
                            interface,
                            Future.any([
                              sub.$1,
                              interface.asyncErrorCompleter.operation
                                  .valueOrCancellation()
                            ])
                          )));

  final asyncErrorCompleter = CancelableCompleter();

  final _p2pStateQueues = PortQueues<void, PublicP2PState>();
  final _blockAdoptionQueues = PortQueues<void, BlockId>();
  final _transactionAdoptionQueues = PortQueues<void, TransactionId>();
  final _pingPongQueues = PortQueues<List<int>, List<int>>();
  final _blockIdAtHeightQueues = PortQueues<Int64, BlockId?>();
  final _headerQueues = PortQueues<BlockId, BlockHeader?>();
  final _bodyQueues = PortQueues<BlockId, BlockBody?>();
  final _transactionQueues = PortQueues<TransactionId, Transaction?>();

  Stream<Unit> get background async* {
    log.info("Starting background message handler");
    try {
      while (!asyncErrorCompleter.isCompleted) {
        final nextMessage = await Future.any<MultiplexedDataExchangePacket?>([
          asyncErrorCompleter.operation.valueOrCancellation().then((_) => null),
          exchange.read().timeout(Duration(seconds: 10))
        ]);
        if (nextMessage == null) return;
        yield unit;
        handleMessage(nextMessage).onError<Object>((e, stackTrace) {
          if (!asyncErrorCompleter.isCompleted)
            asyncErrorCompleter.completeError(e, stackTrace);
        });
      }
    } catch (e) {
      if (!asyncErrorCompleter.isCompleted)
        asyncErrorCompleter.completeError(e);
    }
  }

  Future<void> handleMessage(MultiplexedDataExchangePacket message) async {
    if (message is MultiplexedDataRequest) {
      await handleRequest(message);
    } else if (message is MultiplexedDataResponse) {
      await handleResponse(message);
    }
  }

  Future<void> handleRequest(MultiplexedDataRequest request) async {
    switch (request.port) {
      case MultiplexerIds.BlockIdAtHeightRequest:
        final decoded = P2PCodecs.int64Codec.decode(request.value);
        await _onPeerRequestedBlockIdAtHeight(decoded);
        break;
      case MultiplexerIds.HeaderRequest:
        final decoded = P2PCodecs.blockIdCodec.decode(request.value);
        await _onPeerRequestedHeader(decoded);
        break;
      case MultiplexerIds.BodyRequest:
        final decoded = P2PCodecs.blockIdCodec.decode(request.value);
        await _onPeerRequestedBody(decoded);
        break;
      case MultiplexerIds.BlockAdoptionRequest:
        await _onPeerRequestedBlockAdoption();
        break;
      case MultiplexerIds.TransactionRequest:
        final decoded = P2PCodecs.transactionIdCodec.decode(request.value);
        await _onPeerRequestedTransaction(decoded);
        break;
      case MultiplexerIds.TransactionNotificationRequest:
        await _onPeerRequestedTransactionNotification();
        break;
      case MultiplexerIds.PeerStateRequest:
        await _onPeerRequestedState();
        break;
      case MultiplexerIds.PingRequest:
        await _onPeerRequestedPing(request.value);
        break;
    }
  }

  Future<void> handleResponse(MultiplexedDataResponse response) async {
    switch (response.port) {
      case MultiplexerIds.BlockIdAtHeightRequest:
        final decoded = P2PCodecs.blockIdOptCodec.decode(response.value);
        _onPeerDelivieredBlockIdAtHeight(decoded);
        break;
      case MultiplexerIds.HeaderRequest:
        final decoded = P2PCodecs.headerOptCodec.decode(response.value);
        _onPeerDeliveredHeader(decoded);
        break;
      case MultiplexerIds.BodyRequest:
        final decoded = P2PCodecs.bodyOptCodec.decode(response.value);
        _onPeerDeliveredBody(decoded);
        break;
      case MultiplexerIds.BlockAdoptionRequest:
        final decoded = P2PCodecs.blockIdCodec.decode(response.value);
        _onPeerDeliveredBlockAdoption(decoded);
        break;
      case MultiplexerIds.TransactionRequest:
        final decoded = P2PCodecs.transactionOptCodec.decode(response.value);
        _onPeerDeliveredTransaction(decoded);
        break;
      case MultiplexerIds.TransactionNotificationRequest:
        final decoded = P2PCodecs.transactionIdCodec.decode(response.value);
        _onPeerDeliveredTransactionNotification(decoded);
        break;
      case MultiplexerIds.PeerStateRequest:
        final decoded = P2PCodecs.publicP2PStateCodec.decode(response.value);
        _onPeerDeliveredState(decoded);
        break;
      case MultiplexerIds.PingRequest:
        _onPeerDeliveredPong(response.value);
        break;
    }
  }

  Future<PublicP2PState> get publicState async {
    if (_p2pStateQueues.responses.isNotEmpty)
      return (await _p2pStateQueues.responses.first.operation
          .valueOrCancellation())!;
    final completer = CancelableCompleter<PublicP2PState>();
    _p2pStateQueues.responses.add(completer);
    await exchange
        .write(MultiplexedDataRequest(MultiplexerIds.PeerStateRequest, []));
    return (await completer.operation.valueOrCancellation(null))!;
  }

  Future<BlockId> get nextBlockAdoption async {
    if (_blockAdoptionQueues.responses.isNotEmpty)
      return (await _blockAdoptionQueues.responses.first.operation
          .valueOrCancellation())!;
    final completer = CancelableCompleter<BlockId>();
    _blockAdoptionQueues.responses.add(completer);
    await exchange
        .write(MultiplexedDataRequest(MultiplexerIds.BlockAdoptionRequest, []));
    return (await completer.operation.valueOrCancellation(null))!;
  }

  Future<TransactionId> get nextTransactionNotification async {
    if (_transactionAdoptionQueues.responses.isNotEmpty)
      return (await _transactionAdoptionQueues.responses.first.operation
          .valueOrCancellation())!;
    final completer = CancelableCompleter<TransactionId>();
    _transactionAdoptionQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.TransactionNotificationRequest, []));
    return (await completer.operation.valueOrCancellation(null))!;
  }

  Future<BlockHeader?> fetchHeader(BlockId id) async {
    final completer = CancelableCompleter<BlockHeader?>();
    _headerQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.HeaderRequest, P2PCodecs.blockIdCodec.encode(id)));
    return completer.operation.valueOrCancellation(null);
  }

  Future<BlockBody?> fetchBody(BlockId id) async {
    final completer = CancelableCompleter<BlockBody?>();
    _bodyQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BodyRequest, P2PCodecs.blockIdCodec.encode(id)));
    return completer.operation.valueOrCancellation(null);
  }

  Future<Transaction?> fetchTransaction(TransactionId id) async {
    final completer = CancelableCompleter<Transaction?>();
    _transactionQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BodyRequest, P2PCodecs.transactionIdCodec.encode(id)));
    return completer.operation.valueOrCancellation(null);
  }

  Future<BlockId?> remoteBlockIdAtHeight(Int64 height) async {
    final completer = CancelableCompleter<BlockId?>();
    _blockIdAtHeightQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BlockIdAtHeightRequest,
        P2PCodecs.int64Codec.encode(height)));
    return completer.operation.valueOrCancellation(null);
  }

  Future<List<int>> ping(List<int> message) async {
    final completer = CancelableCompleter<List<int>>();
    _pingPongQueues.responses.add(completer);
    await exchange
        .write(MultiplexedDataRequest(MultiplexerIds.PingRequest, message));
    return (await completer.operation.valueOrCancellation(null))!;
  }

  Future<BlockId> get commonAncestor async {
    final currentHeadId = await blockchain.consensus.localChain.currentHead;
    final currentHead =
        await blockchain.dataStores.headers.getOrRaise(currentHeadId);
    final currentHeight = currentHead.height;
    final intersection = await narySearch(
        blockchain.consensus.localChain.blockIdAtHeight,
        remoteBlockIdAtHeight,
        Rational.fromInt(2, 3),
        Int64.ONE,
        currentHeight);
    return intersection!;
  }

  Future<void> _onPeerRequestedBlockIdAtHeight(Int64 height) =>
      _blockIdAtHeightQueues.processRequest(height, (height) async {
        final localBlockId =
            await blockchain.consensus.localChain.blockIdAtHeight(height);
        final encoded = P2PCodecs.blockIdOptCodec.encode(localBlockId);
        await exchange.write(MultiplexedDataResponse(
            MultiplexerIds.BlockIdAtHeightRequest, encoded));
      });

  Future<void> _onPeerRequestedHeader(BlockId id) =>
      _headerQueues.processRequest(id, (id) async {
        final value = await blockchain.dataStores.headers.get(id);
        final encoded = P2PCodecs.headerOptCodec.encode(value);
        await exchange.write(
            MultiplexedDataResponse(MultiplexerIds.HeaderRequest, encoded));
      });

  Future<void> _onPeerRequestedBody(BlockId id) =>
      _bodyQueues.processRequest(id, (id) async {
        final value = await blockchain.dataStores.bodies.get(id);
        final encoded = P2PCodecs.bodyOptCodec.encode(value);
        await exchange.write(
            MultiplexedDataResponse(MultiplexerIds.BodyRequest, encoded));
      });

  Future<void> _onPeerRequestedTransaction(TransactionId id) =>
      _transactionQueues.processRequest(id, (id) async {
        final value = await blockchain.dataStores.transactions.get(id);
        final encoded = P2PCodecs.transactionOptCodec.encode(value);
        await exchange.write(MultiplexedDataResponse(
            MultiplexerIds.TransactionRequest, encoded));
      });

  Future<void> _onPeerRequestedState() =>
      _p2pStateQueues.processRequest((), (_) async {
        final value = peersManager.publicState;
        final encoded = P2PCodecs.publicP2PStateCodec.encode(value);
        await exchange.write(
            MultiplexedDataResponse(MultiplexerIds.PeerStateRequest, encoded));
      });

  Future<void> _onPeerRequestedPing(List<int> message) =>
      _pingPongQueues.processRequest(message, (message) async {
        await exchange.write(
            MultiplexedDataResponse(MultiplexerIds.PingRequest, message));
      });

  Future<void> _onPeerRequestedBlockAdoption() =>
      _blockAdoptionQueues.processRequest((), (_) async {
        // TODO: cache/buffer
        final value = await blockchain.consensus.localChain.adoptions.first;
        final encoded = P2PCodecs.blockIdCodec.encode(value);
        await exchange.write(MultiplexedDataResponse(
            MultiplexerIds.BlockAdoptionRequest, encoded));
      });

  Future<void> _onPeerRequestedTransactionNotification() =>
      _transactionAdoptionQueues.processRequest((), (_) async {
        // TODO: cache/buffer
        final value = await blockchain.ledger.mempool.changes
            .whereType<MempoolAdded>()
            .map((a) => a.id)
            .first;
        final encoded = P2PCodecs.transactionIdCodec.encode(value);
        await exchange.write(MultiplexedDataResponse(
            MultiplexerIds.TransactionNotificationRequest, encoded));
      });

  void _onPeerDeliveredBlockAdoption(BlockId id) {
    _blockAdoptionQueues.processResponse(id, "Unexpected block notification");
  }

  void _onPeerDelivieredBlockIdAtHeight(BlockId? id) {
    _blockIdAtHeightQueues.processResponse(
        id, "Unexpected blockIdAtHeight response");
  }

  void _onPeerDeliveredHeader(BlockHeader? header) {
    _headerQueues.processResponse(header, "Unexpected header");
  }

  void _onPeerDeliveredBody(BlockBody? body) {
    _bodyQueues.processResponse(body, "Unexpected body");
  }

  void _onPeerDeliveredTransactionNotification(TransactionId id) {
    _transactionAdoptionQueues.processResponse(
        id, "Unexpected transaction notification");
  }

  void _onPeerDeliveredTransaction(Transaction? transaction) {
    _transactionQueues.processResponse(transaction, "Unexpected transaction");
  }

  void _onPeerDeliveredState(PublicP2PState info) {
    _p2pStateQueues.processResponse(info, "Unexpected p2p state");
  }

  void _onPeerDeliveredPong(List<int> message) {
    _pingPongQueues.processResponse(message, "Unexpected pong");
  }
}

class PeerHandler {
  final BlockchainCore blockchain;
  final PeerId remotePeerId;
  final MultiplexedDataExchange exchange;
  final Logger log;
  final PeersManager peersManager;
  final PeerBlockchainInterface interface;

  PeerHandler({
    required this.blockchain,
    required this.remotePeerId,
    required this.exchange,
    required this.peersManager,
    required this.interface,
  }) : log = Logger("Blockchain.P2P.Peer(${remotePeerId.show})");

  Stream<Unit>? _dynamicStream;

  Stream<Unit> run() => MergeStream([
        _pingPong,
        _peerState,
        _dynamicStreamProcessor,
      ]);

  Stream<Unit> get _dynamicStreamProcessor async* {
    _dynamicStream = _verifyGenesisAgreement;
    while (_dynamicStream != null) {
      await for (final v in _dynamicStream!) {
        yield v;
      }
    }
  }

  Stream<Unit> get _pingPong => Stream.periodic(Duration(seconds: 5))
      // .asyncMap((_) => log.timedInfoAsync(() => interface.ping([]),
      //     messageF: (duration) => "Ping took $duration"))
      .asyncMap((_) => interface.ping([]))
      .map((_) => unit);

  Stream<Unit> get _peerState => Stream.periodic(Duration(seconds: 30))
      .asyncMap((_) => interface.publicState)
      .map((state) {
        log.info(
            "Peer delivered state update.  Remote peer is connected to ${state.peers.length} peers");
        return state;
      })
      .map((state) => peersManager.onPeerStateGossiped(remotePeerId, state))
      .map((_) => unit);

  Stream<Unit> get _verifyGenesisAgreement async* {
    log.info("Verifying genesis agreement");
    final remoteGenesisId = await interface.remoteBlockIdAtHeight(Int64.ONE);
    final localGenesisId = blockchain.consensus.localChain.genesis;
    assert(localGenesisId == remoteGenesisId);
    log.info("Genesis is agreed");
    yield unit;
    _dynamicStream = _syncCheck;
  }

  Stream<Unit> get _syncCheck async* {
    final commonAncestorId = await interface.commonAncestor;
    log.info("Common ancestor id=${commonAncestorId.show}");
    final commonAncestor =
        await blockchain.dataStores.headers.getOrRaise(commonAncestorId);
    final remoteHeadId = (await interface.remoteBlockIdAtHeight(Int64.ZERO))!;
    log.info("Remote peer head id=${remoteHeadId.show}");
    final remoteHead = (await interface.fetchHeader(remoteHeadId))!;
    final remoteHeaderAtHeight = (Int64 height) async {
      final id = await interface.remoteBlockIdAtHeight(height);
      if (id == null) return null;
      return (await interface.fetchHeader(id))!;
    };
    yield unit;
    final localHeadId = await blockchain.consensus.localChain.currentHead;
    final localHead =
        await blockchain.dataStores.headers.getOrRaise(localHeadId);
    final localHeaderAtHeight = (Int64 height) async {
      final id = await blockchain.consensus.localChain.blockIdAtHeight(height);
      if (id == null) return null;
      return blockchain.dataStores.headers.getOrRaise(id);
    };
    final chainSelectionResult = await blockchain.consensus.chainSelection
        .select(localHead, remoteHead, commonAncestor, localHeaderAtHeight,
            remoteHeaderAtHeight);
    yield unit;
    if (chainSelectionResult is StandardSelectionOutcome) {
      if (chainSelectionResult.id == localHeadId) {
        log.info("Remote peer is up-to-date but local chain is better.");
        _dynamicStream = _waitingForBetterBlock;
      } else {
        log.info("Local peer is up-to-date but remote chain is better.");
        _dynamicStream = _sync(commonAncestor);
      }
    } else if (chainSelectionResult is DensitySelectionOutcome) {
      if (chainSelectionResult.id == localHeadId) {
        log.info("Remote peer is out-of-sync but local chain is better");
        _dynamicStream = _waitingForBetterBlock;
      } else {
        log.info("Local peer out-of-sync and remote chain is better");
        _dynamicStream = _sync(commonAncestor);
      }
    }
  }

  Stream<Unit> get _waitingForBetterBlock async* {
    // TODO: Transaction/mempool sync
    while (true) {
      log.info("Awaiting next block from remote peer");
      final next = await interface.nextBlockAdoption;
      yield unit;
      final localHeader = await blockchain.dataStores.headers.get(next);
      if (localHeader == null) {
        final remoteHeader = (await interface.fetchHeader(next))!;
        final localHeadId = await blockchain.consensus.localChain.currentHead;
        if (remoteHeader.parentHeaderId == localHeadId) {
          await _fetchVerifyPersist(remoteHeader);
          yield unit;
          await blockchain.consensus.localChain.adopt(next);
          yield unit;
        } else {
          _dynamicStream = _syncCheck;
          break;
        }
      } else {
        log.info("Ignoring known block id=${next.show}");
      }
    }
  }

  Stream<Unit> _sync(BlockHeader commonAncestor) async* {
    log.info("Synchronizing from commonAncestor id=${commonAncestor.id.show}");
    Int64 h = commonAncestor.height + 1;
    BlockId? lastProcessed;
    while (true) {
      final remoteId = await interface.remoteBlockIdAtHeight(h);
      yield unit;
      if (remoteId == null) break;
      final header = (await interface.fetchHeader(remoteId))!;
      assert(lastProcessed == null || header.parentHeaderId == lastProcessed,
          "Remote peer branched during syncing");
      yield unit;
      await _fetchVerifyPersist(header);
      yield unit;
      lastProcessed = header.id;
      h++;
    }
    if (lastProcessed != null)
      await blockchain.consensus.localChain.adopt(lastProcessed);
    yield unit;
    _dynamicStream = _waitingForBetterBlock;
  }

  Future<void> _fetchVerifyPersist(BlockHeader header) async {
    log.info("Processing remote block id=${header.id.show}");
    final headerErrors =
        await blockchain.consensus.blockHeaderValidation.validate(header);
    if (headerErrors.isNotEmpty) throw headerErrors[0];
    await blockchain.dataStores.headers.put(header.id, header);
    await blockchain.parentChildTree.assocate(header.id, header.parentHeaderId);
    final body = (await interface.fetchBody(header.id))!;
    final transactions = [
      for (final id in body.transactionIds)
        (await interface.fetchTransaction(id))!
    ];
    final fullBlock = FullBlock(
        header: header, fullBody: FullBlockBody(transactions: transactions));
    await blockchain.validateBlockBody(fullBlock);
  }
}

Future<T?> narySearch<T>(
    Future<T> Function(Int64) getLocal,
    Future<T?> Function(Int64) getRemote,
    Rational searchSpaceTarget,
    Int64 min,
    Int64 max) async {
  Future<T?> f(Int64 min, Int64 max, T? ifNull) async {
    if (min == max) {
      final localValue = await getLocal(min);
      final remoteValue = await getRemote(min);
      if (localValue == remoteValue)
        return localValue;
      else
        return ifNull;
    } else {
      final targetHeight = (min +
          (Rational((max - min).toBigInt) * searchSpaceTarget).floor().toInt());
      final localValue = await getLocal(targetHeight);
      final remoteValue = await getRemote(targetHeight);
      if (remoteValue == localValue) {
        return f(targetHeight + 1, max, remoteValue);
      } else {
        return f(min, targetHeight, ifNull);
      }
    }
  }

  return f(min, max, null);
}

class MultiplexerIds {
  static const BlockIdAtHeightRequest = 10;
  static const HeaderRequest = 11;
  static const BodyRequest = 12;
  static const BlockAdoptionRequest = 13;
  static const TransactionRequest = 14;
  static const TransactionNotificationRequest = 15;
  static const PeerStateRequest = 16;
  static const PingRequest = 17;
}
