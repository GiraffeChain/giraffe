///
//  Generated code. Do not modify.
//  source: models/transaction.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use transactionDescriptor instead')
const Transaction$json = const {
  '1': 'Transaction',
  '2': const [
    const {'1': 'inputs', '3': 1, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionInput', '10': 'inputs'},
    const {'1': 'outputs', '3': 2, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionOutput', '10': 'outputs'},
  ],
};

/// Descriptor for `Transaction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionDescriptor = $convert.base64Decode('CgtUcmFuc2FjdGlvbhI/CgZpbnB1dHMYASADKAsyJy5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25JbnB1dFIGaW5wdXRzEkIKB291dHB1dHMYAiADKAsyKC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25PdXRwdXRSB291dHB1dHM=');
@$core.Deprecated('Use transactionInputDescriptor instead')
const TransactionInput$json = const {
  '1': 'TransactionInput',
  '2': const [
    const {'1': 'spentTransactionOutput', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionOutputReference', '10': 'spentTransactionOutput'},
    const {'1': 'challengeArguments', '3': 2, '4': 3, '5': 12, '10': 'challengeArguments'},
  ],
};

/// Descriptor for `TransactionInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionInputDescriptor = $convert.base64Decode('ChBUcmFuc2FjdGlvbklucHV0EmkKFnNwZW50VHJhbnNhY3Rpb25PdXRwdXQYASABKAsyMS5jb20uYmxvY2tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25PdXRwdXRSZWZlcmVuY2VSFnNwZW50VHJhbnNhY3Rpb25PdXRwdXQSLgoSY2hhbGxlbmdlQXJndW1lbnRzGAIgAygMUhJjaGFsbGVuZ2VBcmd1bWVudHM=');
@$core.Deprecated('Use transactionOutputDescriptor instead')
const TransactionOutput$json = const {
  '1': 'TransactionOutput',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Value', '10': 'value'},
    const {'1': 'spendChallenge', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Challenge', '9': 0, '10': 'spendChallenge'},
    const {'1': 'donation', '3': 3, '4': 1, '5': 11, '6': '.com.blockchain.models.Donation', '9': 0, '10': 'donation'},
  ],
  '8': const [
    const {'1': 'constraint'},
  ],
};

/// Descriptor for `TransactionOutput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List transactionOutputDescriptor = $convert.base64Decode('ChFUcmFuc2FjdGlvbk91dHB1dBIyCgV2YWx1ZRgBIAEoCzIcLmNvbS5ibG9ja2NoYWluLm1vZGVscy5WYWx1ZVIFdmFsdWUSSgoOc3BlbmRDaGFsbGVuZ2UYAiABKAsyIC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuQ2hhbGxlbmdlSABSDnNwZW5kQ2hhbGxlbmdlEj0KCGRvbmF0aW9uGAMgASgLMh8uY29tLmJsb2NrY2hhaW4ubW9kZWxzLkRvbmF0aW9uSABSCGRvbmF0aW9uQgwKCmNvbnN0cmFpbnQ=');
@$core.Deprecated('Use valueDescriptor instead')
const Value$json = const {
  '1': 'Value',
  '2': const [
    const {'1': 'coin', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Value.Coin', '9': 0, '10': 'coin'},
    const {'1': 'data', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Value.Data', '9': 0, '10': 'data'},
  ],
  '3': const [Value_Coin$json, Value_Data$json],
  '8': const [
    const {'1': 'value'},
  ],
};

@$core.Deprecated('Use valueDescriptor instead')
const Value_Coin$json = const {
  '1': 'Coin',
  '2': const [
    const {'1': 'quantity', '3': 1, '4': 1, '5': 9, '10': 'quantity'},
    const {'1': 'donationChallengeVote', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.Challenge', '10': 'donationChallengeVote'},
  ],
};

@$core.Deprecated('Use valueDescriptor instead')
const Value_Data$json = const {
  '1': 'Data',
  '2': const [
    const {'1': 'dataType', '3': 1, '4': 1, '5': 9, '10': 'dataType'},
    const {'1': 'bytes', '3': 2, '4': 1, '5': 12, '10': 'bytes'},
  ],
};

/// Descriptor for `Value`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List valueDescriptor = $convert.base64Decode('CgVWYWx1ZRI3CgRjb2luGAEgASgLMiEuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlZhbHVlLkNvaW5IAFIEY29pbhI3CgRkYXRhGAIgASgLMiEuY29tLmJsb2NrY2hhaW4ubW9kZWxzLlZhbHVlLkRhdGFIAFIEZGF0YRp6CgRDb2luEhoKCHF1YW50aXR5GAEgASgJUghxdWFudGl0eRJWChVkb25hdGlvbkNoYWxsZW5nZVZvdGUYAiABKAsyIC5jb20uYmxvY2tjaGFpbi5tb2RlbHMuQ2hhbGxlbmdlUhVkb25hdGlvbkNoYWxsZW5nZVZvdGUaOAoERGF0YRIaCghkYXRhVHlwZRgBIAEoCVIIZGF0YVR5cGUSFAoFYnl0ZXMYAiABKAxSBWJ5dGVzQgcKBXZhbHVl');
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
@$core.Deprecated('Use challengeDescriptor instead')
const Challenge$json = const {
  '1': 'Challenge',
  '2': const [
    const {'1': 'script', '3': 1, '4': 1, '5': 9, '10': 'script'},
  ],
};

/// Descriptor for `Challenge`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List challengeDescriptor = $convert.base64Decode('CglDaGFsbGVuZ2USFgoGc2NyaXB0GAEgASgJUgZzY3JpcHQ=');
@$core.Deprecated('Use donationDescriptor instead')
const Donation$json = const {
  '1': 'Donation',
  '2': const [
    const {'1': 'from', '3': 1, '4': 1, '5': 12, '10': 'from'},
  ],
};

/// Descriptor for `Donation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List donationDescriptor = $convert.base64Decode('CghEb25hdGlvbhISCgRmcm9tGAEgASgMUgRmcm9t');
