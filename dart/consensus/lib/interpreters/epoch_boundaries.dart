import 'package:blockchain_common/algebras/clock_algebra.dart';
import 'package:blockchain_common/algebras/event_sourced_state_algebra.dart';
import 'package:blockchain_common/algebras/parent_child_tree_algebra.dart';
import 'package:blockchain_common/algebras/store_algebra.dart';
import 'package:blockchain_common/interpreters/event_tree_state.dart';
import 'package:blockchain_common/models/common.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

typedef EpochBoundariesState = StoreAlgebra<Epoch, BlockId>;

EventSourcedStateAlgebra<EpochBoundariesState, BlockId>
    epochBoundariesEventSourcedState(
        ClockAlgebra clock,
        BlockId initialBlockId,
        ParentChildTreeAlgebra<BlockId> parentChildTree,
        Future<void> Function(BlockId) currentEventChanged,
        EpochBoundariesState initialState,
        Future<SlotData> Function(BlockId) fetchSlotData) {
  Future<EpochBoundariesState> applyBlock(
      EpochBoundariesState state, BlockId blockId) async {
    final slotData = await fetchSlotData(blockId);
    final epoch = clock.epochOfSlot(slotData.slotId.slot);
    await state.put(epoch, blockId);
    return state;
  }

  Future<EpochBoundariesState> unapplyBlock(
      EpochBoundariesState state, BlockId blockId) async {
    final slotData = await fetchSlotData(blockId);
    final epoch = clock.epochOfSlot(slotData.slotId.slot);
    final parentEpoch = clock.epochOfSlot(slotData.parentSlotId.slot);
    if (epoch == parentEpoch)
      await state.put(epoch, slotData.parentSlotId.blockId);
    else
      state.remove(epoch);
    return state;
  }

  return EventTreeState(applyBlock, unapplyBlock, parentChildTree, initialState,
      initialBlockId, currentEventChanged);
}
