import 'dart:async';

import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_block_production/block_producer.dart';
import 'package:blockchain_block_production/impl/block_producer_impl.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_common/blockchain_clock.dart';
import 'package:blockchain_common/store.dart';
import 'package:blockchain_consensus/consensus.dart';
import 'package:blockchain_consensus/impl/consensus_impl.dart';
import 'package:blockchain_network/network.dart';
import 'package:blockchain_network/rpc_server.dart';
import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:async/async.dart' show CancelableOperation, StreamGroup;

class Blockchain {
  final BlockchainConfig config;
  final BlockchainClock clock;
  final BlockProducer blockProducer;
  final Consensus consensus;
  final Store<BlockId, Block> blockStore;
  final Network network;
  final StreamController remoteBlocksController;

  Blockchain(this.config, this.clock, this.blockProducer, this.consensus,
      this.blockStore, this.network, this.remoteBlocksController);

  static Future<Blockchain> make(BlockchainConfig config) async {
    final genesisTimestamp =
        Int64(config.genesisTimestamp.millisecondsSinceEpoch);
    final genesisBlock = Block()..timestamp = genesisTimestamp;
    final genesisBlockId = genesisBlock.id;
    final clock =
        BlockchainClock(genesisTimestamp, Duration(milliseconds: 250));
    final blockProducer = BlockProducerImpl(clock);
    final blockStore = InMemoryStore<BlockId, Block>();
    await blockStore.set(genesisBlockId, genesisBlock);
    final consensus = ConsensusImpl(genesisBlockId, blockStore.getOrRaise);

    final controller = StreamController();

    late Network network;

    network = await Network.make(
      config.networkBindHost,
      config.networkBindPort,
      genesisBlockId,
      RpcServer(
        () => consensus.adoptions,
        blockStore.getOrRaise,
      ),
      (peer) => unawaited(
        network.outboundPeers.containsKey(peer)
            ? Future.value()
            : _peerBlockStream(peer, network, blockStore)
                .forEach(controller.add),
      ),
    );

    final blockchain = Blockchain(config, clock, blockProducer, consensus,
        blockStore, network, controller);

    return blockchain;
  }

  Future<void> get run => Future.wait([
        _candidateBlocks.asyncMap(_processCandidate).drain(),
      ]);

  Stream<Block> get _candidateBlocks =>
      StreamGroup.merge([_locallyProducedBlocks, _remoteBlocks]);

  Stream<Block> get _locallyProducedBlocks {
    CancelableOperation<void>? currentOperation;
    return StreamGroup.merge(
            [Stream.fromFuture(consensus.currentHead), consensus.adoptions])
        .asyncMap(blockStore.getOrRaise)
        .transform(StreamTransformer.fromHandlers(handleData: (block, sink) {
      if (currentOperation != null) {
        currentOperation?.cancel().then((v) {
          currentOperation = CancelableOperation.fromFuture(
              blockProducer.produceBlock(block).then(sink.add));
        });
      } else {
        currentOperation = CancelableOperation.fromFuture(
            blockProducer.produceBlock(block).then(sink.add));
      }
    }));
  }

  Stream<Block> get _remoteBlocks => StreamGroup.merge(
      config.initialPeers.map((p) => _peerBlockStream(p, network, blockStore)));

  static Stream<Block> _peerBlockStream(
      String address, Network network, Store<BlockId, Block> blockStore) {
    print("Connecting to peer=$address");

    return Stream.fromFuture(network.connectTo(address)).asyncExpand(
      (peer) => peer
          .blockIdGossip(BlockIdGossipReq())
          .map((r) => r.blockId)
          .map((id) {
            print("Remote peer notified blockId=${id.show}");
            return id;
          })
          .asyncMap(
              (id) async => {"id": id, "known": await blockStore.contains(id)})
          .where((e) => !(e["known"] as bool))
          .map((v) => v["id"] as BlockId)
          .asyncMap((id) async {
            final blocks = [
              (await peer.getBlock(GetBlockReq(blockId: id))).block
            ];
            while (!await blockStore.contains(blocks.first.parentHeaderId)) {
              blocks.insert(
                0,
                (await peer.getBlock(
                        GetBlockReq(blockId: blocks.first.parentHeaderId)))
                    .block,
              );
            }
            return blocks;
          })
          .asyncExpand(Stream.fromIterable),
    );
  }

  Future<Block?> _processCandidate(Block newBlock) async {
    final newBlockId = newBlock.id;
    blockStore.set(newBlockId, newBlock);
    final preferredHeadId = await consensus.chainPreference(
      newBlockId,
      await consensus.currentHead,
    );
    if (preferredHeadId == newBlockId) {
      await consensus.adopt(newBlockId);
      print("Adopted blockId=${newBlockId.show}");
      return newBlock;
    }
  }
}
