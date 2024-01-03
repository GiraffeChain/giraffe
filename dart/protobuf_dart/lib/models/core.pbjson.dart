//
//  Generated code. Do not modify.
//  source: models/core.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use blockIdDescriptor instead')
const BlockId$json = {
  '1': 'BlockId',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `BlockId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockIdDescriptor = $convert.base64Decode(
    'CgdCbG9ja0lkEhQKBXZhbHVlGAEgASgMUgV2YWx1ZQ==');

@$core.Deprecated('Use blockHeaderDescriptor instead')
const BlockHeader$json = {
  '1': 'BlockHeader',
  '2': [
    {'1': 'headerId', '3': 12, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'headerId'},
    {'1': 'parentHeaderId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '8': {}, '10': 'parentHeaderId'},
    {'1': 'parentSlot', '3': 2, '4': 1, '5': 4, '10': 'parentSlot'},
    {'1': 'txRoot', '3': 3, '4': 1, '5': 12, '8': {}, '10': 'txRoot'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 4, '10': 'timestamp'},
    {'1': 'height', '3': 5, '4': 1, '5': 4, '10': 'height'},
    {'1': 'slot', '3': 6, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'eligibilityCertificate', '3': 7, '4': 1, '5': 11, '6': '.com.blockchain.models.EligibilityCertificate', '8': {}, '10': 'eligibilityCertificate'},
    {'1': 'operationalCertificate', '3': 8, '4': 1, '5': 11, '6': '.com.blockchain.models.OperationalCertificate', '8': {}, '10': 'operationalCertificate'},
    {'1': 'metadata', '3': 9, '4': 1, '5': 12, '8': {}, '10': 'metadata'},
    {'1': 'address', '3': 10, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingAddress', '8': {}, '10': 'address'},
    {'1': 'settings', '3': 11, '4': 3, '5': 11, '6': '.com.blockchain.models.BlockHeader.SettingsEntry', '10': 'settings'},
  ],
  '3': [BlockHeader_SettingsEntry$json],
};

@$core.Deprecated('Use blockHeaderDescriptor instead')
const BlockHeader_SettingsEntry$json = {
  '1': 'SettingsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `BlockHeader`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockHeaderDescriptor = $convert.base64Decode(
    'CgtCbG9ja0hlYWRlchI6CghoZWFkZXJJZBgMIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZGVscy'
    '5CbG9ja0lkUghoZWFkZXJJZBJQCg5wYXJlbnRIZWFkZXJJZBgBIAEoCzIeLmNvbS5ibG9ja2No'
    'YWluLm1vZGVscy5CbG9ja0lkQgj6QgWKAQIQAVIOcGFyZW50SGVhZGVySWQSHgoKcGFyZW50U2'
    'xvdBgCIAEoBFIKcGFyZW50U2xvdBIfCgZ0eFJvb3QYAyABKAxCB/pCBHoCaCBSBnR4Um9vdBIc'
    'Cgl0aW1lc3RhbXAYBCABKARSCXRpbWVzdGFtcBIWCgZoZWlnaHQYBSABKARSBmhlaWdodBISCg'
    'RzbG90GAYgASgEUgRzbG90Em8KFmVsaWdpYmlsaXR5Q2VydGlmaWNhdGUYByABKAsyLS5jb20u'
    'YmxvY2tjaGFpbi5tb2RlbHMuRWxpZ2liaWxpdHlDZXJ0aWZpY2F0ZUII+kIFigECEAFSFmVsaW'
    'dpYmlsaXR5Q2VydGlmaWNhdGUSbwoWb3BlcmF0aW9uYWxDZXJ0aWZpY2F0ZRgIIAEoCzItLmNv'
    'bS5ibG9ja2NoYWluLm1vZGVscy5PcGVyYXRpb25hbENlcnRpZmljYXRlQgj6QgWKAQIQAVIWb3'
    'BlcmF0aW9uYWxDZXJ0aWZpY2F0ZRIjCghtZXRhZGF0YRgJIAEoDEIH+kIEegIYIFIIbWV0YWRh'
    'dGESSQoHYWRkcmVzcxgKIAEoCzIlLmNvbS5ibG9ja2NoYWluLm1vZGVscy5TdGFraW5nQWRkcm'
    'Vzc0II+kIFigECEAFSB2FkZHJlc3MSTAoIc2V0dGluZ3MYCyADKAsyMC5jb20uYmxvY2tjaGFp'
    'bi5tb2RlbHMuQmxvY2tIZWFkZXIuU2V0dGluZ3NFbnRyeVIIc2V0dGluZ3MaOwoNU2V0dGluZ3'
    'NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use eligibilityCertificateDescriptor instead')
const EligibilityCertificate$json = {
  '1': 'EligibilityCertificate',
  '2': [
    {'1': 'vrfSig', '3': 1, '4': 1, '5': 12, '8': {}, '10': 'vrfSig'},
    {'1': 'vrfVK', '3': 2, '4': 1, '5': 12, '8': {}, '10': 'vrfVK'},
    {'1': 'thresholdEvidence', '3': 3, '4': 1, '5': 12, '8': {}, '10': 'thresholdEvidence'},
    {'1': 'eta', '3': 4, '4': 1, '5': 12, '8': {}, '10': 'eta'},
  ],
};

/// Descriptor for `EligibilityCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eligibilityCertificateDescriptor = $convert.base64Decode(
    'ChZFbGlnaWJpbGl0eUNlcnRpZmljYXRlEh8KBnZyZlNpZxgBIAEoDEIH+kIEegJoUFIGdnJmU2'
    'lnEh0KBXZyZlZLGAIgASgMQgf6QgR6AmggUgV2cmZWSxI1ChF0aHJlc2hvbGRFdmlkZW5jZRgD'
    'IAEoDEIH+kIEegJoIFIRdGhyZXNob2xkRXZpZGVuY2USGQoDZXRhGAQgASgMQgf6QgR6AmggUg'
    'NldGE=');

@$core.Deprecated('Use operationalCertificateDescriptor instead')
const OperationalCertificate$json = {
  '1': 'OperationalCertificate',
  '2': [
    {'1': 'parentVK', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.VerificationKeyKesProduct', '8': {}, '10': 'parentVK'},
    {'1': 'parentSignature', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesProduct', '8': {}, '10': 'parentSignature'},
    {'1': 'childVK', '3': 3, '4': 1, '5': 12, '8': {}, '10': 'childVK'},
    {'1': 'childSignature', '3': 4, '4': 1, '5': 12, '8': {}, '10': 'childSignature'},
  ],
};

/// Descriptor for `OperationalCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operationalCertificateDescriptor = $convert.base64Decode(
    'ChZPcGVyYXRpb25hbENlcnRpZmljYXRlElYKCHBhcmVudFZLGAEgASgLMjAuY29tLmJsb2NrY2'
    'hhaW4ubW9kZWxzLlZlcmlmaWNhdGlvbktleUtlc1Byb2R1Y3RCCPpCBYoBAhABUghwYXJlbnRW'
    'SxJeCg9wYXJlbnRTaWduYXR1cmUYAiABKAsyKi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuU2lnbm'
    'F0dXJlS2VzUHJvZHVjdEII+kIFigECEAFSD3BhcmVudFNpZ25hdHVyZRIhCgdjaGlsZFZLGAMg'
    'ASgMQgf6QgR6AmggUgdjaGlsZFZLEi8KDmNoaWxkU2lnbmF0dXJlGAQgASgMQgf6QgR6AmhAUg'
    '5jaGlsZFNpZ25hdHVyZQ==');

@$core.Deprecated('Use verificationKeyKesProductDescriptor instead')
const VerificationKeyKesProduct$json = {
  '1': 'VerificationKeyKesProduct',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '8': {}, '10': 'value'},
    {'1': 'step', '3': 2, '4': 1, '5': 13, '10': 'step'},
  ],
};

