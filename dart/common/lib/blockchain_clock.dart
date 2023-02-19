import 'package:fixnum/fixnum.dart';

class BlockchainClock {
  final Int64 genesisTimestamp;

  BlockchainClock(this.genesisTimestamp);

  Int64 get currentTimestamp => Int64(DateTime.now().millisecondsSinceEpoch);

  Future<void> delayUntil(DateTime dateTime) async => Future.delayed(Duration(
      milliseconds:
          dateTime.millisecondsSinceEpoch - currentTimestamp.toInt()));
}
