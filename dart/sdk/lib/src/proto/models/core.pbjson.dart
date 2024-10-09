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
    {'1': 'headerId', '3': 12, '4': 1, '5': 11, '6': '.com.giraffechain.models.BlockId', '10': 'headerId'},
    {'1': 'parentHeaderId', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.BlockId', '8': {}, '10': 'parentHeaderId'},
    {'1': 'txRoot', '3': 3, '4': 1, '5': 9, '10': 'txRoot'},
    {'1': 'timestamp', '3': 4, '4': 1, '5': 4, '10': 'timestamp'},
    {'1': 'height', '3': 5, '4': 1, '5': 4, '10': 'height'},
    {'1': 'slot', '3': 6, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'stakerCertificate', '3': 7, '4': 1, '5': 11, '6': '.com.giraffechain.models.StakerCertificate', '8': {}, '10': 'stakerCertificate'},
    {'1': 'account', '3': 8, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionOutputReference', '8': {}, '10': 'account'},
    {'1': 'settings', '3': 9, '4': 3, '5': 11, '6': '.com.giraffechain.models.BlockHeader.SettingsEntry', '10': 'settings'},
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
    'CgtCbG9ja0hlYWRlchI8CghoZWFkZXJJZBgMIAEoCzIgLmNvbS5naXJhZmZlY2hhaW4ubW9kZW'
    'xzLkJsb2NrSWRSCGhlYWRlcklkElIKDnBhcmVudEhlYWRlcklkGAEgASgLMiAuY29tLmdpcmFm'
    'ZmVjaGFpbi5tb2RlbHMuQmxvY2tJZEII+kIFigECEAFSDnBhcmVudEhlYWRlcklkEhYKBnR4Um'
    '9vdBgDIAEoCVIGdHhSb290EhwKCXRpbWVzdGFtcBgEIAEoBFIJdGltZXN0YW1wEhYKBmhlaWdo'
    'dBgFIAEoBFIGaGVpZ2h0EhIKBHNsb3QYBiABKARSBHNsb3QSYgoRc3Rha2VyQ2VydGlmaWNhdG'
    'UYByABKAsyKi5jb20uZ2lyYWZmZWNoYWluLm1vZGVscy5TdGFrZXJDZXJ0aWZpY2F0ZUII+kIF'
    'igECEAFSEXN0YWtlckNlcnRpZmljYXRlElcKB2FjY291bnQYCCABKAsyMy5jb20uZ2lyYWZmZW'
    'NoYWluLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZUII+kIFigECEAFSB2FjY291'
    'bnQSTgoIc2V0dGluZ3MYCSADKAsyMi5jb20uZ2lyYWZmZWNoYWluLm1vZGVscy5CbG9ja0hlYW'
    'Rlci5TZXR0aW5nc0VudHJ5UghzZXR0aW5ncxo7Cg1TZXR0aW5nc0VudHJ5EhAKA2tleRgBIAEo'
    'CVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use stakerCertificateDescriptor instead')
const StakerCertificate$json = {
  '1': 'StakerCertificate',
  '2': [
    {'1': 'blockSignature', '3': 1, '4': 1, '5': 9, '10': 'blockSignature'},
    {'1': 'vrfSignature', '3': 2, '4': 1, '5': 9, '10': 'vrfSignature'},
    {'1': 'vrfVK', '3': 3, '4': 1, '5': 9, '10': 'vrfVK'},
    {'1': 'eta', '3': 5, '4': 1, '5': 9, '10': 'eta'},
  ],
};

/// Descriptor for `StakerCertificate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stakerCertificateDescriptor = $convert.base64Decode(
    'ChFTdGFrZXJDZXJ0aWZpY2F0ZRImCg5ibG9ja1NpZ25hdHVyZRgBIAEoCVIOYmxvY2tTaWduYX'
    'R1cmUSIgoMdnJmU2lnbmF0dXJlGAIgASgJUgx2cmZTaWduYXR1cmUSFAoFdnJmVksYAyABKAlS'
    'BXZyZlZLEhAKA2V0YRgFIAEoCVIDZXRh');