/// Descriptor for `VerificationKeyKesProduct`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verificationKeyKesProductDescriptor = $convert.base64Decode(
    'ChlWZXJpZmljYXRpb25LZXlLZXNQcm9kdWN0Eh0KBXZhbHVlGAEgASgMQgf6QgR6AmggUgV2YW'
    'x1ZRISCgRzdGVwGAIgASgNUgRzdGVw');

@$core.Deprecated('Use signatureKesSumDescriptor instead')
const SignatureKesSum$json = {
  '1': 'SignatureKesSum',
  '2': [
    {'1': 'verificationKey', '3': 1, '4': 1, '5': 12, '8': {}, '10': 'verificationKey'},
    {'1': 'signature', '3': 2, '4': 1, '5': 12, '8': {}, '10': 'signature'},
    {'1': 'witness', '3': 3, '4': 3, '5': 12, '8': {}, '10': 'witness'},
  ],
};

/// Descriptor for `SignatureKesSum`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signatureKesSumDescriptor = $convert.base64Decode(
    'Cg9TaWduYXR1cmVLZXNTdW0SMQoPdmVyaWZpY2F0aW9uS2V5GAEgASgMQgf6QgR6AmggUg92ZX'
    'JpZmljYXRpb25LZXkSJQoJc2lnbmF0dXJlGAIgASgMQgf6QgR6AmhAUglzaWduYXR1cmUSJgoH'
    'd2l0bmVzcxgDIAMoDEIM+kIJkgEGIgR6AmggUgd3aXRuZXNz');

