import 'package:blockchain_ledger/algebras/body_authorization_validation_algebra.dart';
import 'package:blockchain_ledger/algebras/transaction_authorization_verifier.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

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
