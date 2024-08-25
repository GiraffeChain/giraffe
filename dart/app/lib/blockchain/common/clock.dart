import 'dart:async';

import 'package:fixnum/fixnum.dart';

abstract class Clock {
  Duration get slotLength;
  Int64 get slotsPerEpoch;
  Int64 get globalSlot;
  Int64 get localTimestamp;
  Int64 timestampToSlot(Int64 timestamp);
  // Returns an inclusive range (minimum, maximum) of valid timestamps for the given slot
  (Int64, Int64) slotToTimestamps(Int64 slot);
  Future<void> delayedUntilTimestamp(Int64 timestamp);

  Future<void> delayedUntilSlot(Int64 slot) =>
      delayedUntilTimestamp(slotToTimestamps(slot).$1);

  Timer timerUntilTimestamp(Int64 timestamp, void Function() onComplete) =>
      Timer(
        DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()).difference(
            DateTime.fromMillisecondsSinceEpoch(localTimestamp.toInt())),
        onComplete,
      );

  Timer timerUntilSlot(Int64 slot, void Function() onComplete) =>
      timerUntilTimestamp(slotToTimestamps(slot).$1, onComplete);

  Int64 epochOfSlot(Int64 slot) {
    if (slot == Int64.ZERO) {
      return Int64(-1);
    } else if (slot < Int64.ZERO) {
      return Int64(-2);
    } else {
      return (slot - 1) ~/ slotsPerEpoch;
    }
  }

  Int64 get globalEpoch => epochOfSlot(globalSlot);

  (Int64, Int64) epochRange(Int64 epoch) {
    if (epoch == Int64(-1)) {
      return const (Int64.ZERO, Int64.ZERO);
    } else if (epoch < Int64(-1)) {
      return (Int64(-1), Int64(-1));
    } else {
      return ((epoch * slotsPerEpoch + 1), (epoch + 1) * slotsPerEpoch);
    }
  }
}

class ClockImpl extends Clock {
  @override
  final Duration slotLength;
  @override
  final Int64 slotsPerEpoch;
  final Int64 _genesisTimestamp;

  ClockImpl(
    this.slotLength,
    this.slotsPerEpoch,
    this._genesisTimestamp,
  );

  @override
  Future<void> delayedUntilTimestamp(Int64 timestamp) async {
    final now = localTimestamp;
    if (timestamp <= now) {
      return;
    }
    final delay = timestamp - now;
    await Future.delayed(Duration(milliseconds: delay.toInt()));
  }

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
