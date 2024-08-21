import 'dart:async';
import 'dart:math';

import '../codecs.dart';
import '../common/clock.dart';
import '../common/models/unsigned.dart';
import '../common/resource.dart';
import 'package:blockchain_sdk/sdk.dart';
import '../ledger/block_header_to_body_validation.dart';
import '../ledger/block_packer.dart';
import 'models/vrf_hit.dart';
import 'staking.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:ribs_effect/ribs_effect.dart';
import 'package:rxdart/rxdart.dart';

abstract class BlockProducer {
  Stream<FullBlock> get blocks;
}

class BlockProducerImpl extends BlockProducer {
  final Stream<BlockHeader> parentHeaders;
  final Staking staker;
  final Clock clock;
  final BlockPacker blockPacker;
  final LockAddress? rewardAddress;
  Int64 _nextSlotMinimum = Int64.ZERO;

  BlockProducerImpl(
    this.parentHeaders,
    this.staker,
    this.clock,
    this.blockPacker,
    this.rewardAddress,
  );

  final log = Logger("BlockProducer");

  @override
  Stream<FullBlock> get blocks =>
      parentHeaders.transform(AbandoningTransformer(_makeChild)).whereNotNull();

  IO<FullBlock?> _makeChild(BlockHeader parentHeader) {
    final parentSlotId =
        SlotId(slot: parentHeader.slot, blockId: parentHeader.id);
    Int64 fromSlot = parentHeader.slot + 1;
    if (fromSlot < _nextSlotMinimum) fromSlot = _nextSlotMinimum;
    return IO
        .delay(() => log.info("Calculating eligibility for" +
            " parentId=${parentHeader.id.show}" +
            " parentSlot=${parentHeader.slot}"))
        .flatMap((_) => _nextEligibility(parentSlotId, fromSlot))
        .flatMap<FullBlock?>((nextHit) => (nextHit == null)
            ? IO
                .delay(() => log.warning("No eligibilities found"))
                .flatMap((_) => IO.never())
            : IO
                .delay(() => log.info("Packing block for slot=${nextHit.slot}"))
                .flatMap((_) {
                FullBlockBody bodyTmp = FullBlockBody();
                return ResourceUtils.backgroundStream(blockPacker
                        .streamed(parentSlotId.blockId, parentHeader.height + 1,
                            nextHit.slot)
                        .map((b) => bodyTmp = b))
                    .use((h) => clock.delayedUntilSlot(nextHit.slot))
                    .map((_) => bodyTmp)
                    .flatMap((body) => IO.fromFutureF(() async {
                          log.info(
                              "Constructing block for slot=${nextHit.slot}");
                          final bodyWithoutReward = bodyTmp;
                          final body =
                              insertReward(bodyWithoutReward, parentHeader.id);
                          final now = DateTime.now().millisecondsSinceEpoch;
                          final (slotStart, slotEnd) =
                              clock.slotToTimestamps(nextHit.slot);
                          final timestamp = Int64(min(
                              slotEnd.toInt(), max(now, slotStart.toInt())));
                          return await staker.certifyBlock(
                              parentSlotId,
                              nextHit.slot,
                              _prepareUnsignedBlock(
                                parentHeader,
                                body,
                                timestamp,
                                nextHit,
                              ));
                        }).flatMap((maybeHeader) {
                          if (maybeHeader != null) {
                            return IO.delay(() {
                              maybeHeader.embedId();
                              final headerId = maybeHeader.id;
                              final transactionIds =
                                  body.transactions.map((tx) => tx.id);
                              log.info(
                                  "Produced block id=${headerId.show} height=${maybeHeader.height} slot=${maybeHeader.slot} parentId=${maybeHeader.parentHeaderId.show} transactionIds=[${transactionIds.map((i) => i.show).join(",")}]");
                              _nextSlotMinimum = maybeHeader.slot + 1;
                              return FullBlock()
                                ..header = maybeHeader
                                ..fullBody = bodyTmp;
                            });
                          } else {
                            return IO
                                .delay(() => log.warning(
                                    "Failed to certify block at next slot=${nextHit.slot}.  Skipping eligibilities within current operational period."))
                                .flatMap((_) => IO.delay(() {
                                      final (nextOperationalPeriodStart, _) =
                                          clock.operationalPeriodRange(
                                              clock.operationalPeriodOfSlot(
                                                      nextHit.slot) +
                                                  1);
                                      _nextSlotMinimum =
                                          nextOperationalPeriodStart;
                                    }))
                                .flatMap((_) => _makeChild(parentHeader));
                          }
                        }));
              }))
        .onCancel(
            IO.delay(() => log.info("Abandoning block attempt")).voided());
  }

  IO<VrfHit?> _nextEligibility(SlotId parentSlotId, Int64 fromSlot) => IO
          .delay(() =>
              clock.epochRange(clock.epochOfSlot(parentSlotId.slot) + 1).$2)
          .flatMap((exitSlot) {
        IO<VrfHit?> go(Int64 test) => test < exitSlot
            ? (IO
                .fromFutureF(() => staker.elect(parentSlotId, test))
                .flatMap((h) => h == null ? go(test + 1) : IO.pure(h)))
            : IO.pure(null);
        return go(fromSlot);
      });

  UnsignedBlockHeader Function(PartialOperationalCertificate)
      _prepareUnsignedBlock(BlockHeader parentHeader, FullBlockBody fullBody,
              Int64 timestamp, VrfHit nextHit) =>
          (PartialOperationalCertificate partialOperationalCertificate) =>
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
                partialOperationalCertificate,
                "",
                staker.account,
              );

  FullBlockBody insertReward(FullBlockBody base, BlockId parentId) {
    if (rewardAddress != null) {
      assert(
          base.transactions.where((t) => t.hasRewardParentBlockId()).length ==
              0,
          "Block already contains reward");
      Int64 maximumQuantity = Int64.ZERO;
      for (final tx in base.transactions) maximumQuantity += tx.reward;
      final output = TransactionOutput(
          lockAddress: rewardAddress, value: Value(quantity: maximumQuantity));
      final rewardTx =
          Transaction(outputs: [output], rewardParentBlockId: parentId);
      return FullBlockBody(transactions: [...base.transactions, rewardTx]);
    } else
      return base;
  }
}
