import 'dart:convert';
import 'dart:typed_data';
import 'package:blockchain_codecs/codecs.dart';
import 'package:blockchain_common/models/common.dart';
import 'package:blockchain_common/utils.dart';
import 'package:blockchain_crypto/ed25519vrf.dart';
import 'package:hashlib/hashlib.dart';
import 'package:rational/rational.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';

final TestStringArray = utf8.encode("TEST");
final NonceStringArray = utf8.encode("NONCE");

extension RhoOps on Rho {
  Uint8List get rhoTestHash => blake2b512.convert(this + TestStringArray).bytes;
  Uint8List get rhoNonceHash =>
      blake2b512.convert(this + NonceStringArray).bytes;
}

extension RatioOps on Rational {
  Uint8List get thresholdEvidence =>
      blake2b256.convert(numerator.bytes + denominator.bytes).bytes;
}

extension BlockHeaderOps on BlockHeader {
  Future<SlotData> get slotData async => SlotData(
        slotId: SlotId(blockId: await id, slot: slot),
        parentSlotId: SlotId(blockId: parentHeaderId, slot: parentSlot),
        rho: await ed25519Vrf.proofToHash(eligibilityCertificate.vrfSig),
        eta: eligibilityCertificate.eta,
        height: height,
      );
}