@$core.Deprecated('Use slotIdDescriptor instead')
const SlotId$json = {
  '1': 'SlotId',
  '2': [
    {'1': 'slot', '3': 1, '4': 1, '5': 4, '10': 'slot'},
    {'1': 'blockId', '3': 2, '4': 1, '5': 11, '6': '.com.giraffechain.models.BlockId', '8': {}, '10': 'blockId'},
  ],
};

/// Descriptor for `SlotId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List slotIdDescriptor = $convert.base64Decode(
    'CgZTbG90SWQSEgoEc2xvdBgBIAEoBFIEc2xvdBJECgdibG9ja0lkGAIgASgLMiAuY29tLmdpcm'
    'FmZmVjaGFpbi5tb2RlbHMuQmxvY2tJZEII+kIFigECEAFSB2Jsb2NrSWQ=');

@$core.Deprecated('Use blockBodyDescriptor instead')
const BlockBody$json = {
  '1': 'BlockBody',
  '2': [
    {'1': 'transactionIds', '3': 1, '4': 3, '5': 11, '6': '.com.giraffechain.models.TransactionId', '10': 'transactionIds'},
  ],
};

/// Descriptor for `BlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockBodyDescriptor = $convert.base64Decode(
    'CglCbG9ja0JvZHkSTgoOdHJhbnNhY3Rpb25JZHMYASADKAsyJi5jb20uZ2lyYWZmZWNoYWluLm'
    '1vZGVscy5UcmFuc2FjdGlvbklkUg50cmFuc2FjdGlvbklkcw==');

@$core.Deprecated('Use fullBlockBodyDescriptor instead')
const FullBlockBody$json = {
  '1': 'FullBlockBody',
  '2': [
    {'1': 'transactions', '3': 1, '4': 3, '5': 11, '6': '.com.giraffechain.models.Transaction', '10': 'transactions'},
  ],
};

/// Descriptor for `FullBlockBody`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockBodyDescriptor = $convert.base64Decode(
    'Cg1GdWxsQmxvY2tCb2R5EkgKDHRyYW5zYWN0aW9ucxgBIAMoCzIkLmNvbS5naXJhZmZlY2hhaW'
    '4ubW9kZWxzLlRyYW5zYWN0aW9uUgx0cmFuc2FjdGlvbnM=');

@$core.Deprecated('Use blockDescriptor instead')
const Block$json = {
  '1': 'Block',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'body', '3': 2, '4': 1, '5': 11, '6': '.com.giraffechain.models.BlockBody', '8': {}, '10': 'body'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode(
    'CgVCbG9jaxJGCgZoZWFkZXIYASABKAsyJC5jb20uZ2lyYWZmZWNoYWluLm1vZGVscy5CbG9ja0'
    'hlYWRlckII+kIFigECEAFSBmhlYWRlchJACgRib2R5GAIgASgLMiIuY29tLmdpcmFmZmVjaGFp'
    'bi5tb2RlbHMuQmxvY2tCb2R5Qgj6QgWKAQIQAVIEYm9keQ==');

@$core.Deprecated('Use fullBlockDescriptor instead')
const FullBlock$json = {
  '1': 'FullBlock',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.BlockHeader', '8': {}, '10': 'header'},
    {'1': 'fullBody', '3': 2, '4': 1, '5': 11, '6': '.com.giraffechain.models.FullBlockBody', '8': {}, '10': 'fullBody'},
  ],
};

/// Descriptor for `FullBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockDescriptor = $convert.base64Decode(
    'CglGdWxsQmxvY2sSRgoGaGVhZGVyGAEgASgLMiQuY29tLmdpcmFmZmVjaGFpbi5tb2RlbHMuQm'
    'xvY2tIZWFkZXJCCPpCBYoBAhABUgZoZWFkZXISTAoIZnVsbEJvZHkYAiABKAsyJi5jb20uZ2ly'
    'YWZmZWNoYWluLm1vZGVscy5GdWxsQmxvY2tCb2R5Qgj6QgWKAQIQAVIIZnVsbEJvZHk=');

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
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionId', '10': 'transactionId'},
    {'1': 'inputs', '3': 2, '4': 3, '5': 11, '6': '.com.giraffechain.models.TransactionInput', '10': 'inputs'},
    {'1': 'outputs', '3': 3, '4': 3, '5': 11, '6': '.com.giraffechain.models.TransactionOutput', '10': 'outputs'},
    {'1': 'attestation', '3': 4, '4': 3, '5': 11, '6': '.com.giraffechain.models.Witness', '10': 'attestation'},
    {'1': 'rewardParentBlockId', '3': 5, '4': 1, '5': 11, '6': '.com.giraffechain.models.BlockId', '10': 'rewardParentBlockId'},
  ],
};

