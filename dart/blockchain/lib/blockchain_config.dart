class BlockchainConfig {
  String networkBindHost;
  int networkBindPort;
  DateTime genesisTimestamp;
  List<String> initialPeers;

  BlockchainConfig(
    this.networkBindHost,
    this.networkBindPort,
    this.genesisTimestamp,
    this.initialPeers,
  );
}
