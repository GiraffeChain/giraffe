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
    {'1': 'headerId', '3': 12, '4': 1, '5': 11, '6': '.giraffe.models.BlockId', '10': 'headerId'},
    {'1': 'parentHeaderId', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.BlockId', '8': {}, '10': 'parentHeaderId'},
    {'1': 'parentSlot', '3': 2, '4': 1, '5': 4, '10': 'parentSlot'},
    {'1': 'txRoot', '3': 3, '4': 1, '5': 9, '10': 'txRoot'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 4, '10': 'timestamp'},
    {'1': 'height', '3': 5, '4': 1, '5': 4, '10': 'height'},
    {'1': 'slot', '3': 6, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'stakerCertificate', '3': 7, '4': 1, '5': 11, '6': '.giraffe.models.StakerCertificate', '8': {}, '10': 'stakerCertificate'},
    {'1': 'account', '3': 8, '4': 1, '5': 11, '6': '.giraffe.models.TransactionOutputReference', '8': {}, '10': 'account'},
    {'1': 'settings', '3': 9, '4': 3, '5': 11, '6': '.giraffe.models.BlockHeader.SettingsEntry', '10': 'settings'},
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
    'CgtCbG9ja0hlYWRlchIzCghoZWFkZXJJZBgMIAEoCzIXLmdpcmFmZmUubW9kZWxzLkJsb2NrSW'
    'RSCGhlYWRlcklkEkkKDnBhcmVudEhlYWRlcklkGAEgASgLMhcuZ2lyYWZmZS5tb2RlbHMuQmxv'
    'Y2tJZEII+kIFigECEAFSDnBhcmVudEhlYWRlcklkEh4KCnBhcmVudFNsb3QYAiABKARSCnBhcm'
    'VudFNsb3QSFgoGdHhSb290GAMgASgJUgZ0eFJvb3QSHAoJdGltZXN0YW1wGAQgASgEUgl0aW1l'
    'c3RhbXASFgoGaGVpZ2h0GAUgASgEUgZoZWlnaHQSEgoEc2xvdBgGIAEoBFIEc2xvdBJZChFzdG'
    'FrZXJDZXJ0aWZpY2F0ZRgHIAEoCzIhLmdpcmFmZmUubW9kZWxzLlN0YWtlckNlcnRpZmljYXRl'
    'Qgj6QgWKAQIQAVIRc3Rha2VyQ2VydGlmaWNhdGUSTgoHYWNjb3VudBgIIAEoCzIqLmdpcmFmZm'
    'UubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0UmVmZXJlbmNlQgj6QgWKAQIQAVIHYWNjb3VudBJF'
    'CghzZXR0aW5ncxgJIAMoCzIpLmdpcmFmZmUubW9kZWxzLkJsb2NrSGVhZGVyLlNldHRpbmdzRW'
    '50cnlSCHNldHRpbmdzGjsKDVNldHRpbmdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFs'
    'dWUYAiABKAlSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use stakerCertificateDescriptor instead')
const StakerCertificate$json = {
  '1': 'StakerCertificate',
  '2': [
    {'1': 'blockSignature', '3': 1, '4': 1, '5': 9, '10': 'blockSignature'},
    {'1': 'vrfSignature', '3': 2, '4': 1, '5': 9, '10': 'vrfSignature'},
    {'1': 'vrfVK', '3': 3, '4': 1, '5': 9, '10': 'vrfVK'},
    {'1': 'thresholdEvidence', '3': 4, '4': 1, '5': 9, '10': 'thresholdEvidence'},
    {'1': 'eta', '3': 5, '4': 1, '5': 9, '10': 'eta'},
  ],
};

