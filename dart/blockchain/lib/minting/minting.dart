import 'dart:io';

import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/consensus/consensus.dart';
import 'package:blockchain/consensus/eta_calculation.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/consensus/staker_tracker.dart';
import 'package:blockchain/crypto/ed25519.dart';
import 'package:blockchain/crypto/ed25519vrf.dart';
import 'package:blockchain/ledger/block_packer.dart';
import 'package:blockchain/minting/block_producer.dart';
import 'package:blockchain/minting/secure_store.dart';
import 'package:blockchain/minting/staking.dart';
import 'package:blockchain/minting/vrf_calculator.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rxdart/transformers.dart';

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

  static Resource<Minting> make(
    Directory stakingDir,
    ProtocolSettings protocolSettings,
    Clock clock,
    BlockPacker blockPacker,
    SlotData canonicalHeadSlotData,
    Stream<SlotData> adoptedSlotData,
    EtaCalculation etaCalculation,
    LeaderElection leaderElection,
    StakerTracker stakerTracker,
  ) =>
      Resource.pure(Directory("${stakingDir.path}/kes"))
          .map((kesDir) => DiskSecureStore(baseDir: kesDir))
          .evalFlatMap((secureStore) async {
        final vrfSk = await File("${stakingDir.path}/vrf").readAsBytes();
        final vrfVk = await ed25519Vrf.getVerificationKey(vrfSk);
        final operatorSk =
            await File("${stakingDir.path}/operator").readAsBytes();
        final operatorVk = await ed25519.getVerificationKey(operatorSk);
        final stakingAddress = StakingAddress(value: operatorVk);
        final vrfCalculator =
            VrfCalculatorImpl(vrfSk, clock, leaderElection, protocolSettings);

        return StakingImpl.make(
          canonicalHeadSlotData.slotId,
          protocolSettings.operationalPeriodLength,
          Int64(0),
          stakingAddress,
          vrfVk,
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

  static Resource<Minting> makeForConsensus(
    Directory stakingDir,
    ProtocolSettings protocolSettings,
    Clock clock,
    Consensus consensus,
    BlockPacker blockPacker,
    SlotData canonicalHeadSlotData,
    Stream<SlotData> adoptedSlotData,
  ) =>
      make(
          stakingDir,
          protocolSettings,
          clock,
          blockPacker,
          canonicalHeadSlotData,
          adoptedSlotData,
          consensus.etaCalculation,
          consensus.leaderElection,
          consensus.stakerTracker);

  static Resource<Minting> makeForRpc(
    Directory stakingDir,
    ProtocolSettings protocolSettings,
    Clock clock,
    SlotData canonicalHeadSlotData,
    Stream<SlotData> adoptedSlotData,
    LeaderElection leaderElection,
    NodeRpcClient nodeClient,
    StakerSupportRpcClient stakerSupportClient,
  ) =>
      make(
        stakingDir,
        protocolSettings,
        clock,
        BlockPackerForStakerSupportRpc(
            client: stakerSupportClient, nodeClient: nodeClient),
        canonicalHeadSlotData,
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
      BlockId parentBlockId, Int64 height, Int64 slot) {
    final s = client
        .packBlock(PackBlockReq(parentBlockId: parentBlockId, untilSlot: slot));
    return s
        .doOnCancel(() => s.cancel())
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
}
