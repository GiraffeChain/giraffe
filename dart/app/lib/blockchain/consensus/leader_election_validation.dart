import 'dart:math';
import 'dart:typed_data';

import '../common/models/common.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'numeric_utils.dart';
import 'utils.dart';
import 'package:quiver/cache.dart';
import 'package:rational/rational.dart';
import 'package:fixnum/fixnum.dart';

abstract class LeaderElection {
  Future<Rational> getThreshold(Rational relativeStake, Int64 slotDiff);
  Future<bool> isEligible(Rational threshold, Rho rho);
}

class LeaderElectionImpl extends LeaderElection {
  final ProtocolSettings protocolSettings;
  final DComputeImpl _compute;

  LeaderElectionImpl(this.protocolSettings, this._compute);

  @override
  Future<Rational> getThreshold(Rational relativeStake, Int64 slotDiff) =>
      _compute((t) => _getThreshold(t.$1.$1, t.$1.$2, t.$2),
          ((relativeStake, slotDiff), protocolSettings));

  @override
  Future<bool> isEligible(Rational threshold, Rho rho) =>
      _compute((t) => _isSlotLeaderForThreshold(t.$1, t.$2), (threshold, rho));
}

final _normalizationConstant = BigInt.from(2).pow(512);

final _thresholdCache =
    MapCache<(Rational, Int64), Rational>.lru(maximumSize: 1024);

Future<Rational> _getThreshold(Rational relativeStake, Int64 slotDiffIn,
    ProtocolSettings protocolSettings) async {
  if (slotDiffIn <= protocolSettings.vrfSlotGap) {
    return Rational.zero;
  }
  final slotDiff = Int64(max(
      0,
      min(protocolSettings.vrfLddCutoff + 1,
          slotDiffIn.toInt() - protocolSettings.vrfSlotGap)));
  final cacheKey = (relativeStake, slotDiff);
  return (await _thresholdCache.get(cacheKey, ifAbsent: (_) {
    final difficultyCurve = (slotDiff > protocolSettings.vrfLddCutoff)
        ? protocolSettings.vrfBaselineDifficulty
        : (Rational(
                slotDiff.toBigInt, BigInt.from(protocolSettings.vrfLddCutoff)) *
            protocolSettings.vrfAmplitude);

    if (difficultyCurve == Rational.one) {
      return difficultyCurve;
    } else {
      final coefficient = log1p(Rational.fromInt(-1) * difficultyCurve);
      final expResult = exp(coefficient * relativeStake);
      final result = Rational.one - expResult;
      return result;
    }
  }))!;
}

Future<bool> _isSlotLeaderForThreshold(Rational threshold, Rho rho) async {
  final testRhoHashBytes = rho.rhoTestHash;
  final numeratorBytes = Int8List(65)
    ..[0] = 0x00
    ..setRange(1, testRhoHashBytes.length + 1, testRhoHashBytes);
  final numerator = numeratorBytes.toBigInt;
  final test = Rational(numerator, _normalizationConstant);
  return threshold > test;
}