/// Descriptor for `StakerCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakerCertificateDescriptor = $convert.base64Decode(
    'ChFTdGFrZXJDZXJ0aWZpY2F0ZRImCg5ibG9ja1NpZ25hdHVyZRgBIAEoCVIOYmxvY2tTaWduYX'
    'R1cmUSIgoMdnJmU2lnbmF0dXJlGAIgASgJUgx2cmZTaWduYXR1cmUSFAoFdnJmVksYAyABKAlS'
    'BXZyZlZLEiwKEXRocmVzaG9sZEV2aWRlbmNlGAQgASgJUhF0aHJlc2hvbGRFdmlkZW5jZRIQCg'
    'NldGEYBSABKAlSA2V0YQ==');

@$core.Deprecated('Use slotIdDescriptor instead')
const SlotId$json = {
  '1': 'SlotId',
  '2': [
    {'1': 'slot', '3': 1, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'blockId', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.BlockId', '8': {}, '10': 'blockId'},
  ],
};

/// Descriptor for `SlotId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List slotIdDescriptor = $convert.base64Decode(
    'CgZTbG90SWQSEgoEc2xvdBgBIAEoBFIEc2xvdBI7CgdibG9ja0lkGAIgASgLMhcuZ2lyYWZmZS'
    '5tb2RlbHMuQmxvY2tJZEII+kIFigECEAFSB2Jsb2NrSWQ=');

@$core.Deprecated('Use blockBodyDescriptor instead')
const BlockBody$json = {
  '1': 'BlockBody',
  '2': [
    {'1': 'transactionIds', '3': 1, '4': 3, '5': 11, '6': '.giraffe.models.TransactionId', '10': 'transactionIds'},
  ],
};

/// Descriptor for `BlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockBodyDescriptor = $convert.base64Decode(
    'CglCbG9ja0JvZHkSRQoOdHJhbnNhY3Rpb25JZHMYASADKAsyHS5naXJhZmZlLm1vZGVscy5Ucm'
    'Fuc2FjdGlvbklkUg50cmFuc2FjdGlvbklkcw==');

@$core.Deprecated('Use fullBlockBodyDescriptor instead')
const FullBlockBody$json = {
  '1': 'FullBlockBody',
  '2': [
    {'1': 'transactions', '3': 1, '4': 3, '5': 11, '6': '.giraffe.models.Transaction', '10': 'transactions'},
  ],
};

/// Descriptor for `FullBlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockBodyDescriptor = $convert.base64Decode(
    'Cg1GdWxsQmxvY2tCb2R5Ej8KDHRyYW5zYWN0aW9ucxgBIAMoCzIbLmdpcmFmZmUubW9kZWxzLl'
    'RyYW5zYWN0aW9uUgx0cmFuc2FjdGlvbnM=');

@$core.Deprecated('Use blockDescriptor instead')
const Block$json = {
  '1': 'Block',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'body', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.BlockBody', '8': {}, '10': 'body'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode(
    'CgVCbG9jaxI9CgZoZWFkZXIYASABKAsyGy5naXJhZmZlLm1vZGVscy5CbG9ja0hlYWRlckII+k'
    'IFigECEAFSBmhlYWRlchI3CgRib2R5GAIgASgLMhkuZ2lyYWZmZS5tb2RlbHMuQmxvY2tCb2R5'
    'Qgj6QgWKAQIQAVIEYm9keQ==');

@$core.Deprecated('Use fullBlockDescriptor instead')
const FullBlock$json = {
  '1': 'FullBlock',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'fullBody', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.FullBlockBody', '8': {}, '10': 'fullBody'},
  ],
};

