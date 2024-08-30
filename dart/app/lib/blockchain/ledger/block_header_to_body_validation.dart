import 'package:blockchain_sdk/sdk.dart';
import 'package:hashlib/hashlib.dart';

abstract class BlockHeaderToBodyValidation {
  Future<List<String>> validate(Block block);
}

class BlockHeaderToBodyValidationImpl extends BlockHeaderToBodyValidation {
  final Future<BlockHeader> Function(BlockId) fetchHeader;

  BlockHeaderToBodyValidationImpl({required this.fetchHeader});
  @override
  Future<List<String>> validate(Block block) async {
    final parentHeader = await fetchHeader(block.header.parentHeaderId);
    final expectedTxRoot = TxRoot.calculateFromTransactionIds(
        parentHeader.txRoot.decodeBase58, block.body.transactionIds);
    if (expectedTxRoot.sameElements(block.header.txRoot.decodeBase58)) {
      return [];
    }
    return ["TxRoot Mismatch"];
  }
}

class TxRoot {
  static List<int> calculateFromTransactionIds(
      List<int> parentRoot, Iterable<TransactionId> transactionIds) {
    final sink = blake2b256.createSink();
    sink.add(parentRoot);
    for (final id in transactionIds) {
      sink.add(id.value.decodeBase58);
    }
    return sink.digest().bytes;
  }

  static List<int> calculateFromTransactions(
          List<int> parentRoot, Iterable<Transaction> transactions) =>
      calculateFromTransactionIds(parentRoot, transactions.map((t) => t.id));
}
