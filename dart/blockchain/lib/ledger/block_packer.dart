import 'dart:collection';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/ledger/body_validation.dart';
import 'package:blockchain/ledger/mempool.dart';
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
  final Clock clock;
  final Future<Transaction> Function(TransactionId) fetchTransaction;
  final Future<bool> Function(TransactionId) transactionExistsLocally;
  final Future<bool> Function(BlockBody, TransactionValidationContext)
      validateTransaction;

  final log = Logger("BlockPacker");

  BlockPackerImpl(this.mempool, this.clock, this.fetchTransaction,
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
      final body =
          BlockBody(transactionIds: fullBody.transactions.map((t) => t.id));
      final context = TransactionValidationContext(parentBlockId, height, slot);
      final validationResult = await validateTransaction(body, context);
      if (validationResult) return fullBody;
      if (!queue.isEmpty) return improve(current);
      return null;
    }

    FullBlockBody best = FullBlockBody();

    while (clock.globalSlot < slot) {
      yield best;
      FullBlockBody? next = await improve(best);
      while (next == null) {
        if (clock.globalSlot >= slot) break;
        next = await Future.delayed(
            Duration(milliseconds: 200), () => improve(best));
      }
      if (clock.globalSlot >= slot) break;
      best = next!;
    }
  }

  static Future<bool> Function(BlockBody, TransactionValidationContext)
      makeBodyValidator(BodyValidation bodyValidation) {
    final log = Logger("BlockPacker.Validator");
    return (proposedBody, context) async {
      final errors = <String>[];
      errors.addAll(await bodyValidation.validate(proposedBody, context));
      if (errors.isNotEmpty) {
        log.fine("Rejecting block body due to errors=$errors");
        return false;
      }
      return true;
    };
  }
}
