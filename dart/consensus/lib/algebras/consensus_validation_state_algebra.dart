import 'package:rational/rational.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

abstract class ConsensusValidationStateAlgebra {
  Future<Rational?> operatorRelativeStake(
      BlockId currentBlockId, Int64 slot, StakingAddress address);

  Future<SignatureKesProduct?> operatorRegistration(
      BlockId currentBlockId, Int64 slot, StakingAddress address);
}
