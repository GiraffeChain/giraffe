import 'dart:typed_data';

import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';
import 'package:crypto/crypto.dart';

import 'package:bs58/bs58.dart';

extension BlockCodecOps on Block {
  BlockId get id {
    List<int> bytes = [];
    bytes.addAll(parentHeaderId.bytes);
    bytes.addAll(timestamp.toBytes());
    bytes.addAll(height.toBytes());
    bytes.addAll(slot.toBytes());
    bytes.addAll(proof);
    transactionIds.forEach((id) => bytes.addAll(id.bytes));
    final digest = sha256.convert(bytes);

    return BlockId(bytes: digest.bytes);
  }
}

extension TransactionCodecOps on Transaction {
  TransactionId get id => TransactionId(); // TODO
}

extension BlockIdShowOps on BlockId {
  String get show => base58.encode(Uint8List.fromList(bytes));
}

extension TransactionIdShowOps on TransactionId {
  String get show => base58.encode(Uint8List.fromList(bytes));
}
