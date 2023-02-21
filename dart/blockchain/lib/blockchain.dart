import 'dart:async';
import 'dart:math';

import 'package:bit_array/bit_array.dart';
import 'package:blockchain/blockchain_config.dart';
import 'package:blockchain_block_production/impl/block_producer.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_consensus/impl/chain_selection.dart';
import 'package:blockchain_consensus/impl/consensus_validator.dart';
import 'package:blockchain_common/blockchain_clock.dart';
import 'package:blockchain_common/store.dart';
import 'package:blockchain_ledger/impl/mempool.dart';
import 'package:blockchain_ledger/impl/transaction_syntax_validation.dart';
import 'package:blockchain_ledger/ledger.dart';
import 'package:blockchain_network/network.dart';
import 'package:blockchain_network/rpc_server.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:blockchain_ledger/impl/utxo_ledger.dart';
import 'genesis.dart';

class Blockchain {
  final BlockchainConfig config;
  final BlockchainClock clock;
  final ConsensusValidator consensusValidator;
  final ScoreBasedChainSelection chainSelection;
  final Ledger ledger;
  final Store<BlockId, Block> blockStore;
  final Store<TransactionId, Transaction> transactionStore;
  final Network network;
  final BlockProducer blockProducer;
  final StreamController<BlockId> _newBlocksController;
  final StreamController<BlockId> _adoptionsController;
  BlockId _headId;
  Set<BlockId> _headIds;

  Blockchain(
    this.config,
    this.clock,
    this.consensusValidator,
    this.chainSelection,
    this.ledger,
    this.blockStore,
    this.transactionStore,
    this.network,
    this.blockProducer,
    this._newBlocksController,
    this._adoptionsController,
    this._headId,
    this._headIds,
  );

  static Future<Blockchain> make(BlockchainConfig config) async {
    final genesisTimestamp =
        Int64(config.genesisTimestamp.millisecondsSinceEpoch);
    final genesisBlock = genesis(genesisTimestamp, []);
    final genesisBlockId = genesisBlock.id;
    final clock = BlockchainClock(genesisTimestamp);
    final blockStore = InMemoryStore<BlockId, Block>();
    await blockStore.set(genesisBlockId, genesisBlock.block);
    final transactionStore = InMemoryStore<TransactionId, Transaction>();
    genesisBlock.transactions.forEach((transaction) async =>
        await transactionStore.set(transaction.id, transaction));
    final consensusValidator = ConsensusValidator(blockStore.getOrRaise);

    final fetchTransactionOutput = (TransactionOutputReference reference) =>
        transactionStore
            .get(reference.transactionId)
            .then((t) => t!.outputs[reference.index]);

    final txoStore = InMemoryStore<TransactionId, BitArray>();

    final ledger = UtxoLedger(fetchTransactionOutput, txoStore);
    genesisBlock.transactions
        .forEach((transaction) async => await ledger.apply(transaction));

    final StreamController<BlockId> newBlocksController =
        StreamController.broadcast();
    final StreamController<BlockId> blockGossipController =
        StreamController.broadcast();
    final StreamController<TransactionId> transactionGossipController =
        StreamController.broadcast();

    final Mempool mempool = Mempool();

    Future<void> processTransaction(Transaction transaction) async {
      final syntaxErrors = validateTransactionSyntax(transaction);
      if (syntaxErrors.isNotEmpty) {
        await mempool.add(transaction);
      }
    }

    late Network network;
    late Blockchain blockchain;

    network = await Network.make(
      config.networkBindHost,
      config.networkBindPort,
      genesisBlockId,
      RpcServer(
          () => blockGossipController.stream,
          () => transactionGossipController.stream,
          blockStore.getOrRaise,
          transactionStore.getOrRaise,
          processTransaction),
      (peer) => unawaited(
        network.outboundPeers.containsKey(peer)
            ? Future.value()
            : _peerBlockStream(peer, network, blockStore, transactionStore)
                .forEach(blockchain.validateAndSave),
      ),
    );

    final random = Random();

    final rewardsAccount = Account(
        id: List.filled(32, 0).map((_) => random.nextInt(256)).toList());

    final blockProducer =
        BlockProducer(rewardsAccount, (parent) => Future.value([]));

    final chainSelectionScoreStore = InMemoryStore<BlockId, double>();
    await chainSelectionScoreStore.set(genesisBlockId, 1);
    final chainSelection = ScoreBasedChainSelection(
      genesisBlockId,
      chainSelectionScoreStore,
      (id) => blockStore.getOrRaise(id).then((b) => b.parentHeaderId),
      0.1,
    );

    blockchain = Blockchain(
        config,
        clock,
        consensusValidator,
        chainSelection,
        ledger,
        blockStore,
        transactionStore,
        network,
        blockProducer,
        newBlocksController,
        blockGossipController,
        genesisBlockId,
        Set()..add(genesisBlockId));

    return blockchain;
  }

