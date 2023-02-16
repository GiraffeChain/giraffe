class BlockchainConfig {
  final String networkBindHost;
  final int networkBindPort;
  final DateTime genesisTimestamp;

  BlockchainConfig(
      this.networkBindHost, this.networkBindPort, this.genesisTimestamp);
}
