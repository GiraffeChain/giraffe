import 'dart:io';

import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/consensus/eta_calculation.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/consensus/staker_tracker.dart';
import 'package:blockchain/ledger/block_packer.dart';
import 'package:blockchain/minting/block_producer.dart';
import 'package:blockchain/minting/secure_store.dart';
import 'package:blockchain/minting/staking.dart';
import 'package:blockchain/minting/vrf_calculator.dart';
import 'package:blockchain/staker_initializer.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';

class Minting {
  final BlockProducer blockProducer;
  final SecureStore secureStore;
  final Staking staking;
  final VrfCalculator vrfCalculator;

  Minting({
    required this.blockProducer,
    required this.secureStore,
    required this.staking,
    required this.vrfCalculator,
  });

  static Resource<Minting> makeForConsensus(
    ProtocolSettings protocolSettings,
    Clock clock,
    Consensus consensus,
    BlockPacker blockPacker,
    SlotData canonicalHeadSlotData,
    StakerInitializer stakerInitializer,
    Stream<SlotData> adoptedSlotData,
  ) =>
      make(
          protocolSettings,
          clock,
          blockPacker,
          canonicalHeadSlotData,
          stakerInitializer,
          adoptedSlotData,
          consensus.etaCalculation,
          consensus.leaderElection,
          consensus.stakerTracker);

  static Resource<Minting> make(
    ProtocolSettings protocolSettings,
    Clock clock,
    BlockPacker blockPacker,
    SlotData canonicalHeadSlotData,
    StakerInitializer stakerInitializer,
    Stream<SlotData> adoptedSlotData,
    EtaCalculation etaCalculation,
    LeaderElection leaderElection,
    StakerTracker stakerTracker,
  ) =>
      Resource.eval(() => Directory.systemTemp.createTemp("secure-store"))
          .map((stakingDir) => DiskSecureStore(baseDir: stakingDir))
          .flatMap((secureStore) {
        final vrfCalculator = VrfCalculatorImpl(stakerInitializer.vrfKeyPair.sk,
            clock, leaderElection, protocolSettings);

        return StakingImpl.make(
          canonicalHeadSlotData.slotId,
          protocolSettings.operationalPeriodLength,
          Int64(0),
          stakerInitializer.stakingAddress,
          stakerInitializer.kesKeyPair.sk,
          stakerInitializer.vrfKeyPair.vk,
          secureStore,
          clock,
          vrfCalculator,
          etaCalculation,
          stakerTracker,
          leaderElection,
        ).map((staking) {
          final blockProducer = BlockProducerImpl(
            adoptedSlotData,
            staking,
            clock,
            blockPacker,
          );

          return Minting(
            blockProducer: blockProducer,
            secureStore: secureStore,
            staking: staking,
            vrfCalculator: vrfCalculator,
          );
        });
      });

  static Resource<Minting> makeForRpc(
    ProtocolSettings protocolSettings,
    Clock clock,
    SlotData canonicalHeadSlotData,
    StakerInitializer stakerInitializer,
    Stream<SlotData> adoptedSlotData,
    LeaderElection leaderElection,
    NodeRpcClient nodeClient,
    StakerSupportRpcClient stakerSupportClient,
  ) =>
      make(
        protocolSettings,
        clock,
        BlockPackerForStakerSupportRpc(
            client: stakerSupportClient, nodeClient: nodeClient),
        canonicalHeadSlotData,
        stakerInitializer,
        adoptedSlotData,
        EtaCalculationForStakerSupportRpc(client: stakerSupportClient),
        leaderElection,
        StakerTrackerForStakerSupportRpc(client: stakerSupportClient),
      );
}

class EtaCalculationForStakerSupportRpc extends EtaCalculation {
  final StakerSupportRpcClient client;

  EtaCalculationForStakerSupportRpc({required this.client});

  @override
  Future<Eta> etaToBe(SlotId parentSlotId, Int64 childSlot) async =>
      (await client.calculateEta(CalculateEtaReq(
              parentBlockId: parentSlotId.blockId, slot: childSlot)))
          .eta;
}

class StakerTrackerForStakerSupportRpc extends StakerTracker {
  final StakerSupportRpcClient client;

  StakerTrackerForStakerSupportRpc({required this.client});

  @override
  Future<ActiveStaker?> staker(
      BlockId currentBlockId, Int64 slot, StakingAddress address) async {
    final rpcResult = await client.getStaker(GetStakerReq(
        stakingAddress: address, parentBlockId: currentBlockId, slot: slot));
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
  final NodeRpcClient nodeClient;
  BlockPackerForStakerSupportRpc(
      {required this.client, required this.nodeClient});

  @override
  Stream<FullBlockBody> streamed(
          BlockId parentBlockId, Int64 height, Int64 slot) =>
      client
          .packBlock(
              PackBlockReq(parentBlockId: parentBlockId, untilSlot: slot))
          .takeWhile((v) => v.hasBody())
          .map((v) => v.body)
          .asyncMap(
            (body) => Future.wait(
              body.transactionIds.map(
                (id) => nodeClient
                    .getTransaction(GetTransactionReq(transactionId: id))
                    .then((txRes) {
                  assert(txRes.hasTransaction());
                  return txRes.transaction;
                }),
              ),
            ),
          )
          .map((transactions) => FullBlockBody(transactions: transactions));
}
