import 'dart:typed_data';

import 'package:fast_base58/fast_base58.dart';
import 'package:fixnum/fixnum.dart';
import 'package:giraffe_sdk/sdk.dart';

// Encoders
typedef P2PEncoder<T> = Uint8List Function(T);
Uint8List encodeHeight(Int64 height) => height.toBytesBigEndian();
Uint8List encodeBlockId(BlockId id) =>
    Uint8List.fromList(Base58Decode(id.value));
Uint8List encodeBlockIdOpt(BlockId? id) => encodeNullable(id, encodeBlockId);
Uint8List encodeTransactionId(TransactionId id) =>
    Uint8List.fromList(Base58Decode(id.value));
final _emptyList = Uint8List(0);
Uint8List encodeVoid(void v) => _emptyList;
Uint8List encodeNullable<T>(T? t, Uint8List Function(T) encode) =>
    t == null ? Uint8List(1) : Uint8List.fromList([1, ...encode(t)]);
Uint8List encodeHeaderOpt(BlockHeader? header) =>
    encodeNullable(header, (header) => header.writeToBuffer());
Uint8List encodeBodyOpt(BlockBody? body) =>
    encodeNullable(body, (body) => body.writeToBuffer());
Uint8List encodeTransactionOpt(Transaction? transaction) =>
    encodeNullable(transaction, (transaction) => transaction.writeToBuffer());
Uint8List encodePublicP2PState(PublicP2PState state) => state.writeToBuffer();

// Decoders
typedef P2PDecoder<T> = T Function(Uint8List);
Int64 decodeHeight(Uint8List bytes) => Int64.fromBytesBigEndian(bytes);
BlockId? decodeBlockIdOpt(Uint8List bytes) =>
    bytes[0] == 0 ? null : decodeBlockId(bytes.sublist(1));
BlockId decodeBlockId(Uint8List bytes) => BlockId(value: Base58Encode(bytes));
TransactionId decodeTransactionId(Uint8List bytes) =>
    TransactionId(value: Base58Encode(bytes));
PublicP2PState decodePublicP2PState(Uint8List bytes) =>
    PublicP2PState.fromBuffer(bytes);
BlockHeader? decodeHeaderOpt(Uint8List bytes) =>
    bytes[0] == 0 ? null : BlockHeader.fromBuffer(bytes.sublist(1));
BlockBody? decodeBodyOpt(Uint8List bytes) =>
    bytes[0] == 0 ? null : BlockBody.fromBuffer(bytes.sublist(1));
Transaction? decodeTransactionOpt(Uint8List bytes) =>
    bytes[0] == 0 ? null : Transaction.fromBuffer(bytes.sublist(1));

class P2PCodec<T> {
  final P2PEncoder<T> encoder;
  final P2PDecoder<T> decoder;

  P2PCodec({required this.encoder, required this.decoder});
}

final heightCodec = P2PCodec(encoder: encodeHeight, decoder: decodeHeight);
final blockIdCodec = P2PCodec(encoder: encodeBlockId, decoder: decodeBlockId);
final blockIdOptCodec =
    P2PCodec(encoder: encodeBlockIdOpt, decoder: decodeBlockIdOpt);
final transactionIdCodec =
    P2PCodec(encoder: encodeTransactionId, decoder: decodeTransactionId);
final voidCodec = P2PCodec(encoder: encodeVoid, decoder: (_) => null);
final headerOptCodec =
    P2PCodec(encoder: encodeHeaderOpt, decoder: decodeHeaderOpt);
final bodyOptCodec = P2PCodec(encoder: encodeBodyOpt, decoder: decodeBodyOpt);
final transactionOptCodec =
    P2PCodec(encoder: encodeTransactionOpt, decoder: decodeTransactionOpt);
final publicP2PStateCodec =
    P2PCodec(encoder: encodePublicP2PState, decoder: decodePublicP2PState);
final bytesCodec = P2PCodec(encoder: (v) => v, decoder: (v) => v);
