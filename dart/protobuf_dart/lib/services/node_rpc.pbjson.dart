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
    {'1': 'transaction', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Transaction', '10': 'transaction'},
  ],
};

/// Descriptor for `BroadcastTransactionReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List broadcastTransactionReqDescriptor = $convert.base64Decode(
    'ChdCcm9hZGNhc3RUcmFuc2FjdGlvblJlcRJECgt0cmFuc2FjdGlvbhgBIAEoCzIiLmNvbS5ibG'
    '9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvblILdHJhbnNhY3Rpb24=');

@$core.Deprecated('Use broadcastTransactionResDescriptor instead')
const BroadcastTransactionRes$json = {
  '1': 'BroadcastTransactionRes',
};

/// Descriptor for `BroadcastTransactionRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List broadcastTransactionResDescriptor = $convert.base64Decode(
    'ChdCcm9hZGNhc3RUcmFuc2FjdGlvblJlcw==');

@$core.Deprecated('Use getSlotDataReqDescriptor instead')
const GetSlotDataReq$json = {
  '1': 'GetSlotDataReq',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'blockId'},
  ],
};

/// Descriptor for `GetSlotDataReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSlotDataReqDescriptor = $convert.base64Decode(
    'Cg5HZXRTbG90RGF0YVJlcRI4CgdibG9ja0lkGAEgASgLMh4uY29tLmJsb2NrY2hhaW4ubW9kZW'
    'xzLkJsb2NrSWRSB2Jsb2NrSWQ=');

@$core.Deprecated('Use getSlotDataResDescriptor instead')
const GetSlotDataRes$json = {
  '1': 'GetSlotDataRes',
  '2': [
    {'1': 'slotData', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.SlotData', '10': 'slotData'},
  ],
};

/// Descriptor for `GetSlotDataRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSlotDataResDescriptor = $convert.base64Decode(
    'Cg5HZXRTbG90RGF0YVJlcxI7CghzbG90RGF0YRgBIAEoCzIfLmNvbS5ibG9ja2NoYWluLm1vZG'
    'Vscy5TbG90RGF0YVIIc2xvdERhdGE=');

@$core.Deprecated('Use getBlockHeaderReqDescriptor instead')
const GetBlockHeaderReq$json = {
  '1': 'GetBlockHeaderReq',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'blockId'},
  ],
};

/// Descriptor for `GetBlockHeaderReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockHeaderReqDescriptor = $convert.base64Decode(
    'ChFHZXRCbG9ja0hlYWRlclJlcRI4CgdibG9ja0lkGAEgASgLMh4uY29tLmJsb2NrY2hhaW4ubW'
    '9kZWxzLkJsb2NrSWRSB2Jsb2NrSWQ=');

@$core.Deprecated('Use getBlockHeaderResDescriptor instead')
const GetBlockHeaderRes$json = {
  '1': 'GetBlockHeaderRes',
  '2': [
    {'1': 'header', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockHeader', '10': 'header'},
  ],
};

/// Descriptor for `GetBlockHeaderRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockHeaderResDescriptor = $convert.base64Decode(
    'ChFHZXRCbG9ja0hlYWRlclJlcxI6CgZoZWFkZXIYASABKAsyIi5jb20uYmxvY2tjaGFpbi5tb2'
    'RlbHMuQmxvY2tIZWFkZXJSBmhlYWRlcg==');

@$core.Deprecated('Use getBlockBodyReqDescriptor instead')
const GetBlockBodyReq$json = {
  '1': 'GetBlockBodyReq',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'blockId'},
  ],
};

/// Descriptor for `GetBlockBodyReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockBodyReqDescriptor = $convert.base64Decode(
    'Cg9HZXRCbG9ja0JvZHlSZXESOAoHYmxvY2tJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZG'
    'Vscy5CbG9ja0lkUgdibG9ja0lk');

@$core.Deprecated('Use getBlockBodyResDescriptor instead')
const GetBlockBodyRes$json = {
  '1': 'GetBlockBodyRes',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockBody', '10': 'body'},
  ],
};

