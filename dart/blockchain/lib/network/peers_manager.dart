import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain/blockchain.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/resource.dart';
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
          .flatTap(
        (manager) => Resource.forStreamSubscription(
            () => Stream.periodic(Duration(seconds: 30), (_) {
                  log.info(
                      "Connected peers count=${manager.connectedPeers.length} ids=${manager.connectedPeers.keys.map((id) => id.show).join(",")}");
                  final targets = Map.fromEntries(manager.connectedPeers.values
                      .expand((s) => s.publicState.peers)
                      .where((p) => p.hasHost() && p.hasPort())
                      .map((p) => MapEntry(p.peerId, p)));

                  targets.remove(localPeer.peerId);

                  for (final connectedId in manager.connectedPeers.keys)
                    targets.remove(connectedId);
                  final targetsList = targets.values.toList();
                  if (targetsList.isNotEmpty) {
                    final selected =
                        targetsList[Random().nextInt(targetsList.length)];
                    connect(selected.host.value, selected.port.value);
                  }
                }).listen(null)),
      );

  final connectedPeers = <PeerId, PeerState>{};
  static final log = Logger("Blockchain.P2P.PeersManager");

  PeerId get localPeerId => PeerId(value: localPeerKeyPair.vk);

  Future<void> handleConnection(Socket socket) async {
    log.info("Initializing handshake with ${socket.remoteAddress}");
    final chunkedReader = ChunkedStreamReader(socket);
    final handshakeResult = await handshake(chunkedReader.readBytes,
        (data) async => socket.add(data), localPeerKeyPair, magicBytes);

    final state = PeerState(
      publicState: PublicP2PState(
          localPeer: ConnectedPeer(peerId: handshakeResult.peerId)),
    );

    connectedPeers[handshakeResult.peerId] = state;

    log.info("Handshake success with peerId=${handshakeResult.peerId.show}");

    final exchange = MultiplexedDataExchange(
        MultiplexedIOForFramedIO(SocketBasedFramedIO(socket, chunkedReader)));

    await Resource.onFinalize(
            () async => connectedPeers.remove(handshakeResult.peerId))
        .flatMap((_) => PeerBlockchainInterface.make(
            blockchain: blockchain,
            remotePeerId: handshakeResult.peerId,
            exchange: exchange,
            peersManager: this))
        .flatMap((interfaceWithBackground) => Resource.forStreamSubscription(
            () => PeerHandler(
                    blockchain: blockchain,
                    remotePeerId: handshakeResult.peerId,
                    exchange: exchange,
                    peersManager: this,
                    interface: interfaceWithBackground.$1)
                .run()
                .listen(null)).map((sub) =>
            Future.any([interfaceWithBackground.$2, sub.asFuture(), socket.done])))
        .use_;
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
  PublicP2PState publicState;
  PeerState({required this.publicState});
}

class P2PCodecs {
  static final int64Codec = Codec<Int64>((v) => v.toBytes(), Int64.fromBytes);
  static final blockIdCodec =
      Codec<BlockId>((v) => v.value, (v) => BlockId(value: v));

  static final blockIdOptCodec = optCodec<BlockId>(blockIdCodec);
  static final transactionIdCodec =
      Codec<TransactionId>((v) => v.value, (v) => TransactionId(value: v));

  static final fullBlockCodec =
      Codec<FullBlock>((v) => v.writeToBuffer(), FullBlock.fromBuffer);

  static final fullBlockOptCodec = optCodec<FullBlock>(fullBlockCodec);

  static final transactionCodec =
      Codec<Transaction>((v) => v.writeToBuffer(), Transaction.fromBuffer);

  static final transactionOptCodec = optCodec<Transaction>(transactionCodec);

  static final publicP2PStateCodec = Codec<PublicP2PState>(
      (v) => v.writeToBuffer(), PublicP2PState.fromBuffer);

  static Codec<T?> optCodec<T>(Codec<T> baseCodec) => Codec<T?>(
      (v) => (v == null) ? [0] : [1]
        ..addAll(baseCodec.encode(v!)),
      (bytes) => (bytes[0] == 0) ? null : baseCodec.decode(bytes.sublist(1)));
}

class PeerBlockchainInterface {
  final BlockchainCore blockchain;
  final PeerId remotePeerId;
  final MultiplexedDataExchange exchange;
  final Logger log;
  final PeersManager peersManager;

  PeerBlockchainInterface({
    required this.blockchain,
    required this.remotePeerId,
    required this.exchange,
    required this.peersManager,
  }) : log = Logger("Blockchain.P2P.Peer(${remotePeerId.show})");

