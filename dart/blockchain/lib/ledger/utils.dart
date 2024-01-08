import 'package:blockchain_protobuf/models/core.pb.dart';

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
      if (output.value.hasEdge()) {
        final edge = output.value.edge;
        final aTx = await fetchTransaction(edge.a.transactionId);
        final aTxO = aTx.outputs[edge.a.index];
        result.add(aTxO.value.vertex.edgeLockAddress);
        final bTx = await fetchTransaction(edge.b.transactionId);
        final bTxO = bTx.outputs[edge.b.index];
        result.add(bTxO.value.vertex.edgeLockAddress);
      }
    }
    return result;
  }
}
