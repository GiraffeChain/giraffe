import 'package:blockchain_app/blockchain/consensus/eta_calculation.dart';
import 'package:blockchain_app/blockchain/consensus/staker_tracker.dart';
import 'package:blockchain_app/blockchain/ledger/block_packer.dart';
import 'package:blockchain_app/providers/staking/staking.dart';
import 'package:blockchain_app/providers/wallet.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

import '../../blockchain/common/clock.dart';
import '../../blockchain/consensus/leader_election_validation.dart';
import '../../blockchain/crypto/ed25519vrf.dart';
import '../../blockchain/minting/block_producer.dart';
import '../../blockchain/minting/staking.dart';
import '../../blockchain/minting/vrf_calculator.dart';
import '../blockchain_client.dart';

part 'block_production.freezed.dart';
part 'block_production.g.dart';

@Riverpod(keepAlive: true)
class PodBlockProduction extends _$PodBlockProduction {
  @override
  PodBlockProductionState build() => InactivePodBlockProductionState();

  void start() async {
    final stakerData = ref.read(podStakingProvider);
    if (stakerData == null) {
      throw Exception("Staker data not available");
    }
    final rewardAddress =
        (await ref.read(podWalletProvider.future)).defaultLockAddress;

    final client = ref.read(podBlockchainClientProvider);
    final canonicalHeadId = await client.canonicalHeadId;
    final canonicalHead = await client.getBlockHeaderOrRaise(canonicalHeadId);
    log.info(
        "Canonical head id=${canonicalHeadId.show} height=${canonicalHead.height} slot=${canonicalHead.slot}");
    final protocolSettings = await client.protocolSettings;

    final genesisBlockId = await client.genesisBlockId;
    final genesisHeader = await client.getBlockHeaderOrRaise(genesisBlockId);
    log.info(
        "Genesis id=${genesisBlockId.show} height=${genesisHeader.height} slot=${genesisHeader.slot}");
    final clock = ClockImpl(
      protocolSettings.slotDuration,
      protocolSettings.epochLength,
      genesisHeader.timestamp,
    );
    final leaderElection = LeaderElectionImpl(protocolSettings, isolate);

    final vrfCalculator = VrfCalculatorImpl(
        stakerData.vrfSk, clock, leaderElection, protocolSettings);
    final vrfVk = await ed25519Vrf.getVerificationKey(stakerData.vrfSk);

    final staking = StakingImpl(
      stakerData.account,
      vrfVk,
      stakerData.operatorSk,
      StakerTrackerForStakerSupportRpc(client: client),
      EtaCalculationForStakerSupportRpc(client: client),
      vrfCalculator,
      leaderElection,
    );

    final blockProducer = BlockProducerImpl(
      staking,
      clock,
      BlockPackerForStakerSupportRpc(client: client),
      rewardAddress,
    );

    Future<void> Function() cancel = () => Future.value();
    final mainSub = ConcatEagerStream([
      Stream.value(canonicalHead),
      client.adoptedBlocks.map((b) => b.header)
    ]).asyncMap((h) async {
      await cancel();
      final sub = blockProducer
          .makeChild(h)
          .asyncMap((b) => client.broadcastBlock(
                Block(
                  header: b.header,
                  body: BlockBody(
                      transactionIds: b.fullBody.transactions.map((t) => t.id)),
                ),
                b.fullBody.rewardTransaction,
              ))
          .listen(null);
      cancel = () => sub.cancel();
    }).listen(null);

    Future<void> c() async {
      await mainSub.cancel();
      await cancel();
    }

    ref.onDispose(() async {
      await c();
    });

    state = ActivePodBlockProductionState(stop: c);
  }

  void stop() async {
    if (state is ActivePodBlockProductionState) {
      await (state as ActivePodBlockProductionState).stop!();
      state = InactivePodBlockProductionState();
    } else {
      throw Exception("Block production not active");
    }
  }

  static final log = Logger("Blockchain.BlockProducer");
}

abstract class PodBlockProductionState {}

class InactivePodBlockProductionState extends PodBlockProductionState {}

@freezed
class ActivePodBlockProductionState extends PodBlockProductionState
    with _$ActivePodBlockProductionState {
  const factory ActivePodBlockProductionState(
          {required Future<void> Function()? stop}) =
      _ActivePodBlockProductionState;
}
