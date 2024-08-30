import 'dart:convert';
import 'dart:typed_data';
import '../common/models/common.dart';
import 'package:blockchain_sdk/sdk.dart';
import '../crypto/ed25519vrf.dart';
import 'package:hashlib/hashlib.dart';
import 'package:rational/rational.dart';

final _testStringArray = utf8.encode("TEST");
final _nonceStringArray = utf8.encode("NONCE");

extension RhoOps on Rho {
  Uint8List get rhoTestHash =>
      blake2b512.convert(this + _testStringArray).bytes;
  Uint8List get rhoNonceHash =>
      blake2b512.convert(this + _nonceStringArray).bytes;
}

extension RatioOps on Rational {
  Uint8List get thresholdEvidence => blake2b256
      .convert(
          numerator.toString().utf8Bytes + denominator.toString().utf8Bytes)
      .bytes;
}

extension BlockHeaderOps on BlockHeader {
  Future<Uint8List> get rho =>
      ed25519Vrf.proofToHash(stakerCertificate.vrfSignature.decodeBase58);
}