/// Descriptor for `Transaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionDescriptor = $convert.base64Decode(
    'CgtUcmFuc2FjdGlvbhJMCg10cmFuc2FjdGlvbklkGAEgASgLMiYuY29tLmdpcmFmZmVjaGFpbi'
    '5tb2RlbHMuVHJhbnNhY3Rpb25JZFINdHJhbnNhY3Rpb25JZBJBCgZpbnB1dHMYAiADKAsyKS5j'
    'b20uZ2lyYWZmZWNoYWluLm1vZGVscy5UcmFuc2FjdGlvbklucHV0UgZpbnB1dHMSRAoHb3V0cH'
    'V0cxgDIAMoCzIqLmNvbS5naXJhZmZlY2hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0Ugdv'
    'dXRwdXRzEkIKC2F0dGVzdGF0aW9uGAQgAygLMiAuY29tLmdpcmFmZmVjaGFpbi5tb2RlbHMuV2'
    'l0bmVzc1ILYXR0ZXN0YXRpb24SUgoTcmV3YXJkUGFyZW50QmxvY2tJZBgFIAEoCzIgLmNvbS5n'
    'aXJhZmZlY2hhaW4ubW9kZWxzLkJsb2NrSWRSE3Jld2FyZFBhcmVudEJsb2NrSWQ=');

@$core.Deprecated('Use transactionConfirmationDescriptor instead')
const TransactionConfirmation$json = {
  '1': 'TransactionConfirmation',
  '2': [
    {'1': 'height', '3': 1, '4': 1, '5': 4, '10': 'height'},
    {'1': 'depth', '3': 2, '4': 1, '5': 4, '10': 'depth'},
  ],
};

/// Descriptor for `TransactionConfirmation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionConfirmationDescriptor = $convert.base64Decode(
    'ChdUcmFuc2FjdGlvbkNvbmZpcm1hdGlvbhIWCgZoZWlnaHQYASABKARSBmhlaWdodBIUCgVkZX'
    'B0aBgCIAEoBFIFZGVwdGg=');

@$core.Deprecated('Use witnessDescriptor instead')
const Witness$json = {
  '1': 'Witness',
  '2': [
    {'1': 'lockAddress', '3': 3, '4': 1, '5': 11, '6': '.com.giraffechain.models.LockAddress', '8': {}, '10': 'lockAddress'},
    {'1': 'lock', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.Lock', '8': {}, '10': 'lock'},
    {'1': 'key', '3': 2, '4': 1, '5': 11, '6': '.com.giraffechain.models.Key', '8': {}, '10': 'key'},
  ],
};

/// Descriptor for `Witness`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List witnessDescriptor = $convert.base64Decode(
    'CgdXaXRuZXNzElAKC2xvY2tBZGRyZXNzGAMgASgLMiQuY29tLmdpcmFmZmVjaGFpbi5tb2RlbH'
    'MuTG9ja0FkZHJlc3NCCPpCBYoBAhABUgtsb2NrQWRkcmVzcxI7CgRsb2NrGAEgASgLMh0uY29t'
    'LmdpcmFmZmVjaGFpbi5tb2RlbHMuTG9ja0II+kIFigECEAFSBGxvY2sSOAoDa2V5GAIgASgLMh'
    'wuY29tLmdpcmFmZmVjaGFpbi5tb2RlbHMuS2V5Qgj6QgWKAQIQAVIDa2V5');

@$core.Deprecated('Use transactionInputDescriptor instead')
const TransactionInput$json = {
  '1': 'TransactionInput',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionOutputReference', '8': {}, '10': 'reference'},
  ],
};

