///
//  Generated code. Do not modify.
//  source: models/block.proto
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
    const {'1': 'slot', '3': 4, '4': 1, '5': 4, '10': 'slot'},
    const {'1': 'proof', '3': 5, '4': 1, '5': 12, '10': 'proof'},
    const {'1': 'transactionIds', '3': 6, '4': 3, '5': 11, '6': '.com.blockchain.models.TransactionId', '10': 'transactionIds'},
  ],
};

/// Descriptor for `Block`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List blockDescriptor = $convert.base64Decode('CgVCbG9jaxJGCg5wYXJlbnRIZWFkZXJJZBgBIAEoCzIeLmNvbS5ibG9ja2NoYWluLm1vZGVscy5CbG9ja0lkUg5wYXJlbnRIZWFkZXJJZBIcCgl0aW1lc3RhbXAYAiABKARSCXRpbWVzdGFtcBIWCgZoZWlnaHQYAyABKARSBmhlaWdodBISCgRzbG90GAQgASgEUgRzbG90EhQKBXByb29mGAUgASgMUgVwcm9vZhJMCg50cmFuc2FjdGlvbklkcxgGIAMoCzIkLmNvbS5ibG9ja2NoYWluLm1vZGVscy5UcmFuc2FjdGlvbklkUg50cmFuc2FjdGlvbklkcw==');