@$core.Deprecated('Use signatureKesProductDescriptor instead')
const SignatureKesProduct$json = {
  '1': 'SignatureKesProduct',
  '2': [
    {'1': 'superSignature', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesSum', '8': {}, '10': 'superSignature'},
    {'1': 'subSignature', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesSum', '8': {}, '10': 'subSignature'},
    {'1': 'subRoot', '3': 3, '4': 1, '5': 12, '8': {}, '10': 'subRoot'},
  ],
};

/// Descriptor for `SignatureKesProduct`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signatureKesProductDescriptor = $convert.base64Decode(
    'ChNTaWduYXR1cmVLZXNQcm9kdWN0ElgKDnN1cGVyU2lnbmF0dXJlGAEgASgLMiYuY29tLmJsb2'
    'NrY2hhaW4ubW9kZWxzLlNpZ25hdHVyZUtlc1N1bUII+kIFigECEAFSDnN1cGVyU2lnbmF0dXJl'
    'ElQKDHN1YlNpZ25hdHVyZRgCIAEoCzImLmNvbS5ibG9ja2NoYWluLm1vZGVscy5TaWduYXR1cm'
    'VLZXNTdW1CCPpCBYoBAhABUgxzdWJTaWduYXR1cmUSIQoHc3ViUm9vdBgDIAEoDEIH+kIEegJo'
    'IFIHc3ViUm9vdA==');

@$core.Deprecated('Use slotDataDescriptor instead')
const SlotData$json = {
  '1': 'SlotData',
  '2': [
    {'1': 'slotId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.SlotId', '8': {}, '10': 'slotId'},
    {'1': 'parentSlotId', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.SlotId', '8': {}, '10': 'parentSlotId'},
    {'1': 'rho', '3': 3, '4': 1, '5': 12, '8': {}, '10': 'rho'},
    {'1': 'eta', '3': 4, '4': 1, '5': 12, '8': {}, '10': 'eta'},
    {'1': 'height', '3': 5, '4': 1, '5': 4, '10': 'height'},
  ],
};

/// Descriptor for `SlotData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List slotDataDescriptor = $convert.base64Decode(
    'CghTbG90RGF0YRI/CgZzbG90SWQYASABKAsyHS5jb20uYmxvY2tjaGFpbi5tb2RlbHMuU2xvdE'
    'lkQgj6QgWKAQIQAVIGc2xvdElkEksKDHBhcmVudFNsb3RJZBgCIAEoCzIdLmNvbS5ibG9ja2No'
    'YWluLm1vZGVscy5TbG90SWRCCPpCBYoBAhABUgxwYXJlbnRTbG90SWQSGQoDcmhvGAMgASgMQg'
    'f6QgR6AmhAUgNyaG8SGQoDZXRhGAQgASgMQgf6QgR6AmggUgNldGESFgoGaGVpZ2h0GAUgASgE'
    'UgZoZWlnaHQ=');

@$core.Deprecated('Use slotIdDescriptor instead')
const SlotId$json = {
  '1': 'SlotId',
  '2': [
    {'1': 'slot', '3': 1, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'blockId', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '8': {}, '10': 'blockId'},
  ],
};

/// Descriptor for `SlotId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List slotIdDescriptor = $convert.base64Decode(
    'CgZTbG90SWQSEgoEc2xvdBgBIAEoBFIEc2xvdBJCCgdibG9ja0lkGAIgASgLMh4uY29tLmJsb2'
    'NrY2hhaW4ubW9kZWxzLkJsb2NrSWRCCPpCBYoBAhABUgdibG9ja0lk');

