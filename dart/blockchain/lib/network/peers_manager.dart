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
import 'package:blockchain/network/merge_stream_eager_complete.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:rational/rational.dart';
import 'package:ribs_core/ribs_core.dart';
import 'package:ribs_effect/ribs_effect.dart';
import 'package:rxdart/rxdart.dart';

class PeersManager {
  final ConnectedPeer localPeer;
  final Ed25519KeyPair localPeerKeyPair;
  final Uint8List magicBytes;
  final BlockchainCore blockchain;
  final void Function(String, int) connectOutbound;

  PeersManager({
    required this.localPeer,
    required this.localPeerKeyPair,
    required this.magicBytes,
    required this.blockchain,
    required this.connectOutbound,
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
        blockchain: blockchain,
        connectOutbound: connect,
      ))
          .tapLogFinalize(log, "Terminating")
          .onFinalize(
              (manager) => IO.fromFutureF(() => manager.close()).voided())
          .flatTap((manager) => ResourceUtils.backgroundStream(
              manager.connectionInitializer(connect)));

  final connectedPeers = <PeerId, PeerState>{};

  final disconnectedPeers = <PeerId, PeerState>{};

  static final log = Logger("Blockchain.P2P.PeersManager");

  PeerId get localPeerId => PeerId(value: localPeerKeyPair.vk);

  Future<void> close() =>
      Future.wait(connectedPeers.values.map((peer) => peer.close()));

  Stream<Unit> connectionInitializer(Function(String, int) connect) =>
      Stream.periodic(Duration(seconds: 30), (_) => connectNext())
          .map((_) => unit);

  void connectNext() {
    log.info(
        "Connected peers count=${connectedPeers.length} ids=${connectedPeers.keys.map((id) => id.show).join(",")}");
    final targets = Map.fromEntries(connectedPeers.values
        .expand((s) => s.publicState.peers)
        .where((p) => p.hasHost() && p.hasPort())
        .map((p) => MapEntry(p.peerId, p)));

    targets.remove(localPeer.peerId);

    for (final connectedId in connectedPeers.keys) targets.remove(connectedId);
    final targetsList = targets.values.toList();
    if (targetsList.isNotEmpty) {
      final selected = targetsList[Random().nextInt(targetsList.length)];
      connectOutbound(selected.host.value, selected.port.value);
    }
  }

  Future<void> handleConnection(Socket socket) async {
    log.info(
        "Initializing handshake with remote=${socket.remoteAddress.address}:${socket.remotePort}");

    try {
      await socket.chunkedResource.use((chunkedReader) =>
          IO.fromFutureF(() async {
            final handshakeResult = await handshake(chunkedReader.readChunk,
                (data) async => socket.add(data), localPeerKeyPair, magicBytes);
            final peerId = handshakeResult.peerId;

            log.info("Handshake success with peerId=${peerId.show}");

            await PeerState.make(
              socket: socket,
              publicState:
                  PublicP2PState(localPeer: ConnectedPeer(peerId: peerId)),
            )
                .onFinalize((state) => IO.delay(() {
                      log.info(
                          "Connection closed with peerId=${state.publicState.localPeer.peerId.show}");
                      connectedPeers.remove(state.publicState.localPeer.peerId);
                      return Unit();
                    }))
                .use((state) => IO.fromFutureF(() async {
                      connectedPeers[peerId] = state;
                      final exchange = MultiplexedDataExchange(
                          MultiplexedIO(FramedIO(socket, chunkedReader)));
                      await PeerBlockchainInterface.make(
                        blockchain: blockchain,
                        remotePeerState: state,
                        exchange: exchange,
                        peersManager: this,
                      ).use((interface) => ResourceUtils.backgroundStream(
                            MergeStreamEagerComplete([
                              interface.background
                                  .doOnDone(() => log.info("Background done")),
                              PeerHandler(
                                blockchain: blockchain,
                                remotePeerId:
                                    state.publicState.localPeer.peerId,
                                peersManager: this,
                                interface: interface,
                              ).run().doOnDone(
                                  () => log.info("Peer handler done")),
                            ]),
                          )
                              .tap((sub) => state.addCloseHandler(sub.cancel))
                              .tapLogFinalize(log, "Closing")
                              .use((backgroundHandler) =>
                                  IO.fromFutureF(() async {
                                    log.info("Running");
                                    await Future.any(
                                        [backgroundHandler.done, socket.done]);
                                    log.info("Done running");
                                  })));
                    }));
          }));
    } on GracefulPeerTermination {
    } catch (e) {
      log.warning("Peer error", e);
    }
  }

  PublicP2PState get publicState => PublicP2PState(
        localPeer: localPeer,
        peers: connectedPeers.entries.map((e) => e.value.publicState.localPeer),
      );

  void onPeerStateGossiped(PeerId peerId, PublicP2PState publicState) {
    connectedPeers[peerId]!.publicState = publicState;
    connectNext();
  }
}

