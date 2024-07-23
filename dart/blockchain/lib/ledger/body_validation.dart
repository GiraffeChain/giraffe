import 'package:blockchain_sdk/sdk.dart';
import 'package:blockchain/ledger/transaction_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

abstract class BodyValidation {
  Future<List<String>> validate(
      BlockBody body, TransactionValidationContext context);
}

class BodyValidationImpl extends BodyValidation {
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final TransactionSyntaxValidation transactionSyntaxValidation;
  final TransactionSemanticValidation transactionSemanticValidation;
  final Int64 inflation;

  BodyValidationImpl({
    required this.fetchTransaction,
    required this.transactionSyntaxValidation,
    required this.transactionSemanticValidation,
    required this.inflation,
  });

  @override
  Future<List<String>> validate(
      BlockBody body, TransactionValidationContext context) async {
    final errors = <String>[];
    final spentOutputs = <TransactionOutputReference>[];
    Transaction? rewardTransaction;
    Int64 collectibleReward = inflation;
    for (final transactionId in body.transactionIds) {
      final transaction = await fetchTransaction(transactionId);
      spentOutputs.addAll(transaction.inputs.map((input) => input.reference));
      if (transaction.hasRewardParentBlockId()) {
        if (rewardTransaction != null) return ["DuplicateRewardTransaction"];
        rewardTransaction = transaction;
      } else {
        collectibleReward += transaction.reward;
      }
      errors.addAll(transactionSyntaxValidation.validate(transaction));
      if (errors.isNotEmpty) return errors;
      errors.addAll(
          await transactionSemanticValidation.validate(transaction, context));
      if (errors.isNotEmpty) return errors;
    }
    if (spentOutputs.toSet().length != spentOutputs.length)
      return ["DoubleSpend"];
    if (rewardTransaction != null)
      errors.addAll(validateReward(
          rewardTransaction, collectibleReward, context.parentHeaderId));
    if (errors.isNotEmpty) return errors;
    return [];
  }

  List<String> validateReward(
    Transaction transaction,
    Int64 maximumReward,
    BlockId parentBlockId,
  ) {
    if (transaction.rewardParentBlockId != parentBlockId)
      return ["InvalidRewardBlockId"];
    if (transaction.inputs.isNotEmpty) return ["InvalidRewardInput"];
    if (transaction.attestation.isNotEmpty)
      return ["RewardContainsAttestation"];
    Int64 claimedSum = Int64.ZERO;
    for (final output in transaction.outputs) {
      if (output.value.hasAccountRegistration())
        return ["RewardContainsRegistration"];
      else if (output.value.hasGraphEntry())
        return ["RewardContainsGraphElement"];
      claimedSum += output.value.quantity;
    }
    if (claimedSum > maximumReward) return ["InvalidRewardQuantity"];
    return [];
  }
}
