import 'package:blockchain/codecs.dart';
import 'package:blockchain/ledger/box_state.dart';
import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain/ledger/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:collection/collection.dart';

abstract class TransactionSemanticValidation {
  Future<List<String>> validate(
      Transaction transaction, TransactionValidationContext context);
}

const _lockAddressSetEq = SetEquality<LockAddress>();

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
    errors.addAll(await _attestationValidation(transaction, context));
    if (errors.isNotEmpty) return errors;
    for (final output in transaction.outputs) {
      errors.addAll(await _graphValidation(output, context));
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
    return [];
  }

  Future<List<String>> _attestationValidation(
      Transaction transaction, TransactionValidationContext context) async {
    final providedLockAddressesList =
        transaction.attestation.map((w) => w.lockAddress).toList();
    final providedLockAddresses = providedLockAddressesList.toSet();
    if (providedLockAddressesList.length != providedLockAddresses)
      return ["Duplicate witness"];
    final expectedLockAddresses =
        await transaction.expectedAttestations(fetchTransaction);
    if (!_lockAddressSetEq.equals(expectedLockAddresses, providedLockAddresses))
      return ["Insufficient attestation"];
    final witnessContext = WitnessContext(
        height: context.height,
        slot: context.slot,
        messageToSign: transaction.immutableBytes);
    return Stream.fromIterable(transaction.attestation)
        .asyncMap(witnessContext.validate)
        .firstWhere((e) => e.isNotEmpty, orElse: () => <String>[]);
  }

  Future<List<String>> _spendableValidation(
      TransactionInput input, TransactionValidationContext context) async {
    final boxExists =
        await boxState.boxExistsAt(context.parentHeaderId, input.reference);
    if (!boxExists) return ["UnspendableBox"];
    return [];
  }

  Future<List<String>> _graphValidation(
      TransactionOutput output, TransactionValidationContext context) async {
    if (output.value.hasEdge()) {
      final edge = output.value.edge;

      if (!(await boxState.boxExistsAt(context.parentHeaderId, edge.a)))
        return ["Edge.A Not Spendable"];
      if (!(await boxState.boxExistsAt(context.parentHeaderId, edge.b)))
        return ["Edge.B Not Spendable"];

      final aTx = await fetchTransaction(edge.a.transactionId);
      if (!aTx.outputs[edge.a.index].value.hasVertex())
        return ["Edge.A is not a vertex"];
      final bTx = await fetchTransaction(edge.b.transactionId);
      if (!bTx.outputs[edge.b.index].value.hasVertex())
        return ["Edge.B is not a vertex"];
    }
    return [];
  }
}
