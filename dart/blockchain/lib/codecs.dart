import 'dart:convert';
import 'dart:typed_data';

import 'package:blockchain/common/models/unsigned.dart';
import 'package:blockchain/common/utils.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain_protobuf/google/protobuf/struct.pb.dart' as struct;
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fast_base58/fast_base58.dart';

import 'package:fixnum/fixnum.dart';
import 'package:hashlib/hashlib.dart';
import 'package:ribs_core/ribs_core.dart';

const arr0 = [0x00];
const arr1 = [0x01];

extension ListCodec<T> on List<T> {
  List<int> immutableBytes(List<int> Function(T) encodeT) {
    final result = <int>[]..addAll(length.immutableBytes);
    for (final t in this) result.addAll(encodeT(t));
    return result;
  }
}

extension BlockHeaderCodecs on BlockHeader {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentHeaderId.value)
    ..addAll(parentSlot.immutableBytes)
    ..addAll(txRoot)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(eligibilityCertificate.immutableBytes)
    ..addAll(operationalCertificate.immutableBytes)
    ..addAll(metadata)
    ..addAll(account.immutableBytes);

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
    ..addAll(parentSlot.immutableBytes)
    ..addAll(txRoot)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(eligibilityCertificate.immutableBytes)
    ..addAll(partialOperationalCertificate.immutableBytes)
    ..addAll(metadata)
    ..addAll(account.immutableBytes);
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
  List<int> immutableBytes(List<int> Function(T) encodeItem) {
    final result = <int>[]..addAll(length.immutableBytes);
    for (final t in this) result.addAll(encodeItem(t));
    return result;
  }
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
  List<int> get immutableBytes => Int32(this).toBytesBigEndian();
}

extension Int64Codecs on Int64 {
  List<int> get immutableBytes => toBytesBigEndian();
}

extension Int128Codecs on List<int> {
  String get base58 => Base58Encode(Uint8List.fromList(this));
  String get show => base58;
}

extension BlockIdCodecs on BlockId {
  List<int> get immutableBytes => value;
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
  List<int> get immutableBytes => [
        ...inputs.immutableBytes((i) => i.immutableBytes),
        ...outputs.immutableBytes((o) => o.immutableBytes),
        ...condOptCodec(hasRewardParentBlockId(), rewardParentBlockId,
            (v) => v.immutableBytes),
      ];

  List<int> get signableBytes => immutableBytes;

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
  List<int> get immutableBytes => [
        ...lockAddress.immutableBytes,
        ...value.immutableBytes,
        ...condOptCodec(
            hasAccount(), account, (accout) => account.immutableBytes),
      ];
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

List<int> optCodec<T>(T? t, List<int> Function(T) encode) =>
    (t == null) ? [...arr0] : [...arr1, ...encode(t)];

List<int> condOptCodec<T>(bool cond, T t, List<int> Function(T) encode) =>
    optCodec(cond ? t : null, encode);

extension ValueCodecs on Value {
  List<int> get immutableBytes => [
        ...quantity.immutableBytes,
        ...condOptCodec(hasAccountRegistration(), accountRegistration,
            (v) => v.immutableBytes),
        ...condOptCodec(hasGraphEntry(), graphEntry, (v) => v.immutableBytes),
      ];
}

extension AccountRegistrationCodecs on AccountRegistration {
  List<int> get immutableBytes => [
        ...associationLock.immutableBytes,
        ...stakingRegistration.immutableBytes
      ];
}

extension GraphEntryCodecs on GraphEntry {
  List<int> get immutableBytes =>
      hasVertex() ? vertex.immutableBytes : edge.immutableBytes;
}

extension VertexCodecs on Vertex {
  List<int> get immutableBytes => [
        ...label.immutableBytes,
        ...condOptCodec(hasData(), data, (v) => v.immutableBytes),
      ];
}

extension EdgeCodecs on Edge {
  List<int> get immutableBytes => [
        ...label.immutableBytes,
        ...condOptCodec(hasData(), data, (v) => v.immutableBytes),
        ...a.immutableBytes,
        ...b.immutableBytes,
      ];
}

extension StructCodecs on struct.Struct {
  List<int> get immutableBytes {
    final sorted = fields.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted
        .map((e) => [
              ...e.key.immutableBytes,
              ...e.value.immutableBytes,
            ])
        .immutableBytes(identity);
  }
}

extension StructValueCodecs on struct.Value {
  List<int> get immutableBytes {
    if (hasNumberValue())
      return numberValue.toString().immutableBytes;
    else if (hasStringValue())
      return stringValue.immutableBytes;
    else if (hasBoolValue())
      return boolValue.immutableBytes;
    else if (hasStructValue())
      return structValue.immutableBytes;
    else if (hasListValue())
      return listValue.values.immutableBytes((v) => v.immutableBytes);
    return [...arr0];
  }
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

extension StringCodecs on String {
  List<int> get immutableBytes => utf8.encode(this);
}

extension BoolCodecs on bool {
  List<int> get immutableBytes => this ? [...arr1] : [...arr0];
}

class PersistenceCodecs {
  static Uint8List encodeHeightBlockId((Int64, BlockId) heightBlockTuple) =>
      Uint8List.fromList(<int>[]
        ..addAll(heightBlockTuple.$1.toBytesBigEndian())
        ..addAll(heightBlockTuple.$2.value));
  static (Int64, BlockId) decodeHeightBlockId(Uint8List bytes) => (
        Int64.fromBytesBigEndian(bytes.sublist(0, 8)),
        BlockId(value: bytes.sublist(8))
      );

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
  static final int64Codec =
      Codec<Int64>((v) => v.toBytesBigEndian(), Int64.fromBytesBigEndian);
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
      (v) => (v == null) ? [...arr0] : [...arr1, ...baseCodec.encode(v)],
      (bytes) => (bytes[0] == 0) ? null : baseCodec.decode(bytes.sublist(1)));
}
