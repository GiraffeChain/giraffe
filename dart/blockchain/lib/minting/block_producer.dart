import 'dart:async';
import 'dart:math';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/models/unsigned.dart';
import 'package:async/async.dart';
import 'package:blockchain/common/utils.dart';
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
      CancelableCompleter<FullBlock?>? currentOperation = null;
      final controller = StreamController<FullBlock>(sync: true);
      controller.onListen = () {
        final subscription = stream.listen((data) {
          currentOperation?.operation.cancel();
          final nextOp = _makeChild(data);
          currentOperation = nextOp;
          unawaited(nextOp.operation.valueOrCancellation(null).then((blockOpt) {
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
            await currentOperation?.operation.cancel();
            await subscription.cancel;
          };
      };
      return controller.stream.listen(null);
    });
    return parentHeaders.transform(transformer);
  }

  CancelableCompleter<FullBlock?> _makeChild(SlotData parentSlotData) {
    List<Future<void> Function()> _cancelOps = [
      () => Future.sync(() => log.info(
          "Abandoning attempt on parentId=${parentSlotData.slotId.blockId.show}"))
    ];

    final CancelableCompleter<FullBlock?> completer = CancelableCompleter(
        onCancel: () => Future.wait(_cancelOps.map((f) => f())));

    StreamSubscription? packOperation;

    Future<void> go() async {
      try {
        Int64 fromSlot = parentSlotData.slotId.slot + 1;
        if (fromSlot < _nextSlotMinimum) fromSlot = _nextSlotMinimum;
        log.info("Calculating eligibility for" +
            " parentId=${parentSlotData.slotId.blockId.show}" +
            " parentSlot=${parentSlotData.slotId.slot}");
        final nextHit = await log.timedInfoAsync(
            () => _nextEligibility(parentSlotData.slotId, fromSlot),
            messageF: (duration) => "Eligibility calculation took $duration");
        if (nextHit != null && !completer.isCanceled) {
          log.info("Packing block for slot=${nextHit.slot}");
          FullBlockBody bodyTmp = FullBlockBody();
          packOperation = blockPacker
              .streamed(parentSlotData.slotId.blockId,
                  parentSlotData.height + 1, nextHit.slot)
              .takeWhile((_) =>
                  clock.globalSlot <= nextHit.slot && !completer.isCanceled)
              .listen((b) => bodyTmp = b,
                  onError: (e) => completer.completeError(e));
          _cancelOps.add(() async => packOperation?.cancel());
          final timer = clock.timerUntilSlot(nextHit.slot, () async {
            try {
              // TODO: gRPC stream bug that does not properly respect stream cancelation
              // await packOperation?.cancel();
              packOperation = null;
              final body = bodyTmp;
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
                final headerId = maybeHeader.id;
                final transactionIds = body.transactions.map((tx) => tx.id);
                log.info(
                    "Produced block id=${headerId.show} height=${maybeHeader.height} slot=${maybeHeader.slot} parentId=${maybeHeader.parentHeaderId.show} transactionIds=[${transactionIds.map((i) => i.show).join(",")}]");
                _nextSlotMinimum = maybeHeader.slot + 1;
                completer.complete(FullBlock()
                  ..header = maybeHeader
                  ..fullBody = bodyTmp);
              } else {
                log.warning(
                    "Failed to certify block at next slot=${nextHit.slot}.  Skipping eligibilities within current operational period.");
                final (nextOperationalPeriodStart, _) =
                    clock.operationalPeriodRange(
                        clock.operationalPeriodOfSlot(nextHit.slot) + 1);
                _nextSlotMinimum = nextOperationalPeriodStart;
                go().ignore();
              }
            } on Exception catch (e) {
              completer.completeError(e);
            }
          });
          _cancelOps.add(() async => timer.cancel());
        } else if (nextHit == null) completer.complete(null);
      } on Exception catch (e) {
        completer.completeError(e);
      }
    }

    go().onError((error, stackTrace) => null).ignore();
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
