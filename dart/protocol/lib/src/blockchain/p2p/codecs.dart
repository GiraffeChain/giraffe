import 'dart:typed_data';

import 'package:fast_base58/fast_base58.dart';
import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';

// Encoders
typedef P2PEncoder<T> = Uint8List Function(T);

class P2PEncoders {
  static Uint8List encodeHeight(Int64 height) => height.toBytesBigEndian();
  static Uint8List encodeBlockId(BlockId id) =>
      Uint8List.fromList(Base58Decode(id.value));
  static Uint8List encodeBlockIdOpt(BlockId? id) =>
      encodeNullable(id, encodeBlockId);
  static Uint8List encodeTransactionId(TransactionId id) =>
      Uint8List.fromList(Base58Decode(id.value));
  static final _emptyList = Uint8List(0);
  static Uint8List encodeVoid(void v) => _emptyList;
  static Uint8List encodeNullable<T>(T? t, Uint8List Function(T) encode) =>
      t == null ? Uint8List(1) : Uint8List.fromList([1, ...encode(t)]);
  static Uint8List encodeHeaderOpt(BlockHeader? header) =>
      encodeNullable(header, (header) => header.writeToBuffer());
  static Uint8List encodeBodyOpt(BlockBody? body) =>
      encodeNullable(body, (body) => body.writeToBuffer());
  static Uint8List encodeTransactionOpt(Transaction? transaction) =>
      encodeNullable(transaction, (transaction) => transaction.writeToBuffer());
  static Uint8List encodePublicP2PState(PublicP2PState state) =>
      state.writeToBuffer();
}

// Decoders
typedef P2PDecoder<T> = T Function(Uint8List);

class P2PDecoders {
  static Int64 decodeHeight(Uint8List bytes) => Int64.fromBytesBigEndian(bytes);
  static BlockId? decodeBlockIdOpt(Uint8List bytes) =>
      bytes[0] == 0 ? null : decodeBlockId(bytes.sublist(1));
  static BlockId decodeBlockId(Uint8List bytes) =>
      BlockId(value: Base58Encode(bytes));
  static TransactionId decodeTransactionId(Uint8List bytes) =>
      TransactionId(value: Base58Encode(bytes));
  static PublicP2PState decodePublicP2PState(Uint8List bytes) =>
      PublicP2PState.fromBuffer(bytes);
  static BlockHeader? decodeHeaderOpt(Uint8List bytes) =>
      bytes[0] == 0 ? null : BlockHeader.fromBuffer(bytes.sublist(1));
  static BlockBody? decodeBodyOpt(Uint8List bytes) =>
      bytes[0] == 0 ? null : BlockBody.fromBuffer(bytes.sublist(1));
  static Transaction? decodeTransactionOpt(Uint8List bytes) =>
      bytes[0] == 0 ? null : Transaction.fromBuffer(bytes.sublist(1));
}

class P2PCodec<T> {
  final P2PEncoder<T> encoder;
  final P2PDecoder<T> decoder;

  P2PCodec({required this.encoder, required this.decoder});
}

class P2PCodecs {
  static final heightCodec = P2PCodec(
      encoder: P2PEncoders.encodeHeight, decoder: P2PDecoders.decodeHeight);
  static final blockIdCodec = P2PCodec(
      encoder: P2PEncoders.encodeBlockId, decoder: P2PDecoders.decodeBlockId);
  static final blockIdOptCodec = P2PCodec(
      encoder: P2PEncoders.encodeBlockIdOpt,
      decoder: P2PDecoders.decodeBlockIdOpt);
  static final transactionIdCodec = P2PCodec(
      encoder: P2PEncoders.encodeTransactionId,
      decoder: P2PDecoders.decodeTransactionId);
  static final voidCodec =
      P2PCodec(encoder: P2PEncoders.encodeVoid, decoder: (_) => null);
  static final headerOptCodec = P2PCodec(
      encoder: P2PEncoders.encodeHeaderOpt,
      decoder: P2PDecoders.decodeHeaderOpt);
  static final bodyOptCodec = P2PCodec(
      encoder: P2PEncoders.encodeBodyOpt, decoder: P2PDecoders.decodeBodyOpt);
  static final transactionOptCodec = P2PCodec(
      encoder: P2PEncoders.encodeTransactionOpt,
      decoder: P2PDecoders.decodeTransactionOpt);
  static final publicP2PStateCodec = P2PCodec(
      encoder: P2PEncoders.encodePublicP2PState,
      decoder: P2PDecoders.decodePublicP2PState);
  static final bytesCodec = P2PCodec(encoder: (v) => v, decoder: (v) => v);
}
