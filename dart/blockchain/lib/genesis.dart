import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain/ledger/block_header_to_body_validation.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class Genesis {
  static Future<void> save(Directory directory, FullBlock block) async {
    await directory.create(recursive: true);
    final blockIdStr = block.header.id.show;
    Future<void> save(String name, List<int> data) async {
      final file = File("${directory.path}/$name");
      await file.writeAsBytes(data);
    }

    await save("$blockIdStr.header.pbuf", block.header.writeToBuffer());
    final body =
        BlockBody(transactionIds: block.fullBody.transactions.map((t) => t.id));
    await save("$blockIdStr.body.pbuf", body.writeToBuffer());
    for (final transaction in block.fullBody.transactions) {
      final transactionIdStr = transaction.id.show;
      await save(
          "$transactionIdStr.transaction.pbuf", transaction.writeToBuffer());
    }
  }

  static Future<FullBlock> loadFromDisk(
      Directory directory, BlockId blockId) async {
    final blockIdStr = blockId.show;
    Future<List<int>> load(String name) async {
      final file = File("${directory.path}/$name");
      return file.readAsBytes();
    }

    final header =
        BlockHeader.fromBuffer(await load("$blockIdStr.header.pbuf"));

    final body = BlockBody.fromBuffer(await load("$blockIdStr.body.pbuf"));

    final transactions = [
      for (final transactionId in body.transactionIds)
        await Transaction.fromBuffer(
            await load("${transactionId.show}.transaction.pbuf"))
    ];

    final fullBody = FullBlockBody(transactions: transactions);
    // TODO: Verify
    return FullBlock(header: header, fullBody: fullBody);
  }
}

class GenesisConfig {
  final Int64 timestamp;
  final List<Transaction> transactions;
  final List<int> etaPrefix;
  final Map<String, String> settings;

  GenesisConfig(
      this.timestamp, this.transactions, this.etaPrefix, this.settings);

  static final DefaultEtaPrefix = utf8.encode("genesis");

  Future<FullBlock> get block async {
    final eta = await (etaPrefix +
            transactions
                .map((t) => t.id.value)
                .fold(Uint8List(0), (a, b) => a + b))
        .hash256;
    final eligibilityCertificate = EligibilityCertificate()
      ..vrfSig = _emptyBytes(80)
      ..vrfVK = _emptyBytes(32)
      ..thresholdEvidence = _emptyBytes(32)
      ..eta = eta;
    final header = BlockHeader()
      ..parentHeaderId = GenesisParentId
      ..parentSlot = Int64(-1)
      ..txRoot = TxRoot.calculateFromTransactions(Uint8List(32), transactions)
      ..timestamp = timestamp
      ..height = Int64.ONE
      ..slot = Int64.ZERO
      ..eligibilityCertificate = eligibilityCertificate
      ..operationalCertificate = GenesisOperationalCertificate
      ..address = (StakingAddress()..value = _emptyBytes(32));

    header.settings.addAll(settings);

    return FullBlock()
      ..header = header
      ..fullBody = (FullBlockBody()..transactions.addAll(transactions));
  }
}

final GenesisParentId = BlockId()..value = Int8List(32);
final GenesisOperationalCertificate = OperationalCertificate()
  ..parentVK = (VerificationKeyKesProduct()
    ..value = _emptyBytes(32)
    ..step = 0)
  ..parentSignature = (SignatureKesProduct()
    ..superSignature = (SignatureKesSum()..verificationKey = _emptyBytes(32))
    ..subSignature = (SignatureKesSum()..verificationKey = _emptyBytes(32))
    ..subRoot = _emptyBytes(32))
  ..childVK = _emptyBytes(32)
  ..childSignature = _emptyBytes(64);

Int8List _emptyBytes(int length) => Int8List(length);
