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
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `BlockId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockIdDescriptor = $convert.base64Decode(
    'CgdCbG9ja0lkEhQKBXZhbHVlGAEgASgJUgV2YWx1ZQ==');

@$core.Deprecated('Use blockHeaderDescriptor instead')
const BlockHeader$json = {
  '1': 'BlockHeader',
  '2': [
    {'1': 'headerId', '3': 12, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '10': 'headerId'},
    {'1': 'parentHeaderId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '8': {}, '10': 'parentHeaderId'},
    {'1': 'parentSlot', '3': 2, '4': 1, '5': 4, '10': 'parentSlot'},
    {'1': 'txRoot', '3': 3, '4': 1, '5': 9, '10': 'txRoot'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 4, '10': 'timestamp'},
    {'1': 'height', '3': 5, '4': 1, '5': 4, '10': 'height'},
    {'1': 'slot', '3': 6, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'eligibilityCertificate', '3': 7, '4': 1, '5': 11, '6': '.blockchain.models.EligibilityCertificate', '8': {}, '10': 'eligibilityCertificate'},
    {'1': 'operationalCertificate', '3': 8, '4': 1, '5': 11, '6': '.blockchain.models.OperationalCertificate', '8': {}, '10': 'operationalCertificate'},
    {'1': 'metadata', '3': 9, '4': 1, '5': 9, '10': 'metadata'},
    {'1': 'account', '3': 10, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '8': {}, '10': 'account'},
    {'1': 'settings', '3': 11, '4': 3, '5': 11, '6': '.blockchain.models.BlockHeader.SettingsEntry', '10': 'settings'},
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
    'CgtCbG9ja0hlYWRlchI2CghoZWFkZXJJZBgMIAEoCzIaLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2'
    'NrSWRSCGhlYWRlcklkEkwKDnBhcmVudEhlYWRlcklkGAEgASgLMhouYmxvY2tjaGFpbi5tb2Rl'
    'bHMuQmxvY2tJZEII+kIFigECEAFSDnBhcmVudEhlYWRlcklkEh4KCnBhcmVudFNsb3QYAiABKA'
    'RSCnBhcmVudFNsb3QSFgoGdHhSb290GAMgASgJUgZ0eFJvb3QSHAoJdGltZXN0YW1wGAQgASgE'
    'Ugl0aW1lc3RhbXASFgoGaGVpZ2h0GAUgASgEUgZoZWlnaHQSEgoEc2xvdBgGIAEoBFIEc2xvdB'
    'JrChZlbGlnaWJpbGl0eUNlcnRpZmljYXRlGAcgASgLMikuYmxvY2tjaGFpbi5tb2RlbHMuRWxp'
    'Z2liaWxpdHlDZXJ0aWZpY2F0ZUII+kIFigECEAFSFmVsaWdpYmlsaXR5Q2VydGlmaWNhdGUSaw'
    'oWb3BlcmF0aW9uYWxDZXJ0aWZpY2F0ZRgIIAEoCzIpLmJsb2NrY2hhaW4ubW9kZWxzLk9wZXJh'
    'dGlvbmFsQ2VydGlmaWNhdGVCCPpCBYoBAhABUhZvcGVyYXRpb25hbENlcnRpZmljYXRlEhoKCG'
    '1ldGFkYXRhGAkgASgJUghtZXRhZGF0YRJRCgdhY2NvdW50GAogASgLMi0uYmxvY2tjaGFpbi5t'
    'b2RlbHMuVHJhbnNhY3Rpb25PdXRwdXRSZWZlcmVuY2VCCPpCBYoBAhABUgdhY2NvdW50EkgKCH'
    'NldHRpbmdzGAsgAygLMiwuYmxvY2tjaGFpbi5tb2RlbHMuQmxvY2tIZWFkZXIuU2V0dGluZ3NF'
    'bnRyeVIIc2V0dGluZ3MaOwoNU2V0dGluZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YW'
    'x1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use eligibilityCertificateDescriptor instead')
const EligibilityCertificate$json = {
  '1': 'EligibilityCertificate',
  '2': [
    {'1': 'vrfSig', '3': 1, '4': 1, '5': 9, '10': 'vrfSig'},
    {'1': 'vrfVK', '3': 2, '4': 1, '5': 9, '10': 'vrfVK'},
    {'1': 'thresholdEvidence', '3': 3, '4': 1, '5': 9, '10': 'thresholdEvidence'},
    {'1': 'eta', '3': 4, '4': 1, '5': 9, '10': 'eta'},
  ],
};

/// Descriptor for `EligibilityCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eligibilityCertificateDescriptor = $convert.base64Decode(
    'ChZFbGlnaWJpbGl0eUNlcnRpZmljYXRlEhYKBnZyZlNpZxgBIAEoCVIGdnJmU2lnEhQKBXZyZl'
    'ZLGAIgASgJUgV2cmZWSxIsChF0aHJlc2hvbGRFdmlkZW5jZRgDIAEoCVIRdGhyZXNob2xkRXZp'
    'ZGVuY2USEAoDZXRhGAQgASgJUgNldGE=');

