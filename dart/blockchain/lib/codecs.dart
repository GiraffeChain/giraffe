import 'dart:typed_data';

import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';

import 'common/models/unsigned.dart';

extension BlockHeaderCodecs on BlockHeader {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentHeaderId.immutableBytes)
    ..addAll(parentSlot.immutableBytes)
    ..addAll(txRoot.decodeBase58)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(eligibilityCertificate.immutableBytes)
    ..addAll(operationalCertificate.immutableBytes)
    ..addAll(metadata.utf8Bytes)
    ..addAll(account.immutableBytes);

  BlockId get id => hasHeaderId() ? headerId : computeId;

  BlockId get computeId => BlockId()..value = immutableBytes.hash256.base58;

  void embedId() => headerId = computeId;

  bool get containsValidId => headerId == computeId;
}

extension UnsignedBlockHeaderCodecs on UnsignedBlockHeader {
  List<int> get signableBytes => <int>[]
    ..addAll(parentHeaderId.immutableBytes)
    ..addAll(parentSlot.immutableBytes)
    ..addAll(txRoot.decodeBase58)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(eligibilityCertificate.immutableBytes)
    ..addAll(partialOperationalCertificate.immutableBytes)
    ..addAll(metadata.utf8Bytes)
    ..addAll(account.immutableBytes);
}

extension EligibilityCertificateCodecs on EligibilityCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(vrfSig.decodeBase58)
    ..addAll(vrfVK.decodeBase58)
    ..addAll(thresholdEvidence.decodeBase58)
    ..addAll(eta.decodeBase58);
}

extension PartialOperationalCertificateCodecs on PartialOperationalCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentVK.immutableBytes)
    ..addAll(parentSignature.immutableBytes)
    ..addAll(childVK.decodeBase58);
}

extension OperationalCertificateCodecs on OperationalCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentVK.immutableBytes)
    ..addAll(parentSignature.immutableBytes)
    ..addAll(childVK.decodeBase58)
    ..addAll(childSignature.decodeBase58);
}

extension VerificationKeyKesProductCodecs on VerificationKeyKesProduct {
  List<int> get immutableBytes => <int>[]
    ..addAll(value.decodeBase58)
    ..addAll(step.immutableBytes);
}

class PersistenceCodecs {
  static Uint8List encodeHeightBlockId((Int64, BlockId) heightBlockTuple) =>
      Uint8List.fromList(<int>[]
        ..addAll(heightBlockTuple.$1.toBytesBigEndian())
        ..addAll(heightBlockTuple.$2.value.decodeBase58));
  static (Int64, BlockId) decodeHeightBlockId(Uint8List bytes) => (
        Int64.fromBytesBigEndian(bytes.sublist(0, 8)),
        BlockId(value: bytes.sublist(8).base58)
      );

  static Uint8List encodeBlockId(BlockId blockId) =>
      Uint8List.fromList(blockId.value.decodeBase58);
  static BlockId decodeBlockId(Uint8List bytes) => BlockId(value: bytes.base58);

  static Uint8List encodeTransactionId(TransactionId transactionId) =>
      Uint8List.fromList(transactionId.value.decodeBase58);
  static TransactionId decodeTransactionId(Uint8List bytes) =>
      TransactionId(value: bytes.base58);
}

class Codec<T> {
  final List<int> Function(T) encode;
  final T Function(List<int>) decode;

  Codec(this.encode, this.decode);
}

class P2PCodecs {
  static final int64Codec =
      Codec<Int64>((v) => v.toBytesBigEndian(), Int64.fromBytesBigEndian);
  static final blockIdCodec = Codec<BlockId>(
      (v) => v.value.decodeBase58, (v) => BlockId(value: v.base58));

  static final blockIdOptCodec = optCodec<BlockId>(blockIdCodec);
  static final transactionIdCodec = Codec<TransactionId>(
      (v) => v.value.decodeBase58, (v) => TransactionId(value: v.base58));

  static final headerCodec =
      Codec<BlockHeader>((v) => v.writeToBuffer(), BlockHeader.fromBuffer);

  static final headerOptCodec = optCodec<BlockHeader>(headerCodec);

  static final bodyCodec =
      Codec<BlockBody>((v) => v.writeToBuffer(), BlockBody.fromBuffer);

  static final bodyOptCodec = optCodec<BlockBody>(bodyCodec);

  static final transactionCodec =
      Codec<Transaction>((v) => v.writeToBuffer(), Transaction.fromBuffer);

  static final transactionOptCodec = optCodec<Transaction>(transactionCodec);

  static final publicP2PStateCodec = Codec<PublicP2PState>(
      (v) => v.writeToBuffer(), PublicP2PState.fromBuffer);

  static Codec<T?> optCodec<T>(Codec<T> baseCodec) => Codec<T?>(
      (v) => (v == null) ? [...arr0] : [...arr1, ...baseCodec.encode(v)],
      (bytes) => (bytes[0] == 0) ? null : baseCodec.decode(bytes.sublist(1)));
}
