import 'dart:async';
import 'dart:math';

import '../codecs.dart';
import '../common/clock.dart';
import '../common/models/unsigned.dart';
import 'package:blockchain_sdk/sdk.dart';
import '../ledger/block_header_to_body_validation.dart';
import '../ledger/block_packer.dart';
import 'models/vrf_hit.dart';
import 'staking.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BlockProducer {
  Future<FullBlock?> makeChild(BlockHeader parentHeader);
}

class BlockProducerImpl extends BlockProducer {
  final Staking staker;
  final Clock clock;
  final BlockPacker blockPacker;
  final LockAddress? rewardAddress;
  Int64 _nextSlotMinimum = Int64.ZERO;

  BlockProducerImpl(
    this.staker,
    this.clock,
    this.blockPacker,
    this.rewardAddress,
  );

  final log = Logger("BlockProducer");

  int _i = 0;

  @override
  Future<FullBlock?> makeChild(BlockHeader parentHeader) async {
    final i = _i + 1;
    _i = i;
    final parentSlotId =
        SlotId(slot: parentHeader.slot, blockId: parentHeader.id);
    Int64 fromSlot = parentHeader.slot + 1;
    if (fromSlot < _nextSlotMinimum) fromSlot = _nextSlotMinimum;
    log.info(
        "Calculating eligibility for parentId=${parentHeader.id.show} parentSlot=${parentHeader.slot}");
    final nextHit = await _nextEligibility(parentSlotId, fromSlot);
    if (nextHit == null) {
      log.warning("No eligibilities found");
      return null;
    }
    log.info("Packing block for slot=${nextHit.slot}");
    await clock.delayedUntilSlot(nextHit.slot);
    if (i != _i) {
      log.fine("Abandoning block attempt");
      return null;
    }
    final bodyWithoutReward = await blockPacker
        .streamed(parentSlotId.blockId, parentHeader.height + 1, nextHit.slot)
        .first;
    log.info("Constructing block for slot=${nextHit.slot}");
    final body = insertReward(bodyWithoutReward, parentHeader.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final (slotStart, slotEnd) = clock.slotToTimestamps(nextHit.slot);
    final timestamp = Int64(min(slotEnd.toInt(), max(now, slotStart.toInt())));
    final header = await staker.certifyBlock(
        parentSlotId,
        nextHit.slot,
        _prepareUnsignedBlock(
          parentHeader,
          body,
          timestamp,
          nextHit,
        ));
    header.embedId();
    final headerId = header.id;
    final transactionIds = body.transactions.map((tx) => tx.id);
    log.info(
        "Produced block id=${headerId.show} height=${header.height} slot=${header.slot} parentId=${header.parentHeaderId.show} transactionIds=[${transactionIds.map((i) => i.show).join(",")}]");
    _nextSlotMinimum = header.slot + 1;
    return FullBlock()
      ..header = header
      ..fullBody = body;
  }

  Future<VrfHit?> _nextEligibility(SlotId parentSlotId, Int64 fromSlot) async {
    var exitSlot =
        clock.epochRange(clock.epochOfSlot(parentSlotId.slot) + 1).$2;
    var test = fromSlot;
    while (test < exitSlot) {
      final h = await staker.elect(parentSlotId, test);
      if (h != null) {
        return h;
      }
      test += 1;
    }
    return null;
  }

  UnsignedBlockHeader _prepareUnsignedBlock(BlockHeader parentHeader,
          FullBlockBody fullBody, Int64 timestamp, VrfHit nextHit) =>
      UnsignedBlockHeader(
        parentHeader.id,
        parentHeader.slot,
        TxRoot.calculateFromTransactions(
                parentHeader.txRoot.decodeBase58, fullBody.transactions)
            .base58,
        timestamp,
        parentHeader.height + 1,
        nextHit.slot,
        nextHit.cert,
        staker.account,
      );

  FullBlockBody insertReward(FullBlockBody base, BlockId parentId) {
    if (rewardAddress != null) {
      assert(base.transactions.where((t) => t.hasRewardParentBlockId()).isEmpty,
          "Block already contains reward");
      Int64 maximumQuantity = Int64.ZERO;
      for (final tx in base.transactions) {
        maximumQuantity += tx.reward;
      }
      final output = TransactionOutput(
          lockAddress: rewardAddress, value: Value(quantity: maximumQuantity));
      final rewardTx =
          Transaction(outputs: [output], rewardParentBlockId: parentId);
      return FullBlockBody(transactions: [...base.transactions, rewardTx]);
    } else {
      return base;
    }
  }
}
