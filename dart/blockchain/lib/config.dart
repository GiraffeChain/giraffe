import 'package:blockchain/common/utils.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rational/rational.dart';

class BlockchainConfig {
  final BlockchainGenesis genesis;
  final BlockchainConsensus consensus;
  final BlockchainP2P p2p;

  BlockchainConfig(
      {BlockchainGenesis? genesis,
      BlockchainConsensus? consensus,
      BlockchainP2P? p2p})
      : genesis = genesis ?? BlockchainGenesis(),
        consensus = consensus ?? BlockchainConsensus(),
        p2p = p2p ?? BlockchainP2P();

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

class BlockchainConsensus {
  final Rational fEffective;
  final int vrfLddCutoff;
  final int vrfPrecision;
  final Rational vrfBaselineDifficulty;
  final Rational vrfAmpltitude;
  final Int64 chainSelectionKLookback;
  final Duration slotDuration;
  final Int64 forwardBiastedSlotWindow;
  final Int64 operationalPeriodsPerEpoch;
  final int kesKeyHours;
  final int kesKeyMinutes;

  BlockchainConsensus({
    Rational? fEffective,
    int? vrfLddCutoff,
    int? vrfPrecision,
    Rational? vrfBaselineDifficulty,
    Rational? vrfAmpltitude,
    Int64? chainSelectionKLookback,
    Duration? slotDuration,
    Int64? forwardBiastedSlotWindow,
    Int64? operationalPeriodsPerEpoch,
    int? kesKeyHours,
    int? kesKeyMinutes,
  })  : fEffective = fEffective ?? Rational.fromInt(15, 100),
        vrfLddCutoff = vrfLddCutoff ?? 50,
        vrfPrecision = vrfPrecision ?? 40,
        vrfBaselineDifficulty =
            vrfBaselineDifficulty ?? Rational.fromInt(1, 20),
        vrfAmpltitude = vrfAmpltitude ?? Rational.fromInt(1, 2),
        chainSelectionKLookback = chainSelectionKLookback ?? Int64(50),
        slotDuration = slotDuration ?? Duration(milliseconds: 1000),
        forwardBiastedSlotWindow = forwardBiastedSlotWindow ?? Int64(50),
        operationalPeriodsPerEpoch = operationalPeriodsPerEpoch ?? Int64(2),
        kesKeyHours = kesKeyHours ?? 4,
        kesKeyMinutes = kesKeyMinutes ?? 4;

  int get chainSelectionSWindow =>
      (Rational(chainSelectionKLookback.toBigInt, BigInt.from(4)) *
              fEffective.inverse)
          .round()
          .toInt();

  Int64 get epochLength => chainSelectionKLookback * 6;

  Int64 get operationalPeriodLength =>
      epochLength ~/ operationalPeriodsPerEpoch;
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