  static Resource<(PeerBlockchainInterface interface, Future<void> doneSignal)>
      make({
    required BlockchainCore blockchain,
    required PeerId remotePeerId,
    required MultiplexedDataExchange exchange,
    required PeersManager peersManager,
  }) =>
          Resource.pure(PeerBlockchainInterface(
                  blockchain: blockchain,
                  remotePeerId: remotePeerId,
                  exchange: exchange,
                  peersManager: peersManager))
              .flatMap((interface) => Resource.forStreamSubscription(
                      () => interface.background.listen(null))
                  .map((sub) => (interface, sub.asFuture())));

  CancelableCompleter<PublicP2PState>? _p2pStateResponse;

  CancelableCompleter<BlockId>? _blockAdoptionResponse;

  CancelableCompleter<TransactionId>? _transactionAdoptionResponse;

  Queue<CancelableCompleter<BlockId?>> _blockIdAtHeightResponses = Queue();

  Queue<CancelableCompleter<Transaction?>> _transactionResponses = Queue();

  Queue<CancelableCompleter<FullBlock?>> _fullBlockResponses = Queue();

  Stream<Unit> get background async* {
    log.info("Starting background message handler");
    while (true) {
      final nextMessage = await exchange.read();
      yield unit;
      await handleMessage(nextMessage);
      yield unit;
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
      case MultiplexerIds.BlockRequest:
        final decoded = P2PCodecs.blockIdCodec.decode(request.value);
        await _onPeerRequestedBlock(decoded);
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
    }
  }

  Future<void> handleResponse(MultiplexedDataResponse response) async {
    switch (response.port) {
      case MultiplexerIds.BlockIdAtHeightRequest:
        final decoded = P2PCodecs.blockIdOptCodec.decode(response.value);
        await _onPeerDelivieredBlockIdAtHeight(decoded);
        break;
      case MultiplexerIds.BlockRequest:
        final decoded = P2PCodecs.fullBlockOptCodec.decode(response.value);
        if (decoded == null) throw ArgumentError.notNull("Remote FullBlock");
        await _onPeerDeliveredBlock(decoded);
        break;
      case MultiplexerIds.BlockAdoptionRequest:
        final decoded = P2PCodecs.blockIdCodec.decode(response.value);
        await _onPeerDeliveredBlockAdoption(decoded);
        break;
      case MultiplexerIds.TransactionRequest:
        final decoded = P2PCodecs.transactionOptCodec.decode(response.value);
        if (decoded == null) throw ArgumentError.notNull("Remote Transaction");
        await _onPeerDeliveredTransaction(decoded);
        break;
      case MultiplexerIds.TransactionNotificationRequest:
        final decoded = P2PCodecs.transactionIdCodec.decode(response.value);
        await _onPeerDeliveredTransactionNotification(decoded);
        break;
      case MultiplexerIds.PeerStateRequest:
        final decoded = P2PCodecs.publicP2PStateCodec.decode(response.value);
        await _onPeerDeliveredState(decoded);
        break;
    }
  }

  Future<BlockId> get nextBlockAdoption async {
    if (_blockAdoptionResponse != null)
      return (await _blockAdoptionResponse!.operation.valueOrCancellation())!;
    final completer = CancelableCompleter<BlockId>();
    _blockAdoptionResponse = completer;
    await exchange
        .write(MultiplexedDataRequest(MultiplexerIds.BlockAdoptionRequest, []));
    return (await completer.operation.valueOrCancellation(null))!;
  }

