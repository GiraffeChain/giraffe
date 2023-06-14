import 'dart:collection';

import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_minting/algebras/block_packer_algebra.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';

class BlockPacker extends BlockPackerAlgebra {
  final MempoolAlgebra mempool;
  final Future<IoTransaction> Function(TransactionId) fetchTransaction;
  final Future<bool> Function(TransactionId) transactionExistsLocally;
  final Future<bool> Function(TransactionValidationContext) validateTransaction;

  final log = Logger("BlockPacker");

  BlockPacker(this.mempool, this.fetchTransaction,
      this.transactionExistsLocally, this.validateTransaction);

  @override
  Future<Iterative<FullBlockBody>> improvePackedBlock(
      BlockId parentBlockId, Int64 height, Int64 slot) async {
    final queue = Queue<IoTransaction>();

    populateQueue(FullBlockBody current) async {
      final mempoolTransactionIds = await mempool.read(parentBlockId);
      final unsortedTransactions =
          (await Future.wait(mempoolTransactionIds.map(fetchTransaction)))
              .where((tx) => !current.transactions.contains(tx));
      final transactionsWithLocalParents = <IoTransaction>[];
      for (final transaction in unsortedTransactions) {
        final spentIds =
            transaction.inputs.map((i) => i.address.ioTransaction32).toSet();
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
      final sortedTransactions = transactionsWithLocalParents.sortBy(Order.by(
          (a) => a.datum.event.schedule.timestamp.toInt(),
          Order.fromLessThan<int>((a1, a2) => a1 < a2)));

      queue.addAll(sortedTransactions);
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

    return improve;
  }

  static Future<bool> Function(TransactionValidationContext) makeBodyValidator(
      BodySyntaxValidationAlgebra bodySyntaxValidation,
      BodySemanticValidationAlgebra bodySemanticValidation,
      BodyAuthorizationValidationAlgebra bodyAuthorizationValidation) {
    final log = Logger("BlockPacker.Validator");
    return (context) async {
      final proposedBody = BlockBody(
          transactionIds: await Future.wait(context.prefix.map((t) => t.id)));
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
      final quivrContextBuilder = (IoTransaction tx) async =>
          QuivrContextForProposedBlock(
              context.height, context.slot, await tx.signableBytes);
      errors.addAll(await bodyAuthorizationValidation.validate(
          proposedBody, quivrContextBuilder));
      if (errors.isNotEmpty) {
        log.fine("Rejecting block body due to authorization errors: $errors");
        return false;
      }
      return true;
    };
  }
}
