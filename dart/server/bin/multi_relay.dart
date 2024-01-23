import 'dart:io';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/common/resource.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/config.dart' as conf;
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/common/isolate_pool.dart';
import 'package:fixnum/fixnum.dart';
import 'package:logging/logging.dart';
import 'package:ribs_core/ribs_core.dart';

final timestamp =
    Int64(DateTime.now().add(Duration(seconds: 5)).millisecondsSinceEpoch);

final conf.BlockchainConfig config1 = conf.BlockchainConfig(
    genesis: conf.BlockchainGenesis(
  timestamp: timestamp,
  localStakerIndex: -1,
));

final conf.BlockchainConfig config2 = conf.BlockchainConfig(
    data: conf.BlockchainData(
        dataDir: "${Directory.systemTemp.path}/blockchain2/{genesisId}"),
    genesis: conf.BlockchainGenesis(
      timestamp: timestamp,
      localStakerIndex: -1,
    ),
    rpc: conf.BlockchainRPC(bindPort: 2034),
    p2p: conf.BlockchainP2P(
        bindPort: 2033,
        publicHost: "localhost",
        publicPort: 2033,
        knownPeers: ["localhost:2023"]));

final conf.BlockchainConfig config3 = conf.BlockchainConfig(
    data: conf.BlockchainData(
        dataDir: "${Directory.systemTemp.path}/blockchain3/{genesisId}"),
    genesis: conf.BlockchainGenesis(
      timestamp: timestamp,
      localStakerIndex: -1,
    ),
    rpc: conf.BlockchainRPC(bindPort: 2044),
    p2p: conf.BlockchainP2P(bindPort: 2043, knownPeers: ["localhost:2023"]));

Future<void> main() async {
  initRootLogger();

  final resource = IsolatePool.make()
      .map((p) => p.isolate)
      .tap(setComputeFunction)
      .flatMap((isolate) {
    runChain(conf.BlockchainConfig config) =>
        BlockchainCore.make(config, isolate).flatMap(
          (blockchain) => BlockchainRpc.make(blockchain, config)
              .flatMap((_) => BlockchainP2P.make(blockchain, config)),
        );
    return runChain(config1).flatMap((f) => runChain(config2)
        .flatMap((f1) => runChain(config3).map((f2) => [f, f1, f2])));
  });

  await resource.use((fs) => IO.fromFutureF(
      () => Future.any([ProcessSignal.sigint.watch().first, ...fs])));
}
