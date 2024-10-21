import 'dart:async';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

import '../codecs.dart';
import '../common/clock.dart';
import '../common/models/unsigned.dart';
import 'package:giraffe_sdk/sdk.dart';
import '../ledger/block_header_to_body_validation.dart';
import '../ledger/block_packer.dart';
import 'models/vrf_hit.dart';
import 'staking.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';

abstract class BlockProducer {
  Stream<FullBlock> makeChild(BlockHeader parentHeader);
}

class BlockProducerImpl extends BlockProducer {
  final BlockchainClient client;
  final Staking staker;
  final Clock clock;
  final BlockPacker blockPacker;
  final LockAddress? rewardAddress;
  Int64 _nextSlotMinimum = Int64.ZERO;

  BlockProducerImpl(
    this.client,
    this.staker,
    this.clock,
    this.blockPacker,
    this.rewardAddress,
  );

  final log = Logger("BlockProducer");

  @override
  Stream<FullBlock> makeChild(BlockHeader parentHeader) {
    var canceled = false;
    return _makeChildImpl(parentHeader, () => canceled)
        .doOnCancel(() => canceled = true);
  }

  Stream<FullBlock> _makeChildImpl(
      BlockHeader parentHeader, bool Function() cancelCheck) async* {
    final parentSlotId =
        SlotId(slot: parentHeader.slot, blockId: parentHeader.id);
    Int64 fromSlot = parentHeader.slot + 1;
    if (fromSlot < _nextSlotMinimum) fromSlot = _nextSlotMinimum;
    log.info(
        "Calculating eligibility for parentId=${parentHeader.id.show} parentSlot=${parentHeader.slot}");
    final nextHit = await _nextEligibility(parentSlotId, fromSlot, cancelCheck);
    if (cancelCheck()) return;
    if (nextHit == null) {
      log.warning("No eligibilities found");
      return;
    }
    log.info("Delaying until eligibile slot=${nextHit.slot}.");
    await clock.delayedUntilSlot(nextHit.slot);
    if (cancelCheck()) return;
    final FullBlockBody bodyWithoutReward;
    try {
      bodyWithoutReward = await RaceStream([
        blockPacker.streamed(
            parentSlotId.blockId, parentHeader.height + 1, nextHit.slot),
        Stream.periodic(const Duration(milliseconds: 250))
            .map<FullBlockBody?>((_) {
          if (cancelCheck()) throw _CanceledException();
          return null;
        }).whereNotNull(),
      ]).first;
      if (cancelCheck()) return;
    } on _CanceledException {
      return;
    }
    log.info("Constructing block for slot=${nextHit.slot}");
    final body = await insertReward(bodyWithoutReward, parentHeader.id);
    if (cancelCheck()) return;
    final now = clock.localTimestamp;
    final (slotStart, slotEnd) = clock.slotToTimestamps(nextHit.slot);
    final timestamp =
        Int64(min(slotEnd.toInt(), max(now.toInt(), slotStart.toInt())));
    final txRoot = TxRoot.calculateFromTransactions(
            parentHeader.txRoot.decodeBase58, body.transactions)
        .base58;
    final unsignedHeader = UnsignedBlockHeader(
      parentHeader.id,
      txRoot,
      timestamp,
      parentHeader.height + 1,
      nextHit.slot,
      nextHit.cert,
      staker.account,
    );
    final header =
        await staker.certifyBlock(parentSlotId, nextHit.slot, unsignedHeader);
    if (cancelCheck()) return;
    header.embedId();
    final headerId = header.id;
    final transactionIds = body.transactions.map((tx) => tx.id);
    log.info(
        "Produced block id=${headerId.show} height=${header.height} slot=${header.slot} parentId=${header.parentHeaderId.show} transactionIds=[${transactionIds.map((i) => i.show).join(",")}]");
    _nextSlotMinimum = header.slot + 1;
    yield FullBlock()
      ..header = header
      ..fullBody = body;
  }

  Future<VrfHit?> _nextEligibility(
      SlotId parentSlotId, Int64 fromSlot, bool Function() cancelCheck) async {
    var exitSlot =
        clock.epochRange(clock.epochOfSlot(parentSlotId.slot) + 1).$2;
    var test = fromSlot;
    while (test < exitSlot && !cancelCheck()) {
      final h = await staker.elect(parentSlotId, test);
      if (h != null) {
        return h;
      }
      test += 1;
    }
    return null;
  }

  Future<FullBlockBody> insertReward(
      FullBlockBody base, BlockId parentId) async {
    if (rewardAddress != null) {
      assert(base.transactions.where((t) => t.hasRewardParentBlockId()).isEmpty,
          "Block already contains reward");
      Int64 maximumQuantity = Int64.ZERO;
      for (final tx in base.transactions) {
        for (final input in tx.inputs) {
          final output = (await client.getTransactionOutput(input.reference))!;
          maximumQuantity += output.quantity;
        }
        for (final output in tx.outputs) {
          maximumQuantity -= output.quantity;
        }
      }
      if (maximumQuantity > Int64.ZERO) {
        final output = TransactionOutput(
            lockAddress: rewardAddress, quantity: maximumQuantity);
        final rewardTx =
            Transaction(outputs: [output], rewardParentBlockId: parentId);
        return FullBlockBody(transactions: [...base.transactions, rewardTx]);
      } else {
        return base;
      }
    } else {
      return base;
    }
  }
}

class _CanceledException implements Exception {}
