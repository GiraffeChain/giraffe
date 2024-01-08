import 'dart:async';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/event_sourced_state.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/genesis.dart';
import 'package:blockchain/traversal.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

abstract class LocalChain {
  LocalChain(ParentChildTree parentChildTree)
      : _parentChildTree = parentChildTree;

  Future<void> adopt(BlockId newHead);
  Future<BlockId> get currentHead;
  BlockId get genesis;
  Stream<BlockId> get adoptions;
  Future<BlockId?> blockIdAtHeight(Int64 height);
  final ParentChildTree _parentChildTree;

  Stream<TraversalStep> get traversal {
    BlockId? lastId = null;
    return adoptions
        .asyncExpand((id) => (lastId == null)
            ? Stream.value(TraversalStep_Applied(id))
            : traversalBetween(lastId!, id))
        .map((step) {
      lastId = step.blockId;
      return step;
    });
  }

  Stream<TraversalStep> get traversalFromGenesis =>
      Stream.fromFuture(blockIdAtHeight(Int64(1)))
          .asyncExpand((genesisId) => Stream.fromFuture(currentHead)
              .asyncExpand((head) => traversalBetween(genesisId!, head)))
          .concatWith([traversal]);

  Stream<TraversalStep> traversalBetween(BlockId a, BlockId b) =>
      Stream.fromFuture(_parentChildTree.findCommmonAncestor(a, b)).expand(
          (unapplyApply) => <TraversalStep>[]
            ..addAll(unapplyApply.$1.tail
                .toNullable()!
                .map((id) => TraversalStep_Unapplied(id)))
            ..addAll(unapplyApply.$2.tail
                .toNullable()!
                .map((id) => TraversalStep_Applied(id))));
}

class LocalChainImpl extends LocalChain {
  final BlockId genesis;
  LocalChainImpl(this.genesis, BlockId initialHead, this._blockHeightTree,
      this._heightOfBlock, this._streamController, super._parentChildTree)
      : this._currentHead = initialHead;
  BlockId _currentHead;

  final EventSourcedState<BlockHeightTreeState, BlockId> _blockHeightTree;

  final Future<Int64> Function(BlockId) _heightOfBlock;

  final StreamController<BlockId> _streamController;

  final log = Logger("Blockchain.LocalChain");

  static Resource<LocalChainImpl> make(
    BlockId genesis,
    BlockId initialHead,
    BlockHeightTree blockHeightTree,
    Future<Int64> Function(BlockId) heightOfBlock,
    ParentChildTree parentChildTree,
  ) =>
      Resource.streamController(() => StreamController<BlockId>.broadcast())
          .map((controller) => LocalChainImpl(
                genesis,
                initialHead,
                blockHeightTree,
                heightOfBlock,
                controller,
                parentChildTree,
              ));

  @override
  Future<void> adopt(BlockId newHead) async {
    if (_currentHead != newHead) {
      log.info("Adopted head block id=${newHead.show}");
      _currentHead = newHead;
      _streamController.add(newHead);
    }
  }

  @override
  Stream<BlockId> get adoptions => _streamController.stream;

  @override
  Future<BlockId> get currentHead => Future.sync(() => _currentHead);

  @override
  Future<BlockId?> blockIdAtHeight(Int64 height) async {
    if (height == Genesis.height)
      return genesis;
    else if (height > Genesis.height) {
      return _blockHeightTree.useStateAt(await currentHead, (s) => s(height));
    } else if (height == Int64.ZERO) {
      return currentHead;
    } else {
      final headHeight = await _heightOfBlock(await currentHead);
      final targetHeight = headHeight + height;
      if (targetHeight < Genesis.height) return null;
      return blockIdAtHeight(targetHeight);
    }
  }
}
