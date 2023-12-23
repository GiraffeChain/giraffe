import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/block_header_to_body_validation.dart';
import 'package:blockchain/consensus/block_header_validation.dart';
import 'package:blockchain/consensus/chain_selection.dart';
import 'package:blockchain/consensus/consensus_validation_state.dart';
import 'package:blockchain/consensus/eta_calculation.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/consensus/local_chain.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Consensus {
  final BlockHeaderToBodyValidationAlgebra blockHeaderToBodyValidation;
  final BlockHeaderValidationAlgebra blockHeaderValidation;
  final ChainSelectionAlgebra chainSelection;
  final ConsensusValidationStateAlgebra consensusValidationState;
  final EtaCalculationAlgebra etaCalculation;
  final LeaderElectionValidationAlgebra leaderElectionValidation;
  final LocalChainAlgebra localChain;

  Consensus({
    required this.blockHeaderToBodyValidation,
    required this.blockHeaderValidation,
    required this.chainSelection,
    required this.consensusValidationState,
    required this.etaCalculation,
    required this.leaderElectionValidation,
    required this.localChain,
  });

  static Resource<Consensus> make(
          ProtocolSettings protocolSettings,
          DataStores dataStores,
          ClockAlgebra clock,
          FullBlock genesisBlock,
          CurrentEventIdGetterSetters currentEventIdGetterSetters,
          ParentChildTreeAlgebra<BlockId> parentChildTree,
          BlockHeightTree blockHeightTree,
          DComputeImpl isolate) =>
      Resource.eval(() async {
        final genesisBlockId = genesisBlock.header.id;
        final etaCalculation = EtaCalculation(dataStores.slotData.getOrRaise,
            clock, genesisBlock.header.eligibilityCertificate.eta);

        final leaderElection =
            LeaderElectionValidation(protocolSettings, isolate);

        final epochBoundaryState = epochBoundariesEventSourcedState(
            clock,
            await currentEventIdGetterSetters.epochBoundaries.get(),
            parentChildTree,
            currentEventIdGetterSetters.epochBoundaries.set,
            dataStores.epochBoundaries,
            dataStores.slotData.getOrRaise);
        final consensusDataState = consensusDataEventSourcedState(
            await currentEventIdGetterSetters.consensusData.get(),
            parentChildTree,
            currentEventIdGetterSetters.consensusData.set,
            ConsensusData(dataStores.activeStake, dataStores.inactiveStake,
                dataStores.activeStakers),
            dataStores.bodies.getOrRaise,
            dataStores.transactions.getOrRaise);

        final consensusValidationState = ConsensusValidationState(
            genesisBlockId, epochBoundaryState, consensusDataState, clock);

        final localChain = LocalChain(
            genesisBlockId,
            await currentEventIdGetterSetters.canonicalHead.get(),
            blockHeightTree,
            (id) async => (await dataStores.slotData.getOrRaise(id)).height);

        final chainSelection = ChainSelection(dataStores.slotData.getOrRaise);
        final headerValidation = BlockHeaderValidation(
            genesisBlockId,
            etaCalculation,
            consensusValidationState,
            leaderElection,
            clock,
            dataStores.headers.getOrRaise);

        final headerToBodyValidation = BlockHeaderToBodyValidation();

        return Consensus(
            blockHeaderToBodyValidation: headerToBodyValidation,
            blockHeaderValidation: headerValidation,
            chainSelection: chainSelection,
            consensusValidationState: consensusValidationState,
            etaCalculation: etaCalculation,
            leaderElectionValidation: leaderElection,
            localChain: localChain);
      });
}
