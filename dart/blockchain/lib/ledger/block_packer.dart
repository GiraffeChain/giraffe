import 'dart:collection';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/ledger/body_authorization_validation.dart';
import 'package:blockchain/ledger/body_semantic_validation.dart';
import 'package:blockchain/ledger/body_syntax_validation.dart';
import 'package:blockchain/ledger/mempool.dart';
import 'package:blockchain/ledger/models/body_validation_context.dart';
import 'package:blockchain/ledger/models/transaction_validation_context.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';

abstract class BlockPacker {
  Stream<FullBlockBody> streamed(
    BlockId parentBlockId,
    Int64 height,
    Int64 slot,
  );
}

class BlockPackerImpl extends BlockPacker {
  final Mempool mempool;
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final Future<bool> Function(TransactionId) transactionExistsLocally;
  final Future<bool> Function(TransactionValidationContext) validateTransaction;

  final log = Logger("BlockPacker");

  BlockPackerImpl(this.mempool, this.fetchTransaction,
      this.transactionExistsLocally, this.validateTransaction);

  @override
  Stream<FullBlockBody> streamed(
      BlockId parentBlockId, Int64 height, Int64 slot) async* {
    final queue = Queue<Transaction>();

    populateQueue(FullBlockBody current) async {
      final mempoolTransactionIds = await mempool.read(parentBlockId);
      final unsortedTransactions =
          (await Future.wait(mempoolTransactionIds.map(fetchTransaction)))
              .where((tx) => !current.transactions.contains(tx));
      final transactionsWithLocalParents = <Transaction>[];
      for (final transaction in unsortedTransactions) {
        final spentIds =
            transaction.inputs.map((i) => i.reference.transactionId).toSet();
        bool dependenciesExistLocally = true;
        for (final id in spentIds) {
          if (!await transactionExistsLocally(id)) {
            dependenciesExistLocally = false;
            break;
          }
        }
        if (dependenciesExistLocally)
          transactionsWithLocalParents.add(transaction);
      }

      queue.addAll(transactionsWithLocalParents);
    }

    Future<FullBlockBody?> improve(FullBlockBody current) async {
      if (queue.isEmpty) await populateQueue(current);
      if (queue.isEmpty) return null;
      final transaction = queue.removeFirst();
      final fullBody = FullBlockBody()
        ..transactions.addAll(current.transactions)
        ..transactions.add(transaction);
      final context = TransactionValidationContext(
          parentBlockId, fullBody.transactions, height, slot);
      final validationResult = await validateTransaction(context);
      if (validationResult) return fullBody;
      if (!queue.isEmpty) return improve(current);
      return null;
    }

    FullBlockBody best = FullBlockBody();

    while (true) {
      yield best;
      FullBlockBody? next = await improve(best);
      while (next == null) {
        next = await Future.delayed(
            Duration(milliseconds: 200), () => improve(best));
      }
    }
  }

  static Future<bool> Function(TransactionValidationContext) makeBodyValidator(
      BodySyntaxValidation bodySyntaxValidation,
      BodySemanticValidation bodySemanticValidation,
      BodyAuthorizationValidation bodyAuthorizationValidation) {
    final log = Logger("BlockPacker.Validator");
    return (context) async {
      final proposedBody = BlockBody()
        ..transactionIds.addAll(context.prefix.map((t) => t.id));
      final errors = <String>[];

      errors.addAll(await bodySyntaxValidation.validate(proposedBody));
      if (errors.isNotEmpty) {
        log.fine("Rejecting block body due to syntax errors: $errors");
        return false;
      }

      final bodyValidationContext = BodyValidationContext(
          context.parentHeaderId, context.height, context.slot);
      errors.addAll(await bodySemanticValidation.validate(
          proposedBody, bodyValidationContext));
      if (errors.isNotEmpty) {
        log.fine("Rejecting block body due to semantic errors: $errors");
        return false;
      }
      errors.addAll(await bodyAuthorizationValidation.validate(proposedBody));
      if (errors.isNotEmpty) {
        log.fine("Rejecting block body due to authorization errors: $errors");
        return false;
      }
      return true;
    };
  }
}
