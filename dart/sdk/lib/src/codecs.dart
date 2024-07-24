import 'dart:convert';
import 'dart:typed_data';

import 'utils.dart';
import 'crypto/utils.dart';
import 'package:blockchain_protobuf/google/protobuf/struct.pb.dart' as struct;
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fast_base58/fast_base58.dart';

import 'package:fixnum/fixnum.dart';
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

BlockId decodeBlockId(String input) {
  return BlockId()..value = input.startsWith("b_") ? input.substring(2) : input;
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
    ..addAll(verificationKey.decodeBase58)
    ..addAll(signature.decodeBase58)
    ..addAll(witness.immutableBytes((t) => t.decodeBase58));
}

extension SignatureKesProductCodecs on SignatureKesProduct {
  List<int> get immutableBytes => <int>[]
    ..addAll(superSignature.immutableBytes)
    ..addAll(subSignature.immutableBytes)
    ..addAll(subRoot.decodeBase58);
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
  List<int> get immutableBytes => value.decodeBase58;
  String get show => "b_$value";
}

extension TransactionIdCodecs on TransactionId {
  List<int> get immutableBytes => value.decodeBase58;
  String get show => "t_$value";
}

TransactionId decodeTransactionId(String input) {
  return TransactionId()
    ..value = input.startsWith("t_") ? input.substring(2) : input;
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
      TransactionId()..value = immutableBytes.hash256.base58;

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
      return ed25519.signature.decodeBase58;
    else
      throw ArgumentError("Invalid Key");
  }
}

extension StakingAddressCodecs on StakingAddress {
  List<int> get immutableBytes => <int>[]..addAll(value.decodeBase58);
  String get show => "s_$value";
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
        ...condOptCodec(hasStakingRegistration(), stakingRegistration,
            (t) => t.immutableBytes)
      ];
}

extension GraphEntryCodecs on GraphEntry {
  List<int> get immutableBytes =>
      hasVertex() ? vertex.immutableBytes : edge.immutableBytes;
}

extension VertexCodecs on Vertex {
  List<int> get immutableBytes => [
        ...label.decodeBase58,
        ...condOptCodec(hasData(), data, (v) => v.immutableBytes),
      ];
}

extension EdgeCodecs on Edge {
  List<int> get immutableBytes => [
        ...label.decodeBase58,
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
              ...e.key.decodeBase58,
              ...e.value.immutableBytes,
            ])
        .immutableBytes(identity);
  }
}

extension StructValueCodecs on struct.Value {
  List<int> get immutableBytes {
    if (hasNumberValue())
      return numberValue.toString().decodeBase58;
    else if (hasStringValue())
      return stringValue.decodeBase58;
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
  List<int> get immutableBytes => value.decodeBase58;

  String get show => "a_$value";
}

LockAddress decodeLockAddress(String input) {
  return LockAddress()
    ..value = input.startsWith("a_") ? input.substring(2) : input;
}

extension LockCodecs on Lock {
  List<int> get immutableBytes {
    if (hasEd25519())
      return ed25519.immutableBytes;
    else
      throw ArgumentError("Invalid Lock");
  }

  LockAddress get address =>
      LockAddress()..value = immutableBytes.hash256.base58;
}

extension Lock_Ed25519Codecs on Lock_Ed25519 {
  List<int> get immutableBytes => vk.decodeBase58;
}

extension PeerIdCodecs on PeerId {
  String get show => "p_${value.substring(0, 8)}";
}

extension StringCodecs on String {
  List<int> get decodeBase58 => isEmpty ? [] : Base58Decode(this);
  List<int> get utf8Bytes => utf8.encode(this);
}

extension BoolCodecs on bool {
  List<int> get immutableBytes => this ? [...arr1] : [...arr0];
}
