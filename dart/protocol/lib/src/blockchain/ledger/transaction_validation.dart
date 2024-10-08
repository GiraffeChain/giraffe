import 'package:giraffe_sdk/sdk.dart';
import 'package:collection/collection.dart';

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
    if (transaction.outputs.length > maxOutputsCount) {
      return ["ExcessiveOutputsCount"];
    }
    return [];
  }

  static List<String> dataLengthValidation(Transaction transaction) {
    final immutableBytes = transaction.immutableBytes;
    if (immutableBytes.length > maxDataLength) {
      return ["ExcessiveDataLength"];
    }
    return [];
  }

  static List<String> positiveOutputValuesValidation(Transaction transaction) {
    for (final output in transaction.outputs) {
      if (output.quantity <= 0) return ["NonPositiveOutputValue"];
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

  static const maxDataLength = 15360;
  static const maxOutputsCount = 32767;
}