/// Descriptor for `FullBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockDescriptor = $convert.base64Decode(
    'CglGdWxsQmxvY2sSPQoGaGVhZGVyGAEgASgLMhsuZ2lyYWZmZS5tb2RlbHMuQmxvY2tIZWFkZX'
    'JCCPpCBYoBAhABUgZoZWFkZXISQwoIZnVsbEJvZHkYAiABKAsyHS5naXJhZmZlLm1vZGVscy5G'
    'dWxsQmxvY2tCb2R5Qgj6QgWKAQIQAVIIZnVsbEJvZHk=');

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
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.TransactionId', '10': 'transactionId'},
    {'1': 'inputs', '3': 2, '4': 3, '5': 11, '6': '.giraffe.models.TransactionInput', '10': 'inputs'},
    {'1': 'outputs', '3': 3, '4': 3, '5': 11, '6': '.giraffe.models.TransactionOutput', '10': 'outputs'},
    {'1': 'attestation', '3': 4, '4': 3, '5': 11, '6': '.giraffe.models.Witness', '10': 'attestation'},
    {'1': 'rewardParentBlockId', '3': 5, '4': 1, '5': 11, '6': '.giraffe.models.BlockId', '10': 'rewardParentBlockId'},
  ],
};

/// Descriptor for `Transaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionDescriptor = $convert.base64Decode(
    'CgtUcmFuc2FjdGlvbhJDCg10cmFuc2FjdGlvbklkGAEgASgLMh0uZ2lyYWZmZS5tb2RlbHMuVH'
    'JhbnNhY3Rpb25JZFINdHJhbnNhY3Rpb25JZBI4CgZpbnB1dHMYAiADKAsyIC5naXJhZmZlLm1v'
    'ZGVscy5UcmFuc2FjdGlvbklucHV0UgZpbnB1dHMSOwoHb3V0cHV0cxgDIAMoCzIhLmdpcmFmZm'
    'UubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0UgdvdXRwdXRzEjkKC2F0dGVzdGF0aW9uGAQgAygL'
    'MhcuZ2lyYWZmZS5tb2RlbHMuV2l0bmVzc1ILYXR0ZXN0YXRpb24SSQoTcmV3YXJkUGFyZW50Qm'
    'xvY2tJZBgFIAEoCzIXLmdpcmFmZmUubW9kZWxzLkJsb2NrSWRSE3Jld2FyZFBhcmVudEJsb2Nr'
    'SWQ=');

@$core.Deprecated('Use witnessDescriptor instead')
const Witness$json = {
  '1': 'Witness',
  '2': [
    {'1': 'lockAddress', '3': 3, '4': 1, '5': 11, '6': '.giraffe.models.LockAddress', '8': {}, '10': 'lockAddress'},
    {'1': 'lock', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.Lock', '8': {}, '10': 'lock'},
    {'1': 'key', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.Key', '8': {}, '10': 'key'},
  ],
};

/// Descriptor for `Witness`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List witnessDescriptor = $convert.base64Decode(
    'CgdXaXRuZXNzEkcKC2xvY2tBZGRyZXNzGAMgASgLMhsuZ2lyYWZmZS5tb2RlbHMuTG9ja0FkZH'
    'Jlc3NCCPpCBYoBAhABUgtsb2NrQWRkcmVzcxIyCgRsb2NrGAEgASgLMhQuZ2lyYWZmZS5tb2Rl'
    'bHMuTG9ja0II+kIFigECEAFSBGxvY2sSLwoDa2V5GAIgASgLMhMuZ2lyYWZmZS5tb2RlbHMuS2'
    'V5Qgj6QgWKAQIQAVIDa2V5');

@$core.Deprecated('Use transactionInputDescriptor instead')
const TransactionInput$json = {
  '1': 'TransactionInput',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.TransactionOutputReference', '8': {}, '10': 'reference'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.Value', '8': {}, '10': 'value'},
  ],
};

/// Descriptor for `TransactionInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionInputDescriptor = $convert.base64Decode(
    'ChBUcmFuc2FjdGlvbklucHV0ElIKCXJlZmVyZW5jZRgBIAEoCzIqLmdpcmFmZmUubW9kZWxzLl'
    'RyYW5zYWN0aW9uT3V0cHV0UmVmZXJlbmNlQgj6QgWKAQIQAVIJcmVmZXJlbmNlEjUKBXZhbHVl'
    'GAIgASgLMhUuZ2lyYWZmZS5tb2RlbHMuVmFsdWVCCPpCBYoBAhABUgV2YWx1ZQ==');

