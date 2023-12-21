import 'dart:convert';
import 'dart:typed_data';

import 'package:blockchain/codecs.dart';
import 'package:blockchain/crypto/utils.dart';
import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class GenesisConfig {
  final Int64 timestamp;
  final List<Transaction> transactions;
  final List<int> etaPrefix;

  GenesisConfig(this.timestamp, this.transactions, this.etaPrefix);

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
      ..txRoot = _emptyBytes(32) // TODO
      ..bloomFilter = _emptyBytes(256) // TODO
      ..timestamp = timestamp
      ..height = Int64.ONE
      ..slot = Int64.ZERO
      ..eligibilityCertificate = eligibilityCertificate
      ..operationalCertificate = GenesisOperationalCertificate
      ..address = (StakingAddress()..value = _emptyBytes(32));

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