@$core.Deprecated('Use stakingAddressDescriptor instead')
const StakingAddress$json = {
  '1': 'StakingAddress',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '8': {}, '10': 'value'},
  ],
};

/// Descriptor for `StakingAddress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingAddressDescriptor = $convert.base64Decode(
    'Cg5TdGFraW5nQWRkcmVzcxIdCgV2YWx1ZRgBIAEoDEIH+kIEegJoIFIFdmFsdWU=');

@$core.Deprecated('Use blockBodyDescriptor instead')
const BlockBody$json = {
  '1': 'BlockBody',
  '2': [
    {'1': 'transactionIds', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionId', '10': 'transactionIds'},
  ],
};

/// Descriptor for `BlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockBodyDescriptor = $convert.base64Decode(
    'CglCbG9ja0JvZHkSTAoOdHJhbnNhY3Rpb25JZHMYASADKAsyJC5jb20uYmxvY2tjaGFpbi5tb2'
    'RlbHMuVHJhbnNhY3Rpb25JZFIOdHJhbnNhY3Rpb25JZHM=');

@$core.Deprecated('Use fullBlockBodyDescriptor instead')
const FullBlockBody$json = {
  '1': 'FullBlockBody',
  '2': [
    {'1': 'transactions', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.Transaction', '10': 'transactions'},
  ],
};

/// Descriptor for `FullBlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockBodyDescriptor = $convert.base64Decode(
    'Cg1GdWxsQmxvY2tCb2R5EkYKDHRyYW5zYWN0aW9ucxgBIAMoCzIiLmNvbS5ibG9ja2NoYWluLm'
    '1vZGVscy5UcmFuc2FjdGlvblIMdHJhbnNhY3Rpb25z');

@$core.Deprecated('Use blockDescriptor instead')
const Block$json = {
  '1': 'Block',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'body', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockBody', '8': {}, '10': 'body'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode(
    'CgVCbG9jaxJECgZoZWFkZXIYASABKAsyIi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuQmxvY2tIZW'
    'FkZXJCCPpCBYoBAhABUgZoZWFkZXISPgoEYm9keRgCIAEoCzIgLmNvbS5ibG9ja2NoYWluLm1v'
    'ZGVscy5CbG9ja0JvZHlCCPpCBYoBAhABUgRib2R5');

@$core.Deprecated('Use fullBlockDescriptor instead')
const FullBlock$json = {
  '1': 'FullBlock',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'fullBody', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.FullBlockBody', '8': {}, '10': 'fullBody'},
  ],
};