/// Descriptor for `TransactionInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionInputDescriptor = $convert.base64Decode(
    'ChBUcmFuc2FjdGlvbklucHV0ElsKCXJlZmVyZW5jZRgBIAEoCzIzLmNvbS5naXJhZmZlY2hhaW'
    '4ubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0UmVmZXJlbmNlQgj6QgWKAQIQAVIJcmVmZXJlbmNl');

@$core.Deprecated('Use transactionOutputReferenceDescriptor instead')
const TransactionOutputReference$json = {
  '1': 'TransactionOutputReference',
  '2': [
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionId', '10': 'transactionId'},
    {'1': 'index', '3': 2, '4': 1, '5': 13, '10': 'index'},
  ],
};

/// Descriptor for `TransactionOutputReference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputReferenceDescriptor = $convert.base64Decode(
    'ChpUcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZRJMCg10cmFuc2FjdGlvbklkGAEgASgLMiYuY2'
    '9tLmdpcmFmZmVjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25JZFINdHJhbnNhY3Rpb25JZBIUCgVp'
    'bmRleBgCIAEoDVIFaW5kZXg=');

@$core.Deprecated('Use transactionOutputDescriptor instead')
const TransactionOutput$json = {
  '1': 'TransactionOutput',
  '2': [
    {'1': 'lockAddress', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.LockAddress', '8': {}, '10': 'lockAddress'},
    {'1': 'quantity', '3': 2, '4': 1, '5': 4, '10': 'quantity'},
    {'1': 'account', '3': 3, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionOutputReference', '10': 'account'},
    {'1': 'graphEntry', '3': 5, '4': 1, '5': 11, '6': '.com.giraffechain.models.GraphEntry', '10': 'graphEntry'},
    {'1': 'accountRegistration', '3': 6, '4': 1, '5': 11, '6': '.com.giraffechain.models.AccountRegistration', '10': 'accountRegistration'},
    {'1': 'asset', '3': 7, '4': 1, '5': 11, '6': '.com.giraffechain.models.Asset', '10': 'asset'},
  ],
};

/// Descriptor for `TransactionOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputDescriptor = $convert.base64Decode(
    'ChFUcmFuc2FjdGlvbk91dHB1dBJQCgtsb2NrQWRkcmVzcxgBIAEoCzIkLmNvbS5naXJhZmZlY2'
    'hhaW4ubW9kZWxzLkxvY2tBZGRyZXNzQgj6QgWKAQIQAVILbG9ja0FkZHJlc3MSGgoIcXVhbnRp'
    'dHkYAiABKARSCHF1YW50aXR5Ek0KB2FjY291bnQYAyABKAsyMy5jb20uZ2lyYWZmZWNoYWluLm'
    '1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZVIHYWNjb3VudBJDCgpncmFwaEVudHJ5'
    'GAUgASgLMiMuY29tLmdpcmFmZmVjaGFpbi5tb2RlbHMuR3JhcGhFbnRyeVIKZ3JhcGhFbnRyeR'
    'JeChNhY2NvdW50UmVnaXN0cmF0aW9uGAYgASgLMiwuY29tLmdpcmFmZmVjaGFpbi5tb2RlbHMu'
    'QWNjb3VudFJlZ2lzdHJhdGlvblITYWNjb3VudFJlZ2lzdHJhdGlvbhI0CgVhc3NldBgHIAEoCz'
    'IeLmNvbS5naXJhZmZlY2hhaW4ubW9kZWxzLkFzc2V0UgVhc3NldA==');

@$core.Deprecated('Use accountRegistrationDescriptor instead')
const AccountRegistration$json = {
  '1': 'AccountRegistration',
  '2': [
    {'1': 'associationLock', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.LockAddress', '8': {}, '10': 'associationLock'},
    {'1': 'stakingRegistration', '3': 2, '4': 1, '5': 11, '6': '.com.giraffechain.models.StakingRegistration', '10': 'stakingRegistration'},
  ],
};

/// Descriptor for `AccountRegistration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accountRegistrationDescriptor = $convert.base64Decode(
    'ChNBY2NvdW50UmVnaXN0cmF0aW9uElgKD2Fzc29jaWF0aW9uTG9jaxgBIAEoCzIkLmNvbS5naX'
    'JhZmZlY2hhaW4ubW9kZWxzLkxvY2tBZGRyZXNzQgj6QgWKAQIQAVIPYXNzb2NpYXRpb25Mb2Nr'
    'El4KE3N0YWtpbmdSZWdpc3RyYXRpb24YAiABKAsyLC5jb20uZ2lyYWZmZWNoYWluLm1vZGVscy'
    '5TdGFraW5nUmVnaXN0cmF0aW9uUhNzdGFraW5nUmVnaXN0cmF0aW9u');

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
    {'1': 'vertex', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.Vertex', '9': 0, '10': 'vertex'},
    {'1': 'edge', '3': 2, '4': 1, '5': 11, '6': '.com.giraffechain.models.Edge', '9': 0, '10': 'edge'},
  ],
  '8': [
    {'1': 'entry'},
  ],
};

