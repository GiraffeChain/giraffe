import 'package:blockchain_protobuf/models/core.pb.dart';
import 'package:blockchain_sdk/sdk.dart';

import 'common/models/unsigned.dart';

extension BlockHeaderCodecs on BlockHeader {
  List<int> get immutableBytes => <int>[]
    ..addAll(parentHeaderId.immutableBytes)
    ..addAll(parentSlot.immutableBytes)
    ..addAll(txRoot.decodeBase58)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(stakerCertificate.immutableBytes)
    ..addAll(account.immutableBytes);

  BlockId get id => hasHeaderId() ? headerId : computeId;

  BlockId get computeId => BlockId()..value = immutableBytes.hash256.base58;

  void embedId() => headerId = computeId;

  bool get containsValidId => headerId == computeId;
}

extension UnsignedBlockHeaderCodecs on UnsignedBlockHeader {
  List<int> get signableBytes => <int>[]
    ..addAll(parentHeaderId.immutableBytes)
    ..addAll(parentSlot.immutableBytes)
    ..addAll(txRoot.decodeBase58)
    ..addAll(timestamp.immutableBytes)
    ..addAll(height.immutableBytes)
    ..addAll(slot.immutableBytes)
    ..addAll(partialStakerCertificate.immutableBytes)
    ..addAll(account.immutableBytes);
}

extension StakerCertificateCodecs on StakerCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(blockSignature.decodeBase58)
    ..addAll(vrfSignature.decodeBase58)
    ..addAll(vrfVK.decodeBase58)
    ..addAll(thresholdEvidence.decodeBase58)
    ..addAll(eta.decodeBase58);
}

extension PartialStakerCertificateCodecs on PartialStakerCertificate {
  List<int> get immutableBytes => <int>[]
    ..addAll(vrfSignature.decodeBase58)
    ..addAll(vrfVK.decodeBase58)
    ..addAll(thresholdEvidence.decodeBase58)
    ..addAll(eta.decodeBase58);
}
