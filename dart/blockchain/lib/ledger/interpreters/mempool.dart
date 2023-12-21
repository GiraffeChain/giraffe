import 'dart:async';

import 'package:blockchain/common/algebras/event_sourced_state_algebra.dart';
import 'package:blockchain/common/interpreters/event_tree_state.dart';
import 'package:blockchain/common/interpreters/parent_child_tree.dart';
import 'package:blockchain/ledger/algebras/mempool_algebra.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Mempool extends MempoolAlgebra {
  final Map<TransactionId, MempoolEntry> _state;
  final Future<BlockBody> Function(BlockId) fetchBlockBody;
  final EventSourcedStateAlgebra<Map<TransactionId, MempoolEntry>, BlockId>
      eventSourcedState;
  final Future<void> Function(TransactionId transactionId) _add;

  Mempool._(
      this._state, this.fetchBlockBody, this.eventSourcedState, this._add);

  factory Mempool(
      Future<BlockBody> Function(BlockId) fetchBlockBody,
      ParentChildTree<BlockId> parentChildTree,
      BlockId currentEventId,
      Duration expirationDuration) {
    final state = <TransactionId, MempoolEntry>{};
    final _add = (TransactionId transactionId) => state[transactionId] =
        MempoolEntry(transactionId, DateTime.now().add(expirationDuration));
    final eventSourcedState =
        EventTreeState<Map<TransactionId, MempoolEntry>, BlockId>(
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

    return Mempool._(
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
