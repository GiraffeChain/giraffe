import 'package:blockchain_common/algebras/event_sourced_state_algebra.dart';
import 'package:blockchain_common/algebras/parent_child_tree_algebra.dart';
import 'package:blockchain_common/algebras/store_algebra.dart';
import 'package:blockchain_common/interpreters/event_tree_state.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';

class ConsensusData {
  final StoreAlgebra<void, Int64> totalActiveStake;
  final StoreAlgebra<void, Int64> totalInactiveStake;
  final StoreAlgebra<StakingAddress, ActiveStaker> registrations;

  ConsensusData(
      this.totalActiveStake, this.totalInactiveStake, this.registrations);
}

EventSourcedStateAlgebra<ConsensusData, BlockId> consensusDataEventSourcedState(
    BlockId initialBlockId,
    ParentChildTreeAlgebra<BlockId> parentChildTree,
    Future<void> Function(BlockId) currentEventChanged,
    ConsensusData initialState,
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction) {
  return EventTreeState(
      _applyBlock(fetchBlockBody, fetchTransaction),
      _unapplyBlock(fetchBlockBody, fetchTransaction),
      parentChildTree,
      initialState,
      initialBlockId,
      currentEventChanged);
}

Future<ConsensusData> Function(ConsensusData, BlockId) _applyBlock(
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction) {
  List<ActiveStaker> removedStakersOf(Transaction transaction) =>
      transaction.inputs
          .where((i) =>
              i.hasValue() &&
              i.value.hasStakingToken() &&
              i.value.stakingToken.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.stakingToken.registration
            ..quantity = i.value.stakingToken.quantity)
          .toList();

  List<ActiveStaker> addedStakersOf(Transaction transaction) =>
      transaction.outputs
          .where((i) =>
              i.hasValue() &&
              i.value.hasStakingToken() &&
              i.value.stakingToken.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.stakingToken.registration
            ..quantity = i.value.stakingToken.quantity)
          .toList();

  Future<ConsensusData> apply(ConsensusData state, BlockId blockId) async {
    final body = await fetchBlockBody(blockId);
    final transactions =
        await Future.wait(body.transactionIds.map(fetchTransaction));
    final spentActiveStake = _activeQuantityOf(
        transactions.flatMap((t) => t.inputs).map((i) => i.value));
    final createdActiveStake = _activeQuantityOf(
        transactions.flatMap((t) => t.outputs).map((o) => o.value));
    final previousTotalActiveStake =
        await state.totalActiveStake.getOrRaise("");
    await state.totalActiveStake.put(
        "", previousTotalActiveStake - spentActiveStake + createdActiveStake);
    final spentInactiveStake = _inactiveQuantityOf(
        transactions.flatMap((t) => t.inputs).map((i) => i.value));
    final createdInactiveStake = _inactiveQuantityOf(
        transactions.flatMap((t) => t.outputs).map((o) => o.value));
    final previousTotalInactiveStake =
        await state.totalInactiveStake.getOrRaise("");
    await state.totalInactiveStake.put("",
        previousTotalInactiveStake - spentInactiveStake + createdInactiveStake);
    final removedRegistrations = transactions.flatMap(removedStakersOf);
    final addedRegistrations = transactions.flatMap(addedStakersOf);
    await Future.wait(removedRegistrations
        .map((r) => state.registrations.remove(r.registration.stakingAddress)));
    await Future.wait(addedRegistrations.map(
        ((r) => state.registrations.put(r.registration.stakingAddress, r))));
    return state;
  }

  return apply;
}

Future<ConsensusData> Function(ConsensusData, BlockId) _unapplyBlock(
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction) {
  List<ActiveStaker> removedStakersOf(Transaction transaction) =>
      transaction.inputs.reversed
          .where((i) =>
              i.hasValue() &&
              i.value.hasStakingToken() &&
              i.value.stakingToken.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.stakingToken.registration
            ..quantity = i.value.stakingToken.quantity)
          .toList();

  List<ActiveStaker> addedStakersOf(Transaction transaction) =>
      transaction.outputs.reversed
          .where((i) =>
              i.hasValue() &&
              i.value.hasStakingToken() &&
              i.value.stakingToken.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.stakingToken.registration
            ..quantity = i.value.stakingToken.quantity)
          .toList();
  Future<ConsensusData> f(ConsensusData state, BlockId blockId) async {
    final body = await fetchBlockBody(blockId);
    final transactions =
        await Future.wait(body.transactionIds.reversed.map(fetchTransaction));
    final spentActiveStake = _activeQuantityOf(
        transactions.flatMap((t) => t.inputs.reversed).map((i) => i.value));
    final createdActiveStake = _activeQuantityOf(
        transactions.flatMap((t) => t.outputs.reversed).map((o) => o.value));
    final previousTotalActiveStake =
        await state.totalActiveStake.getOrRaise("");
    await state.totalActiveStake.put(
        "", previousTotalActiveStake + spentActiveStake - createdActiveStake);
    final spentInactiveStake = _inactiveQuantityOf(
        transactions.flatMap((t) => t.inputs.reversed).map((i) => i.value));
    final createdInactiveStake = _inactiveQuantityOf(
        transactions.flatMap((t) => t.outputs.reversed).map((o) => o.value));
    final previousTotalInactiveStake =
        await state.totalInactiveStake.getOrRaise("");
    await state.totalInactiveStake.put("",
        previousTotalInactiveStake + spentInactiveStake - createdInactiveStake);
    final addedRegistrations = transactions.flatMap(addedStakersOf);
    final removedRegistrations = transactions.flatMap(removedStakersOf);
    await Future.wait(addedRegistrations
        .map((r) => state.registrations.remove(r.registration.stakingAddress)));
    await Future.wait(removedRegistrations.map(
        ((r) => state.registrations.put(r.registration.stakingAddress, r))));
    return state;
  }

  return f;
}

Int64 _activeQuantityOf(Iterable<Value> values) => values
    .where((v) => v.hasStakingToken() && v.stakingToken.hasRegistration())
    .map((v) => v.stakingToken.quantity)
    .fold(Int64.ZERO, (a, b) => a + b);

Int64 _inactiveQuantityOf(Iterable<Value> values) => values
    .where((v) => v.hasStakingToken() && !v.stakingToken.hasRegistration())
    .map((v) => v.stakingToken.quantity)
    .fold(Int64.ZERO, (a, b) => a + b);