/// Descriptor for `FullBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockDescriptor = $convert.base64Decode(
    'CglGdWxsQmxvY2sSRAoGaGVhZGVyGAEgASgLMiIuY29tLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2'
    'NrSGVhZGVyQgj6QgWKAQIQAVIGaGVhZGVyEkoKCGZ1bGxCb2R5GAIgASgLMiQuY29tLmJsb2Nr'
    'Y2hhaW4ubW9kZWxzLkZ1bGxCbG9ja0JvZHlCCPpCBYoBAhABUghmdWxsQm9keQ==');

@$core.Deprecated('Use transactionIdDescriptor instead')
const TransactionId$json = {
  '1': 'TransactionId',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `TransactionId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionIdDescriptor = $convert.base64Decode(
    'Cg1UcmFuc2FjdGlvbklkEhQKBXZhbHVlGAEgASgMUgV2YWx1ZQ==');

@$core.Deprecated('Use transactionDescriptor instead')
const Transaction$json = {
  '1': 'Transaction',
  '2': [
    {'1': 'inputs', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionInput', '10': 'inputs'},
    {'1': 'outputs', '3': 2, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionOutput', '10': 'outputs'},
  ],
};

/// Descriptor for `Transaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionDescriptor = $convert.base64Decode(
    'CgtUcmFuc2FjdGlvbhI/CgZpbnB1dHMYASADKAsyJy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVH'
    'JhbnNhY3Rpb25JbnB1dFIGaW5wdXRzEkIKB291dHB1dHMYAiADKAsyKC5jb20uYmxvY2tjaGFp'
    'bi5tb2RlbHMuVHJhbnNhY3Rpb25PdXRwdXRSB291dHB1dHM=');

@$core.Deprecated('Use transactionInputDescriptor instead')
const TransactionInput$json = {
  '1': 'TransactionInput',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionOutputReference', '10': 'reference'},
    {'1': 'lock', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Lock', '10': 'lock'},
    {'1': 'key', '3': 3, '4': 1, '5': 11, '6': '.com.blockchain.models.Key', '10': 'key'},
    {'1': 'value', '3': 4, '4': 1, '5': 11, '6': '.com.blockchain.models.Value', '10': 'value'},
  ],
};

/// Descriptor for `TransactionInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionInputDescriptor = $convert.base64Decode(
    'ChBUcmFuc2FjdGlvbklucHV0Ek8KCXJlZmVyZW5jZRgBIAEoCzIxLmNvbS5ibG9ja2NoYWluLm'
    '1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZVIJcmVmZXJlbmNlEi8KBGxvY2sYAiAB'
    'KAsyGy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuTG9ja1IEbG9jaxIsCgNrZXkYAyABKAsyGi5jb2'
    '0uYmxvY2tjaGFpbi5tb2RlbHMuS2V5UgNrZXkSMgoFdmFsdWUYBCABKAsyHC5jb20uYmxvY2tj'
    'aGFpbi5tb2RlbHMuVmFsdWVSBXZhbHVl');

@$core.Deprecated('Use transactionOutputReferenceDescriptor instead')
const TransactionOutputReference$json = {
  '1': 'TransactionOutputReference',
  '2': [
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionId', '10': 'transactionId'},
    {'1': 'index', '3': 2, '4': 1, '5': 13, '10': 'index'},
  ],
};

/// Descriptor for `TransactionOutputReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputReferenceDescriptor = $convert.base64Decode(
    'ChpUcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZRJKCg10cmFuc2FjdGlvbklkGAEgASgLMiQuY2'
    '9tLmJsb2NrY2hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uSWRSDXRyYW5zYWN0aW9uSWQSFAoFaW5k'
    'ZXgYAiABKA1SBWluZGV4');

@$core.Deprecated('Use transactionOutputDescriptor instead')
const TransactionOutput$json = {
  '1': 'TransactionOutput',
  '2': [
    {'1': 'lockAddress', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.LockAddress', '10': 'lockAddress'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Value', '10': 'value'},
  ],
};

