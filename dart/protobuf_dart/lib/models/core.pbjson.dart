///
//  Generated code. Do not modify.
//  source: models/core.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use blockIdDescriptor instead')
const BlockId$json = const {
  '1': 'BlockId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `BlockId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockIdDescriptor = $convert.base64Decode('CgdCbG9ja0lkEhQKBXZhbHVlGAEgASgMUgV2YWx1ZQ==');
@$core.Deprecated('Use blockHeaderDescriptor instead')
const BlockHeader$json = const {
  '1': 'BlockHeader',
  '2': const [
    const {'1': 'headerId', '3': 12, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'headerId'},
    const {'1': 'parentHeaderId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '8': const {}, '10': 'parentHeaderId'},
    const {'1': 'parentSlot', '3': 2, '4': 1, '5': 4, '10': 'parentSlot'},
    const {'1': 'txRoot', '3': 3, '4': 1, '5': 12, '8': const {}, '10': 'txRoot'},
    const {'1': 'bloomFilter', '3': 4, '4': 1, '5': 12, '8': const {}, '10': 'bloomFilter'},
    const {'1': 'timestamp', '3': 5, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'height', '3': 6, '4': 1, '5': 4, '10': 'height'},
    const {'1': 'slot', '3': 7, '4': 1, '5': 4, '10': 'slot'},
    const {'1': 'eligibilityCertificate', '3': 8, '4': 1, '5': 11, '6': '.com.blockchain.models.EligibilityCertificate', '8': const {}, '10': 'eligibilityCertificate'},
    const {'1': 'operationalCertificate', '3': 9, '4': 1, '5': 11, '6': '.com.blockchain.models.OperationalCertificate', '8': const {}, '10': 'operationalCertificate'},
    const {'1': 'metadata', '3': 10, '4': 1, '5': 12, '8': const {}, '10': 'metadata'},
    const {'1': 'address', '3': 11, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingAddress', '8': const {}, '10': 'address'},
  ],
};

/// Descriptor for `BlockHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockHeaderDescriptor = $convert.base64Decode('CgtCbG9ja0hlYWRlchI6CghoZWFkZXJJZBgMIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZGVscy5CbG9ja0lkUghoZWFkZXJJZBJQCg5wYXJlbnRIZWFkZXJJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZGVscy5CbG9ja0lkQgj6QgWKAQIQAVIOcGFyZW50SGVhZGVySWQSHgoKcGFyZW50U2xvdBgCIAEoBFIKcGFyZW50U2xvdBIfCgZ0eFJvb3QYAyABKAxCB/pCBHoCaCBSBnR4Um9vdBIqCgtibG9vbUZpbHRlchgEIAEoDEII+kIFegNogAJSC2Jsb29tRmlsdGVyEhwKCXRpbWVzdGFtcBgFIAEoBFIJdGltZXN0YW1wEhYKBmhlaWdodBgGIAEoBFIGaGVpZ2h0EhIKBHNsb3QYByABKARSBHNsb3QSbwoWZWxpZ2liaWxpdHlDZXJ0aWZpY2F0ZRgIIAEoCzItLmNvbS5ibG9ja2NoYWluLm1vZGVscy5FbGlnaWJpbGl0eUNlcnRpZmljYXRlQgj6QgWKAQIQAVIWZWxpZ2liaWxpdHlDZXJ0aWZpY2F0ZRJvChZvcGVyYXRpb25hbENlcnRpZmljYXRlGAkgASgLMi0uY29tLmJsb2NrY2hhaW4ubW9kZWxzLk9wZXJhdGlvbmFsQ2VydGlmaWNhdGVCCPpCBYoBAhABUhZvcGVyYXRpb25hbENlcnRpZmljYXRlEiMKCG1ldGFkYXRhGAogASgMQgf6QgR6AhggUghtZXRhZGF0YRJJCgdhZGRyZXNzGAsgASgLMiUuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlN0YWtpbmdBZGRyZXNzQgj6QgWKAQIQAVIHYWRkcmVzcw==');
@$core.Deprecated('Use eligibilityCertificateDescriptor instead')
const EligibilityCertificate$json = const {
  '1': 'EligibilityCertificate',
  '2': const [
    const {'1': 'vrfSig', '3': 1, '4': 1, '5': 12, '8': const {}, '10': 'vrfSig'},
    const {'1': 'vrfVK', '3': 2, '4': 1, '5': 12, '8': const {}, '10': 'vrfVK'},
    const {'1': 'thresholdEvidence', '3': 3, '4': 1, '5': 12, '8': const {}, '10': 'thresholdEvidence'},
    const {'1': 'eta', '3': 4, '4': 1, '5': 12, '8': const {}, '10': 'eta'},
  ],
};

/// Descriptor for `EligibilityCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eligibilityCertificateDescriptor = $convert.base64Decode('ChZFbGlnaWJpbGl0eUNlcnRpZmljYXRlEh8KBnZyZlNpZxgBIAEoDEIH+kIEegJoUFIGdnJmU2lnEh0KBXZyZlZLGAIgASgMQgf6QgR6AmggUgV2cmZWSxI1ChF0aHJlc2hvbGRFdmlkZW5jZRgDIAEoDEIH+kIEegJoIFIRdGhyZXNob2xkRXZpZGVuY2USGQoDZXRhGAQgASgMQgf6QgR6AmggUgNldGE=');
@$core.Deprecated('Use operationalCertificateDescriptor instead')
const OperationalCertificate$json = const {
  '1': 'OperationalCertificate',
  '2': const [
    const {'1': 'parentVK', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.VerificationKeyKesProduct', '8': const {}, '10': 'parentVK'},
    const {'1': 'parentSignature', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesProduct', '8': const {}, '10': 'parentSignature'},
    const {'1': 'childVK', '3': 3, '4': 1, '5': 12, '8': const {}, '10': 'childVK'},
    const {'1': 'childSignature', '3': 4, '4': 1, '5': 12, '8': const {}, '10': 'childSignature'},
  ],
};

/// Descriptor for `OperationalCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operationalCertificateDescriptor = $convert.base64Decode('ChZPcGVyYXRpb25hbENlcnRpZmljYXRlElYKCHBhcmVudFZLGAEgASgLMjAuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlZlcmlmaWNhdGlvbktleUtlc1Byb2R1Y3RCCPpCBYoBAhABUghwYXJlbnRWSxJeCg9wYXJlbnRTaWduYXR1cmUYAiABKAsyKi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuU2lnbmF0dXJlS2VzUHJvZHVjdEII+kIFigECEAFSD3BhcmVudFNpZ25hdHVyZRIhCgdjaGlsZFZLGAMgASgMQgf6QgR6AmggUgdjaGlsZFZLEi8KDmNoaWxkU2lnbmF0dXJlGAQgASgMQgf6QgR6AmhAUg5jaGlsZFNpZ25hdHVyZQ==');
@$core.Deprecated('Use verificationKeyKesProductDescriptor instead')
const VerificationKeyKesProduct$json = const {
  '1': 'VerificationKeyKesProduct',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 12, '8': const {}, '10': 'value'},
    const {'1': 'step', '3': 2, '4': 1, '5': 13, '10': 'step'},
  ],
};

/// Descriptor for `VerificationKeyKesProduct`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verificationKeyKesProductDescriptor = $convert.base64Decode('ChlWZXJpZmljYXRpb25LZXlLZXNQcm9kdWN0Eh0KBXZhbHVlGAEgASgMQgf6QgR6AmggUgV2YWx1ZRISCgRzdGVwGAIgASgNUgRzdGVw');
@$core.Deprecated('Use signatureKesSumDescriptor instead')
const SignatureKesSum$json = const {
  '1': 'SignatureKesSum',
  '2': const [
    const {'1': 'verificationKey', '3': 1, '4': 1, '5': 12, '8': const {}, '10': 'verificationKey'},
    const {'1': 'signature', '3': 2, '4': 1, '5': 12, '8': const {}, '10': 'signature'},
    const {'1': 'witness', '3': 3, '4': 3, '5': 12, '8': const {}, '10': 'witness'},
  ],
};

/// Descriptor for `SignatureKesSum`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signatureKesSumDescriptor = $convert.base64Decode('Cg9TaWduYXR1cmVLZXNTdW0SMQoPdmVyaWZpY2F0aW9uS2V5GAEgASgMQgf6QgR6AmggUg92ZXJpZmljYXRpb25LZXkSJQoJc2lnbmF0dXJlGAIgASgMQgf6QgR6AmhAUglzaWduYXR1cmUSJgoHd2l0bmVzcxgDIAMoDEIM+kIJkgEGIgR6AmggUgd3aXRuZXNz');
@$core.Deprecated('Use signatureKesProductDescriptor instead')
const SignatureKesProduct$json = const {
  '1': 'SignatureKesProduct',
  '2': const [
    const {'1': 'superSignature', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesSum', '8': const {}, '10': 'superSignature'},
    const {'1': 'subSignature', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesSum', '8': const {}, '10': 'subSignature'},
    const {'1': 'subRoot', '3': 3, '4': 1, '5': 12, '8': const {}, '10': 'subRoot'},
  ],
};

/// Descriptor for `SignatureKesProduct`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signatureKesProductDescriptor = $convert.base64Decode('ChNTaWduYXR1cmVLZXNQcm9kdWN0ElgKDnN1cGVyU2lnbmF0dXJlGAEgASgLMiYuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlNpZ25hdHVyZUtlc1N1bUII+kIFigECEAFSDnN1cGVyU2lnbmF0dXJlElQKDHN1YlNpZ25hdHVyZRgCIAEoCzImLmNvbS5ibG9ja2NoYWluLm1vZGVscy5TaWduYXR1cmVLZXNTdW1CCPpCBYoBAhABUgxzdWJTaWduYXR1cmUSIQoHc3ViUm9vdBgDIAEoDEIH+kIEegJoIFIHc3ViUm9vdA==');
@$core.Deprecated('Use slotDataDescriptor instead')
const SlotData$json = const {
  '1': 'SlotData',
  '2': const [
    const {'1': 'slotId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.SlotId', '8': const {}, '10': 'slotId'},
    const {'1': 'parentSlotId', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.SlotId', '8': const {}, '10': 'parentSlotId'},
    const {'1': 'rho', '3': 3, '4': 1, '5': 12, '8': const {}, '10': 'rho'},
    const {'1': 'eta', '3': 4, '4': 1, '5': 12, '8': const {}, '10': 'eta'},
    const {'1': 'height', '3': 5, '4': 1, '5': 4, '10': 'height'},
  ],
};

/// Descriptor for `SlotData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List slotDataDescriptor = $convert.base64Decode('CghTbG90RGF0YRI/CgZzbG90SWQYASABKAsyHS5jb20uYmxvY2tjaGFpbi5tb2RlbHMuU2xvdElkQgj6QgWKAQIQAVIGc2xvdElkEksKDHBhcmVudFNsb3RJZBgCIAEoCzIdLmNvbS5ibG9ja2NoYWluLm1vZGVscy5TbG90SWRCCPpCBYoBAhABUgxwYXJlbnRTbG90SWQSGQoDcmhvGAMgASgMQgf6QgR6AmhAUgNyaG8SGQoDZXRhGAQgASgMQgf6QgR6AmggUgNldGESFgoGaGVpZ2h0GAUgASgEUgZoZWlnaHQ=');
@$core.Deprecated('Use slotIdDescriptor instead')
const SlotId$json = const {
  '1': 'SlotId',
  '2': const [
    const {'1': 'slot', '3': 1, '4': 1, '5': 4, '10': 'slot'},
    const {'1': 'blockId', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '8': const {}, '10': 'blockId'},
  ],
};

/// Descriptor for `SlotId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List slotIdDescriptor = $convert.base64Decode('CgZTbG90SWQSEgoEc2xvdBgBIAEoBFIEc2xvdBJCCgdibG9ja0lkGAIgASgLMh4uY29tLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2NrSWRCCPpCBYoBAhABUgdibG9ja0lk');
@$core.Deprecated('Use stakingAddressDescriptor instead')
const StakingAddress$json = const {
  '1': 'StakingAddress',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 12, '8': const {}, '10': 'value'},
  ],
};

/// Descriptor for `StakingAddress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingAddressDescriptor = $convert.base64Decode('Cg5TdGFraW5nQWRkcmVzcxIdCgV2YWx1ZRgBIAEoDEIH+kIEegJoIFIFdmFsdWU=');
@$core.Deprecated('Use blockBodyDescriptor instead')
const BlockBody$json = const {
  '1': 'BlockBody',
  '2': const [
    const {'1': 'transactionIds', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionId', '10': 'transactionIds'},
  ],
};

/// Descriptor for `BlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockBodyDescriptor = $convert.base64Decode('CglCbG9ja0JvZHkSTAoOdHJhbnNhY3Rpb25JZHMYASADKAsyJC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25JZFIOdHJhbnNhY3Rpb25JZHM=');
@$core.Deprecated('Use fullBlockBodyDescriptor instead')
const FullBlockBody$json = const {
  '1': 'FullBlockBody',
  '2': const [
    const {'1': 'transactions', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.Transaction', '10': 'transactions'},
  ],
};

/// Descriptor for `FullBlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockBodyDescriptor = $convert.base64Decode('Cg1GdWxsQmxvY2tCb2R5EkYKDHRyYW5zYWN0aW9ucxgBIAMoCzIiLmNvbS5ibG9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvblIMdHJhbnNhY3Rpb25z');
@$core.Deprecated('Use blockDescriptor instead')
const Block$json = const {
  '1': 'Block',
  '2': const [
    const {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockHeader', '8': const {}, '10': 'header'},
    const {'1': 'body', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockBody', '8': const {}, '10': 'body'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode('CgVCbG9jaxJECgZoZWFkZXIYASABKAsyIi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuQmxvY2tIZWFkZXJCCPpCBYoBAhABUgZoZWFkZXISPgoEYm9keRgCIAEoCzIgLmNvbS5ibG9ja2NoYWluLm1vZGVscy5CbG9ja0JvZHlCCPpCBYoBAhABUgRib2R5');
@$core.Deprecated('Use fullBlockDescriptor instead')
const FullBlock$json = const {
  '1': 'FullBlock',
  '2': const [
    const {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockHeader', '8': const {}, '10': 'header'},
    const {'1': 'fullBody', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.FullBlockBody', '8': const {}, '10': 'fullBody'},
  ],
};

/// Descriptor for `FullBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockDescriptor = $convert.base64Decode('CglGdWxsQmxvY2sSRAoGaGVhZGVyGAEgASgLMiIuY29tLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2NrSGVhZGVyQgj6QgWKAQIQAVIGaGVhZGVyEkoKCGZ1bGxCb2R5GAIgASgLMiQuY29tLmJsb2NrY2hhaW4ubW9kZWxzLkZ1bGxCbG9ja0JvZHlCCPpCBYoBAhABUghmdWxsQm9keQ==');
@$core.Deprecated('Use transactionIdDescriptor instead')
const TransactionId$json = const {
  '1': 'TransactionId',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `TransactionId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionIdDescriptor = $convert.base64Decode('Cg1UcmFuc2FjdGlvbklkEhQKBXZhbHVlGAEgASgMUgV2YWx1ZQ==');
@$core.Deprecated('Use transactionDescriptor instead')
const Transaction$json = const {
  '1': 'Transaction',
  '2': const [
    const {'1': 'inputs', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionInput', '10': 'inputs'},
    const {'1': 'outputs', '3': 2, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionOutput', '10': 'outputs'},
    const {'1': 'schedule', '3': 3, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionSchedule', '10': 'schedule'},
  ],
};

/// Descriptor for `Transaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionDescriptor = $convert.base64Decode('CgtUcmFuc2FjdGlvbhI/CgZpbnB1dHMYASADKAsyJy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25JbnB1dFIGaW5wdXRzEkIKB291dHB1dHMYAiADKAsyKC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25PdXRwdXRSB291dHB1dHMSRgoIc2NoZWR1bGUYAyABKAsyKi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25TY2hlZHVsZVIIc2NoZWR1bGU=');
@$core.Deprecated('Use transactionInputDescriptor instead')
const TransactionInput$json = const {
  '1': 'TransactionInput',
  '2': const [
    const {'1': 'reference', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionOutputReference', '10': 'reference'},
    const {'1': 'lock', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Lock', '10': 'lock'},
    const {'1': 'key', '3': 3, '4': 1, '5': 11, '6': '.com.blockchain.models.Key', '10': 'key'},
    const {'1': 'value', '3': 4, '4': 1, '5': 11, '6': '.com.blockchain.models.Value', '10': 'value'},
  ],
};

/// Descriptor for `TransactionInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionInputDescriptor = $convert.base64Decode('ChBUcmFuc2FjdGlvbklucHV0Ek8KCXJlZmVyZW5jZRgBIAEoCzIxLmNvbS5ibG9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZVIJcmVmZXJlbmNlEi8KBGxvY2sYAiABKAsyGy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuTG9ja1IEbG9jaxIsCgNrZXkYAyABKAsyGi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuS2V5UgNrZXkSMgoFdmFsdWUYBCABKAsyHC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVmFsdWVSBXZhbHVl');
@$core.Deprecated('Use transactionOutputReferenceDescriptor instead')
const TransactionOutputReference$json = const {
  '1': 'TransactionOutputReference',
  '2': const [
    const {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionId', '10': 'transactionId'},
    const {'1': 'index', '3': 2, '4': 1, '5': 13, '10': 'index'},
  ],
};

/// Descriptor for `TransactionOutputReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputReferenceDescriptor = $convert.base64Decode('ChpUcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZRJKCg10cmFuc2FjdGlvbklkGAEgASgLMiQuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uSWRSDXRyYW5zYWN0aW9uSWQSFAoFaW5kZXgYAiABKA1SBWluZGV4');
@$core.Deprecated('Use transactionOutputDescriptor instead')
const TransactionOutput$json = const {
  '1': 'TransactionOutput',
  '2': const [
    const {'1': 'lockAddress', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.LockAddress', '10': 'lockAddress'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Value', '10': 'value'},
  ],
};

/// Descriptor for `TransactionOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputDescriptor = $convert.base64Decode('ChFUcmFuc2FjdGlvbk91dHB1dBJECgtsb2NrQWRkcmVzcxgBIAEoCzIiLmNvbS5ibG9ja2NoYWluLm1vZGVscy5Mb2NrQWRkcmVzc1ILbG9ja0FkZHJlc3MSMgoFdmFsdWUYAiABKAsyHC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVmFsdWVSBXZhbHVl');
@$core.Deprecated('Use transactionScheduleDescriptor instead')
const TransactionSchedule$json = const {
  '1': 'TransactionSchedule',
  '2': const [
    const {'1': 'minSlot', '3': 1, '4': 1, '5': 4, '10': 'minSlot'},
    const {'1': 'maxSlot', '3': 2, '4': 1, '5': 4, '10': 'maxSlot'},
    const {'1': 'timestamp', '3': 3, '4': 1, '5': 4, '10': 'timestamp'},
  ],
};

/// Descriptor for `TransactionSchedule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionScheduleDescriptor = $convert.base64Decode('ChNUcmFuc2FjdGlvblNjaGVkdWxlEhgKB21pblNsb3QYASABKARSB21pblNsb3QSGAoHbWF4U2xvdBgCIAEoBFIHbWF4U2xvdBIcCgl0aW1lc3RhbXAYAyABKARSCXRpbWVzdGFtcA==');
@$core.Deprecated('Use valueDescriptor instead')
const Value$json = const {
  '1': 'Value',
  '2': const [
    const {'1': 'paymentToken', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.PaymentToken', '9': 0, '10': 'paymentToken'},
    const {'1': 'stakingToken', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingToken', '9': 0, '10': 'stakingToken'},
  ],
  '8': const [
    const {'1': 'value'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode('CgVWYWx1ZRJJCgxwYXltZW50VG9rZW4YASABKAsyIy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuUGF5bWVudFRva2VuSABSDHBheW1lbnRUb2tlbhJJCgxzdGFraW5nVG9rZW4YAiABKAsyIy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuU3Rha2luZ1Rva2VuSABSDHN0YWtpbmdUb2tlbkIHCgV2YWx1ZQ==');
@$core.Deprecated('Use paymentTokenDescriptor instead')
const PaymentToken$json = const {
  '1': 'PaymentToken',
  '2': const [
    const {'1': 'quantity', '3': 1, '4': 1, '5': 4, '8': const {}, '10': 'quantity'},
  ],
};

/// Descriptor for `PaymentToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List paymentTokenDescriptor = $convert.base64Decode('CgxQYXltZW50VG9rZW4SJAoIcXVhbnRpdHkYASABKARCCPpCBYoBAhABUghxdWFudGl0eQ==');
@$core.Deprecated('Use stakingTokenDescriptor instead')
const StakingToken$json = const {
  '1': 'StakingToken',
  '2': const [
    const {'1': 'quantity', '3': 1, '4': 1, '5': 4, '8': const {}, '10': 'quantity'},
    const {'1': 'registration', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingRegistration', '10': 'registration'},
  ],
};

/// Descriptor for `StakingToken`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingTokenDescriptor = $convert.base64Decode('CgxTdGFraW5nVG9rZW4SJAoIcXVhbnRpdHkYASABKARCCPpCBYoBAhABUghxdWFudGl0eRJOCgxyZWdpc3RyYXRpb24YAiABKAsyKi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuU3Rha2luZ1JlZ2lzdHJhdGlvblIMcmVnaXN0cmF0aW9u');
@$core.Deprecated('Use stakingRegistrationDescriptor instead')
const StakingRegistration$json = const {
  '1': 'StakingRegistration',
  '2': const [
    const {'1': 'registration', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesProduct', '8': const {}, '10': 'registration'},
    const {'1': 'stakingAddress', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingAddress', '8': const {}, '10': 'stakingAddress'},
  ],
};

/// Descriptor for `StakingRegistration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingRegistrationDescriptor = $convert.base64Decode('ChNTdGFraW5nUmVnaXN0cmF0aW9uElgKDHJlZ2lzdHJhdGlvbhgBIAEoCzIqLmNvbS5ibG9ja2NoYWluLm1vZGVscy5TaWduYXR1cmVLZXNQcm9kdWN0Qgj6QgWKAQIQAVIMcmVnaXN0cmF0aW9uElcKDnN0YWtpbmdBZGRyZXNzGAIgASgLMiUuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlN0YWtpbmdBZGRyZXNzQgj6QgWKAQIQAVIOc3Rha2luZ0FkZHJlc3M=');
@$core.Deprecated('Use lockAddressDescriptor instead')
const LockAddress$json = const {
  '1': 'LockAddress',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `LockAddress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockAddressDescriptor = $convert.base64Decode('CgtMb2NrQWRkcmVzcxIUCgV2YWx1ZRgBIAEoDFIFdmFsdWU=');
@$core.Deprecated('Use lockDescriptor instead')
const Lock$json = const {
  '1': 'Lock',
  '2': const [
    const {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Lock.Ed25519', '9': 0, '10': 'ed25519'},
  ],
  '3': const [Lock_Ed25519$json],
  '8': const [
    const {'1': 'value'},
  ],
};

@$core.Deprecated('Use lockDescriptor instead')
const Lock_Ed25519$json = const {
  '1': 'Ed25519',
  '2': const [
    const {'1': 'vk', '3': 1, '4': 1, '5': 12, '10': 'vk'},
  ],
};

/// Descriptor for `Lock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockDescriptor = $convert.base64Decode('CgRMb2NrEj8KB2VkMjU1MTkYASABKAsyIy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuTG9jay5FZDI1NTE5SABSB2VkMjU1MTkaGQoHRWQyNTUxORIOCgJ2axgBIAEoDFICdmtCBwoFdmFsdWU=');
@$core.Deprecated('Use keyDescriptor instead')
const Key$json = const {
  '1': 'Key',
  '2': const [
    const {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Key.Ed25519', '9': 0, '10': 'ed25519'},
  ],
  '3': const [Key_Ed25519$json],
  '8': const [
    const {'1': 'value'},
  ],
};

@$core.Deprecated('Use keyDescriptor instead')
const Key_Ed25519$json = const {
  '1': 'Ed25519',
  '2': const [
    const {'1': 'signature', '3': 1, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode('CgNLZXkSPgoHZWQyNTUxORgBIAEoCzIiLmNvbS5ibG9ja2NoYWluLm1vZGVscy5LZXkuRWQyNTUxOUgAUgdlZDI1NTE5GicKB0VkMjU1MTkSHAoJc2lnbmF0dXJlGAEgASgMUglzaWduYXR1cmVCBwoFdmFsdWU=');
