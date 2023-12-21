import 'dart:typed_data';

import 'package:blockchain/common/models/unsigned.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:fpdart/fpdart.dart';

import 'package:fixnum/fixnum.dart';
import 'package:hashlib/hashlib.dart';

extension ListCodec<T> on List<T> {
  List<int> immutableBytes(List<int> Function(T) encodeT) {
    final result = <int>[]..addAll(Int32(length).toBytes());
    for (final t in this) result.addAll(encodeT(t));
    return result;
  }
}

extension BlockHeaderCodecs on BlockHeader {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentHeaderId.value)
    ..addAll(parentSlot.toBytes())
    ..addAll(txRoot)
    ..addAll(bloomFilter)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(eligibilityCertificate.immutableBytes)
    ..addAll(operationalCertificate.immutableBytes)
    ..addAll(metadata)
    ..addAll(address.value);
  BlockId get id =>
      BlockId()..value = Uint8List.fromList(immutableBytes.hash256);
}

BlockId decodeBlockId(String input) {
  if (input.startsWith("b_")) return decodeBlockId(input.substring(2));
  final decoded = Base58Decode(input);
  assert(decoded.length == 32);
  final blockId = BlockId()..value = decoded;
  return blockId;
}

extension UnsignedBlockHeaderCodecs on UnsignedBlockHeader {
  List<int> get signableBytes => <int>[]
    ..addAll(parentHeaderId.value)
    ..addAll(parentSlot.toBytes())
    ..addAll(txRoot)
    ..addAll(bloomFilter)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(eligibilityCertificate.immutableBytes)
    ..addAll(partialOperationalCertificate.immutableBytes)
    ..addAll(metadata)
    ..addAll(address.value);
}

extension EligibilityCertificateCodecs on EligibilityCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(vrfSig)
    ..addAll(vrfVK)
    ..addAll(thresholdEvidence)
    ..addAll(eta);
}

extension PartialOperationalCertificateCodecs on PartialOperationalCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentVK.immutableBytes)
    ..addAll(parentSignature.immutableBytes)
    ..addAll(childVK);
}

extension OperationalCertificateCodecs on OperationalCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentVK.immutableBytes)
    ..addAll(parentSignature.immutableBytes)
    ..addAll(childVK)
    ..addAll(childSignature);
}

extension VerificationKeyKesProductCodecs on VerificationKeyKesProduct {
  List<int> get immutableBytes => <int>[]
    ..addAll(value)
    ..addAll(step.immutableBytes);
}

extension IterableCodecs<T> on Iterable<T> {
  List<int> immutableBytes(List<int> Function(T) encodeItem) => <int>[]
    ..addAll(length.immutableBytes)
    ..addAll(flatMap((t) => encodeItem(t)));
}

extension SignatureKesSumCodecs on SignatureKesSum {
  List<int> get immutableBytes => <int>[]
    ..addAll(verificationKey)
    ..addAll(signature)
    ..addAll(witness.immutableBytes((t) => t));
}

extension SignatureKesProductCodecs on SignatureKesProduct {
  List<int> get immutableBytes => <int>[]
    ..addAll(superSignature.immutableBytes)
    ..addAll(subSignature.immutableBytes)
    ..addAll(subRoot);
}

extension IntCodecs on int {
  List<int> get immutableBytes => BigInt.from(this).bytes;
}

extension Int64Codecs on Int64 {
  Uint8List get immutableBytes => toBigInt.bytes;
}

extension Int128Codecs on List<int> {
  String get base58 => Base58Encode(Uint8List.fromList(this));
  String get show => base58;
}

extension BlockIdCodecs on BlockId {
  String get show => "b_${this.value.base58}";
}

extension TransactionIdCodecs on TransactionId {
  String get show => "t_${this.value.base58}";
}

TransactionId decodeTransactionId(String input) {
  if (input.startsWith("t_")) return decodeTransactionId(input.substring(2));
  final decoded = Base58Decode(input);
  assert(decoded.length == 32);
  return TransactionId()..value = decoded;
}

extension TransactionCodecs on Transaction {
  List<int> get immutableBytes => inputs.immutableBytes((i) => i.immutableBytes)
    ..addAll(outputs.immutableBytes((o) => o.immutableBytes));

  TransactionId get id =>
      TransactionId()..value = blake2b256.convert(immutableBytes).bytes;
}

extension TransactionInputCodecs on TransactionInput {
  List<int> get immutableBytes => <int>[]
    ..addAll(lock.immutableBytes)
    ..addAll(key.immutableBytes)
    ..addAll(value.immutableBytes);
}

extension TransactionOutputCodecs on TransactionOutput {
  List<int> get immutableBytes => <int>[]
    ..addAll(lockAddress.immutableBytes)
    ..addAll(value.immutableBytes);
}

extension KeyCodecs on Key {
  List<int> get immutableBytes {
    if (hasEd25519())
      return ed25519.signature;
    else
      throw ArgumentError("Invalid Key");
  }
}

extension ValueCodecs on Value {
  // TODO registration
  List<int> get immutableBytes => <int>[]..addAll(quantity.immutableBytes);
}

extension LockAddressCodecs on LockAddress {
  List<int> get immutableBytes => value;

  String get show => "a_${this.value.base58}";
}

LockAddress decodeLockAddress(String input) {
  if (input.startsWith("a_")) return decodeLockAddress(input.substring(2));
  final decoded = Base58Decode(input);
  assert(decoded.length == 32);
  final lockAddress = LockAddress()..value = decoded;
  return lockAddress;
}

extension LockCodecs on Lock {
  List<int> get immutableBytes {
    if (hasEd25519())
      return ed25519.immutableBytes;
    else
      throw ArgumentError("Invalid Lock");
  }

  LockAddress get address =>
      LockAddress()..value = blake2b256.convert(immutableBytes).bytes;
}

extension Lock_Ed25519Codecs on Lock_Ed25519 {
  List<int> get immutableBytes => vk;
}
