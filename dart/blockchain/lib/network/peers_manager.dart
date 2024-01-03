import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain/blockchain.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/ledger/mempool.dart';
import 'package:blockchain/network/framing.dart';
import 'package:blockchain/network/handshake.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
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

    final peerHandler = PeerHandler(
      blockchain: blockchain,
      remotePeerId: handshakeResult.peerId,
      exchange: exchange,
      peersManager: this,
    );

    await Resource.onFinalize(
            () async => connectedPeers.remove(handshakeResult.peerId))
        .flatMap((_) => Resource.forStreamSubscription(() => StreamGroup.merge(
                [peerHandler.run(), Stream.fromFuture(socket.done)])
            .listen(null,
                onError: (e) => socket.flush().then((_) => socket.destroy()),
                cancelOnError: true)))
        .use((subscription) =>
            Future.any([subscription.asFuture(), socket.done]));
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
  static final transactionIdCodec =
      Codec<TransactionId>((v) => v.value, (v) => TransactionId(value: v));
  static final fullBlockOptCodec = Codec<FullBlock?>(
      (v) => (v == null) ? [0] : [1]
        ..addAll(v!.writeToBuffer()),
      (bytes) =>
          (bytes[0] == 0) ? null : FullBlock.fromBuffer(bytes.sublist(1)));

  static final transactionOptCodec = Codec<Transaction?>(
      (v) => (v == null) ? [0] : [1]
        ..addAll(v!.writeToBuffer()),
      (bytes) =>
          (bytes[0] == 0) ? null : Transaction.fromBuffer(bytes.sublist(1)));

  static final publicP2PStateCodec = Codec<PublicP2PState>(
      (v) => v.writeToBuffer(), PublicP2PState.fromBuffer);
}

class PeerHandler {
  final BlockchainCore blockchain;
  final PeerId remotePeerId;
  final MultiplexedDataExchange exchange;
  final Logger log;
  final PeersManager peersManager;

  PeerHandler({
    required this.blockchain,
    required this.remotePeerId,
    required this.exchange,
    required this.peersManager,
  }) : log = Logger("Blockchain.P2P.Peer(${remotePeerId.show})");

  Stream<Null> run() => ConcatStream([
        _verifyGenesisAgreement(),
        StreamGroup.merge([
          _blockNotifierStream,
          _syncStream,
          _transactionNotifierStream,
          _peerStateNotifierStream,
        ])
      ]);

  Stream<Null> get _syncStream async* {
    log.info("Starting background sync process");
    while (true) {
      final nextMessage = await exchange.read();
      yield null;
      if (nextMessage is MultiplexedDataRequest) {
        await handleRequest(nextMessage);
      } else if (nextMessage is MultiplexedDataResponse) {
        await handleResponse(nextMessage);
      }
      yield null;
    }
  }

  Future<void> handleRequest(MultiplexedDataRequest request) async {
    switch (request.port) {
      case MultiplexerIds.BlockRequest:
        final decoded = P2PCodecs.blockIdCodec.decode(request.value);
        await _onPeerRequestedBlock(decoded);
        break;
      case MultiplexerIds.TransactionRequest:
        final decoded = P2PCodecs.transactionIdCodec.decode(request.value);
        await _onPeerRequestedTransaction(decoded);
        break;
    }
  }

  Future<void> handleResponse(MultiplexedDataResponse response) async {
    switch (response.port) {
      case MultiplexerIds.BlockRequest:
        final decoded = P2PCodecs.fullBlockOptCodec.decode(response.value);
        if (decoded == null) throw ArgumentError.notNull("Remote FullBlock");
        await _onPeerDeliveredBlock(decoded);
        break;
      case MultiplexerIds.BlockAdoption:
        final decoded = P2PCodecs.blockIdCodec.decode(response.value);
        await _onPeerNotifiedBlock(decoded);
        break;
      case MultiplexerIds.TransactionRequest:
        final decoded = P2PCodecs.transactionOptCodec.decode(response.value);
        if (decoded == null) throw ArgumentError.notNull("Remote Transaction");
        await _onPeerDeliveredTransaction(decoded);
        break;
      case MultiplexerIds.TransactionNotification:
        final decoded = P2PCodecs.transactionIdCodec.decode(response.value);
        await _onPeerNotifiedTransaction(decoded);
        break;
      case MultiplexerIds.ConnectedPeersNotification:
        final decoded = P2PCodecs.publicP2PStateCodec.decode(response.value);
        await _onPeerNotifiedState(decoded);
        break;
    }
  }

  Stream<Null> get _blockNotifierStream =>
      Stream.fromFuture(blockchain.consensus.localChain.currentHead)
          .concatWith([blockchain.consensus.localChain.adoptions])
          .map(P2PCodecs.blockIdCodec.encode)
          .asyncMap((bytes) => exchange.write(
              MultiplexedDataResponse(MultiplexerIds.BlockAdoption, bytes)))
          .map((_) => null);

  Stream<Null> get _transactionNotifierStream =>
      Stream.fromFuture(blockchain.consensus.localChain.currentHead)
          .asyncMap(blockchain.ledger.mempool.read)
          .expand((i) => i)
          .concatWith([
            blockchain.ledger.mempool.changes
                .whereType<MempoolAdded>()
                .map((a) => a.id),
          ])
          .map(P2PCodecs.transactionIdCodec.encode)
          .asyncMap((bytes) => exchange.write(MultiplexedDataResponse(
              MultiplexerIds.TransactionNotification, bytes)))
          .map((_) => null);

