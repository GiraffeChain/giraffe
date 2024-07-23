import 'dart:async';
import 'dart:io';

import 'package:blockchain/codecs.dart';
import 'package:blockchain_sdk/sdk.dart' hide setComputeFunction;
import 'package:blockchain/blockchain.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/data_stores.dart';
import 'package:blockchain/common/isolate_pool.dart';
import 'package:blockchain/minting/minting.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:logging/logging.dart';
import 'package:ribs_effect/ribs_effect.dart';

final BlockchainConfig config = BlockchainConfig(
    staking: BlockchainStaking(
        stakingDir:
            "${Directory.systemTemp.path}/blockchain-genesis/{genesisId}/stakers/0"));
Future<void> main() async {
  initRootLogger();

  final log = Logger("BlockProducerServer");

  final Resource<StreamSubscription> resource = IsolatePool.make()
      .map((p) => p.isolate)
      .tap(setComputeFunction)
      .flatMap((isolate) =>
          RpcClient.makeChannel(port: 2024).evalFlatMap((channel) async {
            final rpcClient = NodeRpcClient(channel);
            final viewer = BlockchainViewFromRpc(nodeClient: rpcClient);
            final canonicalHeadId = await viewer.canonicalHeadId;
            final canonicalHead =
                await viewer.getBlockHeaderOrRaise(canonicalHeadId);
            log.info(
                "Canonical head id=${canonicalHeadId.show} height=${canonicalHead.height} slot=${canonicalHead.slot}");
            final protocolSettings = await viewer.protocolSettings;

            final genesisBlockId = await viewer.genesisBlockId;
            final genesisHeader =
                await viewer.getBlockHeaderOrRaise(genesisBlockId);
            log.info(
                "Genesis id=${genesisBlockId.show} height=${genesisHeader.height} slot=${genesisHeader.slot}");
            final stakerSupportClient = StakerSupportRpcClient(channel);
            final clock = ClockImpl(
              protocolSettings.slotDuration,
              protocolSettings.epochLength,
              protocolSettings.operationalPeriodLength,
              genesisHeader.timestamp,
            );
            final leaderElection =
                LeaderElectionImpl(protocolSettings, isolate);
            return Minting.makeForRpc(
              Directory(DataStores.interpolateBlockId(
                  config.staking.stakingDir, genesisBlockId)),
              protocolSettings,
              clock,
              canonicalHead,
              viewer.adoptions.map((id) {
                log.info("Remote peer adopted block id=${id.show}");
                return id;
              }).asyncMap(viewer.getBlockHeaderOrRaise),
              leaderElection,
              viewer,
              stakerSupportClient,
              config.staking.rewardAddress,
            ).flatMap((minting) => ResourceUtils.forStreamSubscription(() =>
                minting
                    .blockProducer.blocks
                    .asyncMap((block) => stakerSupportClient
                        .broadcastBlock(BroadcastBlockReq(
                            block: Block(
                                header: block.header,
                                body: BlockBody(
                                    transactionIds: block.fullBody.transactions
                                        .map((t) => t.id)))))
                        .then((_) => block))
                    .listen(
                      (block) => log.info(
                          "Successfully broadcasted block id=${block.header.id.show}"),
                      onError: (e, s) => log.severe("Production failed", e, s),
                      onDone: () =>
                          log.info("Block production finished unexpectedly"),
                    )));
          }));

  await resource
      .use((subscription) => IO.fromFutureF(() => Future.any(
              [subscription.asFuture(), ProcessSignal.sigint.watch().first])
          .onError<Object>((e, s) => log.warning("Production failed", e, s))))
      .unsafeRunFuture();
}
