import '../common/models/common.dart';
import 'package:fixnum/fixnum.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:rational/rational.dart';

abstract class StakerTracker {
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot);

  Future<ActiveStaker?> staker(
      BlockId currentBlockId, Int64 slot, TransactionOutputReference account);

  Future<Rational?> operatorRelativeStake(BlockId currentBlockId, Int64 slot,
      TransactionOutputReference account) async {
    final s = await staker(currentBlockId, slot, account);
    if (s != null) {
      final total = await totalActiveStake(currentBlockId, slot);
      return Rational(s.quantity.toBigInt, total.toBigInt);
    }
    return null;
  }
}

class StakerTrackerForStakerSupportRpc extends StakerTracker {
  final BlockchainClient client;

  StakerTrackerForStakerSupportRpc({required this.client});

  @override
  Future<ActiveStaker?> staker(BlockId currentBlockId, Int64 slot,
          TransactionOutputReference account) =>
      client.getStaker(currentBlockId, slot, account);

  @override
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot) =>
      client.getTotalActivestake(currentBlockId, slot);
}
