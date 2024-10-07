import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:giraffe_protocol/src/blockchain/consensus/block_heights.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:logging/logging.dart';

import '../common/common.dart';
import '../genesis.dart';

abstract class LocalChain {
  Future<void> adopt(BlockId blockId);
  BlockId get head;
  BlockId get genesis;
  Stream<BlockId> get adoptions;
  Future<BlockId?> blockIdAtHeight(Int64 height);
  Future<void> close();
}

class LocalChainImpl extends LocalChain {
  @override
  final BlockId genesis;
  @override
  BlockId head;
  final Future<void> Function(BlockId) onAdopted;
  final FetchHeader fetchHeader;
  final FetchBody fetchBody;
  final BlockHeightsBSS blockHeightsBSS;

  final StreamController<BlockId> _adoptions =
      StreamController<BlockId>.broadcast();

  LocalChainImpl(
      {required this.genesis,
      required this.head,
      required this.onAdopted,
      required this.fetchHeader,
      required this.fetchBody,
      required this.blockHeightsBSS});

  @override
  Future<void> adopt(BlockId blockId) async {
    head = blockId;
    await onAdopted(blockId);
    _adoptions.add(blockId);
    final header = await fetchHeader(blockId);
    final body = await fetchBody(blockId);
    log.info(
        "Adopted blockId=${blockId.show} height=${header.height} slot=${header.slot} transactions=${body.transactionIds.map((id) => id.show).toList()}");
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

  @override
  Future<void> close() => _adoptions.close();

  static final log = Logger("LocalChain");
}
