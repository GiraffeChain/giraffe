import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:blockchain/blockchain.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/network/framing.dart';
import 'package:blockchain/network/handshake.dart';
import 'package:blockchain/network/util.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/streams.dart';

class PeersManager {
  final Ed25519KeyPair localPeerKeyPair;
  final Uint8List magicBytes;
  final BlockchainCore blockchain;

  PeersManager(
      {required this.localPeerKeyPair,
      required this.magicBytes,
      required this.blockchain});
  final log = Logger("PeersManager");

  Future<void> handleConnection(Socket socket) async {
    log.info("Initializing handshake with ${socket.remoteAddress}");
    final chunkedReader = ChunkedStreamReader(socket);
    final handshakeResult = await handshake(chunkedReader.readBytes,
        (data) async => socket.add(data), localPeerKeyPair, magicBytes);

    log.info(
        "Handshake success with peerId=${handshakeResult.peerId.sublist(0, 8).show}");

    final exchange = MultiplexedDataExchange(
        MultiplexedIOForFramedIO(SocketBasedFramedIO(socket, chunkedReader)));

    final peerHandler = PeerHandler(
        blockchain: blockchain,
        remotePeerId: handshakeResult.peerId,
        exchange: exchange);

    await Resource.forStreamSubscription(() =>
        StreamGroup.merge([peerHandler.run(), Stream.fromFuture(socket.done)])
            .listen(null,
                onError: (e) => socket.flush().then((_) => socket.destroy()),
                cancelOnError: true)).use((_) => socket.done);
  }
}

class P2PCodecs {
  static final int64Codec = Codec<Int64>((v) => v.toBytes(), Int64.fromBytes);
  static final blockIdCodec =
      Codec<BlockId>((v) => v.writeToBuffer(), BlockId.fromBuffer);
  static final fullBlockOptCodec = Codec<FullBlock?>(
      (v) => (v == null) ? [0] : [1]
        ..addAll(v!.writeToBuffer()),
      (bytes) =>
          (bytes[0] == 0) ? null : FullBlock.fromBuffer(bytes.sublist(1)));
}

class PeerHandler {
  final BlockchainCore blockchain;
  final PeerId remotePeerId;
  final MultiplexedDataExchange exchange;
  final Logger log;

  PeerHandler(
      {required this.blockchain,
      required this.remotePeerId,
      required this.exchange})
      : log = Logger("Blockchain.P2P.Peer(${remotePeerId.sublist(0, 8).show})");

  Stream<Null> run() => ConcatStream([
        _verifyGenesisAgreement(),
        StreamGroup.merge([
          _notifierStream,
          _syncStream,
        ])
      ]);

  Stream<Null> get _syncStream async* {
    log.info("Starting background sync process");
    while (true) {
      yield null;
      final nextMessage = await exchange.read();
      yield null;
      if (nextMessage is MultiplexedDataRequest) {
        if (nextMessage.port == 11) {
          final decoded = P2PCodecs.blockIdCodec.decode(nextMessage.value);
          await _onPeerRequestedBlock(decoded);
          yield null;
        }
      } else if (nextMessage is MultiplexedDataResponse) {
        if (nextMessage.port == 11) {
          final decoded = P2PCodecs.fullBlockOptCodec.decode(nextMessage.value);
          if (decoded == null) throw ArgumentError.notNull("Remote FullBlock");
          await _onPeerDeliveredBlock(decoded);
          yield null;
        } else if (nextMessage.port == 12) {
          final decoded = P2PCodecs.blockIdCodec.decode(nextMessage.value);
          await _onPeerNotifiedBlock(decoded);
          yield null;
        }
      }
    }
  }

  Stream<Null> get _notifierStream => blockchain.consensus.localChain.adoptions
      .map(P2PCodecs.blockIdCodec.encode)
      .asyncMap((bytes) => exchange.write(MultiplexedDataResponse(12, bytes)))
      .map((_) => null);

  final _fulfilledBlocks = <FullBlock>[];

  Stream<Null> _verifyGenesisAgreement() async* {
    log.info("Verifying genesis agreement");
    await exchange.write(
        MultiplexedDataRequest(10, P2PCodecs.int64Codec.encode(Int64.ONE)));
    yield null;
    final m1 = await exchange.read();
    assert(m1.port == 10);
    assert(m1 is MultiplexedDataRequest);
    final requestedHeight =
        P2PCodecs.int64Codec.decode((m1 as MultiplexedDataRequest).value);
    assert(requestedHeight == Int64.ONE);
    final localGenesisId = blockchain.consensus.localChain.genesis;
    await exchange.write(MultiplexedDataResponse(
        10, P2PCodecs.blockIdCodec.encode(localGenesisId)));
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
    await exchange.write(MultiplexedDataResponse(11, encoded));
  }

  Future<void> _onPeerNotifiedBlock(BlockId id) async {
    log.info("Remote peer notified block id=${id.show}");
    // TODO: Check if exists locally
    await exchange
        .write(MultiplexedDataRequest(11, P2PCodecs.blockIdCodec.encode(id)));
  }

  Future<void> _onPeerDeliveredBlock(FullBlock block) async {
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
    final localParentId = await blockchain.consensus.localChain
        .blockIdAtHeight(block.header.height - 1);
    if (localParentId == block.header.parentHeaderId) {
      log.info(
          "Found common ancestor.  Validating and attempting adoption of tine.");
      if (_fulfilledBlocks.isEmpty) {
        await blockchain.processFullBlock(block);
      } else {
        _fulfilledBlocks.insert(0, block);
        for (int i = 0; i < _fulfilledBlocks.length - 1; i++) {
          await blockchain.processFullBlock(block, compareAndAdopt: false);
        }
        await blockchain.processFullBlock(_fulfilledBlocks.last);
      }
      _fulfilledBlocks.clear();
    } else {
      log.info(
          "Requesting missing parent block id=${block.header.parentHeaderId.show}");
      await exchange.write(MultiplexedDataRequest(
          11, P2PCodecs.blockIdCodec.encode(block.header.parentHeaderId)));
    }
  }
}