/// Descriptor for `TransactionOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputDescriptor = $convert.base64Decode(
    'ChFUcmFuc2FjdGlvbk91dHB1dBJECgtsb2NrQWRkcmVzcxgBIAEoCzIiLmNvbS5ibG9ja2NoYW'
    'luLm1vZGVscy5Mb2NrQWRkcmVzc1ILbG9ja0FkZHJlc3MSMgoFdmFsdWUYAiABKAsyHC5jb20u'
    'YmxvY2tjaGFpbi5tb2RlbHMuVmFsdWVSBXZhbHVl');

@$core.Deprecated('Use valueDescriptor instead')
const Value$json = {
  '1': 'Value',
  '2': [
    {'1': 'quantity', '3': 1, '4': 1, '5': 4, '8': {}, '10': 'quantity'},
    {'1': 'registration', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingRegistration', '10': 'registration'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode(
    'CgVWYWx1ZRIkCghxdWFudGl0eRgBIAEoBEII+kIFigECEAFSCHF1YW50aXR5Ek4KDHJlZ2lzdH'
    'JhdGlvbhgCIAEoCzIqLmNvbS5ibG9ja2NoYWluLm1vZGVscy5TdGFraW5nUmVnaXN0cmF0aW9u'
    'UgxyZWdpc3RyYXRpb24=');

@$core.Deprecated('Use stakingRegistrationDescriptor instead')
const StakingRegistration$json = {
  '1': 'StakingRegistration',
  '2': [
    {'1': 'signature', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.SignatureKesProduct', '8': {}, '10': 'signature'},
    {'1': 'stakingAddress', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingAddress', '8': {}, '10': 'stakingAddress'},
  ],
};

/// Descriptor for `StakingRegistration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingRegistrationDescriptor = $convert.base64Decode(
    'ChNTdGFraW5nUmVnaXN0cmF0aW9uElIKCXNpZ25hdHVyZRgBIAEoCzIqLmNvbS5ibG9ja2NoYW'
    'luLm1vZGVscy5TaWduYXR1cmVLZXNQcm9kdWN0Qgj6QgWKAQIQAVIJc2lnbmF0dXJlElcKDnN0'
    'YWtpbmdBZGRyZXNzGAIgASgLMiUuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlN0YWtpbmdBZGRyZX'
    'NzQgj6QgWKAQIQAVIOc3Rha2luZ0FkZHJlc3M=');

@$core.Deprecated('Use activeStakerDescriptor instead')
const ActiveStaker$json = {
  '1': 'ActiveStaker',
  '2': [
    {'1': 'registration', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingRegistration', '8': {}, '10': 'registration'},
    {'1': 'quantity', '3': 3, '4': 1, '5': 3, '8': {}, '10': 'quantity'},
  ],
};

/// Descriptor for `ActiveStaker`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeStakerDescriptor = $convert.base64Decode(
    'CgxBY3RpdmVTdGFrZXISWAoMcmVnaXN0cmF0aW9uGAEgASgLMiouY29tLmJsb2NrY2hhaW4ubW'
    '9kZWxzLlN0YWtpbmdSZWdpc3RyYXRpb25CCPpCBYoBAhABUgxyZWdpc3RyYXRpb24SJAoIcXVh'
    'bnRpdHkYAyABKANCCPpCBYoBAhABUghxdWFudGl0eQ==');

@$core.Deprecated('Use lockAddressDescriptor instead')
const LockAddress$json = {
  '1': 'LockAddress',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '10': 'value'},
  ],
};

/// Descriptor for `LockAddress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockAddressDescriptor = $convert.base64Decode(
    'CgtMb2NrQWRkcmVzcxIUCgV2YWx1ZRgBIAEoDFIFdmFsdWU=');

@$core.Deprecated('Use lockDescriptor instead')
const Lock$json = {
  '1': 'Lock',
  '2': [
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Lock.Ed25519', '9': 0, '10': 'ed25519'},
  ],
  '3': [Lock_Ed25519$json],
  '8': [
    {'1': 'value'},
  ],
};