class PeerState {
  final Socket socket;
  PublicP2PState publicState;
  final _closeHandlers = <Future<void> Function()>[];
  PeerState({required this.socket, required this.publicState});

  PeerId get peerId => publicState.localPeer.peerId;

  static Resource<PeerState> make(
          {required Socket socket, required PublicP2PState publicState}) =>
      Resource.pure(PeerState(socket: socket, publicState: publicState))
          .onFinalize((s) => IO.fromFutureF(() => s.close()).voided());

  Future<void> close() async {
    final log = Logger("Blockchain.P2P.Peer(${peerId.show})");
    log.info("Cleaning up PeerState");
    for (final h in _closeHandlers) {
      await h();
    }
  }

  void addCloseHandler(Future<void> Function() f) {
    _closeHandlers.add(f);
  }
}

const DefaultRequestTimeout = Duration(seconds: 5);

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

  static Resource<PeerBlockchainInterface> make({
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
          .onFinalize((interface) => IO.fromFutureF(interface.close).voided())
          .tap((interface) => remotePeerState.addCloseHandler(interface.close));

  final _p2pStateQueues = PortQueues<void, PublicP2PState>();
  final _blockAdoptionQueues = PortQueues<void, BlockId>();
  final _transactionAdoptionQueues = PortQueues<void, TransactionId>();
  final _pingPongQueues = PortQueues<List<int>, List<int>>();
  final _blockIdAtHeightQueues = PortQueues<Int64, BlockId?>();
  final _headerQueues = PortQueues<BlockId, BlockHeader?>();
  final _bodyQueues = PortQueues<BlockId, BlockBody?>();
  final _transactionQueues = PortQueues<TransactionId, Transaction?>();

  List<PortQueues> get allPortQueues => [
        _p2pStateQueues,
        _blockAdoptionQueues,
        _transactionAdoptionQueues,
        _pingPongQueues,
        _blockAdoptionQueues,
        _headerQueues,
        _bodyQueues,
        _transactionAdoptionQueues,
      ];

  final _asyncErrorCompleter = Completer();

  bool _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    log.info("Closing");
    if (!_asyncErrorCompleter.isCompleted) {
      _asyncErrorCompleter.complete();
    }
    allPortQueues
        .forEach((p) => p.cancelAll(GracefulPeerTermination.instance).ignore());
  }

  Stream<Unit> get background => MergeStreamEagerComplete([
        _background.doOnDone(() => log.info("Interface stream done")),
        Stream.fromFuture(_asyncErrorCompleter.future)
            .map((_) => unit)
            .doOnDone(() => log.info("Interface async completer done")),
      ])
          .doOnCancel(() => log.info("Interface stream canceled"))
          .doOnDone(() => close().ignore())
          .doOnCancel(() => close().ignore());

  Stream<Unit> get _background async* {
    log.info("Starting background message handler");
    while (true) {
      if (_asyncErrorCompleter.isCompleted) {
        await _asyncErrorCompleter.future;
        return;
      }
      final nextMessage = await exchange.read().timeout(Duration(seconds: 10));
      yield unit;
      if (nextMessage == null) {
        log.info("Remote peer closed the connection");
        if (!_asyncErrorCompleter.isCompleted) _asyncErrorCompleter.complete();
        break;
      }
      handleMessage(nextMessage).onError<Object>((e, stackTrace) {
        if (!_asyncErrorCompleter.isCompleted)
          _asyncErrorCompleter.completeError(e, stackTrace);
      }).ignore();
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
    await exchange
        .write(MultiplexedDataRequest(MultiplexerIds.PeerStateRequest, []));
    final completer = CancelableCompleter<PublicP2PState>();
    _p2pStateQueues.responses.add(completer);
    return (await completer.operation
        .valueOrCancellation(null)
        .timeout(DefaultRequestTimeout))!;
  }

  Stream<BlockId> get nextBlockAdoption {
    final completer = CancelableCompleter<BlockId>();
    _blockAdoptionQueues.responses.add(completer);
    return Stream.fromFuture(exchange
            .write(
                MultiplexedDataRequest(MultiplexerIds.BlockAdoptionRequest, []))
            .onError(completer.completeError))
        .asyncExpand((_) => completer.operation.asStream());
  }

  Stream<TransactionId> get nextTransactionNotification {
    final completer = CancelableCompleter<TransactionId>();
    _transactionAdoptionQueues.responses.add(completer);
    return Stream.fromFuture(exchange
            .write(MultiplexedDataRequest(
                MultiplexerIds.TransactionNotificationRequest, []))
            .onError(completer.completeError))
        .asyncExpand((_) => completer.operation.asStream());
  }

  Future<BlockHeader?> fetchHeader(BlockId id) async {
    final completer = CancelableCompleter<BlockHeader?>();
    _headerQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.HeaderRequest, P2PCodecs.blockIdCodec.encode(id)));
    return completer.operation
        .valueOrCancellation(null)
        .timeout(DefaultRequestTimeout);
  }

  Future<BlockBody?> fetchBody(BlockId id) async {
    final completer = CancelableCompleter<BlockBody?>();
    _bodyQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BodyRequest, P2PCodecs.blockIdCodec.encode(id)));
    return completer.operation
        .valueOrCancellation(null)
        .timeout(DefaultRequestTimeout);
  }

  Future<Transaction?> fetchTransaction(TransactionId id) async {
    final completer = CancelableCompleter<Transaction?>();
    _transactionQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.TransactionRequest,
        P2PCodecs.transactionIdCodec.encode(id)));
    return completer.operation
        .valueOrCancellation(null)
        .timeout(DefaultRequestTimeout);
  }

  Future<BlockId?> remoteBlockIdAtHeight(Int64 height) async {
    final completer = CancelableCompleter<BlockId?>();
    _blockIdAtHeightQueues.responses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BlockIdAtHeightRequest,
        P2PCodecs.int64Codec.encode(height)));
    return completer.operation
        .valueOrCancellation(null)
        .timeout(DefaultRequestTimeout);
  }

  Future<List<int>> ping(List<int> message) async {
    final completer = CancelableCompleter<List<int>>();
    _pingPongQueues.responses.add(completer);
    await exchange
        .write(MultiplexedDataRequest(MultiplexerIds.PingRequest, message));
    return (await completer.operation
        .valueOrCancellation(null)
        .timeout(DefaultRequestTimeout))!;
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
            .map((a) => a.transaction.id)
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
  final Logger log;
  final PeersManager peersManager;
  final PeerBlockchainInterface interface;

  PeerHandler({
    required this.blockchain,
    required this.remotePeerId,
    required this.peersManager,
    required this.interface,
  }) : log = Logger("Blockchain.P2P.Peer(${remotePeerId.show})");

  Stream<Unit>? _dynamicStream;
  Completer? _mempoolSyncPauser = Completer();
  Completer _stop = Completer();

  Stream<Unit> run() => MergeStreamEagerComplete([
        _pingPong
            .doOnDone(() => log.info("Ping pong stream unexpectedly done")),
        _peerState
            .doOnDone(() => log.info("State sync stream unexpectedly done")),
        _dynamicStreamProcessor
            .doOnDone(() => log.info("Dynamic stream unexpectedly done")),
        _mempoolSync.doOnDone(() => log.info("Mempool sync unexpectedly done")),
      ])
          .doOnCancel(() => log.info("Peer Handler canceled"))
          .doOnCancel(() => _sendStopSignal())
          .doOnDone(() => _sendStopSignal())
          .doOnError((_, __) => _sendStopSignal())
          .handleError((_) {},
              test: (error) => error is GracefulPeerTermination);

  _sendStopSignal() {
    if (!_stop.isCompleted) _stop.complete();
  }

  Stream<Unit> get _dynamicStreamProcessor async* {
    _dynamicStream = _verifyGenesisAgreement;
    while (_dynamicStream != null) {
      yield* _dynamicStream!;
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
    _unpauseMempoolSync();
    _dynamicStream = _syncCheck;
  }

  Stream<Unit> get _syncCheck async* {
    _pauseMempoolSync();
    log.info("Finding common ancestor");
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
    _unpauseMempoolSync();
    while (true) {
      yield unit;
      log.info("Awaiting next block from remote peer");
      late BlockId next;
      await for (final a in interface.nextBlockAdoption) next = a;
      yield unit;
      final localHeaderExists =
          await blockchain.dataStores.headers.contains(next);
      if (!localHeaderExists) {
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
    _pauseMempoolSync();
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

  Stream<Unit> get _mempoolSync async* {
    log.info("Starting mempool sync");
    while (true) {
      if (_mempoolSyncPauser != null) {
        log.info("Pausing next mempool tx sync");
        await _mempoolSyncPauser?.future;
        log.info("Resuming next mempool tx sync");
      }
      yield unit;
      late TransactionId next;
      await for (final v in interface.nextTransactionNotification) next = v;
      yield unit;
      final localTxExists =
          await blockchain.dataStores.transactions.contains(next);
      yield unit;
      if (!localTxExists) {
        final tx = (await interface.fetchTransaction(next))!;
        log.info("Processing transaction id=${next.show}");
        yield unit;
        await blockchain.processTransaction(tx);
        yield unit;
      }
    }
  }

  void _pauseMempoolSync() {
    if (_mempoolSyncPauser == null) _mempoolSyncPauser = Completer();
  }

  void _unpauseMempoolSync() {
    _mempoolSyncPauser?.complete();
    _mempoolSyncPauser = null;
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

class GracefulPeerTermination {
  static const instance = GracefulPeerTermination();

  const GracefulPeerTermination();

  @override
  String toString() => "GraceulPeerTermination";
}
