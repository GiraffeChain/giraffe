//
//  Generated code. Do not modify.
//  source: services/staker_support_rpc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use broadcastBlockReqDescriptor instead')
const BroadcastBlockReq$json = {
  '1': 'BroadcastBlockReq',
  '2': [
    {'1': 'block', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.Block', '10': 'block'},
  ],
};

/// Descriptor for `BroadcastBlockReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List broadcastBlockReqDescriptor = $convert.base64Decode(
    'ChFCcm9hZGNhc3RCbG9ja1JlcRIyCgVibG9jaxgBIAEoCzIcLmNvbS5ibG9ja2NoYWluLm1vZG'
    'Vscy5CbG9ja1IFYmxvY2s=');

@$core.Deprecated('Use broadcastBlockResDescriptor instead')
const BroadcastBlockRes$json = {
  '1': 'BroadcastBlockRes',
};

/// Descriptor for `BroadcastBlockRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List broadcastBlockResDescriptor = $convert.base64Decode(
    'ChFCcm9hZGNhc3RCbG9ja1Jlcw==');

@$core.Deprecated('Use getStakerReqDescriptor instead')
const GetStakerReq$json = {
  '1': 'GetStakerReq',
  '2': [
    {'1': 'stakingAddress', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.StakingAddress', '10': 'stakingAddress'},
    {'1': 'parentBlockId', '3': 2, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'parentBlockId'},
    {'1': 'slot', '3': 3, '4': 1, '5': 4, '10': 'slot'},
  ],
};

/// Descriptor for `GetStakerReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStakerReqDescriptor = $convert.base64Decode(
    'CgxHZXRTdGFrZXJSZXESTQoOc3Rha2luZ0FkZHJlc3MYASABKAsyJS5jb20uYmxvY2tjaGFpbi'
    '5tb2RlbHMuU3Rha2luZ0FkZHJlc3NSDnN0YWtpbmdBZGRyZXNzEkQKDXBhcmVudEJsb2NrSWQY'
    'AiABKAsyHi5jb20uYmxvY2tjaGFpbi5tb2RlbHMuQmxvY2tJZFINcGFyZW50QmxvY2tJZBISCg'
    'RzbG90GAMgASgEUgRzbG90');

@$core.Deprecated('Use getStakerResDescriptor instead')
const GetStakerRes$json = {
  '1': 'GetStakerRes',
  '2': [
    {'1': 'staker', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.ActiveStaker', '10': 'staker'},
  ],
};

/// Descriptor for `GetStakerRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStakerResDescriptor = $convert.base64Decode(
    'CgxHZXRTdGFrZXJSZXMSOwoGc3Rha2VyGAEgASgLMiMuY29tLmJsb2NrY2hhaW4ubW9kZWxzLk'
    'FjdGl2ZVN0YWtlclIGc3Rha2Vy');

@$core.Deprecated('Use getTotalActiveStakeReqDescriptor instead')
const GetTotalActiveStakeReq$json = {
  '1': 'GetTotalActiveStakeReq',
  '2': [
    {'1': 'parentBlockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'parentBlockId'},
    {'1': 'slot', '3': 2, '4': 1, '5': 4, '10': 'slot'},
  ],
};

/// Descriptor for `GetTotalActiveStakeReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTotalActiveStakeReqDescriptor = $convert.base64Decode(
    'ChZHZXRUb3RhbEFjdGl2ZVN0YWtlUmVxEkQKDXBhcmVudEJsb2NrSWQYASABKAsyHi5jb20uYm'
    'xvY2tjaGFpbi5tb2RlbHMuQmxvY2tJZFINcGFyZW50QmxvY2tJZBISCgRzbG90GAIgASgEUgRz'
    'bG90');

@$core.Deprecated('Use getTotalActiveStakeResDescriptor instead')
const GetTotalActiveStakeRes$json = {
  '1': 'GetTotalActiveStakeRes',
  '2': [
    {'1': 'totalActiveStake', '3': 1, '4': 1, '5': 3, '10': 'totalActiveStake'},
  ],
};

/// Descriptor for `GetTotalActiveStakeRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTotalActiveStakeResDescriptor = $convert.base64Decode(
    'ChZHZXRUb3RhbEFjdGl2ZVN0YWtlUmVzEioKEHRvdGFsQWN0aXZlU3Rha2UYASABKANSEHRvdG'
    'FsQWN0aXZlU3Rha2U=');

@$core.Deprecated('Use calculateEtaReqDescriptor instead')
const CalculateEtaReq$json = {
  '1': 'CalculateEtaReq',
  '2': [
    {'1': 'parentBlockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'parentBlockId'},
    {'1': 'slot', '3': 2, '4': 1, '5': 4, '10': 'slot'},
  ],
};

/// Descriptor for `CalculateEtaReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calculateEtaReqDescriptor = $convert.base64Decode(
    'Cg9DYWxjdWxhdGVFdGFSZXESRAoNcGFyZW50QmxvY2tJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYW'
    'luLm1vZGVscy5CbG9ja0lkUg1wYXJlbnRCbG9ja0lkEhIKBHNsb3QYAiABKARSBHNsb3Q=');

@$core.Deprecated('Use calculateEtaResDescriptor instead')
const CalculateEtaRes$json = {
  '1': 'CalculateEtaRes',
  '2': [
    {'1': 'eta', '3': 1, '4': 1, '5': 12, '8': {}, '10': 'eta'},
  ],
};

/// Descriptor for `CalculateEtaRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List calculateEtaResDescriptor = $convert.base64Decode(
    'Cg9DYWxjdWxhdGVFdGFSZXMSGQoDZXRhGAEgASgMQgf6QgR6AmggUgNldGE=');

@$core.Deprecated('Use packBlockReqDescriptor instead')
const PackBlockReq$json = {
  '1': 'PackBlockReq',
  '2': [
    {'1': 'parentBlockId', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockId', '10': 'parentBlockId'},
    {'1': 'untilSlot', '3': 2, '4': 1, '5': 4, '10': 'untilSlot'},
  ],
};

/// Descriptor for `PackBlockReq`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List packBlockReqDescriptor = $convert.base64Decode(
    'CgxQYWNrQmxvY2tSZXESRAoNcGFyZW50QmxvY2tJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYWluLm'
    '1vZGVscy5CbG9ja0lkUg1wYXJlbnRCbG9ja0lkEhwKCXVudGlsU2xvdBgCIAEoBFIJdW50aWxT'
    'bG90');

@$core.Deprecated('Use packBlockResDescriptor instead')
const PackBlockRes$json = {
  '1': 'PackBlockRes',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 11, '6': '.com.blockchain.models.BlockBody', '10': 'body'},
  ],
};

/// Descriptor for `PackBlockRes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List packBlockResDescriptor = $convert.base64Decode(
    'CgxQYWNrQmxvY2tSZXMSNAoEYm9keRgBIAEoCzIgLmNvbS5ibG9ja2NoYWluLm1vZGVscy5CbG'
    '9ja0JvZHlSBGJvZHk=');

