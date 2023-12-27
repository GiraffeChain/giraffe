import 'dart:async';

import 'package:fixnum/fixnum.dart';

import 'package:blockchain/common/models/common.dart';

abstract class Clock {
  Duration get slotLength;
  Int64 get slotsPerEpoch;
  Int64 get slotsPerOperationalPeriod;
  Int64 get globalSlot;
  Int64 get localTimestamp;
  int get forwardBiasedSlotWindow;
  Int64 timestampToSlot(Int64 timestamp);
  // Returns an inclusive range (minimum, maximum) of valid timestamps for the given slot
  (Int64, Int64) slotToTimestamps(Int64 slot);
  Future<void> delayedUntilSlot(Int64 slot);
  Future<void> delayedUntilTimestamp(Int64 timestamp);

  Int64 epochOfSlot(Int64 slot) => slot ~/ slotsPerEpoch;
  Int64 get globalEpoch => epochOfSlot(globalSlot);
  (Int64, Int64) epochRange(Int64 epoch) {
    final spe = slotsPerEpoch;
    return (epoch * spe, (epoch + 1) * spe - 1);
  }

  Int64 operationalPeriodOfSlot(Int64 slot) =>
      slot ~/ slotsPerOperationalPeriod;

  Int64 get globalOperationalPeriod => operationalPeriodOfSlot(globalSlot);

  (Int64, Int64) operationalPeriodRange(Int64 operationalPeriod) {
    final spor = slotsPerOperationalPeriod;
    return (operationalPeriod * spor, (spor + 1) * spor - 1);
  }

  Stream<Slot> get slots async* {
    var s = globalSlot;
    while (true) {
      await delayedUntilSlot(s);
      yield s;
      s++;
    }
  }
}

class ClockImpl extends Clock {
  final Duration slotLength;
  final Int64 slotsPerEpoch;
  final Int64 slotsPerOperationalPeriod;
  final Int64 _genesisTimestamp;
  final int forwardBiasedSlotWindow;

  ClockImpl(
    this.slotLength,
    this.slotsPerEpoch,
    this.slotsPerOperationalPeriod,
    this._genesisTimestamp,
    this.forwardBiasedSlotWindow,
  );

  @override
  Future<void> delayedUntilSlot(Int64 slot) =>
      delayedUntilTimestamp(slotToTimestamps(slot).$1);

  @override
  Future<void> delayedUntilTimestamp(Int64 timestamp) => Future.delayed(
      Duration(milliseconds: (timestamp - localTimestamp).toInt()));

  @override
  Int64 get globalSlot => timestampToSlot(localTimestamp);

  @override
  Int64 get localTimestamp => Int64(DateTime.now().millisecondsSinceEpoch);

  @override
  (Int64, Int64) slotToTimestamps(Int64 slot) {
    final first = _genesisTimestamp + (slot * slotLength.inMilliseconds);
    final second = first + (slotLength.inMilliseconds - 1);
    return (first, second);
  }

  @override
  Int64 timestampToSlot(Int64 timestamp) =>
      ((timestamp - _genesisTimestamp) ~/ slotLength.inMilliseconds);
}
