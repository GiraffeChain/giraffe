import 'package:flutter_background/flutter_background.dart';
import 'package:giraffe_frontend/utils.dart';
import 'package:giraffe_protocol/protocol.dart';

import '../../providers/staking/staking.dart';
import '../../providers/wallet.dart';
import 'package:giraffe_sdk/sdk.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rxdart/rxdart.dart';

import '../blockchain_client.dart';

part 'block_production.freezed.dart';
part 'block_production.g.dart';

@Riverpod(keepAlive: true)
class PodBlockProduction extends _$PodBlockProduction {
  @override
  PodBlockProductionState build() => InactivePodBlockProductionState();

  void start() async {
    final stakerData = await ref.read(podStakingProvider.future);
    if (stakerData == null) {
      throw Exception("Staker data not available");
    }
    final rewardAddress =
        (await ref.read(podWalletProvider.future)).defaultLockAddress;

    final client = ref.read(podBlockchainClientProvider)!;
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
      client,
      staking,
      clock,
      BlockPackerForStakerSupportRpc(client: client),
      rewardAddress,
    );
    if (isAndroidSafe) {
      await FlutterBackground.enableBackgroundExecution();
    }
    Future<void> Function() cancel = () => Future.value();
    final mainSub = ConcatEagerStream([
      Stream.value(canonicalHead),
      RetryStream(() => client.adoptions)
          .debounceTime(const Duration(milliseconds: 100))
          .asyncMap(client.getBlockHeaderOrRaise)
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
      if (isAndroidSafe) {
        await FlutterBackground.disableBackgroundExecution();
      }
      await cancel();
      await mainSub.cancel();
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
