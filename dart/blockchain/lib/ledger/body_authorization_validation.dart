import 'package:blockchain/ledger/transaction_authorization_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodyAuthorizationValidation {
  Future<List<String>> validate(BlockBody body);
}

class BodyAuthorizationValidationImpl extends BodyAuthorizationValidation {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final TransactionAuthorizationValidation transactionAuthorizationVerifier;

  BodyAuthorizationValidationImpl(
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
