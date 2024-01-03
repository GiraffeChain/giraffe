import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/store.dart';
import 'package:fpdart/fpdart.dart';
import 'package:blockchain/common/utils.dart';
import 'package:rational/rational.dart';

abstract class StakerTracker {
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot);

  Future<ActiveStaker?> staker(
      BlockId currentBlockId, Int64 slot, StakingAddress address);
  Future<Rational?> operatorRelativeStake(
      BlockId currentBlockId, Int64 slot, StakingAddress address) async {
    final s = await staker(currentBlockId, slot, address);
    if (s != null) {
      final total = await totalActiveStake(currentBlockId, slot);
      return Rational(s.quantity.toBigInt, total.toBigInt);
    }
    return null;
  }
}

class ConsensusData {
  final Store<void, Int64> totalActiveStake;
  final Store<void, Int64> totalInactiveStake;
  final Store<StakingAddress, ActiveStaker> registrations;

  ConsensusData(
      this.totalActiveStake, this.totalInactiveStake, this.registrations);
}

EventSourcedState<ConsensusData, BlockId> consensusDataEventSourcedState(
    BlockId initialBlockId,
    ParentChildTree<BlockId> parentChildTree,
    Future<void> Function(BlockId) currentEventChanged,
    ConsensusData initialState,
    Future<BlockBody> Function(BlockId) fetchBlockBody,
    Future<Transaction> Function(TransactionId) fetchTransaction) {
  return EventTreeStateImpl(
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
          .where((i) => i.hasValue() && i.value.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.registration
            ..quantity = i.value.quantity)
          .toList();

  List<ActiveStaker> addedStakersOf(Transaction transaction) =>
      transaction.outputs
          .where((i) => i.hasValue() && i.value.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.registration
            ..quantity = i.value.quantity)
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
          .where((i) => i.hasValue() && i.value.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.registration
            ..quantity = i.value.quantity)
          .toList();

  List<ActiveStaker> addedStakersOf(Transaction transaction) =>
      transaction.outputs.reversed
          .where((i) => i.hasValue() && i.value.hasRegistration())
          .map((i) => ActiveStaker()
            ..registration = i.value.registration
            ..quantity = i.value.quantity)
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
    .where((v) => v.hasRegistration())
    .map((v) => v.quantity)
    .fold(Int64.ZERO, (a, b) => a + b);

Int64 _inactiveQuantityOf(Iterable<Value> values) => values
    .where((v) => v.hasRegistration())
    .map((v) => v.quantity)
    .fold(Int64.ZERO, (a, b) => a + b);

class StakerTrackerImpl extends StakerTracker {
  final BlockId genesisBlockId;
  final EventSourcedState<EpochBoundariesState, BlockId> epochBoundaryState;
  final EventSourcedState<ConsensusData, BlockId> consensusDataState;
  final Clock clock;

  StakerTrackerImpl(this.genesisBlockId, this.epochBoundaryState,
      this.consensusDataState, this.clock);

  @override
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot) =>
      _useStateAtTargetBoundary(
          currentBlockId, slot, (p0) => p0.totalActiveStake.getOrRaise(""));

  @override
  Future<ActiveStaker?> staker(
          BlockId currentBlockId, Int64 slot, StakingAddress address) =>
      _useStateAtTargetBoundary(
          currentBlockId, slot, (t) => t.registrations.get(address));

  Future<Res> _useStateAtTargetBoundary<Res>(BlockId currentBlockId, Slot slot,
      Future<Res> Function(ConsensusData) f) async {
    final epoch = clock.epochOfSlot(slot);
    final targetEpoch = epoch - 2;
    final boundaryBlockId = (targetEpoch >= 0)
        ? await epochBoundaryState.useStateAt(
            currentBlockId, (s) => s.getOrRaise(targetEpoch))
        : genesisBlockId;
    return consensusDataState.useStateAt(boundaryBlockId, f);
  }
}

typedef EpochBoundariesState = Store<Epoch, BlockId>;

EventSourcedState<EpochBoundariesState, BlockId>
    epochBoundariesEventSourcedState(
        Clock clock,
        BlockId initialBlockId,
        ParentChildTree<BlockId> parentChildTree,
        Future<void> Function(BlockId) currentEventChanged,
        EpochBoundariesState initialState,
        Future<BlockHeader> Function(BlockId) fetchHeader) {
  Future<EpochBoundariesState> applyBlock(
      EpochBoundariesState state, BlockId blockId) async {
    final header = await fetchHeader(blockId);
    final epoch = clock.epochOfSlot(header.slotId.slot);
    await state.put(epoch, blockId);
    return state;
  }

  Future<EpochBoundariesState> unapplyBlock(
      EpochBoundariesState state, BlockId blockId) async {
    final header = await fetchHeader(blockId);
    final epoch = clock.epochOfSlot(header.slotId.slot);
    final parentEpoch = clock.epochOfSlot(header.parentSlot);
    if (epoch == parentEpoch)
      await state.put(epoch, header.parentHeaderId);
    else
      state.remove(epoch);
    return state;
  }

  return EventTreeStateImpl(applyBlock, unapplyBlock, parentChildTree,
      initialState, initialBlockId, currentEventChanged);
}
