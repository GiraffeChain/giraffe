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
    const {'1': 'bytes', '3': 1, '4': 1, '5': 12, '10': 'bytes'},
  ],
};

/// Descriptor for `BlockId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockIdDescriptor = $convert.base64Decode('CgdCbG9ja0lkEhQKBWJ5dGVzGAEgASgMUgVieXRlcw==');
@$core.Deprecated('Use blockDescriptor instead')
const Block$json = const {
  '1': 'Block',
  '2': const [
    const {'1': 'parentHeaderId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'parentHeaderId'},
    const {'1': 'timestamp', '3': 2, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'height', '3': 3, '4': 1, '5': 4, '10': 'height'},
    const {'1': 'proof', '3': 4, '4': 1, '5': 12, '10': 'proof'},
    const {'1': 'transactionIds', '3': 7, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionId', '10': 'transactionIds'},
    const {'1': 'reward', '3': 8, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionOutput', '10': 'reward'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode('CgVCbG9jaxJGCg5wYXJlbnRIZWFkZXJJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZGVscy5CbG9ja0lkUg5wYXJlbnRIZWFkZXJJZBIcCgl0aW1lc3RhbXAYAiABKARSCXRpbWVzdGFtcBIWCgZoZWlnaHQYAyABKARSBmhlaWdodBIUCgVwcm9vZhgEIAEoDFIFcHJvb2YSTAoOdHJhbnNhY3Rpb25JZHMYByADKAsyJC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25JZFIOdHJhbnNhY3Rpb25JZHMSQAoGcmV3YXJkGAggASgLMiguY29tLmJsb2NrY2hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0UgZyZXdhcmQ=');
@$core.Deprecated('Use fullBlockDescriptor instead')
const FullBlock$json = const {
  '1': 'FullBlock',
  '2': const [
    const {'1': 'parentHeaderId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'parentHeaderId'},
    const {'1': 'timestamp', '3': 2, '4': 1, '5': 4, '10': 'timestamp'},
    const {'1': 'height', '3': 3, '4': 1, '5': 4, '10': 'height'},
    const {'1': 'proof', '3': 4, '4': 1, '5': 12, '10': 'proof'},
    const {'1': 'transactions', '3': 7, '4': 3, '5': 11, '6': '.com.blockchain.models.Transaction', '10': 'transactions'},
    const {'1': 'reward', '3': 8, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionOutput', '10': 'reward'},
  ],
};

/// Descriptor for `FullBlock`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fullBlockDescriptor = $convert.base64Decode('CglGdWxsQmxvY2sSRgoOcGFyZW50SGVhZGVySWQYASABKAsyHi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuQmxvY2tJZFIOcGFyZW50SGVhZGVySWQSHAoJdGltZXN0YW1wGAIgASgEUgl0aW1lc3RhbXASFgoGaGVpZ2h0GAMgASgEUgZoZWlnaHQSFAoFcHJvb2YYBCABKAxSBXByb29mEkYKDHRyYW5zYWN0aW9ucxgHIAMoCzIiLmNvbS5ibG9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvblIMdHJhbnNhY3Rpb25zEkAKBnJld2FyZBgIIAEoCzIoLmNvbS5ibG9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFIGcmV3YXJk');
@$core.Deprecated('Use transactionDescriptor instead')
const Transaction$json = const {
  '1': 'Transaction',
  '2': const [
    const {'1': 'inputs', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionInput', '10': 'inputs'},
    const {'1': 'outputs', '3': 2, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionOutput', '10': 'outputs'},
    const {'1': 'rewardInputs', '3': 3, '4': 3, '5': 11, '6': '.com.blockchain.models.RewardInput', '10': 'rewardInputs'},
  ],
};

/// Descriptor for `Transaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionDescriptor = $convert.base64Decode('CgtUcmFuc2FjdGlvbhI/CgZpbnB1dHMYASADKAsyJy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25JbnB1dFIGaW5wdXRzEkIKB291dHB1dHMYAiADKAsyKC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25PdXRwdXRSB291dHB1dHMSRgoMcmV3YXJkSW5wdXRzGAMgAygLMiIuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlJld2FyZElucHV0UgxyZXdhcmRJbnB1dHM=');
@$core.Deprecated('Use transactionInputDescriptor instead')
const TransactionInput$json = const {
  '1': 'TransactionInput',
  '2': const [
    const {'1': 'reference', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionOutputReference', '10': 'reference'},
    const {'1': 'challenge', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Challenge', '10': 'challenge'},
    const {'1': 'challengeArguments', '3': 3, '4': 3, '5': 12, '10': 'challengeArguments'},
  ],
};

/// Descriptor for `TransactionInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionInputDescriptor = $convert.base64Decode('ChBUcmFuc2FjdGlvbklucHV0Ek8KCXJlZmVyZW5jZRgBIAEoCzIxLmNvbS5ibG9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZVIJcmVmZXJlbmNlEj4KCWNoYWxsZW5nZRgCIAEoCzIgLmNvbS5ibG9ja2NoYWluLm1vZGVscy5DaGFsbGVuZ2VSCWNoYWxsZW5nZRIuChJjaGFsbGVuZ2VBcmd1bWVudHMYAyADKAxSEmNoYWxsZW5nZUFyZ3VtZW50cw==');
@$core.Deprecated('Use transactionOutputDescriptor instead')
const TransactionOutput$json = const {
  '1': 'TransactionOutput',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Value', '10': 'value'},
    const {'1': 'account', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Account', '10': 'account'},
  ],
};

/// Descriptor for `TransactionOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputDescriptor = $convert.base64Decode('ChFUcmFuc2FjdGlvbk91dHB1dBIyCgV2YWx1ZRgBIAEoCzIcLmNvbS5ibG9ja2NoYWluLm1vZGVscy5WYWx1ZVIFdmFsdWUSOAoHYWNjb3VudBgCIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZGVscy5BY2NvdW50UgdhY2NvdW50');
@$core.Deprecated('Use rewardInputDescriptor instead')
const RewardInput$json = const {
  '1': 'RewardInput',
  '2': const [
    const {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'blockId'},
  ],
};

/// Descriptor for `RewardInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rewardInputDescriptor = $convert.base64Decode('CgtSZXdhcmRJbnB1dBI4CgdibG9ja0lkGAEgASgLMh4uY29tLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2NrSWRSB2Jsb2NrSWQ=');
@$core.Deprecated('Use valueDescriptor instead')
const Value$json = const {
  '1': 'Value',
  '2': const [
    const {'1': 'coin', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Value.Coin', '9': 0, '10': 'coin'},
  ],
  '3': const [Value_Coin$json],
  '8': const [
    const {'1': 'value'},
  ],
};

@$core.Deprecated('Use valueDescriptor instead')
const Value_Coin$json = const {
  '1': 'Coin',
  '2': const [
    const {'1': 'quantity', '3': 1, '4': 1, '5': 9, '10': 'quantity'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode('CgVWYWx1ZRI3CgRjb2luGAEgASgLMiEuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlZhbHVlLkNvaW5IAFIEY29pbhoiCgRDb2luEhoKCHF1YW50aXR5GAEgASgJUghxdWFudGl0eUIHCgV2YWx1ZQ==');
@$core.Deprecated('Use transactionIdDescriptor instead')
const TransactionId$json = const {
  '1': 'TransactionId',
  '2': const [
    const {'1': 'bytes', '3': 1, '4': 1, '5': 12, '10': 'bytes'},
  ],
};

/// Descriptor for `TransactionId`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionIdDescriptor = $convert.base64Decode('Cg1UcmFuc2FjdGlvbklkEhQKBWJ5dGVzGAEgASgMUgVieXRlcw==');
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
@$core.Deprecated('Use accountDescriptor instead')
const Account$json = const {
  '1': 'Account',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 12, '10': 'id'},
  ],
};

/// Descriptor for `Account`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List accountDescriptor = $convert.base64Decode('CgdBY2NvdW50Eg4KAmlkGAEgASgMUgJpZA==');
@$core.Deprecated('Use challengeDescriptor instead')
const Challenge$json = const {
  '1': 'Challenge',
  '2': const [
    const {'1': 'script', '3': 1, '4': 1, '5': 9, '10': 'script'},
  ],
};

/// Descriptor for `Challenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List challengeDescriptor = $convert.base64Decode('CglDaGFsbGVuZ2USFgoGc2NyaXB0GAEgASgJUgZzY3JpcHQ=');
