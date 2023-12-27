import 'dart:async';
import 'dart:math';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/models/unsigned.dart';
import 'package:async/async.dart';
import 'package:blockchain/ledger/block_packer.dart';
import 'package:blockchain/minting/models/vrf_hit.dart';
import 'package:blockchain/minting/staking.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

abstract class BlockProducer {
  Stream<FullBlock> get blocks;
}

class BlockProducerImpl extends BlockProducer {
  final Stream<SlotData> parentHeaders;
  final Staking staker;
  final Clock clock;
  final BlockPacker blockPacker;
  Int64 _nextSlotMinimum = Int64.ZERO;

  BlockProducerImpl(
      this.parentHeaders, this.staker, this.clock, this.blockPacker);

  final log = Logger("BlockProducer");

  @override
  Stream<FullBlock> get blocks {
    final transformer =
        StreamTransformer((Stream<SlotData> stream, cancelOnError) {
      CancelableOperation<FullBlock?>? currentOperation = null;
      final controller = StreamController<FullBlock>(sync: true);
      controller.onListen = () {
        final subscription = stream.listen((data) {
          currentOperation?.cancel();
          final nextOp = _makeChild(data);
          currentOperation = nextOp;
          unawaited(nextOp.valueOrCancellation(null).then((blockOpt) {
            if (blockOpt != null) controller.add(blockOpt);
          }));
        },
            onError: controller.addError,
            onDone: controller.close,
            cancelOnError: cancelOnError);
        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume
          ..onCancel = () async {
            await currentOperation?.cancel();
            await subscription.cancel;
          };
      };
      return controller.stream.listen(null);
    });
    return parentHeaders.transform(transformer);
  }

  CancelableOperation<FullBlock?> _makeChild(SlotData parentSlotData) {
    late final CancelableOperation<FullBlock?> completer;
    List<Future<void> Function()> _cancelOps = [];

    Future<FullBlock?> go() async {
      Int64 fromSlot = parentSlotData.slotId.slot + 1;
      if (fromSlot < _nextSlotMinimum) fromSlot = _nextSlotMinimum;
      final nextHit = await _nextEligibility(parentSlotData.slotId, fromSlot);
      if (nextHit != null) {
        log.info("Packing block for slot=${nextHit.slot}");
        FullBlockBody bodyOpt = FullBlockBody();
        final packOperation = CancelableOperation.fromFuture(blockPacker
            .streamed(parentSlotData.slotId.blockId, parentSlotData.height + 1,
                nextHit.slot)
            .takeWhile((_) => clock.globalSlot <= nextHit.slot)
            .forEach((b) => bodyOpt = b));
        _cancelOps.add(packOperation.cancel);
        await clock.delayedUntilSlot(nextHit.slot);
        await packOperation.cancel();
        final body = bodyOpt;
        log.info("Constructing block for slot=${nextHit.slot}");
        final now = DateTime.now().millisecondsSinceEpoch;
        final (slotStart, slotEnd) = clock.slotToTimestamps(nextHit.slot);
        final timestamp =
            Int64(min(slotEnd.toInt(), max(now, slotStart.toInt())));
        final maybeHeader = await staker.certifyBlock(
            parentSlotData.slotId,
            nextHit.slot,
            _prepareUnsignedBlock(
              parentSlotData,
              body,
              timestamp,
              nextHit,
            ));
        if (maybeHeader != null) {
          final headerId = await maybeHeader.id;
          final transactionIds = body.transactions.map((tx) => tx.id);
          log.info(
              "Produced block id=${headerId.show} height=${maybeHeader.height} slot=${maybeHeader.slot} parentId=${maybeHeader.parentHeaderId.show} transactionIds=[${transactionIds.map((i) => i.show).join(",")}]");
          _nextSlotMinimum = maybeHeader.slot + 1;
          return FullBlock()
            ..header = maybeHeader
            ..fullBody = bodyOpt;
        } else {
          log.warning(
              "Failed to certify block at next slot=${nextHit.slot}.  Skipping eligibilities within current operational period.");
          final (nextOperationalPeriodStart, _) = clock.operationalPeriodRange(
              clock.operationalPeriodOfSlot(nextHit.slot) + 1);
          _nextSlotMinimum = nextOperationalPeriodStart;
          return go();
        }
      }
      return null;
    }

    completer = CancelableOperation.fromFuture(go(),
        onCancel: () => Future.wait(_cancelOps.map((f) => f())));
    return completer;
  }

  Future<VrfHit?> _nextEligibility(SlotId parentSlotId, Int64 fromSlot) async {
    Int64 test = fromSlot;
    final exitSlot =
        clock.epochRange(clock.epochOfSlot(parentSlotId.slot) + 1).$2;
    VrfHit? maybeHit;
    while (maybeHit == null && test < exitSlot) {
      maybeHit = await staker.elect(parentSlotId, test);
      test = test + 1;
    }
    return maybeHit;
  }

  UnsignedBlockHeader Function(PartialOperationalCertificate)
      _prepareUnsignedBlock(SlotData parentSlotData, FullBlockBody fullBody,
              Int64 timestamp, VrfHit nextHit) =>
          (PartialOperationalCertificate partialOperationalCertificate) =>
              UnsignedBlockHeader(
                parentSlotData.slotId.blockId,
                parentSlotData.slotId.slot,
                [], // TODO
                [], // TODO
                timestamp,
                parentSlotData.height + 1,
                nextHit.slot,
                nextHit.cert,
                partialOperationalCertificate,
                [],
                staker.address,
              );
}
