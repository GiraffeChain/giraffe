import 'dart:async';

import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_block_production/block_producer.dart';
import 'package:blockchain_block_production/impl/block_producer_impl.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_common/blockchain_clock.dart';
import 'package:blockchain_common/store.dart';
import 'package:blockchain_consensus/consensus.dart';
import 'package:blockchain_consensus/impl/consensus_impl.dart';
import 'package:blockchain_ledger/ledger.dart';
import 'package:blockchain_network/network.dart';
import 'package:blockchain_network/rpc_server.dart';
import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:async/async.dart' show CancelableOperation, StreamGroup;
import 'package:blockchain_ledger/impl/utxo_ledger.dart';
import 'genesis.dart';

class Blockchain {
  final BlockchainConfig config;
  final BlockchainClock clock;
  final BlockProducer blockProducer;
  final Consensus consensus;
  final Ledger ledger;
  final Store<BlockId, Block> blockStore;
  final Store<TransactionId, Transaction> transactionStore;
  final Network network;
  final StreamController<FullBlock> remoteBlocksController;

  Blockchain(
    this.config,
    this.clock,
    this.blockProducer,
    this.consensus,
    this.ledger,
    this.blockStore,
    this.transactionStore,
    this.network,
    this.remoteBlocksController,
  );

  static Future<Blockchain> make(BlockchainConfig config) async {
    final genesisTimestamp =
        Int64(config.genesisTimestamp.millisecondsSinceEpoch);
    final genesisBlock = genesis(genesisTimestamp, []);
    final genesisBlockId = genesisBlock.id;
    final clock =
        BlockchainClock(genesisTimestamp, Duration(milliseconds: 500));
    final blockProducer = BlockProducerImpl(clock);
    final blockStore = InMemoryStore<BlockId, Block>();
    await blockStore.set(genesisBlockId, genesisBlock.block);
    final transactionStore = InMemoryStore<TransactionId, Transaction>();
    genesisBlock.transactions.forEach((transaction) async =>
        await transactionStore.set(transaction.id, transaction));
    final consensus = ConsensusImpl(genesisBlockId, blockStore.getOrRaise);

    final fetchTransactionOutput = (TransactionOutputReference reference) =>
        transactionStore
            .get(reference.transactionId)
            .then((t) => t!.outputs[reference.index]);

    final ledger = UtxoLedger(fetchTransactionOutput, {});
    genesisBlock.transactions
        .forEach((transaction) async => await ledger.apply(transaction));

    final controller = StreamController<FullBlock>();

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
            : _peerBlockStream(peer, network, blockStore, transactionStore)
                .forEach(controller.add),
      ),
    );

    final blockchain = Blockchain(
      config,
      clock,
      blockProducer,
      consensus,
      ledger,
      blockStore,
      transactionStore,
      network,
      controller,
    );

    return blockchain;
  }

  Future<void> get run => Future.wait([
        _locallyProducedBlocks.asyncMap(_processCandidate).drain(),
        _remoteBlocks.asyncMap(_processCandidate).drain(),
      ]);

  Stream<FullBlock> get _locallyProducedBlocks {
    CancelableOperation<void>? currentOperation;
    void Function(Block, EventSink<Block>) updateOperation = (block, sink) =>
        currentOperation = CancelableOperation.fromFuture(
            blockProducer.produceBlock(block).then(sink.add));

    return StreamGroup.merge(
            [Stream.fromFuture(consensus.currentHead), consensus.adoptions])
        .asyncMap(blockStore.getOrRaise)
        .transform(
      StreamTransformer.fromHandlers(
          handleData: (Block block, EventSink<Block> sink) {
        if (currentOperation != null) {
          currentOperation?.cancel();
          updateOperation(block, sink);
        } else {
          updateOperation(block, sink);
        }
      }),
    ).map((block) {
      print("Minted blockId=${block.id.show}");
      return block;
    }).asyncMap(
      (block) async => FullBlock(
          parentHeaderId: block.parentHeaderId,
          timestamp: block.timestamp,
          height: block.height,
          slot: block.slot,
          proof: block.proof,
          transactions: await Stream.fromIterable(block.transactionIds)
              .asyncMap(transactionStore.getOrRaise)
              .toList()),
    );
  }

  Stream<FullBlock> get _remoteBlocks => StreamGroup.merge(
        [remoteBlocksController.stream]..addAll(config.initialPeers.map(
            (p) => _peerBlockStream(p, network, blockStore, transactionStore))),
      );

  static Stream<FullBlock> _peerBlockStream(
      String address,
      Network network,
      Store<BlockId, Block> blockStore,
      Store<TransactionId, Transaction> transactionStore) {
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
            final fullBlocks = await Stream.fromIterable(blocks)
                .asyncMap((block) async => FullBlock(
                      parentHeaderId: block.parentHeaderId,
                      timestamp: block.timestamp,
                      height: block.height,
                      slot: block.slot,
                      proof: block.proof,
                      transactions:
                          await Stream.fromIterable(block.transactionIds)
                              .asyncMap((id) async {
                        final localTx = await transactionStore.get(id);
                        if (localTx != null) return localTx;

                        return (await peer.getTransaction(
                                GetTransactionReq(transactionId: id)))
                            .transaction;
                      }).toList(),
                    ))
                .toList();
            return fullBlocks;
          })
          .asyncExpand(Stream.fromIterable),
    );
  }

  Future<Block?> _processCandidate(FullBlock newFullBlock) async {
    final newBlock = newFullBlock.block;
    final newBlockId = newBlock.id;
    final consensusValidationErrors = await consensus.validate(newBlock);
    if (consensusValidationErrors.isNotEmpty) {
      print(
          "Block id=${newBlockId.show} consensusErrors=[${consensusValidationErrors.join(',')}]");

      return null;
    }

    for (final transaction in newFullBlock.transactions) {
      final ledgerErrors = await ledger.validate(transaction);
      if (ledgerErrors.isNotEmpty) {
        print(
            "Block blockId=${newBlockId.show} contained invalid transactionId=${transaction.id.show} ledgerErrors=[${ledgerErrors.join(',')}]");

        return null;
      }
    }

    await blockStore.set(newBlockId, newBlock);

    for (final transaction in newFullBlock.transactions) {
      final id = transaction.id;
      if (!(await transactionStore.contains(id))) {
        await transactionStore.set(id, transaction);
      }
    }

    final preferredHeadId = await consensus.chainPreference(
      newBlockId,
      await consensus.currentHead,
    );
    if (preferredHeadId == newBlockId) {
      await consensus.adopt(newBlockId);
      print("Adopted blockId=${newBlockId.show}");
      return newBlock;
    }
    return null;
  }
}
