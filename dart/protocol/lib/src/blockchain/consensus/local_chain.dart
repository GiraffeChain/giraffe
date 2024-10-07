import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/src/blockchain/consensus/block_heights.dart';
import 'package:giraffe_sdk/sdk.dart';

import '../common/common.dart';
import '../genesis.dart';

abstract class LocalChain {
  Future<void> adopt(BlockId blockId);
  BlockId get head;
  BlockId get genesis;
  Stream<BlockId> get adoptions;
  Future<BlockId?> blockIdAtHeight(Int64 height);
}

class LocalChainImpl extends LocalChain {
  @override
  final BlockId genesis;
  @override
  BlockId head;
  final FetchHeader fetchHeader;
  final BlockHeightsBSS blockHeightsBSS;
  final StreamController<BlockId> _adoptions =
      StreamController<BlockId>.broadcast();

  LocalChainImpl(
      {required this.genesis,
      required this.head,
      required this.fetchHeader,
      required this.blockHeightsBSS});

  @override
  Future<void> adopt(BlockId blockId) async {
    head = blockId;
    _adoptions.add(blockId);
  }

  @override
  Stream<BlockId> get adoptions => _adoptions.stream;

  @override
  Future<BlockId?> blockIdAtHeight(Int64 height) async {
    if (height == Genesis.height) {
      return genesis;
    } else if (height > Genesis.height) {
      return blockHeightsBSS.useStateAt(head, (state) => state(height));
    } else if (height == Int64.ZERO) {
      return head;
    } else {
      final currentHeader = await fetchHeader(head);
      final targetHeight = currentHeader.height + height;
      if (targetHeight < Genesis.height) return null;
      return blockIdAtHeight(targetHeight);
    }
  }
}