/// Descriptor for `GetBlockBodyRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockBodyResDescriptor = $convert.base64Decode(
    'Cg9HZXRCbG9ja0JvZHlSZXMSNAoEYm9keRgBIAEoCzIgLmNvbS5ibG9ja2NoYWluLm1vZGVscy'
    '5CbG9ja0JvZHlSBGJvZHk=');

@$core.Deprecated('Use getFullBlockReqDescriptor instead')
const GetFullBlockReq$json = {
  '1': 'GetFullBlockReq',
  '2': [
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'blockId'},
  ],
};

/// Descriptor for `GetFullBlockReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFullBlockReqDescriptor = $convert.base64Decode(
    'Cg9HZXRGdWxsQmxvY2tSZXESOAoHYmxvY2tJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZG'
    'Vscy5CbG9ja0lkUgdibG9ja0lk');

@$core.Deprecated('Use getFullBlockResDescriptor instead')
const GetFullBlockRes$json = {
  '1': 'GetFullBlockRes',
  '2': [
    {'1': 'fullBlock', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.FullBlock', '10': 'fullBlock'},
  ],
};

/// Descriptor for `GetFullBlockRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getFullBlockResDescriptor = $convert.base64Decode(
    'Cg9HZXRGdWxsQmxvY2tSZXMSPgoJZnVsbEJsb2NrGAEgASgLMiAuY29tLmJsb2NrY2hhaW4ubW'
    '9kZWxzLkZ1bGxCbG9ja1IJZnVsbEJsb2Nr');

@$core.Deprecated('Use getTransactionReqDescriptor instead')
const GetTransactionReq$json = {
  '1': 'GetTransactionReq',
  '2': [
    {'1': 'transactionId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.TransactionId', '10': 'transactionId'},
  ],
};

/// Descriptor for `GetTransactionReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTransactionReqDescriptor = $convert.base64Decode(
    'ChFHZXRUcmFuc2FjdGlvblJlcRJKCg10cmFuc2FjdGlvbklkGAEgASgLMiQuY29tLmJsb2NrY2'
    'hhaW4ubW9kZWxzLlRyYW5zYWN0aW9uSWRSDXRyYW5zYWN0aW9uSWQ=');

@$core.Deprecated('Use getTransactionResDescriptor instead')
const GetTransactionRes$json = {
  '1': 'GetTransactionRes',
  '2': [
    {'1': 'transaction', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Transaction', '10': 'transaction'},
  ],
};

/// Descriptor for `GetTransactionRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTransactionResDescriptor = $convert.base64Decode(
    'ChFHZXRUcmFuc2FjdGlvblJlcxJECgt0cmFuc2FjdGlvbhgBIAEoCzIiLmNvbS5ibG9ja2NoYW'
    'luLm1vZGVscy5UcmFuc2FjdGlvblILdHJhbnNhY3Rpb24=');

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
    {'1': 'adopted', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '9': 0, '10': 'adopted'},
    {'1': 'unadopted', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '9': 0, '10': 'unadopted'},
  ],
  '8': [
    {'1': 'step'},
  ],
};

/// Descriptor for `FollowRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List followResDescriptor = $convert.base64Decode(
    'CglGb2xsb3dSZXMSOgoHYWRvcHRlZBgBIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZGVscy5CbG'
    '9ja0lkSABSB2Fkb3B0ZWQSPgoJdW5hZG9wdGVkGAIgASgLMh4uY29tLmJsb2NrY2hhaW4ubW9k'
    'ZWxzLkJsb2NrSWRIAFIJdW5hZG9wdGVkQgYKBHN0ZXA=');

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
    {'1': 'blockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'blockId'},
  ],
};

/// Descriptor for `GetBlockIdAtHeightRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBlockIdAtHeightResDescriptor = $convert.base64Decode(
    'ChVHZXRCbG9ja0lkQXRIZWlnaHRSZXMSOAoHYmxvY2tJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYW'
    'luLm1vZGVscy5CbG9ja0lkUgdibG9ja0lk');

