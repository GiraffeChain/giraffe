import 'dart:convert';
import 'dart:typed_data';

import 'package:blockchain_protobuf/models/block.pb.dart';
import 'package:blockchain_protobuf/models/transaction.pb.dart';
import 'package:crypto/crypto.dart';

import 'package:bs58/bs58.dart';

extension BlockCodecOps on Block {
  BlockId get id => BlockId(bytes: sha256.convert(encodeV1).bytes);

  List<int> get encodeV1 {
    List<int> bytes = [];
    bytes.addAll(parentHeaderId.bytes);
    bytes.addAll(timestamp.toBytes());
    bytes.addAll(height.toBytes());
    bytes.addAll(slot.toBytes());
    bytes.addAll(proof);
    transactionIds.forEach((id) => bytes.addAll(id.bytes));
    return bytes;
  }
}

extension FullBlockCodecOps on FullBlock {
  Block get block => Block(
      parentHeaderId: parentHeaderId,
      timestamp: timestamp,
      height: height,
      slot: slot,
      proof: proof,
      transactionIds: transactions.map((t) => t.id));

  BlockId get id => block.id;
}

extension TransactionCodecOps on Transaction {
  TransactionId get id => TransactionId(bytes: sha256.convert(encodeV1).bytes);

  List<int> get encodeV1 {
    final bytes = <int>[];
    inputs.map((i) => i.encodeV1).forEach(bytes.addAll);
    outputs.map((i) => i.encodeV1).forEach(bytes.addAll);
    return bytes;
  }
}

extension TransactionInputCodecOps on TransactionInput {
  List<int> get encodeV1 {
    final bytes = <int>[];
    bytes.addAll(spentTransactionOutput.encodeV1);
    bytes.addAll(challenge.encodeV1);
    challengeArguments.forEach(bytes.addAll);
    return bytes;
  }
}

extension TransactionOutputCodecOps on TransactionOutput {
  List<int> get encodeV1 {
    final bytes = <int>[];
    bytes.addAll(value.encodeV1);
    if (hasSpendChallengeHash()) {
      bytes.add(0);
      bytes.addAll(spendChallengeHash.encodeV1);
    } else {
      bytes.add(1);
      bytes.addAll(donation.encodeV1);
    }

    return bytes;
  }
}

extension TransactionOutputReferenceCodecOps on TransactionOutputReference {
  List<int> get encodeV1 {
    final bytes = <int>[];
    bytes.addAll(transactionId.bytes);
    bytes.addAll((ByteData(4)..setInt32(0, index)).buffer.asUint8List());
    return bytes;
  }
}

extension ValueCodecOps on Value {
  List<int> get encodeV1 {
    final bytes = <int>[];
    if (hasCoin()) {
      bytes.add(0);
      bytes.addAll(utf8.encode(coin.quantity));
      bytes.addAll(coin.donationChallengeVote.encodeV1);
    } else {
      bytes.add(1);
      bytes.addAll(utf8.encode(data.dataType));
      bytes.addAll(data.bytes);
    }
    return bytes;
  }
}

extension ChallengeHashCodecOps on ChallengeHash {
  List<int> get encodeV1 {
    final bytes = <int>[];
    bytes.addAll(hash);
    return bytes;
  }
}

extension ChallengeCodecOps on Challenge {
  List<int> get encodeV1 {
    final bytes = <int>[];
    bytes.addAll(utf8.encode(script));
    return bytes;
  }
}

extension DonationCodecOps on Donation {
  List<int> get encodeV1 {
    final bytes = <int>[];
    bytes.addAll(from);
    return bytes;
  }
}

extension BlockIdShowOps on BlockId {
  String get show => base58.encode(Uint8List.fromList(bytes));
}

extension TransactionIdShowOps on TransactionId {
  String get show => base58.encode(Uint8List.fromList(bytes));
}
