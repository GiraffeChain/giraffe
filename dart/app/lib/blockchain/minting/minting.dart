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
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:ribs_effect/ribs_effect.dart';
import 'package:rxdart/streams.dart';
import 'package:rxdart/transformers.dart';

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
    BlockchainView view,
    StakerSupportRpcClient stakerSupportClient,
    LockAddress? rewardAddress,
  ) =>
      make(
        stakerData,
        protocolSettings,
        clock,
        BlockPackerForStakerSupportRpc(client: stakerSupportClient, view: view),
        canonicalHead,
        adoptedHeaders,
        EtaCalculationForStakerSupportRpc(client: stakerSupportClient),
        leaderElection,
        StakerTrackerForStakerSupportRpc(client: stakerSupportClient),
        rewardAddress,
      );
}

class EtaCalculationForStakerSupportRpc extends EtaCalculation {
  final StakerSupportRpcClient client;

  EtaCalculationForStakerSupportRpc({required this.client});

  @override
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot) async =>
      (await client.calculateEta(CalculateEtaReq(
        parentBlockId: parentSlotId.blockId,
        slot: childSlot,
      )))
          .eta
          .decodeBase58;
}

class StakerTrackerForStakerSupportRpc extends StakerTracker {
  final StakerSupportRpcClient client;

  StakerTrackerForStakerSupportRpc({required this.client});

  @override
  Future<ActiveStaker?> staker(BlockId currentBlockId, Int64 slot,
      TransactionOutputReference account) async {
    final rpcResult = await client.getStaker(GetStakerReq(
        stakingAccount: account, parentBlockId: currentBlockId, slot: slot));
    if (rpcResult.hasStaker()) return rpcResult.staker;
    return null;
  }

  @override
  Future<Int64> totalActiveStake(BlockId currentBlockId, Slot slot) async {
    final rpcResult = await client.getTotalActivestake(
        GetTotalActiveStakeReq(parentBlockId: currentBlockId, slot: slot));
    return rpcResult.totalActiveStake;
  }
}

class BlockPackerForStakerSupportRpc extends BlockPacker {
  final StakerSupportRpcClient client;
  final BlockchainView view;
  BlockPackerForStakerSupportRpc({required this.client, required this.view});

  @override
  Stream<FullBlockBody> streamed(
      BlockId parentBlockId, Int64 height, Int64 slot) {
    s() {
      final x = client.packBlock(
          PackBlockReq(parentBlockId: parentBlockId, untilSlot: slot));
      return x.doOnCancel(() => x.cancel());
    }

    // return retryableStream(s,
    //         onError: (e, s) => Minting.log
    //             .warning("Remote BlockPacker error. Retrying.", e, s))
    return s()
        .takeWhile((v) => v.hasBody())
        .map((v) => v.body.transactionIds.map(view.getTransactionOrRaise))
        .asyncMap(Future.wait)
        .map((transactions) => FullBlockBody(transactions: transactions));
  }
}