@$core.Deprecated('Use operationalCertificateDescriptor instead')
const OperationalCertificate$json = {
  '1': 'OperationalCertificate',
  '2': [
    {'1': 'parentVK', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.VerificationKeyKesProduct', '8': {}, '10': 'parentVK'},
    {'1': 'parentSignature', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.SignatureKesProduct', '8': {}, '10': 'parentSignature'},
    {'1': 'childVK', '3': 3, '4': 1, '5': 9, '10': 'childVK'},
    {'1': 'childSignature', '3': 4, '4': 1, '5': 9, '10': 'childSignature'},
  ],
};

/// Descriptor for `OperationalCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operationalCertificateDescriptor = $convert.base64Decode(
    'ChZPcGVyYXRpb25hbENlcnRpZmljYXRlElIKCHBhcmVudFZLGAEgASgLMiwuYmxvY2tjaGFpbi'
    '5tb2RlbHMuVmVyaWZpY2F0aW9uS2V5S2VzUHJvZHVjdEII+kIFigECEAFSCHBhcmVudFZLEloK'
    'D3BhcmVudFNpZ25hdHVyZRgCIAEoCzImLmJsb2NrY2hhaW4ubW9kZWxzLlNpZ25hdHVyZUtlc1'
    'Byb2R1Y3RCCPpCBYoBAhABUg9wYXJlbnRTaWduYXR1cmUSGAoHY2hpbGRWSxgDIAEoCVIHY2hp'
    'bGRWSxImCg5jaGlsZFNpZ25hdHVyZRgEIAEoCVIOY2hpbGRTaWduYXR1cmU=');

@$core.Deprecated('Use verificationKeyKesProductDescriptor instead')
const VerificationKeyKesProduct$json = {
  '1': 'VerificationKeyKesProduct',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
    {'1': 'step', '3': 2, '4': 1, '5': 13, '10': 'step'},
  ],
};

/// Descriptor for `VerificationKeyKesProduct`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List verificationKeyKesProductDescriptor = $convert.base64Decode(
    'ChlWZXJpZmljYXRpb25LZXlLZXNQcm9kdWN0EhQKBXZhbHVlGAEgASgJUgV2YWx1ZRISCgRzdG'
    'VwGAIgASgNUgRzdGVw');

@$core.Deprecated('Use signatureKesSumDescriptor instead')
const SignatureKesSum$json = {
  '1': 'SignatureKesSum',
  '2': [
    {'1': 'verificationKey', '3': 1, '4': 1, '5': 9, '10': 'verificationKey'},
    {'1': 'signature', '3': 2, '4': 1, '5': 9, '10': 'signature'},
    {'1': 'witness', '3': 3, '4': 3, '5': 9, '10': 'witness'},
  ],
};

/// Descriptor for `SignatureKesSum`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signatureKesSumDescriptor = $convert.base64Decode(
    'Cg9TaWduYXR1cmVLZXNTdW0SKAoPdmVyaWZpY2F0aW9uS2V5GAEgASgJUg92ZXJpZmljYXRpb2'
    '5LZXkSHAoJc2lnbmF0dXJlGAIgASgJUglzaWduYXR1cmUSGAoHd2l0bmVzcxgDIAMoCVIHd2l0'
    'bmVzcw==');

