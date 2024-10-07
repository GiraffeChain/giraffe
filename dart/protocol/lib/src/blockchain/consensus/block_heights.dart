import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/protocol.dart';
import 'package:giraffe_protocol/src/blockchain/block_id_tree.dart';
import 'package:giraffe_protocol/src/blockchain/block_sourced_state.dart';
import 'package:giraffe_sdk/sdk.dart';

import '../store.dart';

class BlockHeights {
  static BlockHeightsBSS make(
      Store<Int64, BlockId> store,
      BlockId currentId,
      BlockIdTree blockIdTree,
      Future<void> Function(BlockId) blockIdChanged,
      FetchHeader fetchHeader) {
    return BlockSourcedStateImpl(
      applyBlock: (state, id) async =>
          store.put((await fetchHeader(id)).height, id).then((_) => state),
      unapplyBlock: (state, id) async =>
          store.remove((await fetchHeader(id)).height).then((_) => state),
      blockIdTree: blockIdTree,
      state: store.get,
      currentId: currentId,
      blockIdChanged: blockIdChanged,
    );
  }
}

typedef BlockHeightsState = Future<BlockId?> Function(Int64);
typedef BlockHeightsBSS = BlockSourcedState<BlockHeightsState>;
