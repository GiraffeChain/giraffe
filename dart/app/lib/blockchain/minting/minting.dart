import '../common/models/unsigned.dart';
import 'models/staker_data.dart';
import 'package:blockchain_sdk/sdk.dart';
import '../common/clock.dart';
import '../common/models/common.dart';
import '../common/resource.dart';
import '../consensus/eta_calculation.dart';
import '../consensus/leader_election_validation.dart';
import '../consensus/staker_tracker.dart';
import '../crypto/ed25519vrf.dart';
import '../ledger/block_packer.dart';
import 'block_producer.dart';
import 'staking.dart';
import 'vrf_calculator.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:ribs_effect/ribs_effect.dart';
import 'package:rxdart/streams.dart';

class Minting {
  final BlockProducer blockProducer;
  final Staking staking;
  final VrfCalculator vrfCalculator;

  Minting({
    required this.blockProducer,
    required this.staking,
    required this.vrfCalculator,
  });

  static final log = Logger("Blockchain.Minting");

  static Resource<Minting> make(
    StakerData stakerData,
    ProtocolSettings protocolSettings,
    Clock clock,
    BlockPacker blockPacker,
    BlockHeader canonicalHead,
    Stream<BlockHeader> adoptedHeaders,
    EtaCalculation etaCalculation,
    LeaderElection leaderElection,
    StakerTracker stakerTracker,
    LockAddress? rewardAddress,
  ) =>
      Resource.pure(VrfCalculatorImpl(
              stakerData.vrfSk, clock, leaderElection, protocolSettings))
          .evalFlatMap((vrfCalculator) async {
        final vrfVk = await ed25519Vrf.getVerificationKey(stakerData.vrfSk);

        return StakingImpl.make(
          canonicalHead.slotId,
          stakerData.account,
          vrfVk,
          stakerData.operatorSk,
          clock,
          vrfCalculator,
          etaCalculation,
          stakerTracker,
          leaderElection,
        ).map((staking) {
          if (rewardAddress == null) log.warning("Reward Address not set.");
          final blockProducer = BlockProducerImpl(
            ConcatEagerStream([Stream.value(canonicalHead), adoptedHeaders]),
            staking,
            clock,
            blockPacker,
            rewardAddress,
          );

          return Minting(
            blockProducer: blockProducer,
            staking: staking,
            vrfCalculator: vrfCalculator,
          );
        });
      });

  static Resource<Minting> makeForRpc(
    StakerData stakerData,
    ProtocolSettings protocolSettings,
    Clock clock,
    BlockHeader canonicalHead,
    Stream<BlockHeader> adoptedHeaders,
    LeaderElection leaderElection,
    BlockchainClient client,
    LockAddress? rewardAddress,
  ) =>
      make(
        stakerData,
        protocolSettings,
        clock,
        BlockPackerForStakerSupportRpc(client: client),
        canonicalHead,
        adoptedHeaders,
        EtaCalculationForStakerSupportRpc(client: client),
        leaderElection,
        StakerTrackerForStakerSupportRpc(client: client),
        rewardAddress,
      );
}

class EtaCalculationForStakerSupportRpc extends EtaCalculation {
  final BlockchainClient client;

  EtaCalculationForStakerSupportRpc({required this.client});

  @override
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot) =>
      client.calculateEta(
        parentSlotId.blockId,
        childSlot,
      );
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

class BlockPackerForStakerSupportRpc extends BlockPacker {
  final BlockchainClient client;
  BlockPackerForStakerSupportRpc({required this.client});

  @override
  Stream<FullBlockBody> streamed(
      BlockId parentBlockId, Int64 height, Int64 slot) {
    return client.packBlock
        .map((v) => v.transactionIds.map(client.getTransactionOrRaise))
        .asyncMap(Future.wait)
        .map((transactions) => FullBlockBody(transactions: transactions));
  }
}
