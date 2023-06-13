import 'dart:convert';
import 'dart:typed_data';
import 'package:blockchain_common/utils.dart';
import 'package:hashlib/hashlib.dart';
import 'package:rational/rational.dart';

final TestStringArray = utf8.encode("TEST");
final NonceStringArray = utf8.encode("NONCE");

extension RhoOps on Uint8List {
  Uint8List get rhoTestHash => blake2b512.convert(this + TestStringArray).bytes;
  Uint8List get rhoNonceHash =>
      blake2b512.convert(this + NonceStringArray).bytes;
}

extension RatioOps on Rational {
  Uint8List get thresholdEvidence =>
      blake2b256.convert(numerator.bytes + denominator.bytes).bytes;
}
