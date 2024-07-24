//
//  Generated code. Do not modify.
//  source: services/node_rpc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use broadcastTransactionReqDescriptor instead')
const BroadcastTransactionReq$json = {
  '1': 'BroadcastTransactionReq',
  '2': [
    {'1': 'transaction', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.Transaction', '8': {}, '10': 'transaction'},
  ],
};

/// Descriptor for `BroadcastTransactionReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List broadcastTransactionReqDescriptor = $convert.base64Decode(
    'ChdCcm9hZGNhc3RUcmFuc2FjdGlvblJlcRJKCgt0cmFuc2FjdGlvbhgBIAEoCzIeLmJsb2NrY2'
    'hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uQgj6QgWKAQIQAVILdHJhbnNhY3Rpb24=');

@$core.Deprecated('Use broadcastTransactionResDescriptor instead')
const BroadcastTransactionRes$json = {
  '1': 'BroadcastTransactionRes',
};

/// Descriptor for `BroadcastTransactionRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List broadcastTransactionResDescriptor = $convert.base64Decode(
    'ChdCcm9hZGNhc3RUcmFuc2FjdGlvblJlcw==');

@$core.Deprecated('Use getBlockHeaderReqDescriptor instead')
const GetBlockHeaderReq$json = {
  '1': 'GetBlockHeaderReq',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '8': {}, '10': 'blockId'},
  ],
};

/// Descriptor for `GetBlockHeaderReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockHeaderReqDescriptor = $convert.base64Decode(
    'ChFHZXRCbG9ja0hlYWRlclJlcRI+CgdibG9ja0lkGAEgASgLMhouYmxvY2tjaGFpbi5tb2RlbH'
    'MuQmxvY2tJZEII+kIFigECEAFSB2Jsb2NrSWQ=');

@$core.Deprecated('Use getBlockHeaderResDescriptor instead')
const GetBlockHeaderRes$json = {
  '1': 'GetBlockHeaderRes',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockHeader', '10': 'header'},
  ],
};

/// Descriptor for `GetBlockHeaderRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockHeaderResDescriptor = $convert.base64Decode(
    'ChFHZXRCbG9ja0hlYWRlclJlcxI2CgZoZWFkZXIYASABKAsyHi5ibG9ja2NoYWluLm1vZGVscy'
    '5CbG9ja0hlYWRlclIGaGVhZGVy');

@$core.Deprecated('Use getBlockBodyReqDescriptor instead')
const GetBlockBodyReq$json = {
  '1': 'GetBlockBodyReq',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '8': {}, '10': 'blockId'},
  ],
};

/// Descriptor for `GetBlockBodyReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockBodyReqDescriptor = $convert.base64Decode(
    'Cg9HZXRCbG9ja0JvZHlSZXESPgoHYmxvY2tJZBgBIAEoCzIaLmJsb2NrY2hhaW4ubW9kZWxzLk'
    'Jsb2NrSWRCCPpCBYoBAhABUgdibG9ja0lk');

@$core.Deprecated('Use getBlockBodyResDescriptor instead')
const GetBlockBodyRes$json = {
  '1': 'GetBlockBodyRes',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockBody', '10': 'body'},
  ],
};

/// Descriptor for `GetBlockBodyRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockBodyResDescriptor = $convert.base64Decode(
    'Cg9HZXRCbG9ja0JvZHlSZXMSMAoEYm9keRgBIAEoCzIcLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2'
    'NrQm9keVIEYm9keQ==');

@$core.Deprecated('Use getFullBlockReqDescriptor instead')
const GetFullBlockReq$json = {
  '1': 'GetFullBlockReq',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '8': {}, '10': 'blockId'},
  ],
};

/// Descriptor for `GetFullBlockReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFullBlockReqDescriptor = $convert.base64Decode(
    'Cg9HZXRGdWxsQmxvY2tSZXESPgoHYmxvY2tJZBgBIAEoCzIaLmJsb2NrY2hhaW4ubW9kZWxzLk'
    'Jsb2NrSWRCCPpCBYoBAhABUgdibG9ja0lk');

