import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';

import 'genesis.dart';

abstract class BlockIdTree {
  Future<BlockId?> parentOf(BlockId blockId);
  Future<void> associate(BlockId child, BlockId parent);
  Future<Int64> heightOf(BlockId blockId);
  Future<(List<BlockId>, List<BlockId>)> findCommonAncestor(
      BlockId a, BlockId b);
}

class BlockIdTreeImpl extends BlockIdTree {
  final Future<(Int64, BlockId)?> Function(BlockId) read;
  final Future<void> Function(BlockId, (Int64, BlockId)) write;

  BlockIdTreeImpl({required this.read, required this.write});

  Future<(Int64, BlockId)> _readOrRaise(BlockId id) {
    return read(id).then((value) {
      if (value == null) {
        throw Exception('Value not found for key=$id');
      }
      return value;
    });
  }

  @override
  Future<void> associate(BlockId child, BlockId parent) async {
    if (parent == Genesis.parentId) {
      await write(child, (Int64(1), parent));
    } else {
      final (parentHeight, _) = await _readOrRaise(parent);
      await write(child, (parentHeight + Int64(1), parent));
    }
  }

  @override
  Future<(List<BlockId>, List<BlockId>)> findCommonAncestor(
      BlockId a, BlockId b) async {
    final chainA = [a];
    final chainB = [b];
    if (a == b) return (chainA, chainB);
    Int64 aHeight = await heightOf(a);
    Int64 bHeight = await heightOf(b);
    while (aHeight > bHeight) {
      a = (await parentOf(a))!;
      chainA.insert(0, a);
      aHeight -= 1;
    }
    while (bHeight > aHeight) {
      b = (await parentOf(b))!;
      chainB.insert(0, b);
      bHeight -= 1;
    }
    while (a != b) {
      a = (await parentOf(a))!;
      chainA.insert(0, a);
      b = (await parentOf(b))!;
      chainB.insert(0, b);
    }
    return (chainA, chainB);
  }

  @override
  Future<Int64> heightOf(BlockId blockId) async {
    if (blockId == Genesis.parentId) {
      return Int64(0);
    } else {
      final (height, _) = await _readOrRaise(blockId);
      return height;
    }
  }

  @override
  Future<BlockId?> parentOf(BlockId blockId) async {
    if (blockId == Genesis.parentId) {
      return null;
    } else {
      final (_, parent) = await _readOrRaise(blockId);
      return parent;
    }
  }
}
