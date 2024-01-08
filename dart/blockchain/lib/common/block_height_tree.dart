import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/store.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

typedef BlockHeightTreeState = Future<BlockId?> Function(Int64);

typedef BlockHeightTree = BlockSourcedState<BlockHeightTreeState>;

BlockHeightTree makeBlockHeightTree(
  Store<Int64, BlockId> store,
  BlockId currentEventId,
  Future<BlockHeader> Function(BlockId) fetchHeader,
  ParentChildTreeImpl<BlockId> parentChildTree,
  Future<void> Function(BlockId) currentEventChanged,
) {
  Future<BlockHeightTreeState> applyBlock(
      BlockHeightTreeState state, BlockId id) async {
    final slotData = await fetchHeader(id);
    final height = slotData.height;
    await store.put(height, id);
    return state;
  }

  Future<BlockHeightTreeState> unapplyBlock(
      BlockHeightTreeState state, BlockId id) async {
    final slotData = await fetchHeader(id);
    final height = slotData.height;
    await store.remove(height);
    return state;
  }

  return BlockSourcedState<BlockHeightTreeState>(applyBlock, unapplyBlock,
      parentChildTree, store.get, currentEventId, currentEventChanged);
}
