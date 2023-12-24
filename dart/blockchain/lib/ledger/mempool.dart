import 'dart:async';

import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class Mempool {
  Future<Set<TransactionId>> read(BlockId currentHead);
  Future<void> add(TransactionId transactionId);
  Future<void> remove(TransactionId transactionId);
}

class MempoolImpl extends Mempool {
  final Map<TransactionId, MempoolEntry> _state;
  final Future<BlockBody> Function(BlockId) fetchBlockBody;
  final EventSourcedState<Map<TransactionId, MempoolEntry>, BlockId>
      eventSourcedState;
  final Future<void> Function(TransactionId transactionId) _add;

  MempoolImpl._(
      this._state, this.fetchBlockBody, this.eventSourcedState, this._add);

  factory MempoolImpl(
      Future<BlockBody> Function(BlockId) fetchBlockBody,
      ParentChildTree<BlockId> parentChildTree,
      BlockId currentEventId,
      Duration expirationDuration) {
    final state = <TransactionId, MempoolEntry>{};
    final _add = (TransactionId transactionId) => state[transactionId] =
        MempoolEntry(transactionId, DateTime.now().add(expirationDuration));
    final eventSourcedState =
        EventTreeStateImpl<Map<TransactionId, MempoolEntry>, BlockId>(
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

    Timer.periodic(Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      state.removeWhere((key, value) => value.addedAt.isBefore(now));
    });

    return MempoolImpl._(
        state, fetchBlockBody, eventSourcedState, (id) async => _add(id));
  }

  @override
  Future<void> add(TransactionId transactionId) => _add(transactionId);

  @override
  Future<Set<TransactionId>> read(BlockId currentHead) => eventSourcedState
      .useStateAt(currentHead, (state) async => state.keys.toSet());

  @override
  Future<void> remove(TransactionId transactionId) async {
    _state.remove(transactionId);
  }
}

class MempoolEntry {
  final TransactionId transactionId;
  final DateTime addedAt;

  MempoolEntry(this.transactionId, this.addedAt);
}
