import 'package:giraffe_sdk/sdk.dart';

import '../../codecs.dart';
import 'package:fixnum/fixnum.dart';

class UnsignedBlockHeader {
  final BlockId parentHeaderId;
  final String txRoot;
  final Int64 timestamp;
  final Int64 height;
  final Int64 slot;
  final PartialStakerCertificate partialStakerCertificate;
  final TransactionOutputReference account;

  UnsignedBlockHeader(
    this.parentHeaderId,
    this.txRoot,
    this.timestamp,
    this.height,
    this.slot,
    this.partialStakerCertificate,
    this.account,
  );
}

class PartialStakerCertificate {
  final String vrfSignature;
  final String vrfVK;
  final String eta;

  PartialStakerCertificate(
      {required this.vrfSignature, required this.vrfVK, required this.eta});
}

extension BlockHeaderOps on BlockHeader {
  UnsignedBlockHeader get unsigned => UnsignedBlockHeader(
        parentHeaderId,
        txRoot,
        timestamp,
        height,
        slot,
        PartialStakerCertificate(
          vrfSignature: stakerCertificate.vrfSignature,
          vrfVK: stakerCertificate.vrfVK,
          eta: stakerCertificate.eta,
        ),
        account,
      );

  SlotId get slotId => SlotId(slot: slot, blockId: id);
}
