import 'package:fixnum/fixnum.dart';

class BlockchainConfig {
  final BlockchainGenesis genesis;
  final BlockchainP2P p2p;
  final BlockchainRPC rpc;

  BlockchainConfig({
    BlockchainGenesis? genesis,
    BlockchainP2P? p2p,
    BlockchainRPC? rpc,
  })  : genesis = genesis ?? BlockchainGenesis(),
        p2p = p2p ?? BlockchainP2P(),
        rpc = rpc ?? BlockchainRPC();

  static final BlockchainConfig defaultConfig = BlockchainConfig();
}

class BlockchainGenesis {
  final Int64 timestamp;
  final int stakerCount;
  final List<Int64> stakes;
  final int? localStakerIndex;

  BlockchainGenesis({
    Int64? timestamp,
    int? stakerCount,
    List<Int64>? stakes,
    int? localStakerIndex,
  })  : timestamp = timestamp ??
            Int64(DateTime.now()
                .add(Duration(seconds: 5))
                .millisecondsSinceEpoch),
        stakerCount = stakerCount ?? 1,
        stakes = stakes ??
            List.generate(stakerCount ?? 1,
                (idx) => Int64(1000000 ~/ (stakerCount ?? 1))),
        localStakerIndex = localStakerIndex ?? 0;
}

class BlockchainP2P {
  final String bindHost;
  final int bindPort;
  final List<String> knownPeers;

  BlockchainP2P({String? bindHost, int? bindPort, List<String>? knownPeers})
      : bindHost = bindHost ?? "0.0.0.0",
        bindPort = bindPort ?? 2023,
        knownPeers = knownPeers ?? [];
}

class BlockchainRPC {
  final String bindHost;
  final int bindPort;

  BlockchainRPC({String? bindHost, int? bindPort, List<String>? knownPeers})
      : bindHost = bindHost ?? "0.0.0.0",
        bindPort = bindPort ?? 2024;
}
