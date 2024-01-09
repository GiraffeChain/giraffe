import 'package:blockchain/crypto/impl/kes_product.dart';
import 'package:fixnum/fixnum.dart';
import 'package:rational/rational.dart';

class ProtocolSettings {
  final Rational fEffective;
  final int vrfLddCutoff;
  final int vrfPrecision;
  final Rational vrfBaselineDifficulty;
  final Rational vrfAmpltitude;
  final int chainSelectionKLookback;
  final Duration slotDuration;
  final int operationalPeriodsPerEpoch;
  final int kesKeyHours;
  final int kesKeyMinutes;

  ProtocolSettings(
      {required this.fEffective,
      required this.vrfLddCutoff,
      required this.vrfPrecision,
      required this.vrfBaselineDifficulty,
      required this.vrfAmpltitude,
      required this.chainSelectionKLookback,
      required this.slotDuration,
      required this.operationalPeriodsPerEpoch,
      required this.kesKeyHours,
      required this.kesKeyMinutes});

  factory ProtocolSettings.fromMap(Map<String, String> map) => ProtocolSettings(
      fEffective: _parseRational(map["f-effective"]!),
      vrfLddCutoff: int.parse(map["vrf-ldd-cutoff"]!),
      vrfPrecision: int.parse(map["vrf-precision"]!),
      vrfBaselineDifficulty: _parseRational(map["vrf-baseline-difficulty"]!),
      vrfAmpltitude: _parseRational(map["vrf-amplitude"]!),
      chainSelectionKLookback: int.parse(map["chain-selection-k-lookback"]!),
      slotDuration: Duration(milliseconds: int.parse(map["slot-duration-ms"]!)),
      operationalPeriodsPerEpoch:
          int.parse(map["operational-periods-per-epoch"]!),
      kesKeyHours: int.parse(map["kes-key-hours"]!),
      kesKeyMinutes: int.parse(map["kes-key-minutes"]!));

  ProtocolSettings mergeFromMap(Map<String, String> map) => ProtocolSettings(
        fEffective: map.containsKey("f-effective")
            ? _parseRational(map["f-effective"]!)
            : fEffective,
        vrfLddCutoff: map.containsKey("vrf-ldd-cutoff")
            ? int.parse(map["vrf-ldd-cutoff"]!)
            : vrfLddCutoff,
        vrfPrecision: map.containsKey("vrf-precision")
            ? int.parse(map["vrf-precision"]!)
            : vrfPrecision,
        vrfBaselineDifficulty: map.containsKey("vrf-baseline-difficulty")
            ? _parseRational(map["vrf-baseline-difficulty"]!)
            : vrfBaselineDifficulty,
        vrfAmpltitude: map.containsKey("vrf-amplitude")
            ? _parseRational(map["vrf-amplitude"]!)
            : vrfAmpltitude,
        chainSelectionKLookback: map.containsKey("chain-selection-k-lookback")
            ? int.parse(map["chain-selection-k-lookback"]!)
            : chainSelectionKLookback,
        slotDuration: map.containsKey("slot-duration-ms")
            ? Duration(milliseconds: int.parse(map["slot-duration-ms"]!))
            : slotDuration,
        operationalPeriodsPerEpoch:
            map.containsKey("operational-periods-per-epoch")
                ? int.parse(map["operational-periods-per-epoch"]!)
                : operationalPeriodsPerEpoch,
        kesKeyHours: map.containsKey("kes-key-hours")
            ? int.parse(map["kes-key-hours"]!)
            : kesKeyHours,
        kesKeyMinutes: map.containsKey("kes-key-minutes")
            ? int.parse(map["kes-key-minutes"]!)
            : kesKeyMinutes,
      );

  static const defaultAsMap = {
    "f-effective": "3/25",
    "vrf-ldd-cutoff": "15",
    "vrf-precision": "40",
    "vrf-baseline-difficulty": "1/20",
    "vrf-amplitude": "1/2",
    "chain-selection-k-lookback": "81", // 5184
    "slot-duration-ms": "1000",
    "forward-biased-slot-window": "50",
    "operational-periods-per-epoch": "25",
    "kes-key-hours": "9",
    "kes-key-minutes": "9"
  };

  @override
  String toString() =>
      "ProtocolSettings(fEffective=$fEffective, vrfLddCutoff=$vrfLddCutoff, vrfPrecision=$vrfPrecision, vrfBaselineDifficulty=$vrfBaselineDifficulty, vrfAmplitude=$vrfAmpltitude, kLookback=$chainSelectionKLookback, slotDuration=${slotDuration.inMilliseconds}ms, operationalPeriodsPerEpoch=$operationalPeriodsPerEpoch, kesHeight=(${kesKeyHours}, ${kesKeyMinutes}), operationalPeriodLength=$operationalPeriodLength, epochLength=$epochLength)";

  static final ProtocolSettings defaultSettings =
      ProtocolSettings.fromMap(defaultAsMap);

  int get chainSelectionSWindow =>
      (Rational(BigInt.from(chainSelectionKLookback), BigInt.from(4)) *
              fEffective.inverse)
          .round()
          .toInt();

  Int64 get epochLength =>
      Int64((Rational(BigInt.from(chainSelectionKLookback)) *
              fEffective.inverse *
              Rational(BigInt.from(3)))
          .round()
          .toInt());

  Int64 get operationalPeriodLength =>
      epochLength ~/ operationalPeriodsPerEpoch;

  TreeHeight get kesTreeHeight => TreeHeight(kesKeyHours, kesKeyMinutes);
}

_parseRational(String value) {
  final split = value.split("/");
  if (split.length == 1)
    return Rational(BigInt.parse(split[0]));
  else
    return Rational(BigInt.parse(split[0]), BigInt.parse(split[1]));
}
