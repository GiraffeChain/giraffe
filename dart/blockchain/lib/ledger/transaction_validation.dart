import 'package:blockchain_sdk/sdk.dart';
import 'package:blockchain/ledger/transaction_output_state.dart';
import 'package:blockchain/ledger/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';

abstract class TransactionSyntaxValidation {
  List<String> validate(Transaction transaction);
}

class TransactionSyntaxValidationImpl extends TransactionSyntaxValidation {
  @override
  List<String> validate(Transaction transaction) {
    for (final validator in validators) {
      final errors = validator(transaction);
      if (errors.isNotEmpty) {
        return errors;
      }
    }

    return [];
  }

  static const validators = [
    nonEmptyInputsValidation,
    distinctInputsValidation,
    maximumOutputsCountValidation,
    dataLengthValidation,
    positiveOutputValuesValidation,
    sufficientFundsValidation,
    attestationValidation,
  ];

  static List<String> nonEmptyInputsValidation(Transaction transaction) {
    if (transaction.inputs.isEmpty) {
      return ["EmptyInputs"];
    }
    return [];
  }

  static List<String> distinctInputsValidation(Transaction transaction) {
    if (transaction.inputs
        .groupListsBy((input) => input.reference)
        .entries
        .where((entry) => entry.value.length > 1)
        .isNotEmpty) {
      return ["DuplicateInputs"];
    }
    return [];
  }

  static List<String> maximumOutputsCountValidation(Transaction transaction) {
    if (transaction.outputs.length > MaxOutputsCount) {
      return ["ExcessiveOutputsCount"];
    }
    return [];
  }

  static List<String> dataLengthValidation(Transaction transaction) {
    final immutableBytes = transaction.immutableBytes;
    if (immutableBytes.length > MaxDataLength) {
      return ["ExcessiveDataLength"];
    }
    return [];
  }

  static List<String> positiveOutputValuesValidation(Transaction transaction) {
    for (final output in transaction.outputs) {
      final value = output.value;
      if (value.quantity <= 0) return ["NonPositiveOutputValue"];
    }
    return [];
  }

  static List<String> sufficientFundsValidation(Transaction transaction) {
    Int64 paymentTokenBalance = Int64.ZERO;
    for (final input in transaction.inputs) {
      paymentTokenBalance += input.value.quantity;
    }
    for (final output in transaction.outputs) {
      paymentTokenBalance -= output.value.quantity;
    }
    if (paymentTokenBalance < Int64.ZERO) {
      return ["InsufficientFunds"];
    }
    return [];
  }

  static List<String> attestationValidation(Transaction transaction) {
    List<String> verifyLockKeyType(Lock lock, Key key) {
      if (lock.hasEd25519() && !key.hasEd25519()) return ["InvalidKeyType"];
      return <String>[];
    }

    for (final witness in transaction.attestation) {
      final tRes = verifyLockKeyType(witness.lock, witness.key);
      if (tRes.isNotEmpty) return tRes;
    }
    return [];
  }

  static const MaxDataLength = 15360;
  static const MaxOutputsCount = 32767;
}

abstract class TransactionSemanticValidation {
  Future<List<String>> validate(
      Transaction transaction, TransactionValidationContext context);
}

class TransactionSemanticValidationImpl extends TransactionSemanticValidation {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final TransactionOutputState transactionOutputState;

  TransactionSemanticValidationImpl(
      this.fetchTransaction, this.transactionOutputState);

  @override
  Future<List<String>> validate(
      Transaction transaction, TransactionValidationContext context) async {
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
      return ["UnspendableTransactionOutput"];
    final spentOutput = spentTransaction.outputs[input.reference.index];
    if (spentOutput.value != input.value) return ["InputDataMismatch"];
    return [];
  }

  Future<List<String>> _attestationValidation(
      Transaction transaction, TransactionValidationContext context) async {
    final providedLockAddressesList =
        transaction.attestation.map((w) => w.lockAddress).toList();
    final providedLockAddresses = providedLockAddressesList.toSet();
    if (providedLockAddressesList.length != providedLockAddresses.length)
      return ["Duplicate witness"];
    final expectedLockAddresses =
        await transaction.requiredWitnesses(fetchTransaction);
    if (!_lockAddressSetEq.equals(expectedLockAddresses, providedLockAddresses))
      return ["Insufficient attestation"];
    final witnessContext = WitnessContext(
      height: context.height,
      slot: context.slot,
      messageToSign: transaction.signableBytes,
    );
    return Stream.fromIterable(transaction.attestation)
        .asyncMap(witnessContext.validate)
        .firstWhere((e) => e.isNotEmpty, orElse: () => <String>[]);
  }

  Future<List<String>> _spendableValidation(
      TransactionInput input, TransactionValidationContext context) async {
    final transactionOutputIsSpendable = await transactionOutputState
        .transactionOutputIsSpendable(context.parentHeaderId, input.reference);
    if (!transactionOutputIsSpendable) return ["UnspendableTransactionOutput"];
    return [];
  }

  Future<List<String>> _graphValidation(
      TransactionOutput output, TransactionValidationContext context) async {
    if (output.value.hasGraphEntry() && output.value.graphEntry.hasEdge()) {
      final edge = output.value.graphEntry.edge;

      if (!(await transactionOutputState.transactionOutputIsSpendable(
          context.parentHeaderId, edge.a))) return ["Edge.A Not Spendable"];
      if (!(await transactionOutputState.transactionOutputIsSpendable(
          context.parentHeaderId, edge.b))) return ["Edge.B Not Spendable"];

      final aTx = await fetchTransaction(edge.a.transactionId);
      final aOutput = aTx.outputs[edge.a.index];
      if (!aOutput.value.hasGraphEntry() ||
          !aOutput.value.graphEntry.hasVertex())
        return ["Edge.A is not a vertex"];
      final bTx = await fetchTransaction(edge.b.transactionId);
      final bOutput = bTx.outputs[edge.b.index];
      if (!bOutput.value.hasGraphEntry() ||
          !bOutput.value.graphEntry.hasVertex())
        return ["Edge.B is not a vertex"];
    }
    return [];
  }
}

const _lockAddressSetEq = SetEquality<LockAddress>();