@$core.Deprecated('Use signatureKesProductDescriptor instead')
const SignatureKesProduct$json = {
  '1': 'SignatureKesProduct',
  '2': [
    {'1': 'superSignature', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.SignatureKesSum', '8': {}, '10': 'superSignature'},
    {'1': 'subSignature', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.SignatureKesSum', '8': {}, '10': 'subSignature'},
    {'1': 'subRoot', '3': 3, '4': 1, '5': 9, '10': 'subRoot'},
  ],
};

/// Descriptor for `SignatureKesProduct`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List signatureKesProductDescriptor = $convert.base64Decode(
    'ChNTaWduYXR1cmVLZXNQcm9kdWN0ElQKDnN1cGVyU2lnbmF0dXJlGAEgASgLMiIuYmxvY2tjaG'
    'Fpbi5tb2RlbHMuU2lnbmF0dXJlS2VzU3VtQgj6QgWKAQIQAVIOc3VwZXJTaWduYXR1cmUSUAoM'
    'c3ViU2lnbmF0dXJlGAIgASgLMiIuYmxvY2tjaGFpbi5tb2RlbHMuU2lnbmF0dXJlS2VzU3VtQg'
    'j6QgWKAQIQAVIMc3ViU2lnbmF0dXJlEhgKB3N1YlJvb3QYAyABKAlSB3N1YlJvb3Q=');

@$core.Deprecated('Use slotIdDescriptor instead')
const SlotId$json = {
  '1': 'SlotId',
  '2': [
    {'1': 'slot', '3': 1, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'blockId', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '8': {}, '10': 'blockId'},
  ],
};

/// Descriptor for `SlotId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List slotIdDescriptor = $convert.base64Decode(
    'CgZTbG90SWQSEgoEc2xvdBgBIAEoBFIEc2xvdBI+CgdibG9ja0lkGAIgASgLMhouYmxvY2tjaG'
    'Fpbi5tb2RlbHMuQmxvY2tJZEII+kIFigECEAFSB2Jsb2NrSWQ=');

@$core.Deprecated('Use stakingAddressDescriptor instead')
const StakingAddress$json = {
  '1': 'StakingAddress',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `StakingAddress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingAddressDescriptor = $convert.base64Decode(
    'Cg5TdGFraW5nQWRkcmVzcxIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');

@$core.Deprecated('Use blockBodyDescriptor instead')
const BlockBody$json = {
  '1': 'BlockBody',
  '2': [
    {'1': 'transactionIds', '3': 1, '4': 3, '5': 11, '6': '.blockchain.models.TransactionId', '10': 'transactionIds'},
  ],
};

/// Descriptor for `BlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockBodyDescriptor = $convert.base64Decode(
    'CglCbG9ja0JvZHkSSAoOdHJhbnNhY3Rpb25JZHMYASADKAsyIC5ibG9ja2NoYWluLm1vZGVscy'
    '5UcmFuc2FjdGlvbklkUg50cmFuc2FjdGlvbklkcw==');

@$core.Deprecated('Use fullBlockBodyDescriptor instead')
const FullBlockBody$json = {
  '1': 'FullBlockBody',
  '2': [
    {'1': 'transactions', '3': 1, '4': 3, '5': 11, '6': '.blockchain.models.Transaction', '10': 'transactions'},
  ],
};

/// Descriptor for `FullBlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockBodyDescriptor = $convert.base64Decode(
    'Cg1GdWxsQmxvY2tCb2R5EkIKDHRyYW5zYWN0aW9ucxgBIAMoCzIeLmJsb2NrY2hhaW4ubW9kZW'
    'xzLlRyYW5zYWN0aW9uUgx0cmFuc2FjdGlvbnM=');

@$core.Deprecated('Use blockDescriptor instead')
const Block$json = {
  '1': 'Block',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'body', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.BlockBody', '8': {}, '10': 'body'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode(
    'CgVCbG9jaxJACgZoZWFkZXIYASABKAsyHi5ibG9ja2NoYWluLm1vZGVscy5CbG9ja0hlYWRlck'
    'II+kIFigECEAFSBmhlYWRlchI6CgRib2R5GAIgASgLMhwuYmxvY2tjaGFpbi5tb2RlbHMuQmxv'
    'Y2tCb2R5Qgj6QgWKAQIQAVIEYm9keQ==');

@$core.Deprecated('Use fullBlockDescriptor instead')
const FullBlock$json = {
  '1': 'FullBlock',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'fullBody', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.FullBlockBody', '8': {}, '10': 'fullBody'},
  ],
};

