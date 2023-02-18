import 'dart:async';
import 'dart:math';

import 'package:blockchain_block_production/block_producer.dart';
import 'package:blockchain_common/blockchain_clock.dart';
import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_codecs/codecs.dart';
import 'package:fixnum/fixnum.dart';

class BlockProducerImpl extends BlockProducer {
  BlockProducerImpl(this._blockchainClock);

  final BlockchainClock _blockchainClock;

  @override
  Future<Block> produceBlock(Block parent) async {
    final nextEligibleSlot = _nextEligibility(parent.slot);

    await _blockchainClock.delayUntilSlot(nextEligibleSlot);

    // TODO: Proof, Transactions
    return Block()
      ..parentHeaderId = parent.id
      ..height = parent.height + 1
      ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch)
      ..slot = _nextEligibility(parent.slot);
  }

  _nextEligibility(Int64 parentSlot) {
    return parentSlot + 1 + Random().nextInt(9);
  }
}
