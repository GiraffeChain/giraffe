import 'dart:async';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/local_chain.dart';
import 'package:blockchain/ledger/transaction_output_state.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:ribs_core/ribs_core.dart';
import 'package:ribs_effect/ribs_effect.dart';

abstract class Mempool {
  Future<Set<Transaction>> read(BlockId currentHead);
  Future<void> add(Transaction transaction);
  Stream<MempoolChange> get changes;
}

class MempoolImpl extends Mempool {
  final Future<BlockBody> Function(BlockId) fetchBlockBody;
  final BlockSourcedState<Map<TransactionId, MempoolEntry>> eventSourcedState;
  final StreamController<MempoolChange> mempoolChangesController;
  final Duration expirationDuration;
  final LocalChain localChain;

  MempoolImpl(
    this.fetchBlockBody,
    this.eventSourcedState,
    this.mempoolChangesController,
    this.expirationDuration,
    this.localChain,
  );

  static Resource<MempoolImpl> make(
    FetchBlockBody fetchBlockBody,
    FetchTransaction fetchTransaction,
    ParentChildTree<BlockId> parentChildTree,
    BlockId currentEventId,
    Duration expirationDuration,
    LocalChain localChain,
  ) =>
      ResourceUtils.streamController(
              () => StreamController<MempoolChange>.broadcast())
          .flatMap((mempoolChangesController) {
        final state = <TransactionId, MempoolEntry>{};
        final _add = (Transaction transaction) => state[transaction.id] =
            MempoolEntry(transaction, DateTime.now().add(expirationDuration));
        final eventSourcedState =
            BlockSourcedState<Map<TransactionId, MempoolEntry>>(
          (state, blockId) async {
            final blockBody = await fetchBlockBody(blockId);
            blockBody.transactionIds.forEach(state.remove);
            return state;
          },
          (state, blockId) async {
            final blockBody = await fetchBlockBody(blockId);
            for (final transactionId in blockBody.transactionIds) {
              final transaction = await fetchTransaction(transactionId);
              _add(transaction);
            }
            return state;
          },
          parentChildTree,
          state,
          currentEventId,
          (p0) async => {},
        );
        return Resource.pure(MempoolImpl(
          fetchBlockBody,
          eventSourcedState,
          mempoolChangesController,
          expirationDuration,
          localChain,
        )).flatTap(
            (impl) => ResourceUtils.backgroundStream(impl._expirationStream));
      });

  Stream<TransactionId> get _expirationStream =>
      Stream.periodic(Duration(seconds: 10)).asyncMap((_) async {
        final now = DateTime.now();
        return eventSourcedState.useStateAt(await localChain.currentHead,
            (state) async {
          final toRemove = Map.fromEntries(
              state.entries.where((e) => e.value.addedAt.isBefore(now)));
          for (final entry in toRemove.entries) {
            state.remove(entry.key);
            mempoolChangesController
                .add(MempoolExpired(transaction: entry.value.transaction));
          }
          return toRemove.keys;
        });
      }).expand(identity);

  @override
  Future<void> add(Transaction transaction) async =>
      eventSourcedState.useStateAt(await localChain.currentHead, (state) async {
        state[transaction.id] =
            MempoolEntry(transaction, DateTime.now().add(expirationDuration));
        mempoolChangesController.add(MempoolAdded(transaction: transaction));
      });

  @override
  Future<Set<Transaction>> read(BlockId currentHead) =>
      eventSourcedState.useStateAt(currentHead,
          (state) async => state.values.map((e) => e.transaction).toSet());

  @override
  Stream<MempoolChange> get changes => mempoolChangesController.stream;
}

class MempoolEntry {
  final Transaction transaction;
  final DateTime addedAt;

  MempoolEntry(this.transaction, this.addedAt);
}

sealed class MempoolChange {}

class MempoolAdded extends MempoolChange {
  final Transaction transaction;

  MempoolAdded({required this.transaction});
}

class MempoolExpired extends MempoolChange {
  final Transaction transaction;

  MempoolExpired({required this.transaction});
}
