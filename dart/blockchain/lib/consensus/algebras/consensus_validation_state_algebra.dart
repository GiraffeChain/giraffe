import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/common/utils.dart';
import 'package:rational/rational.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

abstract class ConsensusValidationStateAlgebra {
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot);

  Future<ActiveStaker?> staker(
      BlockId currentBlockId, Int64 slot, StakingAddress address);
  Future<Rational?> operatorRelativeStake(
      BlockId currentBlockId, Int64 slot, StakingAddress address) async {
    final s = await staker(currentBlockId, slot, address);
    if (s != null) {
      final total = await totalActiveStake(currentBlockId, slot);
      return Rational(s.quantity.toBigInt, total.toBigInt);
    }
    return null;
  }
}
