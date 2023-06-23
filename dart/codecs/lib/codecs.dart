import 'dart:typed_data';

import 'package:blockchain_common/models/unsigned.dart';
import 'package:blockchain_common/utils.dart';
import 'package:blockchain_crypto/utils.dart';
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
  Future<BlockId> get id async =>
      BlockId()..value = Uint8List.fromList(await immutableBytes.hash256);
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
  String get show => this.value.base58;
}

extension TransactionIdCodecs on TransactionId {
  String get show => this.value.base58;
}

extension TransactionCodecs on Transaction {
  List<int> get immutableBytes => inputs.immutableBytes((i) => i.immutableBytes)
    ..addAll(outputs.immutableBytes((o) => o.immutableBytes))
    ..addAll(schedule.immutableBytes);

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

extension TransactionScheduleCodecs on TransactionSchedule {
  List<int> get immutableBytes => <int>[]
    ..addAll(minSlot.toBytes())
    ..addAll(maxSlot.toBytes())
    ..addAll(timestamp.toBytes());
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
  List<int> get immutableBytes {
    if (hasPaymentToken())
      return paymentToken.immutableBytes;
    else if (hasStakingToken())
      return stakingToken.immutableBytes;
    else
      throw ArgumentError("Invalid Value");
  }
}

extension PaymentTokenCodecs on PaymentToken {
  List<int> get immutableBytes => quantity.toBytes();
}

extension StakingTokenCodecs on StakingToken {
  List<int> get immutableBytes {
    final base = quantity.toBytes();
    // TODO if(hasRegistration())
    return base;
  }
}

extension LockAddressCodecs on LockAddress {
  List<int> get immutableBytes => value;

  String get show => this.value.base58;
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
