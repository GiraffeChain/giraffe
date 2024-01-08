import 'dart:io';

import 'package:blockchain/blockchain.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/config.dart' as conf;
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/isolate_pool.dart';
import 'package:fixnum/fixnum.dart';

final timestamp = null;
// final timestamp = Int64(0);
final stakes = [Int64(20000), Int64(10000)];

final conf.BlockchainConfig config1 = conf.BlockchainConfig(
    genesis: conf.BlockchainGenesis(
  timestamp: timestamp,
  stakes: stakes,
  localStakerIndex: -1,
));

final conf.BlockchainConfig config2 = conf.BlockchainConfig(
    data: conf.BlockchainData(
        dataDir: "${Directory.systemTemp.path}/blockchain2/{genesisId}"),
    genesis: conf.BlockchainGenesis(
      timestamp: timestamp,
      stakes: stakes,
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
      stakes: stakes,
      localStakerIndex: -1,
    ),
    rpc: conf.BlockchainRPC(bindPort: 2044),
    p2p: conf.BlockchainP2P(bindPort: 2043, knownPeers: ["localhost:2023"]));

final config = config1;
Future<void> main() async {
  initRootLogger();
  final resource = IsolatePool.make()
      .map((p) => p.isolate)
      .tap(setComputeFunction)
      .flatMap((isolate) => BlockchainCore.make(config, isolate))
      .flatMap(
        (blockchain) => BlockchainRpc.make(blockchain, config)
            .productR(BlockchainP2P.make(blockchain, config)),
      );

  await resource.use((f) => f.race(ProcessSignal.sigint.watch().first));
}
