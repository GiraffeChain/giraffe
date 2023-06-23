import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_common/utils.dart';
import 'package:blockchain_ledger/algebras/transaction_syntax_verifier.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';

class TransactionSyntaxInterpreter extends TransactionSyntaxVerifier {
  @override
  Future<List<String>> validate(Transaction transaction) async {
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
    positiveTimestampValidation,
    scheduleValidation,
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

  static List<String> positiveTimestampValidation(Transaction transaction) {
    if (transaction.schedule.timestamp < 0) {
      return ["InvalidTimestamp"];
    }
    return [];
  }

  static List<String> scheduleValidation(Transaction transaction) {
    final schedule = transaction.schedule;
    if (schedule.maxSlot < schedule.minSlot || schedule.minSlot < 0) {
      return ["InvalidSchedule"];
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
      if (value.hasPaymentToken()) {
        if (value.paymentToken.quantity <= 0) return ["NonPositiveOutputValue"];
      } else if (value.hasStakingToken()) {
        if (value.stakingToken.quantity <= 0) return ["NonPositiveOutputValue"];
      }
    }
    return [];
  }

  static List<String> sufficientFundsValidation(Transaction transaction) {
    Int64 paymentTokenBalance = Int64.ZERO;
    Int64 stakingTokenBalance = Int64.ZERO;
    for (final input in transaction.inputs) {
      if (input.value.hasPaymentToken()) {
        paymentTokenBalance += input.value.paymentToken.quantity;
      } else if (input.value.hasStakingToken()) {
        stakingTokenBalance += input.value.stakingToken.quantity;
      }
    }
    for (final output in transaction.outputs) {
      if (output.value.hasPaymentToken()) {
        paymentTokenBalance -= output.value.paymentToken.quantity.toBigInt;
      } else if (output.value.hasStakingToken()) {
        stakingTokenBalance -= output.value.stakingToken.quantity.toBigInt;
      }
    }
    if (paymentTokenBalance < Int64.ZERO || stakingTokenBalance < Int64.ZERO) {
      return ["InsufficientFunds"];
    }
    return [];
  }

  static List<String> attestationValidation(Transaction transaction) {
    List<String> verifyPropositionProofType(Lock lock, Key key) {
      if (lock.hasEd25519() && !key.hasEd25519()) return ["InvalidKeyType"];
      return <String>[];
    }

    for (final input in transaction.inputs) {
      final tRes = verifyPropositionProofType(input.lock, input.key);
      if (tRes.isNotEmpty) return tRes;
    }
    return [];
  }

  static const MaxDataLength = 15360;
  static const MaxOutputsCount = 32767;
}