  Stream<Null> get _peerStateNotifierStream =>
      Stream.periodic(Duration(seconds: 30))
          .map((_) => peersManager.publicState)
          .map(P2PCodecs.publicP2PStateCodec.encode)
          .asyncMap((bytes) => exchange.write(MultiplexedDataResponse(
              MultiplexerIds.ConnectedPeersNotification, bytes)))
          .map((_) => null);

  final _fulfilledBlocks = <FullBlock>[];
  final _pendingTransactions = <TransactionId>{};

  Stream<Null> _verifyGenesisAgreement() async* {
    log.info("Verifying genesis agreement");
    await exchange.write(MultiplexedDataRequest(MultiplexerIds.BlockIdAtHeight,
        P2PCodecs.int64Codec.encode(Int64.ONE)));
    yield null;
    final m1 = await exchange.read();
    assert(m1.port == MultiplexerIds.BlockIdAtHeight);
    assert(m1 is MultiplexedDataRequest);
    final requestedHeight =
        P2PCodecs.int64Codec.decode((m1 as MultiplexedDataRequest).value);
    assert(requestedHeight == Int64.ONE);
    final localGenesisId = blockchain.consensus.localChain.genesis;
    await exchange.write(MultiplexedDataResponse(MultiplexerIds.BlockIdAtHeight,
        P2PCodecs.blockIdCodec.encode(localGenesisId)));
    yield null;
    final remoteGenesis = _parseBlockIdAtHeightResponse(await exchange.read());
    assert(localGenesisId == remoteGenesis);
    log.info("Genesis is agreed");
    yield null;
  }

  BlockId _parseBlockIdAtHeightResponse(MultiplexedDataExchangePacket m1) =>
      P2PCodecs.blockIdCodec.decode((m1 as MultiplexedDataResponse).value);

  Future<void> _onPeerRequestedBlock(BlockId id) async {
    final localBlock = await blockchain.dataStores.getFullBlock(id);
    final encoded = P2PCodecs.fullBlockOptCodec.encode(localBlock);
    await exchange
        .write(MultiplexedDataResponse(MultiplexerIds.BlockRequest, encoded));
  }

  Future<void> _onPeerNotifiedBlock(BlockId id) async {
    log.info("Remote peer notified block id=${id.show}");
    final localBlock = await blockchain.dataStores.getFullBlock(id);
    if (localBlock != null) {
      log.info("Block id=${id.show} exists locally.  Skipping.");
      return;
    }
    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.BlockRequest, P2PCodecs.blockIdCodec.encode(id)));
  }

  Future<void> _onPeerDeliveredBlock(FullBlock block) async {
    block.header.embedId();
    log.info("Remote peer delivered block id=${block.header.id.show}");
    if (_fulfilledBlocks.isNotEmpty) {
      final latest = _fulfilledBlocks.last;
      if (block.header.height > latest.header.height) {
        // Check if the tine is reset
        if (block.header.parentHeaderId != latest.header.id) {
          _fulfilledBlocks.clear();
        } else {
          // Otherwise, this is an extension, so add the block and return immediately
          _fulfilledBlocks.add(block);
          return;
        }
      }
    }
    _fulfilledBlocks.insert(0, block);
    final localParentId = await blockchain.consensus.localChain
        .blockIdAtHeight(block.header.height - 1);
    if (localParentId == block.header.parentHeaderId) {
      log.info(
          "Found common ancestor.  Validating and attempting adoption of tine.");
      if (_fulfilledBlocks.length == 1) {
        await blockchain.processFullBlock(block);
      } else {
        for (int i = 0; i < _fulfilledBlocks.length - 1; i++) {
          await blockchain.processFullBlock(_fulfilledBlocks[i],
              compareAndAdopt: false);
        }
        await blockchain.processFullBlock(_fulfilledBlocks.last);
      }
      _fulfilledBlocks.clear();
    } else {
      log.info(
          "Requesting missing parent block id=${block.header.parentHeaderId.show}");
      await exchange.write(MultiplexedDataRequest(MultiplexerIds.BlockRequest,
          P2PCodecs.blockIdCodec.encode(block.header.parentHeaderId)));
    }
  }

  Future<void> _onPeerRequestedTransaction(TransactionId id) async {
    final value = await blockchain.dataStores.transactions.get(id);
    final encoded = P2PCodecs.transactionOptCodec.encode(value);
    await exchange.write(
        MultiplexedDataResponse(MultiplexerIds.TransactionRequest, encoded));
  }

  Future<void> _onPeerNotifiedTransaction(TransactionId id) async {
    log.info("Remote peer notified transaction id=${id.show}");
    if (await blockchain.dataStores.transactions.contains(id)) return;

    _pendingTransactions.add(id);

    await exchange.write(MultiplexedDataRequest(
        MultiplexerIds.TransactionRequest,
        P2PCodecs.transactionIdCodec.encode(id)));
  }

  Future<void> _onPeerDeliveredTransaction(Transaction transaction) async {
    transaction.embedId();
    final id = transaction.id;
    if (!_pendingTransactions.contains(id))
      throw ArgumentError("Unexpected transaction");
    _pendingTransactions.remove(id);
    await blockchain.processTransaction(transaction);
  }

  Future<void> _onPeerNotifiedState(PublicP2PState info) async {
    log.info("Remote peer notified public P2P state");
    peersManager.onPeerStateGossiped(remotePeerId, info);
  }
}

class MultiplexerIds {
  static const BlockIdAtHeight = 10;
  static const BlockRequest = 11;
  static const BlockAdoption = 12;

  static const TransactionRequest = 13;
  static const TransactionNotification = 14;

  static const ConnectedPeersNotification = 15;
}
