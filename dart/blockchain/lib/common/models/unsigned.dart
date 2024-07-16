import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:fixnum/fixnum.dart';

class UnsignedBlockHeader {
  final BlockId parentHeaderId;
  final Int64 parentSlot;
  final String txRoot;
  final Int64 timestamp;
  final Int64 height;
  final Int64 slot;
  final EligibilityCertificate eligibilityCertificate;
  final PartialOperationalCertificate partialOperationalCertificate;
  final String metadata;
  final TransactionOutputReference account;

  UnsignedBlockHeader(
    this.parentHeaderId,
    this.parentSlot,
    this.txRoot,
    this.timestamp,
    this.height,
    this.slot,
    this.eligibilityCertificate,
    this.partialOperationalCertificate,
    this.metadata,
    this.account,
  );
}

class PartialOperationalCertificate {
  final VerificationKeyKesProduct parentVK;
  final SignatureKesProduct parentSignature;
  final String childVK;

  PartialOperationalCertificate(
      this.parentVK, this.parentSignature, this.childVK);
}
