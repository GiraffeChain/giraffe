import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'codecs.dart';
import 'common/models/common.dart';
import 'ledger/block_header_to_body_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';
import 'package:fixnum/fixnum.dart';

class Genesis {
  static const _emptyBytes32 = "11111111111111111111111111111111";
  static const _emptyBytes64 =
      "1111111111111111111111111111111111111111111111111111111111111111";
  static const _emptyBytes80 =
      "11111111111111111111111111111111111111111111111111111111111111111111111111111111";
  static const height = Int64.ONE;
  static const slot = Int64.ZERO;
  static final parentSlot = Int64(-1);

  static final parentId = BlockId()..value = Int8List(32).base58;

  static final stakingAccount = TransactionOutputReference(
      transactionId: TransactionId(value: _emptyBytes32));

  static Eta eta(List<int> prefix, Iterable<TransactionId> transactionIds) {
    final bytes = <int>[...prefix];
    for (final id in transactionIds) {
      bytes.addAll(id.value.decodeBase58);
    }
    return bytes.hash256;
  }

  static StakerCertificate stakerCertificate(Eta eta) => StakerCertificate()
    ..blockSignature = _emptyBytes64
    ..vrfSignature = _emptyBytes80
    ..vrfVK = _emptyBytes32
    ..thresholdEvidence = _emptyBytes32
    ..eta = eta.base58;

  static Future<void> save(Directory directory, FullBlock block) async {
    await directory.create(recursive: true);
    final blockIdStr = block.header.id.show;
    Future<void> save(String name, List<int> data) async {
      final file = File("${directory.path}/$name");
      await file.writeAsBytes(data);
    }

    await save("$blockIdStr.pbuf", block.writeToBuffer());
    await save("$blockIdStr.json", json.encode(block.toProto3Json()).utf8Bytes);
  }
}

class GenesisConfig {
  final Int64 timestamp;
  final List<Transaction> transactions;
  final List<int> etaPrefix;
  final Map<String, String> settings;

  GenesisConfig(
      this.timestamp, this.transactions, this.etaPrefix, this.settings);

  static final defaultEtaPrefix = utf8.encode("genesis");

  FullBlock get block {
    final transactionIds = transactions.map((tx) => tx.id);
    final header = BlockHeader()
      ..parentHeaderId = Genesis.parentId
      ..parentSlot = Genesis.parentSlot
      ..txRoot =
          TxRoot.calculateFromTransactionIds(Uint8List(32), transactionIds)
              .base58
      ..timestamp = timestamp
      ..height = Genesis.height
      ..slot = Genesis.slot
      ..stakerCertificate =
          Genesis.stakerCertificate(Genesis.eta(etaPrefix, transactionIds))
      ..account = Genesis.stakingAccount;

    header.settings.addAll(settings);

    return FullBlock()
      ..header = header
      ..fullBody = (FullBlockBody()..transactions.addAll(transactions));
  }
}