@$core.Deprecated('Use transactionOutputReferenceDescriptor instead')
const TransactionOutputReference$json = {
  '1': 'TransactionOutputReference',
  '2': [
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.TransactionId', '10': 'transactionId'},
    {'1': 'index', '3': 2, '4': 1, '5': 13, '10': 'index'},
  ],
};

/// Descriptor for `TransactionOutputReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputReferenceDescriptor = $convert.base64Decode(
    'ChpUcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZRJDCg10cmFuc2FjdGlvbklkGAEgASgLMh0uZ2'
    'lyYWZmZS5tb2RlbHMuVHJhbnNhY3Rpb25JZFINdHJhbnNhY3Rpb25JZBIUCgVpbmRleBgCIAEo'
    'DVIFaW5kZXg=');

@$core.Deprecated('Use transactionOutputDescriptor instead')
const TransactionOutput$json = {
  '1': 'TransactionOutput',
  '2': [
    {'1': 'lockAddress', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.LockAddress', '8': {}, '10': 'lockAddress'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.Value', '8': {}, '10': 'value'},
    {'1': 'account', '3': 3, '4': 1, '5': 11, '6': '.giraffe.models.TransactionOutputReference', '10': 'account'},
  ],
};

/// Descriptor for `TransactionOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputDescriptor = $convert.base64Decode(
    'ChFUcmFuc2FjdGlvbk91dHB1dBJHCgtsb2NrQWRkcmVzcxgBIAEoCzIbLmdpcmFmZmUubW9kZW'
    'xzLkxvY2tBZGRyZXNzQgj6QgWKAQIQAVILbG9ja0FkZHJlc3MSNQoFdmFsdWUYAiABKAsyFS5n'
    'aXJhZmZlLm1vZGVscy5WYWx1ZUII+kIFigECEAFSBXZhbHVlEkQKB2FjY291bnQYAyABKAsyKi'
    '5naXJhZmZlLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZVIHYWNjb3VudA==');

