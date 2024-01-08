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
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(eligibilityCertificate.immutableBytes)
    ..addAll(operationalCertificate.immutableBytes)
    ..addAll(metadata)
    ..addAll(address.value);

  BlockId get id => hasHeaderId() ? headerId : computeId;

  BlockId get computeId =>
      BlockId()..value = Uint8List.fromList(immutableBytes.hash256);

  void embedId() => headerId = computeId;

  bool get containsValidId => headerId == computeId;
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
  List<int> get immutableBytes => List.from(value);
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

  List<int> get signableBytes =>
      <int>[]..addAll(inputs.immutableBytes((i) => i.immutableBytes)
        ..addAll(outputs.immutableBytes((o) => o.immutableBytes)));

  TransactionId get id => hasTransactionId() ? transactionId : computeId;

  TransactionId get computeId =>
      TransactionId()..value = blake2b256.convert(immutableBytes).bytes;

  void embedId() => transactionId = computeId;

  bool get containsValidId => transactionId == computeId;
}

extension TransactionOutputReferenceCodecs on TransactionOutputReference {
  List<int> get immutableBytes => <int>[]
    ..addAll(transactionId.immutableBytes)
    ..addAll(index.immutableBytes);
}

extension TransactionInputCodecs on TransactionInput {
  List<int> get immutableBytes => <int>[]
    ..addAll(reference.immutableBytes)
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

extension StakingAddressCodecs on StakingAddress {
  List<int> get immutableBytes => <int>[]..addAll(value);
  String get show => "s_${this.value.base58}";
}

extension StakingRegistrationCodecs on StakingRegistration {
  List<int> get immutableBytes => <int>[]
    ..addAll(signature.immutableBytes)
    ..addAll(stakingAddress.immutableBytes);
}

extension ValueCodecs on Value {
  List<int> get immutableBytes => <int>[]
    ..addAll(quantity.immutableBytes)
    ..addAll(registration.immutableBytes);
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

extension PeerIdCodecs on PeerId {
  String get show => "p_${value.sublist(0, 8).show}";
}

class PersistenceCodecs {
  static Uint8List encodeHeightBlockId((Int64, BlockId) heightBlockTuple) =>
      Uint8List.fromList(<int>[]
        ..addAll(heightBlockTuple.$1.toBytes())
        ..addAll(heightBlockTuple.$2.value));
  static (Int64, BlockId) decodeHeightBlockId(Uint8List bytes) =>
      (Int64.fromBytes(bytes.sublist(0, 8)), BlockId(value: bytes.sublist(8)));

  static Uint8List encodeBlockId(BlockId blockId) =>
      Uint8List.fromList(blockId.value);
  static BlockId decodeBlockId(Uint8List bytes) => BlockId(value: bytes);

  static Uint8List encodeTransactionId(TransactionId transactionId) =>
      Uint8List.fromList(transactionId.value);
  static TransactionId decodeTransactionId(Uint8List bytes) =>
      TransactionId(value: bytes);
}

class Codec<T> {
  final List<int> Function(T) encode;
  final T Function(List<int>) decode;

  Codec(this.encode, this.decode);
}

class P2PCodecs {
  static final int64Codec = Codec<Int64>((v) => v.toBytes(), Int64.fromBytes);
  static final blockIdCodec =
      Codec<BlockId>((v) => v.value, (v) => BlockId(value: v));

  static final blockIdOptCodec = optCodec<BlockId>(blockIdCodec);
  static final transactionIdCodec =
      Codec<TransactionId>((v) => v.value, (v) => TransactionId(value: v));

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
      (v) => (v == null) ? [0] : [1, ...baseCodec.encode(v)],
      (bytes) => (bytes[0] == 0) ? null : baseCodec.decode(bytes.sublist(1)));
}
