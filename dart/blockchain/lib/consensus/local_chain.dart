import 'dart:async';

import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

abstract class LocalChainAlgebra {
  Future<void> adopt(BlockId newHead);
  Future<BlockId> get currentHead;
  Stream<BlockId> get adoptions;
  Future<BlockId?> blockIdAtHeight(Int64 height);
  Future<BlockId?> blockIdAtDepth(Int64 height);
}

class LocalChain extends LocalChainAlgebra {
  LocalChain(BlockId initialHead, this._blockHeightTree, this._heightOfBlock)
      : this._currentHead = initialHead;
  BlockId _currentHead;

  final EventSourcedStateAlgebra<BlockHeightTreeState, BlockId>
      _blockHeightTree;

  final Future<Int64> Function(BlockId) _heightOfBlock;

  final StreamController<BlockId> _streamController =
      StreamController.broadcast();

  @override
  Future<void> adopt(BlockId newHead) async {
    if (_currentHead != newHead) {
      _currentHead = newHead;
      _streamController.add(newHead);
    }
  }

  @override
  Stream<BlockId> get adoptions => _streamController.stream;

  @override
  Future<BlockId> get currentHead => Future.sync(() => _currentHead);

  @override
  Future<BlockId?> blockIdAtHeight(Int64 height) async =>
      _blockHeightTree.useStateAt(await currentHead, (s) => s(height));

  @override
  Future<BlockId?> blockIdAtDepth(Int64 depth) async {
    final headId = await currentHead;
    final headHeight = await _heightOfBlock(headId);
    if (headHeight >= depth)
      return _blockHeightTree.useStateAt(
          await currentHead, (s) => s(headHeight - depth));
    else
      return null;
  }
}
