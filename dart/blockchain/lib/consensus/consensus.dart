import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/block_header_to_body_validation.dart';
import 'package:blockchain/consensus/block_header_validation.dart';
import 'package:blockchain/consensus/chain_selection.dart';
import 'package:blockchain/consensus/staker_tracker.dart';
import 'package:blockchain/consensus/eta_calculation.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/consensus/local_chain.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

class Consensus {
  final BlockHeaderToBodyValidation blockHeaderToBodyValidation;
  final BlockHeaderValidation blockHeaderValidation;
  final ChainSelection chainSelection;
  final StakerTracker stakerTracker;
  final EtaCalculation etaCalculation;
  final LeaderElection leaderElection;
  final LocalChain localChain;

  Consensus({
    required this.blockHeaderToBodyValidation,
    required this.blockHeaderValidation,
    required this.chainSelection,
    required this.stakerTracker,
    required this.etaCalculation,
    required this.leaderElection,
    required this.localChain,
  });

  static Resource<Consensus> make(
          ProtocolSettings protocolSettings,
          DataStores dataStores,
          Clock clock,
          FullBlock genesisBlock,
          CurrentEventIdGetterSetters currentEventIdGetterSetters,
          ParentChildTree<BlockId> parentChildTree,
          BlockHeightTree blockHeightTree,
          DComputeImpl isolate) =>
      Resource.eval(() async {
        final genesisBlockId = genesisBlock.header.id;
        final etaCalculation = EtaCalculationImpl(
            dataStores.slotData.getOrRaise,
            clock,
            genesisBlock.header.eligibilityCertificate.eta);

        final leaderElection = LeaderElectionImpl(protocolSettings, isolate);

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

        final consensusValidationState = StakerTrackerImpl(
            genesisBlockId, epochBoundaryState, consensusDataState, clock);

        final localChain = LocalChainImpl(
            genesisBlockId,
            await currentEventIdGetterSetters.canonicalHead.get(),
            blockHeightTree,
            (id) async => (await dataStores.slotData.getOrRaise(id)).height);

        final chainSelection =
            ChainSelectionImpl(dataStores.slotData.getOrRaise);
        final headerValidation = BlockHeaderValidationImpl(
            genesisBlockId,
            etaCalculation,
            consensusValidationState,
            leaderElection,
            clock,
            dataStores.headers.getOrRaise);

        final headerToBodyValidation = BlockHeaderToBodyValidationImpl();

        return Consensus(
            blockHeaderToBodyValidation: headerToBodyValidation,
            blockHeaderValidation: headerValidation,
            chainSelection: chainSelection,
            stakerTracker: consensusValidationState,
            etaCalculation: etaCalculation,
            leaderElection: leaderElection,
            localChain: localChain);
      });
}