@$core.Deprecated('Use lockDescriptor instead')
const Lock_Ed25519$json = {
  '1': 'Ed25519',
  '2': [
    {'1': 'vk', '3': 1, '4': 1, '5': 12, '10': 'vk'},
  ],
};

/// Descriptor for `Lock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockDescriptor = $convert.base64Decode(
    'CgRMb2NrEj8KB2VkMjU1MTkYASABKAsyIy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuTG9jay5FZD'
    'I1NTE5SABSB2VkMjU1MTkaGQoHRWQyNTUxORIOCgJ2axgBIAEoDFICdmtCBwoFdmFsdWU=');

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Key.Ed25519', '9': 0, '10': 'ed25519'},
  ],
  '3': [Key_Ed25519$json],
  '8': [
    {'1': 'value'},
  ],
};

@$core.Deprecated('Use keyDescriptor instead')
const Key_Ed25519$json = {
  '1': 'Ed25519',
  '2': [
    {'1': 'signature', '3': 1, '4': 1, '5': 12, '10': 'signature'},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode(
    'CgNLZXkSPgoHZWQyNTUxORgBIAEoCzIiLmNvbS5ibG9ja2NoYWluLm1vZGVscy5LZXkuRWQyNT'
    'UxOUgAUgdlZDI1NTE5GicKB0VkMjU1MTkSHAoJc2lnbmF0dXJlGAEgASgMUglzaWduYXR1cmVC'
    'BwoFdmFsdWU=');

@$core.Deprecated('Use peerIdDescriptor instead')
const PeerId$json = {
  '1': 'PeerId',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 12, '8': {}, '10': 'value'},
  ],
};

/// Descriptor for `PeerId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List peerIdDescriptor = $convert.base64Decode(
    'CgZQZWVySWQSHQoFdmFsdWUYASABKAxCB/pCBHoCaCBSBXZhbHVl');

@$core.Deprecated('Use publicP2PStateDescriptor instead')
const PublicP2PState$json = {
  '1': 'PublicP2PState',
  '2': [
    {'1': 'localPeer', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.ConnectedPeer', '10': 'localPeer'},
    {'1': 'peers', '3': 2, '4': 3, '5': 11, '6': '.com.blockchain.models.ConnectedPeer', '10': 'peers'},
  ],
};

/// Descriptor for `PublicP2PState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publicP2PStateDescriptor = $convert.base64Decode(
    'Cg5QdWJsaWNQMlBTdGF0ZRJCCglsb2NhbFBlZXIYASABKAsyJC5jb20uYmxvY2tjaGFpbi5tb2'
    'RlbHMuQ29ubmVjdGVkUGVlclIJbG9jYWxQZWVyEjoKBXBlZXJzGAIgAygLMiQuY29tLmJsb2Nr'
    'Y2hhaW4ubW9kZWxzLkNvbm5lY3RlZFBlZXJSBXBlZXJz');

@$core.Deprecated('Use connectedPeerDescriptor instead')
const ConnectedPeer$json = {
  '1': 'ConnectedPeer',
  '2': [
    {'1': 'peerId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.PeerId', '10': 'peerId'},
    {'1': 'host', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.StringValue', '10': 'host'},
    {'1': 'port', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'port'},
  ],
};

/// Descriptor for `ConnectedPeer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectedPeerDescriptor = $convert.base64Decode(
    'Cg1Db25uZWN0ZWRQZWVyEjUKBnBlZXJJZBgBIAEoCzIdLmNvbS5ibG9ja2NoYWluLm1vZGVscy'
    '5QZWVySWRSBnBlZXJJZBIwCgRob3N0GAIgASgLMhwuZ29vZ2xlLnByb3RvYnVmLlN0cmluZ1Zh'
    'bHVlUgRob3N0EjAKBHBvcnQYAyABKAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVmFsdWVSBH'
    'BvcnQ=');