@$core.Deprecated('Use valueDescriptor instead')
const Value$json = {
  '1': 'Value',
  '2': [
    {'1': 'quantity', '3': 1, '4': 1, '5': 4, '10': 'quantity'},
    {'1': 'accountRegistration', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.AccountRegistration', '10': 'accountRegistration'},
    {'1': 'graphEntry', '3': 3, '4': 1, '5': 11, '6': '.giraffe.models.GraphEntry', '10': 'graphEntry'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode(
    'CgVWYWx1ZRIaCghxdWFudGl0eRgBIAEoBFIIcXVhbnRpdHkSVQoTYWNjb3VudFJlZ2lzdHJhdG'
    'lvbhgCIAEoCzIjLmdpcmFmZmUubW9kZWxzLkFjY291bnRSZWdpc3RyYXRpb25SE2FjY291bnRS'
    'ZWdpc3RyYXRpb24SOgoKZ3JhcGhFbnRyeRgDIAEoCzIaLmdpcmFmZmUubW9kZWxzLkdyYXBoRW'
    '50cnlSCmdyYXBoRW50cnk=');

@$core.Deprecated('Use accountRegistrationDescriptor instead')
const AccountRegistration$json = {
  '1': 'AccountRegistration',
  '2': [
    {'1': 'associationLock', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.LockAddress', '8': {}, '10': 'associationLock'},
    {'1': 'stakingRegistration', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.StakingRegistration', '10': 'stakingRegistration'},
  ],
};

/// Descriptor for `AccountRegistration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accountRegistrationDescriptor = $convert.base64Decode(
    'ChNBY2NvdW50UmVnaXN0cmF0aW9uEk8KD2Fzc29jaWF0aW9uTG9jaxgBIAEoCzIbLmdpcmFmZm'
    'UubW9kZWxzLkxvY2tBZGRyZXNzQgj6QgWKAQIQAVIPYXNzb2NpYXRpb25Mb2NrElUKE3N0YWtp'
    'bmdSZWdpc3RyYXRpb24YAiABKAsyIy5naXJhZmZlLm1vZGVscy5TdGFraW5nUmVnaXN0cmF0aW'
    '9uUhNzdGFraW5nUmVnaXN0cmF0aW9u');

@$core.Deprecated('Use stakingRegistrationDescriptor instead')
const StakingRegistration$json = {
  '1': 'StakingRegistration',
  '2': [
    {'1': 'commitmentSignature', '3': 1, '4': 1, '5': 9, '10': 'commitmentSignature'},
    {'1': 'vk', '3': 2, '4': 1, '5': 9, '10': 'vk'},
  ],
};

/// Descriptor for `StakingRegistration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakingRegistrationDescriptor = $convert.base64Decode(
    'ChNTdGFraW5nUmVnaXN0cmF0aW9uEjAKE2NvbW1pdG1lbnRTaWduYXR1cmUYASABKAlSE2NvbW'
    '1pdG1lbnRTaWduYXR1cmUSDgoCdmsYAiABKAlSAnZr');

@$core.Deprecated('Use graphEntryDescriptor instead')
const GraphEntry$json = {
  '1': 'GraphEntry',
  '2': [
    {'1': 'vertex', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.Vertex', '9': 0, '10': 'vertex'},
    {'1': 'edge', '3': 2, '4': 1, '5': 11, '6': '.giraffe.models.Edge', '9': 0, '10': 'edge'},
  ],
  '8': [
    {'1': 'entry'},
  ],
};

/// Descriptor for `GraphEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List graphEntryDescriptor = $convert.base64Decode(
    'CgpHcmFwaEVudHJ5EjAKBnZlcnRleBgBIAEoCzIWLmdpcmFmZmUubW9kZWxzLlZlcnRleEgAUg'
    'Z2ZXJ0ZXgSKgoEZWRnZRgCIAEoCzIULmdpcmFmZmUubW9kZWxzLkVkZ2VIAFIEZWRnZUIHCgVl'
    'bnRyeQ==');

@$core.Deprecated('Use vertexDescriptor instead')
const Vertex$json = {
  '1': 'Vertex',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'data'},
    {'1': 'edgeLockAddress', '3': 3, '4': 1, '5': 11, '6': '.giraffe.models.LockAddress', '10': 'edgeLockAddress'},
  ],
};

/// Descriptor for `Vertex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vertexDescriptor = $convert.base64Decode(
    'CgZWZXJ0ZXgSFAoFbGFiZWwYASABKAlSBWxhYmVsEisKBGRhdGEYAiABKAsyFy5nb29nbGUucH'
    'JvdG9idWYuU3RydWN0UgRkYXRhEkUKD2VkZ2VMb2NrQWRkcmVzcxgDIAEoCzIbLmdpcmFmZmUu'
    'bW9kZWxzLkxvY2tBZGRyZXNzUg9lZGdlTG9ja0FkZHJlc3M=');

@$core.Deprecated('Use edgeDescriptor instead')
const Edge$json = {
  '1': 'Edge',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'data'},
    {'1': 'a', '3': 3, '4': 1, '5': 11, '6': '.giraffe.models.TransactionOutputReference', '8': {}, '10': 'a'},
    {'1': 'b', '3': 4, '4': 1, '5': 11, '6': '.giraffe.models.TransactionOutputReference', '8': {}, '10': 'b'},
  ],
};

/// Descriptor for `Edge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List edgeDescriptor = $convert.base64Decode(
    'CgRFZGdlEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIrCgRkYXRhGAIgASgLMhcuZ29vZ2xlLnByb3'
    'RvYnVmLlN0cnVjdFIEZGF0YRJCCgFhGAMgASgLMiouZ2lyYWZmZS5tb2RlbHMuVHJhbnNhY3Rp'
    'b25PdXRwdXRSZWZlcmVuY2VCCPpCBYoBAhABUgFhEkIKAWIYBCABKAsyKi5naXJhZmZlLm1vZG'
    'Vscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZUII+kIFigECEAFSAWI=');

