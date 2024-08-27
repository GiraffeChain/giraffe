import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

extension TransactionOps on Transaction {
  Future<Set<LockAddress>> requiredWitnesses(
      Future<TransactionOutput> Function(TransactionOutputReference)
          fetchTransactionOutput) async {
    final result = <LockAddress>{};
    for (final input in inputs) {
      final out = await fetchTransactionOutput(input.reference);
      result.add(out.lockAddress);
    }
    for (final output in outputs) {
      if (output.value.hasGraphEntry() && output.value.graphEntry.hasEdge()) {
        final edge = output.value.graphEntry.edge;
        final aTxO = await fetchTransactionOutput(edge.a);

        result.add(aTxO.value.ensureGraphEntry().vertex.edgeLockAddress);
        final bTxO = await fetchTransactionOutput(edge.b);
        result.add(bTxO.value.ensureGraphEntry().vertex.edgeLockAddress);
      }
      if (output.hasAccount()) {
        final accountTxO = await fetchTransactionOutput(output.account);
        result.add(accountTxO.lockAddress);
      }
    }
    return result;
  }

  Int64 get fee => Int64(100); // TODO

  Int64 get inputSum =>
      inputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get outputSum =>
      outputs.fold(Int64.ZERO, (a, input) => a + input.value.quantity);
  Int64 get reward => inputSum - outputSum;
}

extension FullBodyOps on FullBlockBody {
  Transaction? get rewardTransaction => transactions
      .map<Transaction?>((t) => t)
      .firstWhere((t) => t?.hasRewardParentBlockId() ?? false,
          orElse: () => null);
}
