import 'package:blockchain_sdk/sdk.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/transformers.dart';

abstract class BlockchainClient {
  Future<BlockHeader?> getBlockHeader(BlockId blockId);
  Future<BlockBody?> getBlockBody(BlockId blockId);
  Future<Transaction?> getTransaction(TransactionId transactionId);
  Future<TransactionOutput?> getTransactionOutput(
      TransactionOutputReference reference);
  Future<BlockId?> getBlockIdAtHeight(Int64 height);
  Future<BlockId> get canonicalHeadId =>
      getBlockIdAtHeight(Int64.ZERO).then((v) => v!);
  Future<BlockId> get genesisBlockId =>
      getBlockIdAtHeight(Int64.ONE).then((v) => v!);
  Future<List<TransactionOutputReference>> getLockAddressState(
      LockAddress lock);
  Stream<TraversalStep> get traversal;

  Future<void> broadcastTransaction(Transaction transaction);

  Future<void> broadcastBlock(Block block, Transaction? reward);

  Future<ActiveStaker?> getStaker(
      BlockId parentBlockId, Int64 slot, TransactionOutputReference account);

  Future<Int64> getTotalActivestake(BlockId parentBlockId, Int64 slot);

  Future<List<int>> calculateEta(BlockId parentBlockId, Int64 slot);

  Stream<BlockBody> get packBlock;

  Stream<BlockId> get adoptions =>
      traversal.whereType<TraversalStep_Applied>().map((t) => t.blockId);

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

  Future<BlockHeader> get genesisHeader =>
      genesisBlockId.then(getBlockHeaderOrRaise);

  Future<FullBlock> get genesisBlock =>
      genesisBlockId.then(getFullBlockOrRaise);

  Future<ProtocolSettings> get protocolSettings async {
    final genesis = await genesisBlock;
    return ProtocolSettings.defaultSettings
        .mergeFromMap(genesis.header.settings);
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

  Future<BlockHeader> get canonicalHead async =>
      getBlockHeaderOrRaise(await canonicalHeadId);
}

class BlockchainClientFromJsonRpc extends BlockchainClient {
  final JsonRpcClient client;

  BlockchainClientFromJsonRpc({required this.client});

  @override
  Future<BlockBody?> getBlockBody(BlockId blockId) =>
      client.getBlockBody(blockId);

  @override
  Future<BlockHeader?> getBlockHeader(BlockId blockId) =>
      client.getBlockHeader(blockId);

  @override
  Future<FullBlock?> getFullBlock(BlockId blockId) =>
      client.getFullBlock(blockId);

  @override
  Future<BlockId?> getBlockIdAtHeight(Int64 height) =>
      client.getBlockIdAtHeight(height);

  @override
  Future<List<TransactionOutputReference>> getLockAddressState(
          LockAddress lock) =>
      client.getLockAddressState(lock);

  @override
  Future<Transaction?> getTransaction(TransactionId transactionId) =>
      client.getTransaction(transactionId);

  @override
  Future<TransactionOutput?> getTransactionOutput(
          TransactionOutputReference reference) =>
      client.getTransactionOutput(reference);

  @override
  Stream<TraversalStep> get traversal => client.traversal;

  @override
  Future<void> broadcastTransaction(Transaction transaction) =>
      client.broadcastTransaction(transaction);

  @override
  Future<void> broadcastBlock(Block block, Transaction? reward) =>
      client.broadcastBlock(block, reward);

  @override
  Future<List<int>> calculateEta(BlockId parentBlockId, Int64 slot) =>
      client.getEta(parentBlockId, slot);

  @override
  Future<ActiveStaker?> getStaker(BlockId parentBlockId, Int64 slot,
          TransactionOutputReference account) =>
      client.getStaker(parentBlockId, slot, account);

  @override
  Future<Int64> getTotalActivestake(BlockId parentBlockId, Int64 slot) =>
      client.totalActiveStake(parentBlockId, slot);

  @override
  Stream<BlockBody> get packBlock => client.blockPacker;
}
