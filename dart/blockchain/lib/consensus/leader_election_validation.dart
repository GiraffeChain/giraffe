import 'dart:math';
import 'dart:typed_data';

import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/consensus/models/protocol_settings.dart';
import 'package:blockchain/consensus/numeric_utils.dart';
import 'package:blockchain/consensus/utils.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:quiver/cache.dart';
import 'package:rational/rational.dart';
import 'package:fixnum/fixnum.dart';

abstract class LeaderElection {
  Future<Rational> getThreshold(Rational relativeStake, Int64 slotDiff);
  Future<bool> isEligible(Rational threshold, Rho rho);
}

class LeaderElectionImpl extends LeaderElection {
  final ProtocolSettings protocolSettings;
  DComputeImpl _compute;

  LeaderElectionImpl(this.protocolSettings, this._compute);

  @override
  Future<Rational> getThreshold(Rational relativeStake, Int64 slotDiff) =>
      _compute((t) => _getThreshold(t.$1.$1, t.$1.$2, t.$2),
          ((relativeStake, slotDiff), protocolSettings));

  @override
  Future<bool> isEligible(Rational threshold, Rho rho) =>
      _compute((t) => _isSlotLeaderForThreshold(t.$1, t.$2), (threshold, rho));
}

final NormalizationConstant = BigInt.from(2).pow(512);

final _thresholdCache =
    MapCache<(Rational, Int64), Rational>.lru(maximumSize: 1024);

Future<Rational> _getThreshold(Rational relativeStake, Int64 slotDiff,
    ProtocolSettings protocolSettings) async {
  final cacheKey = (
    relativeStake,
    Int64(min(protocolSettings.vrfLddCutoff + 1, slotDiff.toInt()))
  );
  return (await _thresholdCache.get(cacheKey, ifAbsent: (_) {
    final difficultyCurve = (slotDiff > protocolSettings.vrfLddCutoff)
        ? protocolSettings.vrfBaselineDifficulty
        : (Rational(
                slotDiff.toBigInt, BigInt.from(protocolSettings.vrfLddCutoff)) *
            protocolSettings.vrfAmpltitude);

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
  final test = Rational(numerator, NormalizationConstant);
  return threshold > test;
}