/// Descriptor for `FullBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockDescriptor = $convert.base64Decode(
    'CglGdWxsQmxvY2sSQAoGaGVhZGVyGAEgASgLMh4uYmxvY2tjaGFpbi5tb2RlbHMuQmxvY2tIZW'
    'FkZXJCCPpCBYoBAhABUgZoZWFkZXISRgoIZnVsbEJvZHkYAiABKAsyIC5ibG9ja2NoYWluLm1v'
    'ZGVscy5GdWxsQmxvY2tCb2R5Qgj6QgWKAQIQAVIIZnVsbEJvZHk=');

@$core.Deprecated('Use transactionIdDescriptor instead')
const TransactionId$json = {
  '1': 'TransactionId',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `TransactionId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionIdDescriptor = $convert.base64Decode(
    'Cg1UcmFuc2FjdGlvbklkEhQKBXZhbHVlGAEgASgJUgV2YWx1ZQ==');

@$core.Deprecated('Use transactionDescriptor instead')
const Transaction$json = {
  '1': 'Transaction',
  '2': [
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.TransactionId', '10': 'transactionId'},
    {'1': 'inputs', '3': 2, '4': 3, '5': 11, '6': '.blockchain.models.TransactionInput', '10': 'inputs'},
    {'1': 'outputs', '3': 3, '4': 3, '5': 11, '6': '.blockchain.models.TransactionOutput', '10': 'outputs'},
    {'1': 'attestation', '3': 4, '4': 3, '5': 11, '6': '.blockchain.models.Witness', '10': 'attestation'},
    {'1': 'rewardParentBlockId', '3': 5, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '10': 'rewardParentBlockId'},
  ],
};

/// Descriptor for `Transaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionDescriptor = $convert.base64Decode(
    'CgtUcmFuc2FjdGlvbhJGCg10cmFuc2FjdGlvbklkGAEgASgLMiAuYmxvY2tjaGFpbi5tb2RlbH'
    'MuVHJhbnNhY3Rpb25JZFINdHJhbnNhY3Rpb25JZBI7CgZpbnB1dHMYAiADKAsyIy5ibG9ja2No'
    'YWluLm1vZGVscy5UcmFuc2FjdGlvbklucHV0UgZpbnB1dHMSPgoHb3V0cHV0cxgDIAMoCzIkLm'
    'Jsb2NrY2hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0UgdvdXRwdXRzEjwKC2F0dGVzdGF0'
    'aW9uGAQgAygLMhouYmxvY2tjaGFpbi5tb2RlbHMuV2l0bmVzc1ILYXR0ZXN0YXRpb24STAoTcm'
    'V3YXJkUGFyZW50QmxvY2tJZBgFIAEoCzIaLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2NrSWRSE3Jl'
    'd2FyZFBhcmVudEJsb2NrSWQ=');

@$core.Deprecated('Use witnessDescriptor instead')
const Witness$json = {
  '1': 'Witness',
  '2': [
    {'1': 'lockAddress', '3': 3, '4': 1, '5': 11, '6': '.blockchain.models.LockAddress', '8': {}, '10': 'lockAddress'},
    {'1': 'lock', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.Lock', '8': {}, '10': 'lock'},
    {'1': 'key', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.Key', '8': {}, '10': 'key'},
  ],
};

/// Descriptor for `Witness`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List witnessDescriptor = $convert.base64Decode(
    'CgdXaXRuZXNzEkoKC2xvY2tBZGRyZXNzGAMgASgLMh4uYmxvY2tjaGFpbi5tb2RlbHMuTG9ja0'
    'FkZHJlc3NCCPpCBYoBAhABUgtsb2NrQWRkcmVzcxI1CgRsb2NrGAEgASgLMhcuYmxvY2tjaGFp'
    'bi5tb2RlbHMuTG9ja0II+kIFigECEAFSBGxvY2sSMgoDa2V5GAIgASgLMhYuYmxvY2tjaGFpbi'
    '5tb2RlbHMuS2V5Qgj6QgWKAQIQAVIDa2V5');

@$core.Deprecated('Use transactionInputDescriptor instead')
const TransactionInput$json = {
  '1': 'TransactionInput',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '8': {}, '10': 'reference'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.Value', '8': {}, '10': 'value'},
  ],
};

/// Descriptor for `TransactionInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionInputDescriptor = $convert.base64Decode(
    'ChBUcmFuc2FjdGlvbklucHV0ElUKCXJlZmVyZW5jZRgBIAEoCzItLmJsb2NrY2hhaW4ubW9kZW'
    'xzLlRyYW5zYWN0aW9uT3V0cHV0UmVmZXJlbmNlQgj6QgWKAQIQAVIJcmVmZXJlbmNlEjgKBXZh'
    'bHVlGAIgASgLMhguYmxvY2tjaGFpbi5tb2RlbHMuVmFsdWVCCPpCBYoBAhABUgV2YWx1ZQ==');

