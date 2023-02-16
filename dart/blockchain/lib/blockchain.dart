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
import 'package:fixnum/fixnum.dart';
import 'package:async/async.dart' show StreamGroup;

class Blockchain {
  final BlockchainClock clock;
  final BlockProducer blockProducer;
  final Consensus consensus;
  final Store<BlockId, Block> blockStore;
  final Network network;

  Blockchain(this.clock, this.blockProducer, this.consensus, this.blockStore,
      this.network);

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

    final network = await Network.make(
      config.networkBindHost,
      config.networkBindPort,
      RpcServer(
        () => consensus.adoptions,
        blockStore.getOrRaise,
      ),
    );

    return Blockchain(clock, blockProducer, consensus, blockStore, network);
  }

  Future<void> get run => StreamGroup.merge(
          [Stream.fromFuture(consensus.currentHead), consensus.adoptions])
      .asyncMap(blockStore.getOrRaise)
      .asyncMap(blockProducer.produceBlock)
      .asyncMap((newBlock) async {
        final newBlockId = newBlock.id;
        print("Minted blockId=${newBlockId.show}");
        blockStore.set(newBlockId, newBlock);
        if (await consensus.chainPreference(
                newBlockId, await consensus.currentHead) ==
            newBlockId) {
          await consensus.adopt(newBlockId);
          print("Adopted blockId=${newBlockId.show}");
          return newBlock;
        }
      })
      .where((block) => block != null)
      .map((block) => block!)
      .drain();
}
