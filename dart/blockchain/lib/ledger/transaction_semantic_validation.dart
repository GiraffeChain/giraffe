import 'package:blockchain/codecs.dart';
import 'package:blockchain/ledger/box_state.dart';
import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TransactionSemanticValidation {
  Future<List<String>> validate(
      Transaction transaction, TransactionValidationContext context);
}

class TransactionSemanticValidationImpl extends TransactionSemanticValidation {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final BoxState boxState;

  TransactionSemanticValidationImpl(this.fetchTransaction, this.boxState);

  @override
  Future<List<String>> validate(
      Transaction transaction, TransactionValidationContext context) async {
    var augmentation = StateAugmentation.empty();

    for (final transaction in context.prefix) {
      augmentation.augment(transaction);
    }

    final errors = <String>[];
    for (final input in transaction.inputs) {
      errors.addAll(await _dataValidation(input, context));
      if (errors.isNotEmpty) return errors;
      errors.addAll(await _spendableValidation(input, context));
      if (errors.isNotEmpty) return errors;
    }
    return [];
  }

  Future<List<String>> _dataValidation(
      TransactionInput input, TransactionValidationContext context) async {
    final spentTransaction =
        await fetchTransaction(input.reference.transactionId);
    if (spentTransaction.outputs.length <= input.reference.index)
      return ["UnspendableBox"];
    final spentOutput = spentTransaction.outputs[input.reference.index];
    if (spentOutput.value != input.value) return ["InputDataMismatch"];
    final expectedAddress = input.lock.address;
    if (spentOutput.lockAddress != expectedAddress)
      return ["InputDataMismatch"];
    return [];
  }

  Future<List<String>> _spendableValidation(
      TransactionInput input, TransactionValidationContext context) async {
    final boxExists =
        await boxState.boxExistsAt(context.parentHeaderId, input.reference);
    if (!boxExists) return ["UnspendableBox"];
    return [];
  }
}
