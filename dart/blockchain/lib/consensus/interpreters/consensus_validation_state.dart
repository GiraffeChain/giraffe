import 'package:blockchain/common/algebras/clock_algebra.dart';
import 'package:blockchain/common/algebras/event_sourced_state_algebra.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/consensus/algebras/consensus_validation_state_algebra.dart';
import 'package:blockchain/consensus/interpreters/consensus_data_event_sourced_state.dart';
import 'package:blockchain/consensus/interpreters/epoch_boundaries.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
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
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot) =>
      _useStateAtTargetBoundary(
          currentBlockId, slot, (p0) => p0.totalActiveStake.getOrRaise(""));

  @override
  Future<ActiveStaker?> staker(
          BlockId currentBlockId, Int64 slot, StakingAddress address) =>
      _useStateAtTargetBoundary(
          currentBlockId, slot, (t) => t.registrations.get(address));

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
