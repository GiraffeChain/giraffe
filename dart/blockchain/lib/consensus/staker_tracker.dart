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
      BlockId currentBlockId, Int64 slot, TransactionOutputReference account);

  Future<Rational?> operatorRelativeStake(BlockId currentBlockId, Int64 slot,
      TransactionOutputReference account) async {
    final s = await staker(currentBlockId, slot, account);
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
  final Store<TransactionOutputReference, ActiveStaker> registrations;

  ConsensusData(
      this.totalActiveStake, this.totalInactiveStake, this.registrations);

  static BlockSourcedState<ConsensusData> eventSourcedState(
      BlockId initialBlockId,
      ParentChildTree<BlockId> parentChildTree,
      Future<void> Function(BlockId) currentEventChanged,
      ConsensusData initialState,
      Future<BlockBody> Function(BlockId) fetchBlockBody,
      Future<Transaction> Function(TransactionId) fetchTransaction) {
    return BlockSourcedState(
        _applyBlock(fetchBlockBody, fetchTransaction),
        _unapplyBlock(fetchBlockBody, fetchTransaction),
        parentChildTree,
        initialState,
        initialBlockId,
        currentEventChanged);
  }

  static Future<ConsensusData> Function(ConsensusData, BlockId) _applyBlock(
      Future<BlockBody> Function(BlockId) fetchBlockBody,
      Future<Transaction> Function(TransactionId) fetchTransaction) {
    throw UnimplementedError();
  }

  static Future<ConsensusData> Function(ConsensusData, BlockId) _unapplyBlock(
      Future<BlockBody> Function(BlockId) fetchBlockBody,
      Future<Transaction> Function(TransactionId) fetchTransaction) {
    throw UnimplementedError();
  }
}

class StakerTrackerImpl extends StakerTracker {
  final BlockId genesisBlockId;
  final BlockSourcedState<EpochBoundariesState> epochBoundaryState;
  final BlockSourcedState<ConsensusData> consensusDataState;
  final Clock clock;

  StakerTrackerImpl(this.genesisBlockId, this.epochBoundaryState,
      this.consensusDataState, this.clock);

  @override
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot) =>
      _useStateAtTargetBoundary(
          currentBlockId, slot, (p0) => p0.totalActiveStake.getOrRaise(""));

  @override
  Future<ActiveStaker?> staker(BlockId currentBlockId, Int64 slot,
          TransactionOutputReference account) =>
      _useStateAtTargetBoundary(
          currentBlockId, slot, (t) => t.registrations.get(account));

  Future<Res> _useStateAtTargetBoundary<Res>(BlockId currentBlockId, Slot slot,
      Future<Res> Function(ConsensusData) f) async {
    final epoch = clock.epochOfSlot(slot);
    final boundaryBlockId = (epoch > 1)
        ? await epochBoundaryState.useStateAt(
            currentBlockId, (s) => s.getOrRaise(epoch - 2))
        : genesisBlockId;
    return consensusDataState.useStateAt(boundaryBlockId, f);
  }
}

typedef EpochBoundariesState = Store<Epoch, BlockId>;

BlockSourcedState<EpochBoundariesState> epochBoundariesEventSourcedState(
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

  return BlockSourcedState(applyBlock, unapplyBlock, parentChildTree,
      initialState, initialBlockId, currentEventChanged);
}