@$core.Deprecated('Use getFullBlockResDescriptor instead')
const GetFullBlockRes$json = {
  '1': 'GetFullBlockRes',
  '2': [
    {'1': 'fullBlock', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.FullBlock', '10': 'fullBlock'},
  ],
};

/// Descriptor for `GetFullBlockRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFullBlockResDescriptor = $convert.base64Decode(
    'Cg9HZXRGdWxsQmxvY2tSZXMSOgoJZnVsbEJsb2NrGAEgASgLMhwuYmxvY2tjaGFpbi5tb2RlbH'
    'MuRnVsbEJsb2NrUglmdWxsQmxvY2s=');

@$core.Deprecated('Use getTransactionReqDescriptor instead')
const GetTransactionReq$json = {
  '1': 'GetTransactionReq',
  '2': [
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.TransactionId', '8': {}, '10': 'transactionId'},
  ],
};

/// Descriptor for `GetTransactionReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTransactionReqDescriptor = $convert.base64Decode(
    'ChFHZXRUcmFuc2FjdGlvblJlcRJQCg10cmFuc2FjdGlvbklkGAEgASgLMiAuYmxvY2tjaGFpbi'
    '5tb2RlbHMuVHJhbnNhY3Rpb25JZEII+kIFigECEAFSDXRyYW5zYWN0aW9uSWQ=');

@$core.Deprecated('Use getTransactionResDescriptor instead')
const GetTransactionRes$json = {
  '1': 'GetTransactionRes',
  '2': [
    {'1': 'transaction', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.Transaction', '10': 'transaction'},
  ],
};

/// Descriptor for `GetTransactionRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTransactionResDescriptor = $convert.base64Decode(
    'ChFHZXRUcmFuc2FjdGlvblJlcxJACgt0cmFuc2FjdGlvbhgBIAEoCzIeLmJsb2NrY2hhaW4ubW'
    '9kZWxzLlRyYW5zYWN0aW9uUgt0cmFuc2FjdGlvbg==');

@$core.Deprecated('Use followReqDescriptor instead')
const FollowReq$json = {
  '1': 'FollowReq',
};

/// Descriptor for `FollowReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List followReqDescriptor = $convert.base64Decode(
    'CglGb2xsb3dSZXE=');

@$core.Deprecated('Use followResDescriptor instead')
const FollowRes$json = {
  '1': 'FollowRes',
  '2': [
    {'1': 'adopted', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '9': 0, '10': 'adopted'},
    {'1': 'unadopted', '3': 2, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '9': 0, '10': 'unadopted'},
  ],
  '8': [
    {'1': 'step'},
  ],
};

/// Descriptor for `FollowRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List followResDescriptor = $convert.base64Decode(
    'CglGb2xsb3dSZXMSNgoHYWRvcHRlZBgBIAEoCzIaLmJsb2NrY2hhaW4ubW9kZWxzLkJsb2NrSW'
    'RIAFIHYWRvcHRlZBI6Cgl1bmFkb3B0ZWQYAiABKAsyGi5ibG9ja2NoYWluLm1vZGVscy5CbG9j'
    'a0lkSABSCXVuYWRvcHRlZEIGCgRzdGVw');

@$core.Deprecated('Use getBlockIdAtHeightReqDescriptor instead')
const GetBlockIdAtHeightReq$json = {
  '1': 'GetBlockIdAtHeightReq',
  '2': [
    {'1': 'height', '3': 1, '4': 1, '5': 3, '10': 'height'},
  ],
};

/// Descriptor for `GetBlockIdAtHeightReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockIdAtHeightReqDescriptor = $convert.base64Decode(
    'ChVHZXRCbG9ja0lkQXRIZWlnaHRSZXESFgoGaGVpZ2h0GAEgASgDUgZoZWlnaHQ=');

@$core.Deprecated('Use getBlockIdAtHeightResDescriptor instead')
const GetBlockIdAtHeightRes$json = {
  '1': 'GetBlockIdAtHeightRes',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.BlockId', '10': 'blockId'},
  ],
};

/// Descriptor for `GetBlockIdAtHeightRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockIdAtHeightResDescriptor = $convert.base64Decode(
    'ChVHZXRCbG9ja0lkQXRIZWlnaHRSZXMSNAoHYmxvY2tJZBgBIAEoCzIaLmJsb2NrY2hhaW4ubW'
    '9kZWxzLkJsb2NrSWRSB2Jsb2NrSWQ=');

@$core.Deprecated('Use getAccountStateReqDescriptor instead')
const GetAccountStateReq$json = {
  '1': 'GetAccountStateReq',
  '2': [
    {'1': 'account', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '8': {}, '10': 'account'},
  ],
};

