import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

class BlockchainConfig {
  final BlockchainData data;
  final BlockchainStaking staking;
  final BlockchainGenesis genesis;
  final BlockchainP2P p2p;
  final BlockchainRPC rpc;

  BlockchainConfig({
    BlockchainData? data,
    BlockchainStaking? staking,
    BlockchainGenesis? genesis,
    BlockchainP2P? p2p,
    BlockchainRPC? rpc,
  })  : data = data ?? BlockchainData(),
        staking = staking ?? BlockchainStaking(),
        genesis = genesis ?? BlockchainGenesis(),
        p2p = p2p ?? BlockchainP2P(),
        rpc = rpc ?? BlockchainRPC();

  static final BlockchainConfig defaultConfig = BlockchainConfig();
}

class BlockchainData {
  final String dataDir;
  BlockchainData({String? dataDir})
      : dataDir = dataDir ?? "/tmp/bifrost/data/{genesisId}";
}

class BlockchainStaking {
  final String stakingDir;

  BlockchainStaking({String? stakingDir})
      : stakingDir = stakingDir ?? "/tmp/bifrost/staking/{genesisId}";
}

class BlockchainGenesis {
  final Int64 timestamp;
  final List<Int64> stakes;
  final int? localStakerIndex;

  BlockchainGenesis({
    Int64? timestamp,
    List<Int64>? stakes,
    int? localStakerIndex,
  })  : timestamp = timestamp ??
            Int64(DateTime.now()
                .add(Duration(seconds: 5))
                .millisecondsSinceEpoch),
        stakes = [Int64(1000000)],
        localStakerIndex = localStakerIndex ?? 0;
}

class BlockchainP2P {
  final String bindHost;
  final int bindPort;
  final String? publicHost;
  final int? publicPort;
  final List<String> knownPeers;
  final Uint8List magicBytes;

  BlockchainP2P({
    String? bindHost,
    int? bindPort,
    this.publicHost,
    this.publicPort,
    List<String>? knownPeers,
    Uint8List? magicBytes,
  })  : bindHost = bindHost ?? "0.0.0.0",
        bindPort = bindPort ?? 2023,
        knownPeers = knownPeers ?? [],
        magicBytes = magicBytes ?? Uint8List(32);
}

class BlockchainRPC {
  final String bindHost;
  final int bindPort;

  BlockchainRPC({String? bindHost, int? bindPort, List<String>? knownPeers})
      : bindHost = bindHost ?? "0.0.0.0",
        bindPort = bindPort ?? 2024;
}
