import 'package:blockchain_common/algebras/clock_algebra.dart';
import 'package:blockchain_common/algebras/event_sourced_state_algebra.dart';
import 'package:blockchain_common/models/common.dart';
import 'package:blockchain_consensus/algebras/consensus_validation_state_algebra.dart';
import 'package:blockchain_consensus/interpreters/consensus_data_event_sourced_state.dart';
import 'package:blockchain_consensus/interpreters/epoch_boundaries.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:rational/rational.dart';
import 'package:fixnum/fixnum.dart';

class ConsensusValidationState extends ConsensusValidationStateAlgebra {
  final BlockId genesisBlockId;
  final EventSourcedStateAlgebra<EpochBoundariesState, BlockId>
      epochBoundaryState;
  final EventSourcedStateAlgebra<ConsensusData, BlockId> consensusDataState;
  final ClockAlgebra clock;

  ConsensusValidationState(this.genesisBlockId, this.epochBoundaryState,
      this.consensusDataState, this.clock);

  @override
  Future<SignatureKesProduct?> operatorRegistration(
          BlockId currentBlockId, Int64 slot, StakingAddress address) =>
      _useStateAtTargetBoundary(
          currentBlockId, slot, (t) => t.registrations.get(address));

  @override
  Future<Rational?> operatorRelativeStake(
          BlockId currentBlockId, Int64 slot, StakingAddress address) =>
      _useStateAtTargetBoundary(currentBlockId, slot, (consensusData) async {
        final maybeStake = await consensusData.operatorStakes.get(address);
        if (maybeStake != null) {
          final totalStake =
              await consensusData.totalActiveStake.getOrRaise("");
          return Rational(maybeStake, totalStake);
        }
        return null;
      });

  Future<Res> _useStateAtTargetBoundary<Res>(BlockId currentBlockId, Slot slot,
      Future<Res> Function(ConsensusData) f) async {
    final epoch = clock.epochOfSlot(slot);
    final targetEpoch = epoch - 2;
    final boundaryBlockId = (targetEpoch >= 0)
        ? await epochBoundaryState.useStateAt(
            currentBlockId, (s) => s.getOrRaise(targetEpoch))
        : genesisBlockId;
    return consensusDataState.useStateAt(boundaryBlockId, f);
  }
}
