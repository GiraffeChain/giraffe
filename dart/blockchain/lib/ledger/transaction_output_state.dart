import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/store.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class TransactionOutputState {
  Future<bool> transactionOutputIsSpendable(
      BlockId blockId, TransactionOutputReference outputReference);
}

typedef State = Store<TransactionId, Uint32List>;
typedef FetchBlockBody = Future<BlockBody> Function(BlockId);
typedef FetchTransaction = Future<Transaction> Function(TransactionId);

class TransactionOutputStateImpl extends TransactionOutputState {
  final BlockSourcedState<State> eventSourcedState;

  TransactionOutputStateImpl(this.eventSourcedState);

  @override
  Future<bool> transactionOutputIsSpendable(
      BlockId blockId, TransactionOutputReference outputReference) async {
    final spendableIndices = await eventSourcedState.useStateAt(
        blockId, (state) => state.get(outputReference.transactionId));
    return spendableIndices != null &&
        spendableIndices.contains(outputReference.index);
  }

  factory TransactionOutputStateImpl.make(
      State initialState,
      BlockId currentBlockId,
      Future<BlockBody> Function(BlockId) fetchBlockBody,
      Future<Transaction> Function(TransactionId) fetchTransaction,
      ParentChildTree<BlockId> parentChildTree,
      Future<void> Function(BlockId) currentEventChanged) {
    final eventState = BlockSourcedState<State>(
      (state, blockId) => _applyBlock(
        fetchBlockBody,
        fetchTransaction,
        state,
        blockId,
      ),
      (state, blockId) => _unapplyBlock(
        fetchBlockBody,
        fetchTransaction,
        state,
        blockId,
      ),
      parentChildTree,
      initialState,
      currentBlockId,
      currentEventChanged,
    );
    return TransactionOutputStateImpl(eventState);
  }
}

Future<State> _applyBlock(FetchBlockBody fetchBlockBody,
    FetchTransaction fetchTransaction, State state, BlockId blockId) async {
  final body = await fetchBlockBody(blockId);
  for (final transactionId in body.transactionIds) {
    final transaction = await fetchTransaction(transactionId);
    for (final input in transaction.inputs) {
      final spentTxId = input.reference.transactionId;
      final unspentIndices = await state.getOrRaise(spentTxId);
      final newUnspentIndices = Uint32List.fromList(unspentIndices
          .where((index) => index != input.reference.index)
          .toList());
      if (newUnspentIndices.isEmpty) {
        await state.remove(spentTxId);
      } else {
        state.put(spentTxId, newUnspentIndices);
      }
    }
    if (transaction.outputs.isNotEmpty) {
      final indices = Uint32List.fromList(
          List.generate(transaction.outputs.length, (i) => i));
      await state.put(await transaction.id, indices);
    }
  }
  return state;
}

Future<State> _unapplyBlock(FetchBlockBody fetchBlockBody,
    FetchTransaction fetchTransaction, State state, BlockId blockId) async {
  final body = await fetchBlockBody(blockId);
  for (final transactionId in body.transactionIds) {
    final transaction = await fetchTransaction(transactionId);
    state.remove(transactionId);
    for (final input in transaction.inputs) {
      final spentTxId = input.reference.transactionId;
      final unspentIndices = await state.get(spentTxId);
      if (unspentIndices != null) {
        final newUnspentIndices = Uint32List.fromList(unspentIndices)
          ..add(input.reference.index);
        await state.put(spentTxId, newUnspentIndices);
      } else {
        await state.put(
            spentTxId, Uint32List.fromList([input.reference.index]));
      }
    }
  }
  return state;
}