/// Descriptor for `GetAccountStateReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAccountStateReqDescriptor = $convert.base64Decode(
    'ChJHZXRBY2NvdW50U3RhdGVSZXESUQoHYWNjb3VudBgBIAEoCzItLmJsb2NrY2hhaW4ubW9kZW'
    'xzLlRyYW5zYWN0aW9uT3V0cHV0UmVmZXJlbmNlQgj6QgWKAQIQAVIHYWNjb3VudA==');

@$core.Deprecated('Use getAccountStateResDescriptor instead')
const GetAccountStateRes$json = {
  '1': 'GetAccountStateRes',
  '2': [
    {'1': 'transactionOutputs', '3': 1, '4': 3, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '10': 'transactionOutputs'},
  ],
};

/// Descriptor for `GetAccountStateRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAccountStateResDescriptor = $convert.base64Decode(
    'ChJHZXRBY2NvdW50U3RhdGVSZXMSXQoSdHJhbnNhY3Rpb25PdXRwdXRzGAEgAygLMi0uYmxvY2'
    'tjaGFpbi5tb2RlbHMuVHJhbnNhY3Rpb25PdXRwdXRSZWZlcmVuY2VSEnRyYW5zYWN0aW9uT3V0'
    'cHV0cw==');

@$core.Deprecated('Use getLockAddressStateReqDescriptor instead')
const GetLockAddressStateReq$json = {
  '1': 'GetLockAddressStateReq',
  '2': [
    {'1': 'address', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.LockAddress', '8': {}, '10': 'address'},
  ],
};

/// Descriptor for `GetLockAddressStateReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLockAddressStateReqDescriptor = $convert.base64Decode(
    'ChZHZXRMb2NrQWRkcmVzc1N0YXRlUmVxEkIKB2FkZHJlc3MYASABKAsyHi5ibG9ja2NoYWluLm'
    '1vZGVscy5Mb2NrQWRkcmVzc0II+kIFigECEAFSB2FkZHJlc3M=');

@$core.Deprecated('Use getLockAddressStateResDescriptor instead')
const GetLockAddressStateRes$json = {
  '1': 'GetLockAddressStateRes',
  '2': [
    {'1': 'transactionOutputs', '3': 1, '4': 3, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '10': 'transactionOutputs'},
  ],
};

/// Descriptor for `GetLockAddressStateRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLockAddressStateResDescriptor = $convert.base64Decode(
    'ChZHZXRMb2NrQWRkcmVzc1N0YXRlUmVzEl0KEnRyYW5zYWN0aW9uT3V0cHV0cxgBIAMoCzItLm'
    'Jsb2NrY2hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0UmVmZXJlbmNlUhJ0cmFuc2FjdGlv'
    'bk91dHB1dHM=');

@$core.Deprecated('Use getTransactionOutputReqDescriptor instead')
const GetTransactionOutputReq$json = {
  '1': 'GetTransactionOutputReq',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutputReference', '8': {}, '10': 'reference'},
  ],
};

/// Descriptor for `GetTransactionOutputReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTransactionOutputReqDescriptor = $convert.base64Decode(
    'ChdHZXRUcmFuc2FjdGlvbk91dHB1dFJlcRJVCglyZWZlcmVuY2UYASABKAsyLS5ibG9ja2NoYW'
    'luLm1vZGVscy5UcmFuc2FjdGlvbk91dHB1dFJlZmVyZW5jZUII+kIFigECEAFSCXJlZmVyZW5j'
    'ZQ==');

@$core.Deprecated('Use getTransactionOutputResDescriptor instead')
const GetTransactionOutputRes$json = {
  '1': 'GetTransactionOutputRes',
  '2': [
    {'1': 'transactionOutput', '3': 1, '4': 1, '5': 11, '6': '.blockchain.models.TransactionOutput', '10': 'transactionOutput'},
  ],
};

/// Descriptor for `GetTransactionOutputRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTransactionOutputResDescriptor = $convert.base64Decode(
    'ChdHZXRUcmFuc2FjdGlvbk91dHB1dFJlcxJSChF0cmFuc2FjdGlvbk91dHB1dBgBIAEoCzIkLm'
    'Jsb2NrY2hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uT3V0cHV0UhF0cmFuc2FjdGlvbk91dHB1dA==');

