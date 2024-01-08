import 'dart:async';

import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fpdart/fpdart.dart';

abstract class Mempool {
  Future<Set<TransactionId>> read(BlockId currentHead);
  Future<void> add(TransactionId transactionId);
  Stream<MempoolChange> get changes;
}

class MempoolImpl extends Mempool {
  final Map<TransactionId, MempoolEntry> _state;
  final Future<BlockBody> Function(BlockId) fetchBlockBody;
  final BlockSourcedState<Map<TransactionId, MempoolEntry>> eventSourcedState;
  final StreamController<MempoolChange> mempoolChangesController;
  final Duration expirationDuration;

  MempoolImpl._(
    this._state,
    this.fetchBlockBody,
    this.eventSourcedState,
    this.mempoolChangesController,
    this.expirationDuration,
  );

  static Resource<MempoolImpl> make(
          Future<BlockBody> Function(BlockId) fetchBlockBody,
          ParentChildTree<BlockId> parentChildTree,
          BlockId currentEventId,
          Duration expirationDuration) =>
      Resource.streamController(
              () => StreamController<MempoolChange>.broadcast())
          .flatMap((mempoolChangesController) {
        final state = <TransactionId, MempoolEntry>{};
        final _add = (TransactionId transactionId) => state[transactionId] =
            MempoolEntry(transactionId, DateTime.now().add(expirationDuration));
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
              _add(transactionId);
            }
            return state;
          },
          parentChildTree,
          state,
          currentEventId,
          (p0) async => {},
        );

        return Resource.make(
          () =>
              Future.sync(() => Timer.periodic(Duration(seconds: 30), (timer) {
                    final now = DateTime.now();
                    final toRemove =
                        state.filter((v) => v.addedAt.isBefore(now));
                    for (final id in toRemove.keys) {
                      state.remove(id);
                      mempoolChangesController.add(MempoolExpired(id: id));
                    }
                  })),
          (timer) async => timer.cancel(),
        ).as(MempoolImpl._(state, fetchBlockBody, eventSourcedState,
            mempoolChangesController, expirationDuration));
      });

  @override
  Future<void> add(TransactionId transactionId) async {
    _state[transactionId] =
        MempoolEntry(transactionId, DateTime.now().add(expirationDuration));
    mempoolChangesController.add(MempoolAdded(id: transactionId));
  }

  @override
  Future<Set<TransactionId>> read(BlockId currentHead) => eventSourcedState
      .useStateAt(currentHead, (state) async => state.keys.toSet());

  @override
  Stream<MempoolChange> get changes => mempoolChangesController.stream;
}

class MempoolEntry {
  final TransactionId transactionId;
  final DateTime addedAt;

  MempoolEntry(this.transactionId, this.addedAt);
}

sealed class MempoolChange {}

class MempoolAdded extends MempoolChange {
  final TransactionId id;

  MempoolAdded({required this.id});
}

class MempoolExpired extends MempoolChange {
  final TransactionId id;

  MempoolExpired({required this.id});
}
