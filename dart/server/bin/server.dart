import 'dart:io';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/config.dart' as conf;
import 'package:blockchain/isolate_pool.dart';
import 'package:blockchain/crypto/ed25519.dart' as ed25519;
import 'package:blockchain/crypto/ed25519vrf.dart' as ed25519VRF;
import 'package:blockchain/crypto/kes.dart' as kes;
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';

final conf.BlockchainConfig config2 = conf.BlockchainConfig(
    data: conf.BlockchainData(
        dataDir: "${Directory.systemTemp.path}/blockchain2/{genesisId}"),
    genesis: conf.BlockchainGenesis(
      timestamp: Int64(1704142585256),
      // timestamp: null,
      localStakerIndex: -1,
    ),
    rpc: conf.BlockchainRPC(bindPort: 2034),
    p2p: conf.BlockchainP2P(bindPort: 2033, knownPeers: ["localhost:2023"]));

final conf.BlockchainConfig config1 = conf.BlockchainConfig(
    genesis: conf.BlockchainGenesis(
  // timestamp: Int64(1703957370323),
  timestamp: null,
  localStakerIndex: -1,
));

final config = config2;
Future<void> main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    final _errorSuffix = (record.error != null) ? ": ${record.error}" : "";
    final _stackTraceSuffix =
        (record.stackTrace != null) ? "\n${record.stackTrace}" : "";
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}${_errorSuffix}${_stackTraceSuffix}');
  });

  final resource = IsolatePool.make(Platform.numberOfProcessors)
      .map((p) => p.isolate)
      .tap((isolate) {
        ed25519.ed25519 = ed25519.Ed25519Isolated(isolate);
        ed25519VRF.ed25519Vrf = ed25519VRF.Ed25519VRFIsolated(isolate);
        kes.kesProduct = kes.KesProudctIsolated(isolate);
      })
      .flatMap((isolate) => BlockchainCore.make(config, isolate))
      .flatMap((blockchain) => BlockchainRpc.make(blockchain, config)
          .product(BlockchainP2P.make(blockchain, config)))
      .evalTap((_) => ProcessSignal.sigint.watch().first);

  await resource.use((_) async {});
}
