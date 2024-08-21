import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

extension TransactionOps on Transaction {
  Future<Set<LockAddress>> requiredWitnesses(
      Future<Transaction> Function(TransactionId) fetchTransaction) async {
    final result = <LockAddress>{};
    for (final input in inputs) {
      final tx = await fetchTransaction(input.reference.transactionId);
      final out = tx.outputs[input.reference.index];
      result.add(out.lockAddress);
    }
    for (final output in outputs) {
      // TODO: Account lock address
      if (output.value.hasGraphEntry() && output.value.graphEntry.hasEdge()) {
        final edge = output.value.graphEntry.edge;
        final aTx = await fetchTransaction(edge.a.transactionId);
        final aTxO = aTx.outputs[edge.a.index];

        result.add(aTxO.value.ensureGraphEntry().vertex.edgeLockAddress);
        final bTx = await fetchTransaction(edge.b.transactionId);
        final bTxO = bTx.outputs[edge.b.index];
        result.add(bTxO.value.ensureGraphEntry().vertex.edgeLockAddress);
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
