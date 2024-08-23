import 'dart:async';

import 'package:fixnum/fixnum.dart';

import 'models/common.dart';
import 'package:ribs_effect/ribs_effect.dart';

abstract class Clock {
  Duration get slotLength;
  Int64 get slotsPerEpoch;
  Int64 get globalSlot;
  Int64 get localTimestamp;
  Int64 timestampToSlot(Int64 timestamp);
  // Returns an inclusive range (minimum, maximum) of valid timestamps for the given slot
  (Int64, Int64) slotToTimestamps(Int64 slot);
  IO<void> delayedUntilTimestamp(Int64 timestamp);

  IO<void> delayedUntilSlot(Int64 slot) =>
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
    if (slot == Int64.ZERO)
      return Int64(-1);
    else if (slot < Int64.ZERO)
      return Int64(-2);
    else
      return (slot - 1) ~/ slotsPerEpoch;
  }

  Int64 get globalEpoch => epochOfSlot(globalSlot);

  (Int64, Int64) epochRange(Int64 epoch) {
    if (epoch == Int64(-1))
      return const (Int64.ZERO, Int64.ZERO);
    else if (epoch < Int64(-1))
      return (Int64(-1), Int64(-1));
    else
      return ((epoch * slotsPerEpoch + 1), (epoch + 1) * slotsPerEpoch);
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
  final Int64 _genesisTimestamp;

  ClockImpl(
    this.slotLength,
    this.slotsPerEpoch,
    this._genesisTimestamp,
  );

  @override
  IO<void> delayedUntilTimestamp(Int64 timestamp) => IO
      .delay(() => localTimestamp)
      .map((l) => Duration(milliseconds: (timestamp - l).toInt()))
      .flatMap(IO.sleep);

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
