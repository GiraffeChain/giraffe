import 'package:blockchain/ledger/transaction_authorization_interpreter.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodyAuthorizationValidationAlgebra {
  Future<List<String>> validate(BlockBody body);
}

class BodyAuthorizationValidation extends BodyAuthorizationValidationAlgebra {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final TransactionAuthorizationVerifier transactionAuthorizationVerifier;

  BodyAuthorizationValidation(
      this.fetchTransaction, this.transactionAuthorizationVerifier);

  @override
  Future<List<String>> validate(BlockBody body) async {
    for (final transactionId in body.transactionIds) {
      final transaction = await fetchTransaction(transactionId);
      final errors =
          await transactionAuthorizationVerifier.validate(transaction);
      if (errors.isNotEmpty) return errors;
    }
    return [];
  }
}
