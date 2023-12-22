import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/store.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fpdart/fpdart.dart';

abstract class BoxStateAlgebra {
  Future<bool> boxExistsAt(
      BlockId blockId, TransactionOutputReference outputReference);
}

typedef State = StoreAlgebra<TransactionId, List<int>>;
typedef FetchBlockBody = Future<BlockBody> Function(BlockId);
typedef FetchTransaction = Future<Transaction> Function(TransactionId);

class BoxState extends BoxStateAlgebra {
  final EventSourcedStateAlgebra<State, BlockId> eventSourcedState;

  BoxState(this.eventSourcedState);

  @override
  Future<bool> boxExistsAt(
      BlockId blockId, TransactionOutputReference boxId) async {
    final spendableIndices = await eventSourcedState.useStateAt(
        blockId, (state) => state.get(boxId.transactionId));
    return spendableIndices != null && spendableIndices.contains(boxId.index);
  }

  factory BoxState.make(
      State initialState,
      BlockId currentBlockId,
      Future<BlockBody> Function(BlockId) fetchBlockBody,
      Future<Transaction> Function(TransactionId) fetchTransaction,
      ParentChildTreeAlgebra<BlockId> parentChildTree,
      Future<void> Function(BlockId) currentEventChanged) {
    final eventState = EventTreeState<State, BlockId>(
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
    return BoxState(eventState);
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
      final newUnspentIndices = unspentIndices
          .where((index) => index != input.reference.index)
          .toList();
      if (newUnspentIndices.isEmpty) {
        await state.remove(spentTxId);
      } else {
        state.put(spentTxId, newUnspentIndices);
      }
    }
    if (transaction.outputs.isNotEmpty) {
      final indices =
          transaction.outputs.mapWithIndex((t, index) => index).toList();
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
        final newUnspentIndices = List.of(unspentIndices)
          ..add(input.reference.index);
        await state.put(spentTxId, newUnspentIndices);
      } else {
        await state.put(spentTxId, [input.reference.index]);
      }
    }
  }
  return state;
}

class AugmentedBoxState extends BoxStateAlgebra {
  final BoxStateAlgebra boxState;
  final StateAugmentation stateAugmentation;

  AugmentedBoxState(this.boxState, this.stateAugmentation);
  @override
  Future<bool> boxExistsAt(
      BlockId blockId, TransactionOutputReference boxId) async {
    if (stateAugmentation.newBoxIds.contains(boxId))
      return true;
    else if (stateAugmentation.spentBoxIds.contains(boxId))
      return false;
    else
      return boxState.boxExistsAt(blockId, boxId);
  }
}

class StateAugmentation {
  final Set<TransactionOutputReference> spentBoxIds;
  final Set<TransactionOutputReference> newBoxIds;

  StateAugmentation(this.spentBoxIds, this.newBoxIds);

  StateAugmentation.empty()
      : spentBoxIds = {},
        newBoxIds = {};

  Future<StateAugmentation> augment(Transaction transaction) async {
    final transactionSpentBoxIds =
        transaction.inputs.map((i) => i.reference).toSet();
    final transactionId = await transaction.id;
    final transactionNewBoxIds = transaction.outputs
        .mapWithIndex((t, index) => TransactionOutputReference()
          ..index = index
          ..transactionId = transactionId)
        .toSet();

    transactionNewBoxIds.addAll(newBoxIds);
    transactionNewBoxIds.removeAll(transactionSpentBoxIds);
    return StateAugmentation(
        transactionSpentBoxIds..addAll(spentBoxIds), transactionNewBoxIds);
  }
}
