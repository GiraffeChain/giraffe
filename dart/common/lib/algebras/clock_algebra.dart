import 'dart:async';

import 'package:blockchain_common/models/common.dart';
import 'package:fixnum/fixnum.dart';
import 'package:fpdart/fpdart.dart';

abstract class ClockAlgebra {
  Duration get slotLength;
  Int64 get slotsPerEpoch;
  Int64 get globalSlot;
  Int64 get localTimestamp;
  Int64 get forwardBiasedSlotWindow;
  Int64 timestampToSlot(Int64 timestamp);
  // Returns an inclusive range (minimum, maximum) of valid timestamps for the given slot
  Tuple2<Int64, Int64> slotToTimestamps(Int64 slot);
  Future<void> delayedUntilSlot(Int64 slot);
  Future<void> delayedUntilTimestamp(Int64 timestamp);

  Int64 epochOfSlot(Int64 slot) => slot ~/ slotsPerEpoch;
  Int64 get globalEpoch => epochOfSlot(globalSlot);
  Tuple2<Int64, Int64> epochRange(Int64 epoch) {
    final spe = slotsPerEpoch;
    return Tuple2(epoch * spe, (epoch + 1) * spe - 1);
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