/// Descriptor for `GraphEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List graphEntryDescriptor = $convert.base64Decode(
    'CgpHcmFwaEVudHJ5EjkKBnZlcnRleBgBIAEoCzIfLmNvbS5naXJhZmZlY2hhaW4ubW9kZWxzLl'
    'ZlcnRleEgAUgZ2ZXJ0ZXgSMwoEZWRnZRgCIAEoCzIdLmNvbS5naXJhZmZlY2hhaW4ubW9kZWxz'
    'LkVkZ2VIAFIEZWRnZUIHCgVlbnRyeQ==');

@$core.Deprecated('Use vertexDescriptor instead')
const Vertex$json = {
  '1': 'Vertex',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'data'},
    {'1': 'edgeLockAddress', '3': 3, '4': 1, '5': 11, '6': '.com.giraffechain.models.LockAddress', '10': 'edgeLockAddress'},
  ],
};

/// Descriptor for `Vertex`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vertexDescriptor = $convert.base64Decode(
    'CgZWZXJ0ZXgSFAoFbGFiZWwYASABKAlSBWxhYmVsEisKBGRhdGEYAiABKAsyFy5nb29nbGUucH'
    'JvdG9idWYuU3RydWN0UgRkYXRhEk4KD2VkZ2VMb2NrQWRkcmVzcxgDIAEoCzIkLmNvbS5naXJh'
    'ZmZlY2hhaW4ubW9kZWxzLkxvY2tBZGRyZXNzUg9lZGdlTG9ja0FkZHJlc3M=');

