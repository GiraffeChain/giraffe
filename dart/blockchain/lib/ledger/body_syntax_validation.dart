import 'package:blockchain/ledger/transaction_syntax_interpreter.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodySyntaxValidationAlgebra {
  Future<List<String>> validate(BlockBody body);
}

class BodySyntaxValidation extends BodySyntaxValidationAlgebra {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final TransactionSyntaxVerifier transactionSyntaxVerifier;

  BodySyntaxValidation(this.fetchTransaction, this.transactionSyntaxVerifier);
  @override
  Future<List<String>> validate(BlockBody body) async {
    final transactions = await Future.wait(body.transactionIds
        .map((transactionId) => fetchTransaction(transactionId)));
    final errors = <String>[];
    errors.addAll(_validateDistinctInputs(transactions));
    if (errors.isNotEmpty) return errors;
    for (final transaction in transactions) {
      errors.addAll(await transactionSyntaxVerifier.validate(transaction));
      if (errors.isNotEmpty) return errors;
    }
    return [];
  }

  List<String> _validateDistinctInputs(Iterable<Transaction> transactions) {
    final inputs = <TransactionOutputReference>{};
    for (final transaction in transactions) {
      for (final input in transaction.inputs) {
        final address = input.reference;
        if (inputs.contains(address)) {
          return ["DoubleSpend"];
        }
        inputs.add(address);
      }
    }
    return [];
  }
}