@$core.Deprecated('Use activeStakerDescriptor instead')
const ActiveStaker$json = {
  '1': 'ActiveStaker',
  '2': [
    {'1': 'registration', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.StakingRegistration', '8': {}, '10': 'registration'},
    {'1': 'quantity', '3': 2, '4': 1, '5': 3, '10': 'quantity'},
  ],
};

/// Descriptor for `ActiveStaker`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeStakerDescriptor = $convert.base64Decode(
    'CgxBY3RpdmVTdGFrZXISUQoMcmVnaXN0cmF0aW9uGAEgASgLMiMuZ2lyYWZmZS5tb2RlbHMuU3'
    'Rha2luZ1JlZ2lzdHJhdGlvbkII+kIFigECEAFSDHJlZ2lzdHJhdGlvbhIaCghxdWFudGl0eRgC'
    'IAEoA1IIcXVhbnRpdHk=');

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
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.Lock.Ed25519', '9': 0, '10': 'ed25519'},
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
    'CgRMb2NrEjgKB2VkMjU1MTkYASABKAsyHC5naXJhZmZlLm1vZGVscy5Mb2NrLkVkMjU1MTlIAF'
    'IHZWQyNTUxORoZCgdFZDI1NTE5Eg4KAnZrGAEgASgJUgJ2a0IHCgV2YWx1ZQ==');

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.Key.Ed25519', '9': 0, '10': 'ed25519'},
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
    'CgNLZXkSNwoHZWQyNTUxORgBIAEoCzIbLmdpcmFmZmUubW9kZWxzLktleS5FZDI1NTE5SABSB2'
    'VkMjU1MTkaJwoHRWQyNTUxORIcCglzaWduYXR1cmUYASABKAlSCXNpZ25hdHVyZUIHCgV2YWx1'
    'ZQ==');

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
    {'1': 'localPeer', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.ConnectedPeer', '8': {}, '10': 'localPeer'},
    {'1': 'peers', '3': 2, '4': 3, '5': 11, '6': '.giraffe.models.ConnectedPeer', '10': 'peers'},
  ],
};

/// Descriptor for `PublicP2PState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publicP2PStateDescriptor = $convert.base64Decode(
    'Cg5QdWJsaWNQMlBTdGF0ZRJFCglsb2NhbFBlZXIYASABKAsyHS5naXJhZmZlLm1vZGVscy5Db2'
    '5uZWN0ZWRQZWVyQgj6QgWKAQIQAVIJbG9jYWxQZWVyEjMKBXBlZXJzGAIgAygLMh0uZ2lyYWZm'
    'ZS5tb2RlbHMuQ29ubmVjdGVkUGVlclIFcGVlcnM=');

@$core.Deprecated('Use connectedPeerDescriptor instead')
const ConnectedPeer$json = {
  '1': 'ConnectedPeer',
  '2': [
    {'1': 'peerId', '3': 1, '4': 1, '5': 11, '6': '.giraffe.models.PeerId', '8': {}, '10': 'peerId'},
    {'1': 'host', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.StringValue', '10': 'host'},
    {'1': 'port', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'port'},
  ],
};

/// Descriptor for `ConnectedPeer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectedPeerDescriptor = $convert.base64Decode(
    'Cg1Db25uZWN0ZWRQZWVyEjgKBnBlZXJJZBgBIAEoCzIWLmdpcmFmZmUubW9kZWxzLlBlZXJJZE'
    'II+kIFigECEAFSBnBlZXJJZBIwCgRob3N0GAIgASgLMhwuZ29vZ2xlLnByb3RvYnVmLlN0cmlu'
    'Z1ZhbHVlUgRob3N0EjAKBHBvcnQYAyABKAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVmFsdW'
    'VSBHBvcnQ=');