@$core.Deprecated('Use edgeDescriptor instead')
const Edge$json = {
  '1': 'Edge',
  '2': [
    {'1': 'label', '3': 1, '4': 1, '5': 9, '10': 'label'},
    {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'data'},
    {'1': 'a', '3': 3, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionOutputReference', '8': {}, '10': 'a'},
    {'1': 'b', '3': 4, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionOutputReference', '8': {}, '10': 'b'},
  ],
};

/// Descriptor for `Edge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List edgeDescriptor = $convert.base64Decode(
    'CgRFZGdlEhQKBWxhYmVsGAEgASgJUgVsYWJlbBIrCgRkYXRhGAIgASgLMhcuZ29vZ2xlLnByb3'
    'RvYnVmLlN0cnVjdFIEZGF0YRJLCgFhGAMgASgLMjMuY29tLmdpcmFmZmVjaGFpbi5tb2RlbHMu'
    'VHJhbnNhY3Rpb25PdXRwdXRSZWZlcmVuY2VCCPpCBYoBAhABUgFhEksKAWIYBCABKAsyMy5jb2'
    '0uZ2lyYWZmZWNoYWluLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZUII+kIFigEC'
    'EAFSAWI=');

@$core.Deprecated('Use assetDescriptor instead')
const Asset$json = {
  '1': 'Asset',
  '2': [
    {'1': 'origin', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.TransactionOutputReference', '8': {}, '10': 'origin'},
    {'1': 'quantity', '3': 2, '4': 1, '5': 4, '10': 'quantity'},
  ],
};

/// Descriptor for `Asset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List assetDescriptor = $convert.base64Decode(
    'CgVBc3NldBJVCgZvcmlnaW4YASABKAsyMy5jb20uZ2lyYWZmZWNoYWluLm1vZGVscy5UcmFuc2'
    'FjdGlvbk91dHB1dFJlZmVyZW5jZUII+kIFigECEAFSBm9yaWdpbhIaCghxdWFudGl0eRgCIAEo'
    'BFIIcXVhbnRpdHk=');

@$core.Deprecated('Use activeStakerDescriptor instead')
const ActiveStaker$json = {
  '1': 'ActiveStaker',
  '2': [
    {'1': 'registration', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.StakingRegistration', '8': {}, '10': 'registration'},
    {'1': 'quantity', '3': 2, '4': 1, '5': 3, '10': 'quantity'},
  ],
};

/// Descriptor for `ActiveStaker`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activeStakerDescriptor = $convert.base64Decode(
    'CgxBY3RpdmVTdGFrZXISWgoMcmVnaXN0cmF0aW9uGAEgASgLMiwuY29tLmdpcmFmZmVjaGFpbi'
    '5tb2RlbHMuU3Rha2luZ1JlZ2lzdHJhdGlvbkII+kIFigECEAFSDHJlZ2lzdHJhdGlvbhIaCghx'
    'dWFudGl0eRgCIAEoA1IIcXVhbnRpdHk=');

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
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.Lock.Ed25519', '9': 0, '10': 'ed25519'},
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
    'CgRMb2NrEkEKB2VkMjU1MTkYASABKAsyJS5jb20uZ2lyYWZmZWNoYWluLm1vZGVscy5Mb2NrLk'
    'VkMjU1MTlIAFIHZWQyNTUxORoZCgdFZDI1NTE5Eg4KAnZrGAEgASgJUgJ2a0IHCgV2YWx1ZQ==');

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'ed25519', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.Key.Ed25519', '9': 0, '10': 'ed25519'},
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
    'CgNLZXkSQAoHZWQyNTUxORgBIAEoCzIkLmNvbS5naXJhZmZlY2hhaW4ubW9kZWxzLktleS5FZD'
    'I1NTE5SABSB2VkMjU1MTkaJwoHRWQyNTUxORIcCglzaWduYXR1cmUYASABKAlSCXNpZ25hdHVy'
    'ZUIHCgV2YWx1ZQ==');

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
    {'1': 'localPeer', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.ConnectedPeer', '8': {}, '10': 'localPeer'},
    {'1': 'peers', '3': 2, '4': 3, '5': 11, '6': '.com.giraffechain.models.ConnectedPeer', '10': 'peers'},
  ],
};

/// Descriptor for `PublicP2PState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publicP2PStateDescriptor = $convert.base64Decode(
    'Cg5QdWJsaWNQMlBTdGF0ZRJOCglsb2NhbFBlZXIYASABKAsyJi5jb20uZ2lyYWZmZWNoYWluLm'
    '1vZGVscy5Db25uZWN0ZWRQZWVyQgj6QgWKAQIQAVIJbG9jYWxQZWVyEjwKBXBlZXJzGAIgAygL'
    'MiYuY29tLmdpcmFmZmVjaGFpbi5tb2RlbHMuQ29ubmVjdGVkUGVlclIFcGVlcnM=');

@$core.Deprecated('Use connectedPeerDescriptor instead')
const ConnectedPeer$json = {
  '1': 'ConnectedPeer',
  '2': [
    {'1': 'peerId', '3': 1, '4': 1, '5': 11, '6': '.com.giraffechain.models.PeerId', '8': {}, '10': 'peerId'},
    {'1': 'host', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.StringValue', '10': 'host'},
    {'1': 'port', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'port'},
  ],
};

/// Descriptor for `ConnectedPeer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectedPeerDescriptor = $convert.base64Decode(
    'Cg1Db25uZWN0ZWRQZWVyEkEKBnBlZXJJZBgBIAEoCzIfLmNvbS5naXJhZmZlY2hhaW4ubW9kZW'
    'xzLlBlZXJJZEII+kIFigECEAFSBnBlZXJJZBIwCgRob3N0GAIgASgLMhwuZ29vZ2xlLnByb3Rv'
    'YnVmLlN0cmluZ1ZhbHVlUgRob3N0EjAKBHBvcnQYAyABKAsyHC5nb29nbGUucHJvdG9idWYuVU'
    'ludDMyVmFsdWVSBHBvcnQ=');