  Future<TransactionId> get nextTransactionNotification async {
    if (_transactionAdoptionResponse != null)
      return (await _transactionAdoptionResponse!.operation
          .valueOrCancellation())!;
    final completer = CancelableCompleter<TransactionId>();
    _transactionAdoptionResponse = completer;
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.TransactionNotificationRequest, []));
    return (await completer.operation.valueOrCancellation(null))!;
  }

  Future<BlockHeader?> fetchHeader(BlockId id) async {
    // TODO
    final fullBlock = await fetchFullBlock(id);
    return fullBlock?.header;
  }

  Future<FullBlock?> fetchFullBlock(BlockId id) async {
    final completer = CancelableCompleter<FullBlock?>();
    _fullBlockResponses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BlockRequest, P2PCodecs.blockIdCodec.encode(id)));
    return completer.operation.valueOrCancellation(null);
  }

  Future<Transaction?> fetchTransaction(TransactionId id) async {
    final completer = CancelableCompleter<Transaction?>();
    _transactionResponses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BlockRequest, P2PCodecs.transactionIdCodec.encode(id)));
    return completer.operation.valueOrCancellation(null);
  }

  Future<BlockId?> remoteBlockIdAtHeight(Int64 height) async {
    final completer = CancelableCompleter<BlockId?>();
    _blockIdAtHeightResponses.add(completer);
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BlockIdAtHeightRequest,
        P2PCodecs.int64Codec.encode(height)));
    return completer.operation.valueOrCancellation(null);
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

  Future<void> _onPeerRequestedBlockIdAtHeight(Int64 height) async {
    final localBlockId =
        await blockchain.consensus.localChain.blockIdAtHeight(height);
    final encoded = P2PCodecs.blockIdOptCodec.encode(localBlockId);
    await exchange.write(MultiplexedDataResponse(
        MultiplexerIds.BlockIdAtHeightRequest, encoded));
  }

  Future<void> _onPeerRequestedBlock(BlockId id) async {
    final localBlock = await blockchain.dataStores.getFullBlock(id);
    final encoded = P2PCodecs.fullBlockOptCodec.encode(localBlock);
    await exchange
        .write(MultiplexedDataResponse(MultiplexerIds.BlockRequest, encoded));
  }

  Future<void> _onPeerRequestedTransaction(TransactionId id) async {
    final value = await blockchain.dataStores.transactions.get(id);
    final encoded = P2PCodecs.transactionOptCodec.encode(value);
    await exchange.write(
        MultiplexedDataResponse(MultiplexerIds.TransactionRequest, encoded));
  }

  Future<void> _onPeerRequestedState() async {
    final value = peersManager.publicState;
    final encoded = P2PCodecs.publicP2PStateCodec.encode(value);
    await exchange.write(
        MultiplexedDataResponse(MultiplexerIds.PeerStateRequest, encoded));
  }

  Future<void> _onPeerRequestedBlockAdoption() async {
    // TODO: cache/buffer
    final value = await blockchain.consensus.localChain.adoptions.first;
    final encoded = P2PCodecs.blockIdCodec.encode(value);
    await exchange.write(
        MultiplexedDataResponse(MultiplexerIds.BlockAdoptionRequest, encoded));
  }

  Future<void> _onPeerRequestedTransactionNotification() async {
    // TODO: cache/buffer
    final value = await blockchain.ledger.mempool.changes
        .whereType<MempoolAdded>()
        .map((a) => a.id)
        .first;
    final encoded = P2PCodecs.transactionIdCodec.encode(value);
    await exchange.write(
        MultiplexedDataResponse(MultiplexerIds.BlockAdoptionRequest, encoded));
  }

  Future<void> _onPeerDeliveredBlockAdoption(BlockId id) async {
    assert(_blockAdoptionResponse != null,
        "Unexpected block adoption notification");
    _blockAdoptionResponse!.complete(id);
    _blockAdoptionResponse = null;
  }

  Future<void> _onPeerDelivieredBlockIdAtHeight(BlockId? id) async {
    assert(_blockIdAtHeightResponses.isNotEmpty, "Unexpected blockIdAtHeight");
    _blockIdAtHeightResponses.removeFirst().complete(id);
  }

  Future<void> _onPeerDeliveredBlock(FullBlock block) async {
    assert(_fullBlockResponses.isNotEmpty, "Unexpected block");
    block.header.embedId();
    _fullBlockResponses.removeFirst().complete(block);
  }

  Future<void> _onPeerDeliveredTransactionNotification(TransactionId id) async {
    assert(_transactionAdoptionResponse != null,
        "Unexpected transaction notification");
    _transactionAdoptionResponse!.complete(id);
    _transactionAdoptionResponse = null;
  }

  Future<void> _onPeerDeliveredTransaction(Transaction transaction) async {
    assert(_transactionResponses.isNotEmpty, "Unexpected transaction");
    transaction.embedId();
    _transactionResponses.removeFirst().complete(transaction);
  }

  Future<void> _onPeerDeliveredState(PublicP2PState info) async {
    assert(_p2pStateResponse != null, "Unexpected p2p state notification");
    _p2pStateResponse!.complete(info);
    _p2pStateResponse = null;
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

  Stream<Unit> run() => _verifyGenesisAgreement;

  Stream<Unit> get _verifyGenesisAgreement async* {
    log.info("Verifying genesis agreement");
    final remoteGenesisId = await interface.remoteBlockIdAtHeight(Int64.ONE);
    final localGenesisId = blockchain.consensus.localChain.genesis;
    assert(localGenesisId == remoteGenesisId);
    log.info("Genesis is agreed");
    yield unit;
    await for (final _ in _syncCheck);
  }

  Stream<Unit> get _syncCheck async* {
    final commonAncestorId = await interface.commonAncestor;
    final commonAncestor =
        await blockchain.dataStores.headers.getOrRaise(commonAncestorId);
    final remoteHeadId = (await interface.remoteBlockIdAtHeight(Int64.ZERO))!;
    log.info("Remote peer head id=${remoteHeadId.show}");
    final remoteHead = (await interface.fetchHeader(remoteHeadId))!;
    final remoteBlockIdAtHeight = (Int64 height) async {
      final id = await interface.remoteBlockIdAtHeight(height);
      if (id == null) return null;
      return (await interface.fetchFullBlock(id))!.header;
    };
    final localHeadId = await blockchain.consensus.localChain.currentHead;
    final localHead =
        await blockchain.dataStores.headers.getOrRaise(localHeadId);
    final localBlockAtHeight = (Int64 height) async {
      final id = await blockchain.consensus.localChain.blockIdAtHeight(height);
      if (id == null) return null;
      return blockchain.dataStores.headers.getOrRaise(id);
    };
    final chainSelectionResult = await blockchain.consensus.chainSelection
        .select(localHead, remoteHead, commonAncestor, localBlockAtHeight,
            remoteBlockIdAtHeight);
    if (chainSelectionResult is StandardSelectionOutcome) {
      if (chainSelectionResult.id == localHeadId) {
        log.info("Remote peer is up-to-date but local chain is better.");
        await for (final _ in _waitingForBetterBlock);
      } else {
        log.info("Local peer is up-to-date but remote chain is better.");
        await for (final _ in _sync(commonAncestor));
      }
    } else if (chainSelectionResult is DensitySelectionOutcome) {
      if (chainSelectionResult.id == localHeadId) {
        log.info("Remote peer is out-of-sync but local chain is better");
        await for (final _ in _waitingForBetterBlock);
      } else {
        log.info("Local peer out-of-sync and remote chain is better");
        await for (final _ in _sync(commonAncestor));
      }
    }
  }

  Stream<Unit> get _waitingForBetterBlock async* {
    // TODO: Transaction/mempool sync
    BlockId next = await interface.nextBlockAdoption;
    late Stream<Unit> nextOperation;
    while (true) {
      yield unit;
      final localHeader = await blockchain.dataStores.headers.get(next);
      if (localHeader != null) {
        // Already-known block can be ignored
        next = await interface.nextBlockAdoption;
      } else {
        final remoteHeader = (await interface.fetchHeader(next))!;
        final localHeadId = await blockchain.consensus.localChain.currentHead;
        if (remoteHeader.parentHeaderId == localHeadId) {
          await _processSimpleExtension(remoteHeader);
        } else {
          nextOperation = _syncCheck;
          break;
        }
      }
    }
    await for (final _ in nextOperation);
  }

  Stream<Unit> _sync(BlockHeader commonAncestor) async* {
    Int64 h = commonAncestor.height + 1;
    BlockId next = (await interface.remoteBlockIdAtHeight(h))!;
    while (true) {
      final header = (await interface.fetchHeader(next))!;
      final maybeNext = await interface.remoteBlockIdAtHeight(++h);
      await _processSimpleExtension(header, andAdopt: maybeNext == null);
      if (maybeNext == null) break;
      next = maybeNext;
    }
    await for (final _ in _waitingForBetterBlock);
  }

  Future<void> _processSimpleExtension(BlockHeader header,
      {bool andAdopt = true}) async {
    final headerErrors =
        await blockchain.consensus.blockHeaderValidation.validate(header);
    if (headerErrors.isNotEmpty) throw headerErrors[0];
    await blockchain.dataStores.headers.put(header.id, header);
    final fullBlock = (await interface.fetchFullBlock(header.id))!;
    await blockchain.validateBlockBody(fullBlock);
    if (andAdopt) {
      final localHeadId = await blockchain.consensus.localChain.currentHead;
      if (header.parentHeaderId == localHeadId) ;
      await blockchain.consensus.localChain.adopt(header.id);
    }
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
        return null;
    } else {
      final targetHeight = (min + (max - min) * searchSpaceTarget.toDouble());
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
  static const BlockRequest = 11;
  static const BlockAdoptionRequest = 12;

  static const TransactionRequest = 13;
  static const TransactionNotificationRequest = 14;

  static const PeerStateRequest = 15;
}
