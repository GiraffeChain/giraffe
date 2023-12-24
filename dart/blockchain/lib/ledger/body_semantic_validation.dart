import 'package:blockchain/ledger/models/body_validation_context.dart';
import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain/ledger/transaction_semantic_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodySemanticValidation {
  Future<List<String>> validate(BlockBody body, BodyValidationContext context);
}

class BodySemanticValidationImpl extends BodySemanticValidation {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final TransactionSemanticValidation transactionSemanticValidation;

  BodySemanticValidationImpl(
      this.fetchTransaction, this.transactionSemanticValidation);

  @override
  Future<List<String>> validate(
      BlockBody body, BodyValidationContext context) async {
    final prefix = <Transaction>[];
    final transactionValidationContext = TransactionValidationContext(
        context.parentHeaderId, prefix, context.height, context.slot);
    for (final transactionId in body.transactionIds) {
      final transaction = await fetchTransaction(transactionId);
      final errors = await transactionSemanticValidation.validate(
          transaction, transactionValidationContext);
      if (errors.isNotEmpty)
        return errors;
      else
        prefix.add(transaction);
    }
    return [];
  }
}