@$core.Deprecated('Use transactionOutputReferenceDescriptor instead')
const TransactionOutputReference$json = {
  '1': 'TransactionOutputReference',
  '2': [
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.TransactionId', '8': {}, '10': 'transactionId'},
    {'1': 'index', '3': 2, '4': 1, '5': 13, '10': 'index'},
  ],
};

/// Descriptor for `TransactionOutputReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputReferenceDescriptor = $convert.base64Decode(
    'ChpUcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZRJQCg10cmFuc2FjdGlvbklkGAEgASgLMiAuYm'
    'xvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25JZEII+kIFigECEAFSDXRyYW5zYWN0aW9uSWQS'
    'FAoFaW5kZXgYAiABKA1SBWluZGV4');

@$core.Deprecated('Use transactionOutputDescriptor instead')
const TransactionOutput$json = {
  '1': 'TransactionOutput',
  '2': [
    {'1': 'lockAddress', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.LockAddress', '8': {}, '10': 'lockAddress'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.Value', '8': {}, '10': 'value'},
    {'1': 'account', '3': 3, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '10': 'account'},
  ],
};

/// Descriptor for `TransactionOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputDescriptor = $convert.base64Decode(
    'ChFUcmFuc2FjdGlvbk91dHB1dBJKCgtsb2NrQWRkcmVzcxgBIAEoCzIeLmJsb2NrY2hhaW4ubW'
    '9kZWxzLkxvY2tBZGRyZXNzQgj6QgWKAQIQAVILbG9ja0FkZHJlc3MSOAoFdmFsdWUYAiABKAsy'
    'GC5ibG9ja2NoYWluLm1vZGVscy5WYWx1ZUII+kIFigECEAFSBXZhbHVlEkcKB2FjY291bnQYAy'
    'ABKAsyLS5ibG9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZVIHYWNj'
    'b3VudA==');

