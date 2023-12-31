import 'dart:io';

import 'package:blockchain/blockchain_view.dart';
import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/clock.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/config.dart';
import 'package:blockchain/consensus/leader_election_validation.dart';
import 'package:blockchain/isolate_pool.dart';
import 'package:blockchain/crypto/ed25519.dart' as ed25519;
import 'package:blockchain/crypto/ed25519vrf.dart' as ed25519VRF;
import 'package:blockchain/crypto/kes.dart' as kes;
import 'package:blockchain/minting/minting.dart';
import 'package:blockchain/rpc/client.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_protobuf/services/node_rpc.pbgrpc.dart';
import 'package:blockchain_protobuf/services/staker_support_rpc.pbgrpc.dart';
import 'package:logging/logging.dart';

final BlockchainConfig config = BlockchainConfig();
Future<void> main() async {
  assert(config.genesis.localStakerIndex != null);
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final _errorSuffix = (record.error != null) ? ": ${record.error}" : "";
    final _stackTraceSuffix =
        (record.stackTrace != null) ? "\n${record.stackTrace}" : "";
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}${_errorSuffix}${_stackTraceSuffix}');
  });

  final log = Logger("BlockchainProducerServer");

  final resource = IsolatePool.make(Platform.numberOfProcessors)
      .map((p) => p.isolate)
      .tap((isolate) {
    ed25519.ed25519 = ed25519.Ed25519Isolated(isolate);
    ed25519VRF.ed25519Vrf = ed25519VRF.Ed25519VRFIsolated(isolate);
    kes.kesProduct = kes.KesProudctIsolated(isolate);
  }).flatMap((isolate) => RpcClient.makeChannel().evalFlatMap((channel) async {
            final rpcClient = NodeRpcClient(channel);
            final viewer = BlockchainViewFromRpc(nodeClient: rpcClient);
            final canonicalHeadId = await viewer.canonicalHeadId;
            final canonicalHeadSlotData =
                await viewer.getSlotDataOrRaise(canonicalHeadId);
            final protocolSettings = await viewer.protocolSettings;

            final genesisBlockId = await viewer.genesisBlockId;
            final genesisHeader =
                await viewer.getBlockHeaderOrRaise(genesisBlockId);
            final stakerSupportClient = StakerSupportRpcClient(channel);
            final clock = ClockImpl(
              protocolSettings.slotDuration,
              protocolSettings.epochLength,
              protocolSettings.operationalPeriodLength,
              genesisHeader.timestamp,
              protocolSettings.forwardBiasedSlotWindow,
            );
            final leaderElection =
                LeaderElectionImpl(protocolSettings, isolate);
            return Minting.makeForRpc(
              Directory(
                  "${Directory.systemTemp.path}/blockchain/${genesisBlockId.show}/stakers/${config.genesis.localStakerIndex}"),
              protocolSettings,
              clock,
              canonicalHeadSlotData,
              viewer.adoptions.map((id) {
                log.info("Remote peer adopted block id=${id.show}");
                return id;
              }).asyncMap(viewer.getSlotDataOrRaise),
              leaderElection,
              rpcClient,
              stakerSupportClient,
            ).flatMap((minting) => Resource.forStreamSubscription(() => minting
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
                  onError: (e) => log.severe("Production failed", e),
                  onDone: () =>
                      log.info("Block production finished unexpectedly"),
                )));
          }));

  await resource.use((_) => ProcessSignal.sigint.watch().first);
}
