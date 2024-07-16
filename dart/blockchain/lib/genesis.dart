import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/common/models/common.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/ledger/block_header_to_body_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:ribs_effect/ribs_effect.dart';

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
  static final operationalCertificate = OperationalCertificate()
    ..parentVK = (VerificationKeyKesProduct()
      ..value = _emptyBytes32
      ..step = 0)
    ..parentSignature = (SignatureKesProduct()
      ..superSignature = (SignatureKesSum()..verificationKey = _emptyBytes32)
      ..subSignature = (SignatureKesSum()..verificationKey = _emptyBytes32)
      ..subRoot = _emptyBytes32)
    ..childVK = _emptyBytes32
    ..childSignature = _emptyBytes64;

  static final stakingAccount = TransactionOutputReference(
      transactionId: TransactionId(value: _emptyBytes32));

  static Eta eta(List<int> prefix, Iterable<TransactionId> transactionIds) {
    final bytes = <int>[]..addAll(prefix);
    for (final id in transactionIds) bytes.addAll(id.value.decodeBase58);
    return bytes.hash256;
  }

  static EligibilityCertificate eligibilityCertificate(Eta eta) =>
      EligibilityCertificate()
        ..vrfSig = _emptyBytes80
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

    await save("$blockIdStr.header.pbuf", block.header.writeToBuffer());
    await save("$blockIdStr.header.json",
        json.encode(block.header.toProto3Json()).utf8Bytes);
    final body =
        BlockBody(transactionIds: block.fullBody.transactions.map((t) => t.id));
    await save("$blockIdStr.body.pbuf", body.writeToBuffer());
    await save(
        "$blockIdStr.body.json", json.encode(body.toProto3Json()).utf8Bytes);
    for (final transaction in block.fullBody.transactions) {
      final transactionIdStr = transaction.id.show;
      await save(
          "$transactionIdStr.transaction.pbuf", transaction.writeToBuffer());
      await save("$transactionIdStr.transaction.json",
          json.encode(transaction.toProto3Json()).utf8Bytes);
    }
  }

  static IO<FullBlock> loadFromDisk(Directory directory, BlockId blockId) =>
      IO.fromFutureF(() async {
        final blockIdStr = blockId.show;
        Future<List<int>> load(String name) async {
          final file = File("${directory.path}/$name");
          return file.readAsBytes();
        }

        final header =
            BlockHeader.fromBuffer(await load("$blockIdStr.header.pbuf"));

        header.embedId();

        assert(header.id == blockId);

        final body = BlockBody.fromBuffer(await load("$blockIdStr.body.pbuf"));
        final transactions = <Transaction>[];

        for (final transactionId in body.transactionIds) {
          final tx = Transaction.fromBuffer(
              await load("${transactionId.show}.transaction.pbuf"));
          tx.embedId();
          assert(tx.id == transactionId);
          transactions.add(tx);
        }

        final fullBody = FullBlockBody(transactions: transactions);
        final expectedTxRoot =
            TxRoot.calculateFromTransactions(Uint8List(32), transactions);
        assert(expectedTxRoot.sameElements(header.txRoot.decodeBase58));
        return FullBlock(header: header, fullBody: fullBody);
      });
}

class GenesisConfig {
  final Int64 timestamp;
  final List<Transaction> transactions;
  final List<int> etaPrefix;
  final Map<String, String> settings;

  GenesisConfig(
      this.timestamp, this.transactions, this.etaPrefix, this.settings);

  static final DefaultEtaPrefix = utf8.encode("genesis");

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
      ..eligibilityCertificate =
          Genesis.eligibilityCertificate(Genesis.eta(etaPrefix, transactionIds))
      ..operationalCertificate = Genesis.operationalCertificate
      ..account = Genesis.stakingAccount;

    header.settings.addAll(settings);

    return FullBlock()
      ..header = header
      ..fullBody = (FullBlockBody()..transactions.addAll(transactions));
  }
}
