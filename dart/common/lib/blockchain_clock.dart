import 'package:fixnum/fixnum.dart';

class BlockchainClock {
  final Int64 genesisTimestamp;
  final Duration slotDuration;

  BlockchainClock(this.genesisTimestamp, this.slotDuration);

  Int64 get currentTimestamp => Int64(DateTime.now().millisecondsSinceEpoch);
  Int64 get currentSlot =>
      (currentTimestamp - genesisTimestamp) ~/ slotDuration.inMilliseconds;

  Future<void> delayUntilSlot(Int64 slot) async =>
      Future.delayed(slotDuration * (slot - currentSlot).toInt());
}
