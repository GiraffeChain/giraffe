import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/transformers.dart';

abstract class BlockchainView {
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

class BlockchainViewFromRpc extends BlockchainView {
  final NodeRpcClient nodeClient;

  BlockchainViewFromRpc({required this.nodeClient});

  @override
  Future<BlockBody?> getBlockBody(BlockId blockId) => retryableFuture(
          () => nodeClient.getBlockBody(GetBlockBodyReq(blockId: blockId)))
      .then((v) => v.hasBody() ? v.body : null);

  @override
  Future<BlockHeader?> getBlockHeader(BlockId blockId) => retryableFuture(
          () => nodeClient.getBlockHeader(GetBlockHeaderReq(blockId: blockId)))
      .then((v) => v.hasHeader() ? v.header : null);

  @override
  Future<BlockId?> getBlockIdAtHeight(Int64 height) => retryableFuture(() =>
          nodeClient.getBlockIdAtHeight(GetBlockIdAtHeightReq(height: height)))
      .then((v) => v.hasBlockId() ? v.blockId : null);

  @override
  Future<Transaction?> getTransaction(TransactionId transactionId) =>
      retryableFuture(() => nodeClient
              .getTransaction(GetTransactionReq(transactionId: transactionId)))
          .then((v) => v.hasTransaction() ? v.transaction : null);

  Future<TransactionOutput?> getTransactionOutput(
          TransactionOutputReference reference) =>
      retryableFuture(() => nodeClient.getTransactionOutput(
              GetTransactionOutputReq(reference: reference)))
          .then((v) => v.hasTransactionOutput() ? v.transactionOutput : null);

  @override
  Future<List<TransactionOutputReference>> getLockAddressState(
          LockAddress lock) =>
      retryableFuture(() => nodeClient
              .getLockAddressState(GetLockAddressStateReq(address: lock)))
          .then((v) => v.transactionOutputs);

  @override
  Stream<TraversalStep> get traversal {
    _follow() {
      final x = nodeClient.follow(FollowReq());
      return x.doOnCancel(x.cancel);
    }

    return retryableStream(_follow,
        onError: (e, s) =>
            _log.warning("Remote traversal error. Retrying.", e, s)).map(
        (followR) => followR.hasAdopted()
            ? TraversalStep_Applied(followR.adopted)
            : TraversalStep_Unapplied(followR.unadopted));
  }
}

final Logger _log = Logger("Blockchain.View");
