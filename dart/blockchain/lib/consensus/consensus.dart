import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/block_height_tree.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/parent_child_tree.dart';
import 'package:blockchain/common/resource.dart';
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
import 'package:ribs_core/ribs_core.dart';
import 'package:ribs_effect/ribs_effect.dart';

class Consensus {
  final BlockHeaderValidation blockHeaderValidation;
  final ChainSelection chainSelection;
  final StakerTracker stakerTracker;
  final EtaCalculation etaCalculation;
  final LeaderElection leaderElection;
  final LocalChain localChain;

  Consensus({
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
      Resource.eval(IO.fromFutureF(() async {
        final genesisBlockId = genesisBlock.header.id;
        final etaCalculation = EtaCalculationImpl(dataStores.headers.getOrRaise,
            clock, genesisBlock.header.eligibilityCertificate.eta.decodeBase58);

        final leaderElection = LeaderElectionImpl(protocolSettings, isolate);

        final epochBoundaryState = epochBoundariesEventSourcedState(
          clock,
          await currentEventIdGetterSetters.epochBoundaries.get(),
          parentChildTree,
          currentEventIdGetterSetters.epochBoundaries.set,
          dataStores.epochBoundaries,
          dataStores.headers.getOrRaise,
        );
        final consensusDataState = ConsensusData.eventSourcedState(
            await currentEventIdGetterSetters.consensusData.get(),
            parentChildTree,
            currentEventIdGetterSetters.consensusData.set,
            ConsensusData(
                dataStores.delayedActiveStake,
                dataStores.delayedInactiveStake,
                dataStores.delayedActiveStakers),
            dataStores.bodies.getOrRaise,
            dataStores.transactions.getOrRaise);

        final stakerTracker = StakerTrackerImpl(
            genesisBlockId, epochBoundaryState, consensusDataState, clock);

        return LocalChainImpl.make(
                genesisBlockId,
                await currentEventIdGetterSetters.canonicalHead.get(),
                blockHeightTree,
                (id) async => (await dataStores.headers.getOrRaise(id)).height,
                parentChildTree)
            .flatTap((localChain) =>
                stakerTracker.epochBoundaryState.followChain(localChain))
            .flatTap((localChain) => ResourceUtils.forStreamSubscription(() =>
                localChain.adoptions
                    .asyncMap(currentEventIdGetterSetters.canonicalHead.set)
                    .listen(null)))
            .map((localChain) {
          final chainSelection =
              ChainSelection(protocolSettings: protocolSettings);
          final headerValidation = BlockHeaderValidationImpl(
              genesisBlockId,
              etaCalculation,
              stakerTracker,
              leaderElection,
              clock,
              dataStores.headers.getOrRaise);

          return Consensus(
              blockHeaderValidation: headerValidation,
              chainSelection: chainSelection,
              stakerTracker: stakerTracker,
              etaCalculation: etaCalculation,
              leaderElection: leaderElection,
              localChain: localChain);
        });
      })).flatMap(identity);
}
