import 'package:blockchain/blockchain.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/traversal.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/transformers.dart';

abstract class BlockchainView {
  Future<SlotData?> getSlotData(BlockId blockId);
  Future<BlockHeader?> getBlockHeader(BlockId blockId);
  Future<BlockBody?> getBlockBody(BlockId blockId);
  Future<Transaction?> getTransaction(TransactionId transactionId);
  Future<BlockId?> getBlockIdAtHeight(Int64 height);
  Future<BlockId> get canonicalHeadId;
  Future<BlockId> get genesisBlockId;
  Stream<TraversalStep> get traversal;
  Future<List<TransactionId>> get mempoolTransactionIds;

  Stream<BlockId> get adoptions =>
      traversal.whereType<TraversalStep_Applied>().map((t) => t.blockId);

  Future<SlotData> getSlotDataOrRaise(BlockId blockId) =>
      getSlotData(blockId).then((v) => v!);

  Future<BlockHeader> getBlockHeaderOrRaise(BlockId blockId) =>
      getBlockHeader(blockId).then((v) => v!);

  Future<BlockBody> getBlockBodyOrRaise(BlockId blockId) =>
      getBlockBody(blockId).then((v) => v!);

  Future<Transaction> getTransactionOrRaise(TransactionId transactionId) =>
      getTransaction(transactionId).then((v) => v!);

  Future<FullBlock?> getFullBlock(BlockId blockId) async {
    final header = await getBlockHeader(blockId);
    if (header == null) return null;
    final body = await getBlockBody(blockId);
    if (body == null) return null;
    final transactionsResult = <Transaction>[];
    for (final transactionId in body.transactionIds) {
      final transaction = await getTransaction(transactionId);
      if (transaction == null) return null;
      transactionsResult.add(transaction);
    }
    final fullBody = FullBlockBody(transactions: transactionsResult);
    return FullBlock(header: header, fullBody: fullBody);
  }

  Future<FullBlock> getFullBlockOrRaise(BlockId blockId) =>
      getFullBlock(blockId).then((v) => v!);

  Future<FullBlock> get genesisBlock =>
      genesisBlockId.then(getFullBlockOrRaise);

  Future<ProtocolSettings> get protocolSettings async {
    final genesis = await genesisBlock;
    return ProtocolSettings.fromMap(genesis.header.settings);
  }

  Stream<FullBlock> get adoptedBlocks =>
      adoptions.asyncMap(getFullBlock).whereNotNull();

  Stream<BlockId> get replay async* {
    Int64 h = Int64(1);
    while (true) {
      final next = await getBlockIdAtHeight(h);
      if (next == null) break;
      yield next;
      h += 1;
    }
  }

  Stream<FullBlock> get replayBlocks =>
      replay.asyncMap(getFullBlock).whereNotNull();
}

class BlockchainViewFromBlockchain extends BlockchainView {
  final Blockchain blockchain;

  BlockchainViewFromBlockchain({required this.blockchain});

  @override
  Stream<BlockId> get adoptions => blockchain.consensus.localChain.adoptions;

  @override
  Future<BlockId> get canonicalHeadId =>
      blockchain.consensus.localChain.currentHead;

  @override
  Future<BlockId> get genesisBlockId =>
      Future.value(blockchain.consensus.localChain.genesis);

  @override
  Future<BlockBody?> getBlockBody(BlockId blockId) =>
      blockchain.dataStores.bodies.get(blockId);

  @override
  Future<BlockHeader?> getBlockHeader(BlockId blockId) =>
      blockchain.dataStores.headers.get(blockId);

  @override
  Future<BlockId?> getBlockIdAtHeight(Int64 height) =>
      blockchain.consensus.localChain.blockIdAtHeight(height);

  @override
  Future<SlotData?> getSlotData(BlockId blockId) =>
      blockchain.dataStores.slotData.get(blockId);

  @override
  Future<Transaction?> getTransaction(TransactionId transactionId) =>
      blockchain.dataStores.transactions.get(transactionId);

  @override
  Future<List<TransactionId>> get mempoolTransactionIds =>
      blockchain.consensus.localChain.currentHead
          .then(blockchain.ledger.mempool.read)
          .then((l) => l.toList());

  @override
  Stream<TraversalStep> get traversal => blockchain.traversal;
}

class BlockchainViewFromRpc extends BlockchainView {
  final NodeRpcClient nodeClient;

  BlockchainViewFromRpc({required this.nodeClient});

  @override
  Future<BlockId> get canonicalHeadId =>
      getBlockIdAtHeight(Int64.ZERO).then((v) => v!);

  @override
  Future<BlockId> get genesisBlockId =>
      getBlockIdAtHeight(Int64.ONE).then((v) => v!);

  @override
  Future<BlockBody?> getBlockBody(BlockId blockId) => nodeClient
      .getBlockBody(GetBlockBodyReq(blockId: blockId))
      .then((v) => v.hasBody() ? v.body : null);

  @override
  Future<BlockHeader?> getBlockHeader(BlockId blockId) => nodeClient
      .getBlockHeader(GetBlockHeaderReq(blockId: blockId))
      .then((v) => v.hasHeader() ? v.header : null);

  @override
  Future<BlockId?> getBlockIdAtHeight(Int64 height) => nodeClient
      .getBlockIdAtHeight(GetBlockIdAtHeightReq(height: height))
      .then((v) => v.hasBlockId() ? v.blockId : null);

  @override
  Future<SlotData?> getSlotData(BlockId blockId) => nodeClient
      .getSlotData(GetSlotDataReq(blockId: blockId))
      .then((v) => v.hasSlotData() ? v.slotData : null);

  @override
  Future<Transaction?> getTransaction(TransactionId transactionId) => nodeClient
      .getTransaction(GetTransactionReq(transactionId: transactionId))
      .then((v) => v.hasTransaction() ? v.transaction : null);

  @override
  // TODO: implement mempoolTransactionIds
  Future<List<TransactionId>> get mempoolTransactionIds =>
      throw UnimplementedError();

  @override
  Stream<TraversalStep> get traversal =>
      nodeClient.follow(FollowReq()).map((followR) => followR.hasAdopted()
          ? TraversalStep_Applied(followR.adopted)
          : TraversalStep_Unapplied(followR.unadopted));
}
