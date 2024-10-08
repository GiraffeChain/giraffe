import 'package:giraffe_sdk/sdk.dart';
import 'package:mutex/mutex.dart';

import 'block_id_tree.dart';

abstract class BlockSourcedState<State> {
  Future<T> useStateAt<T>(BlockId blockId, Future<T> Function(State state) f);
}

class BlockSourcedStateImpl<State> extends BlockSourcedState<State> {
  final Future<State> Function(State, BlockId) applyBlock;
  final Future<State> Function(State, BlockId) unapplyBlock;
  final BlockIdTree blockIdTree;
  final Mutex mutex = Mutex();
  State state;
  BlockId currentId;
  final Future<void> Function(BlockId) blockIdChanged;

  BlockSourcedStateImpl(
      {required this.applyBlock,
      required this.unapplyBlock,
      required this.blockIdTree,
      required this.state,
      required this.currentId,
      required this.blockIdChanged});

  @override
  Future<T> useStateAt<T>(BlockId blockId, Future<T> Function(State state) f) =>
      mutex.protect(() async {
        if (currentId == blockId) {
          return f(state);
        }
        final (unapplyChain, applyChain) =
            await blockIdTree.findCommonAncestor(currentId, blockId);
        for (int i = unapplyChain.length - 1; i > 1; i--) {
          final id = unapplyChain[i];
          state = await unapplyBlock(state, id);
          currentId = unapplyChain[i - 1];
          blockIdChanged(currentId);
        }
        for (int i = 1; i < applyChain.length; i++) {
          final id = applyChain[i];
          state = await applyBlock(state, id);
          currentId = applyChain[i];
          blockIdChanged(currentId);
        }
        return f(state);
      });
}