  Future<void> get run => Future.wait([_handleInitialPeers]);

  BlockId get headId => _headId;
  Set<BlockId> get headIds => Set.of(_headIds);
  Stream<BlockId> get newBlocks => _newBlocksController.stream;
  Stream<BlockId> get adoptions => _adoptionsController.stream;

  Future<void> get _handleInitialPeers => Future.wait(
        config.initialPeers.map(
          (p) => _peerBlockStream(p, network, blockStore, transactionStore)
              .asyncMap(validateAndSave)
              .forEach((errors) {
            print(errors);
            throw Exception(errors);
          }),
        ),
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
                      proof: block.proof,
                      transactions:
                          await Stream.fromIterable(block.transactionIds)
                              .asyncMap((id) async =>
                                  (await transactionStore.get(id)) ??
                                  (await peer.getTransaction(
                                          GetTransactionReq(transactionId: id)))
                                      .transaction)
                              .toList(),
                    ))
                .toList();
            return fullBlocks;
          })
          .asyncExpand(Stream.fromIterable),
    );
  }

  Future<void> assignScore(BlockId blockId, double score) async {
    final wasSelected = await chainSelection.assignScore(blockId, score);
    if (wasSelected) {
      _adoptionsController.add(blockId);
      _headId = blockId;
    }
  }

  Future<List<String>> validateAndSave(FullBlock newFullBlock) async {
    final newBlock = newFullBlock.block;
    final newBlockId = newBlock.id;
    final consensusValidationErrors =
        await consensusValidator.validate(newBlock);
    if (consensusValidationErrors.isNotEmpty) {
      return consensusValidationErrors;
    }

    for (final transaction in newFullBlock.transactions) {
      final ledgerErrors = await ledger.validate(transaction);
      if (ledgerErrors.isNotEmpty) {
        return ledgerErrors;
      }
    }

    await blockStore.set(newBlockId, newBlock);

    for (final transaction in newFullBlock.transactions) {
      final id = transaction.id;
      if (!(await transactionStore.contains(id))) {
        await transactionStore.set(id, transaction);
      }
    }
    _newBlocksController.add(newBlockId);
    _headIds.remove(newBlock.parentHeaderId);
    _headIds.add(newBlockId);
    return [];
  }
}

extension BlockIdTraceOps on BlockId {
  Stream<BlockId> idHistory(Blockchain blockchain) async* {
    Block currentBlock = await blockchain.blockStore.getOrRaise(this);
    yield this;
    while (currentBlock.height > 1) {
      yield currentBlock.parentHeaderId;
      currentBlock =
          await blockchain.blockStore.getOrRaise(currentBlock.parentHeaderId);
    }
  }

  Stream<Block> blockHistory(Blockchain blockchain) async* {
    Block currentBlock = await blockchain.blockStore.getOrRaise(this);
    yield currentBlock;
    while (currentBlock.height > 1) {
      currentBlock =
          await blockchain.blockStore.getOrRaise(currentBlock.parentHeaderId);
      yield currentBlock;
    }
  }
}
