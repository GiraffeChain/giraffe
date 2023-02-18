import 'dart:async';

import 'package:blockchain_consensus/consensus.dart';
import 'package:blockchain_protobuf/models/block.pb.dart';

class ConsensusImpl extends Consensus {
  ConsensusImpl(this._currentHead, this._fetchBlock) {
    _controller = StreamController.broadcast();
  }

  BlockId _currentHead;
  final Future<Block> Function(BlockId) _fetchBlock;
  late final StreamController _controller;

  @override
  Future<void> adopt(BlockId newHead) async {
    _currentHead = newHead;
    _controller.add(newHead);
  }

  @override
  Future<BlockId> chainPreference(
      BlockId chainAHead, BlockId chainBHead) async {
    final a = await _fetchBlock(chainAHead);
    final b = await _fetchBlock(chainBHead);

    if (a.height > b.height)
      return chainAHead;
    else if (b.height > a.height)
      return chainBHead;
    else if (a.slot < b.slot)
      return chainAHead;
    else if (b.slot < a.slot)
      return chainBHead;
    else
      return chainAHead;
  }

  @override
  Future<BlockId> get currentHead async => _currentHead;

  @override
  Future<List<String>> validate(Block block) async {
    final parent = await _fetchBlock(block.parentHeaderId);
    List<String> errors = [];
    if (block.height != parent.height + 1) errors.add("Invalid block height");
    if (block.slot <= parent.slot) errors.add("Invalid slot");
    if (block.timestamp <= parent.timestamp) errors.add("Invalid timestamp");

    return errors;
  }

  @override
  Stream<BlockId> get adoptions => _controller.stream.cast();

  Future<void> close() {
    return _controller.close();
  }
}
