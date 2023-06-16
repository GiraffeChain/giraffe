import 'dart:typed_data';

import 'package:blockchain_common/models/unsigned.dart';
import 'package:blockchain_common/utils.dart';
import 'package:blockchain_crypto/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:fpdart/fpdart.dart';

import 'package:fixnum/fixnum.dart';

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
      BlockId(value: Uint8List.fromList(await immutableBytes.hash256));
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
  Uint8List get immutableBytes {
    throw UnimplementedError();
  }

  TransactionId get id {
    throw UnimplementedError();
  }
}

extension LockCodecs on Lock {
  Uint8List get immutableBytes {
    throw UnimplementedError();
  }

  TransactionId get address {
    throw UnimplementedError();
  }
}
