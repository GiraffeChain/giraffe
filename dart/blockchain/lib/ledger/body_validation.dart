import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain/ledger/transaction_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BodyValidation {
  Future<List<String>> validate(
      BlockBody body, TransactionValidationContext context);
}

class BodyValidationImpl extends BodyValidation {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final TransactionSyntaxValidation transactionSyntaxValidation;
  final TransactionSemanticValidation transactionSemanticValidation;

  BodyValidationImpl(
      {required this.fetchTransaction,
      required this.transactionSyntaxValidation,
      required this.transactionSemanticValidation});

  @override
  Future<List<String>> validate(
      BlockBody body, TransactionValidationContext context) async {
    final spentOutputs = <TransactionOutputReference>[];
    final syntaxErrors = await Stream.fromIterable(body.transactionIds)
        .asyncMap(fetchTransaction)
        .map((transaction) {
      transaction.inputs.forEach((input) => spentOutputs.add(input.reference));
      return transaction;
    }).asyncMap((transaction) async {
      final syntaxErrors = transactionSyntaxValidation.validate(transaction);
      if (syntaxErrors.isNotEmpty) return syntaxErrors;
      return transactionSemanticValidation.validate(transaction, context);
    }).firstWhere((errors) => errors.isNotEmpty, orElse: () => []);
    if (syntaxErrors.isNotEmpty) return syntaxErrors;
    if (spentOutputs.toSet().length != spentOutputs.length)
      return ["DoubleSpend"];
    return [];
  }
}
