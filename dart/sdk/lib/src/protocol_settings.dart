import 'package:fixnum/fixnum.dart';
import 'package:rational/rational.dart';

class ProtocolSettings {
  final Rational fEffective;
  final int vrfPrecision;
  final Rational vrfAmplitude;
  final int chainSelectionKLookback;
  final Duration slotDuration;

  ProtocolSettings({
    required this.fEffective,
    required this.vrfPrecision,
    required this.vrfAmplitude,
    required this.chainSelectionKLookback,
    required this.slotDuration,
  });

  factory ProtocolSettings.fromMap(Map<String, String> map) => ProtocolSettings(
        fEffective: _parseRational(map["f-effective"]!),
        vrfPrecision: int.parse(map["vrf-precision"]!),
        vrfAmplitude: _parseRational(map["vrf-amplitude"]!),
        chainSelectionKLookback: int.parse(map["chain-selection-k-lookback"]!),
        slotDuration:
            Duration(milliseconds: int.parse(map["slot-duration-ms"]!)),
      );

  ProtocolSettings mergeFromMap(Map<String, String> map) => ProtocolSettings(
        fEffective: map.containsKey("f-effective")
            ? _parseRational(map["f-effective"]!)
            : fEffective,
        vrfPrecision: map.containsKey("vrf-precision")
            ? int.parse(map["vrf-precision"]!)
            : vrfPrecision,
        vrfAmplitude: map.containsKey("vrf-amplitude")
            ? _parseRational(map["vrf-amplitude"]!)
            : vrfAmplitude,
        chainSelectionKLookback: map.containsKey("chain-selection-k-lookback")
            ? int.parse(map["chain-selection-k-lookback"]!)
            : chainSelectionKLookback,
        slotDuration: map.containsKey("slot-duration-ms")
            ? Duration(milliseconds: int.parse(map["slot-duration-ms"]!))
            : slotDuration,
      );

  static const defaultAsMap = {
    "f-effective": "3/25",
    "vrf-precision": "40",
    "vrf-amplitude": "6/15",
    "chain-selection-k-lookback": "576",
    "slot-duration-ms": "1000",
  };

  @override
  String toString() =>
      "ProtocolSettings(fEffective=$fEffective, vrfPrecision=$vrfPrecision, vrfAmplitude=$vrfAmplitude, kLookback=$chainSelectionKLookback slotDuration=${slotDuration.inMilliseconds}ms, epochLength=$epochLength)";

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
}

_parseRational(String value) {
  final split = value.split("/");
  if (split.length == 1)
    return Rational(BigInt.parse(split[0]));
  else
    return Rational(BigInt.parse(split[0]), BigInt.parse(split[1]));
}