@$core.Deprecated('Use valueDescriptor instead')
const Value$json = {
  '1': 'Value',
  '2': [
    {'1': 'quantity', '3': 1, '4': 1, '5': 4, '10': 'quantity'},
    {'1': 'accountRegistration', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.AccountRegistration', '10': 'accountRegistration'},
    {'1': 'graphEntry', '3': 3, '4': 1, '5': 11, '6': '.blockchain.models.GraphEntry', '10': 'graphEntry'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode(
    'CgVWYWx1ZRIaCghxdWFudGl0eRgBIAEoBFIIcXVhbnRpdHkSWAoTYWNjb3VudFJlZ2lzdHJhdG'
    'lvbhgCIAEoCzImLmJsb2NrY2hhaW4ubW9kZWxzLkFjY291bnRSZWdpc3RyYXRpb25SE2FjY291'
    'bnRSZWdpc3RyYXRpb24SPQoKZ3JhcGhFbnRyeRgDIAEoCzIdLmJsb2NrY2hhaW4ubW9kZWxzLk'
    'dyYXBoRW50cnlSCmdyYXBoRW50cnk=');

@$core.Deprecated('Use accountRegistrationDescriptor instead')
const AccountRegistration$json = {
  '1': 'AccountRegistration',
  '2': [
    {'1': 'associationLock', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.LockAddress', '8': {}, '10': 'associationLock'},
    {'1': 'stakingRegistration', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.StakingRegistration', '10': 'stakingRegistration'},
  ],
};

/// Descriptor for `AccountRegistration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accountRegistrationDescriptor = $convert.base64Decode(
    'ChNBY2NvdW50UmVnaXN0cmF0aW9uElIKD2Fzc29jaWF0aW9uTG9jaxgBIAEoCzIeLmJsb2NrY2'
    'hhaW4ubW9kZWxzLkxvY2tBZGRyZXNzQgj6QgWKAQIQAVIPYXNzb2NpYXRpb25Mb2NrElgKE3N0'
    'YWtpbmdSZWdpc3RyYXRpb24YAiABKAsyJi5ibG9ja2NoYWluLm1vZGVscy5TdGFraW5nUmVnaX'
    'N0cmF0aW9uUhNzdGFraW5nUmVnaXN0cmF0aW9u');

@$core.Deprecated('Use stakingRegistrationDescriptor instead')
const StakingRegistration$json = {
  '1': 'StakingRegistration',
  '2': [
    {'1': 'signature', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.SignatureKesProduct', '8': {}, '10': 'signature'},
    {'1': 'stakingAddress', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.StakingAddress', '8': {}, '10': 'stakingAddress'},
  ],
};

/// Descriptor for `StakingRegistration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingRegistrationDescriptor = $convert.base64Decode(
    'ChNTdGFraW5nUmVnaXN0cmF0aW9uEk4KCXNpZ25hdHVyZRgBIAEoCzImLmJsb2NrY2hhaW4ubW'
    '9kZWxzLlNpZ25hdHVyZUtlc1Byb2R1Y3RCCPpCBYoBAhABUglzaWduYXR1cmUSUwoOc3Rha2lu'
    'Z0FkZHJlc3MYAiABKAsyIS5ibG9ja2NoYWluLm1vZGVscy5TdGFraW5nQWRkcmVzc0II+kIFig'
    'ECEAFSDnN0YWtpbmdBZGRyZXNz');

@$core.Deprecated('Use graphEntryDescriptor instead')
const GraphEntry$json = {
  '1': 'GraphEntry',
  '2': [
    {'1': 'vertex', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.Vertex', '9': 0, '10': 'vertex'},
    {'1': 'edge', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.Edge', '9': 0, '10': 'edge'},
  ],
  '8': [
    {'1': 'entry'},
  ],
};

/// Descriptor for `GraphEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List graphEntryDescriptor = $convert.base64Decode(
    'CgpHcmFwaEVudHJ5EjMKBnZlcnRleBgBIAEoCzIZLmJsb2NrY2hhaW4ubW9kZWxzLlZlcnRleE'
    'gAUgZ2ZXJ0ZXgSLQoEZWRnZRgCIAEoCzIXLmJsb2NrY2hhaW4ubW9kZWxzLkVkZ2VIAFIEZWRn'
    'ZUIHCgVlbnRyeQ==');

@$core.Deprecated('Use vertexDescriptor instead')
const Vertex$json = {
  '1': 'Vertex',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'data'},
    {'1': 'edgeLockAddress', '3': 3, '4': 1, '5': 11, '6': '.blockchain.models.LockAddress', '10': 'edgeLockAddress'},
  ],
};

/// Descriptor for `Vertex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vertexDescriptor = $convert.base64Decode(
    'CgZWZXJ0ZXgSFAoFbGFiZWwYASABKAlSBWxhYmVsEisKBGRhdGEYAiABKAsyFy5nb29nbGUucH'
    'JvdG9idWYuU3RydWN0UgRkYXRhEkgKD2VkZ2VMb2NrQWRkcmVzcxgDIAEoCzIeLmJsb2NrY2hh'
    'aW4ubW9kZWxzLkxvY2tBZGRyZXNzUg9lZGdlTG9ja0FkZHJlc3M=');

@$core.Deprecated('Use edgeDescriptor instead')
const Edge$json = {
  '1': 'Edge',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'data'},
    {'1': 'a', '3': 3, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '8': {}, '10': 'a'},
    {'1': 'b', '3': 4, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '8': {}, '10': 'b'},
  ],
};

/// Descriptor for `Edge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List edgeDescriptor = $convert.base64Decode(
    'CgRFZGdlEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIrCgRkYXRhGAIgASgLMhcuZ29vZ2xlLnByb3'
    'RvYnVmLlN0cnVjdFIEZGF0YRJFCgFhGAMgASgLMi0uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNh'
    'Y3Rpb25PdXRwdXRSZWZlcmVuY2VCCPpCBYoBAhABUgFhEkUKAWIYBCABKAsyLS5ibG9ja2NoYW'
    'luLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZUII+kIFigECEAFSAWI=');

@$core.Deprecated('Use activeStakerDescriptor instead')
const ActiveStaker$json = {
  '1': 'ActiveStaker',
  '2': [
    {'1': 'registration', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.StakingRegistration', '8': {}, '10': 'registration'},
    {'1': 'quantity', '3': 2, '4': 1, '5': 3, '10': 'quantity'},
  ],
};

/// Descriptor for `ActiveStaker`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeStakerDescriptor = $convert.base64Decode(
    'CgxBY3RpdmVTdGFrZXISVAoMcmVnaXN0cmF0aW9uGAEgASgLMiYuYmxvY2tjaGFpbi5tb2RlbH'
    'MuU3Rha2luZ1JlZ2lzdHJhdGlvbkII+kIFigECEAFSDHJlZ2lzdHJhdGlvbhIaCghxdWFudGl0'
    'eRgCIAEoA1IIcXVhbnRpdHk=');

@$core.Deprecated('Use lockAddressDescriptor instead')
const LockAddress$json = {
  '1': 'LockAddress',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `LockAddress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockAddressDescriptor = $convert.base64Decode(
    'CgtMb2NrQWRkcmVzcxIUCgV2YWx1ZRgBIAEoCVIFdmFsdWU=');

@$core.Deprecated('Use lockDescriptor instead')
const Lock$json = {
  '1': 'Lock',
  '2': [
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.Lock.Ed25519', '9': 0, '10': 'ed25519'},
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
    {'1': 'vk', '3': 1, '4': 1, '5': 9, '10': 'vk'},
  ],
};

/// Descriptor for `Lock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List lockDescriptor = $convert.base64Decode(
    'CgRMb2NrEjsKB2VkMjU1MTkYASABKAsyHy5ibG9ja2NoYWluLm1vZGVscy5Mb2NrLkVkMjU1MT'
    'lIAFIHZWQyNTUxORoZCgdFZDI1NTE5Eg4KAnZrGAEgASgJUgJ2a0IHCgV2YWx1ZQ==');

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.Key.Ed25519', '9': 0, '10': 'ed25519'},
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
    {'1': 'signature', '3': 1, '4': 1, '5': 9, '10': 'signature'},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode(
    'CgNLZXkSOgoHZWQyNTUxORgBIAEoCzIeLmJsb2NrY2hhaW4ubW9kZWxzLktleS5FZDI1NTE5SA'
    'BSB2VkMjU1MTkaJwoHRWQyNTUxORIcCglzaWduYXR1cmUYASABKAlSCXNpZ25hdHVyZUIHCgV2'
    'YWx1ZQ==');

@$core.Deprecated('Use peerIdDescriptor instead')
const PeerId$json = {
  '1': 'PeerId',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `PeerId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List peerIdDescriptor = $convert.base64Decode(
    'CgZQZWVySWQSFAoFdmFsdWUYASABKAlSBXZhbHVl');

@$core.Deprecated('Use publicP2PStateDescriptor instead')
const PublicP2PState$json = {
  '1': 'PublicP2PState',
  '2': [
    {'1': 'localPeer', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.ConnectedPeer', '8': {}, '10': 'localPeer'},
    {'1': 'peers', '3': 2, '4': 3, '5': 11, '6': '.blockchain.models.ConnectedPeer', '10': 'peers'},
  ],
};

/// Descriptor for `PublicP2PState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publicP2PStateDescriptor = $convert.base64Decode(
    'Cg5QdWJsaWNQMlBTdGF0ZRJICglsb2NhbFBlZXIYASABKAsyIC5ibG9ja2NoYWluLm1vZGVscy'
    '5Db25uZWN0ZWRQZWVyQgj6QgWKAQIQAVIJbG9jYWxQZWVyEjYKBXBlZXJzGAIgAygLMiAuYmxv'
    'Y2tjaGFpbi5tb2RlbHMuQ29ubmVjdGVkUGVlclIFcGVlcnM=');

@$core.Deprecated('Use connectedPeerDescriptor instead')
const ConnectedPeer$json = {
  '1': 'ConnectedPeer',
  '2': [
    {'1': 'peerId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.PeerId', '8': {}, '10': 'peerId'},
    {'1': 'host', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.StringValue', '10': 'host'},
    {'1': 'port', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'port'},
  ],
};

/// Descriptor for `ConnectedPeer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectedPeerDescriptor = $convert.base64Decode(
    'Cg1Db25uZWN0ZWRQZWVyEjsKBnBlZXJJZBgBIAEoCzIZLmJsb2NrY2hhaW4ubW9kZWxzLlBlZX'
    'JJZEII+kIFigECEAFSBnBlZXJJZBIwCgRob3N0GAIgASgLMhwuZ29vZ2xlLnByb3RvYnVmLlN0'
    'cmluZ1ZhbHVlUgRob3N0EjAKBHBvcnQYAyABKAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVm'
    'FsdWVSBHBvcnQ=');

