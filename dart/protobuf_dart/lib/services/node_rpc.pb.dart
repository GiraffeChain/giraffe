//
//  Generated code. Do not modify.
//  source: services/node_rpc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../models/core.pb.dart' as $4;

class BroadcastTransactionReq extends $pb.GeneratedMessage {
  factory BroadcastTransactionReq({
    $4.Transaction? transaction,
  }) {
    final $result = create();
    if (transaction != null) {
      $result.transaction = transaction;
    }
    return $result;
  }
  BroadcastTransactionReq._() : super();
  factory BroadcastTransactionReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastTransactionReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BroadcastTransactionReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.Transaction>(1, _omitFieldNames ? '' : 'transaction', subBuilder: $4.Transaction.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastTransactionReq clone() => BroadcastTransactionReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastTransactionReq copyWith(void Function(BroadcastTransactionReq) updates) => super.copyWith((message) => updates(message as BroadcastTransactionReq)) as BroadcastTransactionReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionReq create() => BroadcastTransactionReq._();
  BroadcastTransactionReq createEmptyInstance() => create();
  static $pb.PbList<BroadcastTransactionReq> createRepeated() => $pb.PbList<BroadcastTransactionReq>();
  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastTransactionReq>(create);
  static BroadcastTransactionReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.Transaction get transaction => $_getN(0);
  @$pb.TagNumber(1)
  set transaction($4.Transaction v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransaction() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransaction() => clearField(1);
  @$pb.TagNumber(1)
  $4.Transaction ensureTransaction() => $_ensure(0);
}

class BroadcastTransactionRes extends $pb.GeneratedMessage {
  factory BroadcastTransactionRes() => create();
  BroadcastTransactionRes._() : super();
  factory BroadcastTransactionRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastTransactionRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BroadcastTransactionRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastTransactionRes clone() => BroadcastTransactionRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastTransactionRes copyWith(void Function(BroadcastTransactionRes) updates) => super.copyWith((message) => updates(message as BroadcastTransactionRes)) as BroadcastTransactionRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionRes create() => BroadcastTransactionRes._();
  BroadcastTransactionRes createEmptyInstance() => create();
  static $pb.PbList<BroadcastTransactionRes> createRepeated() => $pb.PbList<BroadcastTransactionRes>();
  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastTransactionRes>(create);
  static BroadcastTransactionRes? _defaultInstance;
}

class GetBlockHeaderReq extends $pb.GeneratedMessage {
  factory GetBlockHeaderReq({
    $4.BlockId? blockId,
  }) {
    final $result = create();
    if (blockId != null) {
      $result.blockId = blockId;
    }
    return $result;
  }
  GetBlockHeaderReq._() : super();
  factory GetBlockHeaderReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockHeaderReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockHeaderReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.BlockId>(1, _omitFieldNames ? '' : 'blockId', protoName: 'blockId', subBuilder: $4.BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockHeaderReq clone() => GetBlockHeaderReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockHeaderReq copyWith(void Function(GetBlockHeaderReq) updates) => super.copyWith((message) => updates(message as GetBlockHeaderReq)) as GetBlockHeaderReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockHeaderReq create() => GetBlockHeaderReq._();
  GetBlockHeaderReq createEmptyInstance() => create();
  static $pb.PbList<GetBlockHeaderReq> createRepeated() => $pb.PbList<GetBlockHeaderReq>();
  @$core.pragma('dart2js:noInline')
  static GetBlockHeaderReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockHeaderReq>(create);
  static GetBlockHeaderReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($4.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $4.BlockId ensureBlockId() => $_ensure(0);
}

class GetBlockHeaderRes extends $pb.GeneratedMessage {
  factory GetBlockHeaderRes({
    $4.BlockHeader? header,
  }) {
    final $result = create();
    if (header != null) {
      $result.header = header;
    }
    return $result;
  }
  GetBlockHeaderRes._() : super();
  factory GetBlockHeaderRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockHeaderRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockHeaderRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.BlockHeader>(1, _omitFieldNames ? '' : 'header', subBuilder: $4.BlockHeader.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockHeaderRes clone() => GetBlockHeaderRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockHeaderRes copyWith(void Function(GetBlockHeaderRes) updates) => super.copyWith((message) => updates(message as GetBlockHeaderRes)) as GetBlockHeaderRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockHeaderRes create() => GetBlockHeaderRes._();
  GetBlockHeaderRes createEmptyInstance() => create();
  static $pb.PbList<GetBlockHeaderRes> createRepeated() => $pb.PbList<GetBlockHeaderRes>();
  @$core.pragma('dart2js:noInline')
  static GetBlockHeaderRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockHeaderRes>(create);
  static GetBlockHeaderRes? _defaultInstance;

  @$pb.TagNumber(1)
  $4.BlockHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header($4.BlockHeader v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => clearField(1);
  @$pb.TagNumber(1)
  $4.BlockHeader ensureHeader() => $_ensure(0);
}

class GetBlockBodyReq extends $pb.GeneratedMessage {
  factory GetBlockBodyReq({
    $4.BlockId? blockId,
  }) {
    final $result = create();
    if (blockId != null) {
      $result.blockId = blockId;
    }
    return $result;
  }
  GetBlockBodyReq._() : super();
  factory GetBlockBodyReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockBodyReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockBodyReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.BlockId>(1, _omitFieldNames ? '' : 'blockId', protoName: 'blockId', subBuilder: $4.BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockBodyReq clone() => GetBlockBodyReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockBodyReq copyWith(void Function(GetBlockBodyReq) updates) => super.copyWith((message) => updates(message as GetBlockBodyReq)) as GetBlockBodyReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockBodyReq create() => GetBlockBodyReq._();
  GetBlockBodyReq createEmptyInstance() => create();
  static $pb.PbList<GetBlockBodyReq> createRepeated() => $pb.PbList<GetBlockBodyReq>();
  @$core.pragma('dart2js:noInline')
  static GetBlockBodyReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockBodyReq>(create);
  static GetBlockBodyReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($4.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $4.BlockId ensureBlockId() => $_ensure(0);
}

class GetBlockBodyRes extends $pb.GeneratedMessage {
  factory GetBlockBodyRes({
    $4.BlockBody? body,
  }) {
    final $result = create();
    if (body != null) {
      $result.body = body;
    }
    return $result;
  }
  GetBlockBodyRes._() : super();
  factory GetBlockBodyRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockBodyRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockBodyRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.BlockBody>(1, _omitFieldNames ? '' : 'body', subBuilder: $4.BlockBody.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockBodyRes clone() => GetBlockBodyRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockBodyRes copyWith(void Function(GetBlockBodyRes) updates) => super.copyWith((message) => updates(message as GetBlockBodyRes)) as GetBlockBodyRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockBodyRes create() => GetBlockBodyRes._();
  GetBlockBodyRes createEmptyInstance() => create();
  static $pb.PbList<GetBlockBodyRes> createRepeated() => $pb.PbList<GetBlockBodyRes>();
  @$core.pragma('dart2js:noInline')
  static GetBlockBodyRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockBodyRes>(create);
  static GetBlockBodyRes? _defaultInstance;

  @$pb.TagNumber(1)
  $4.BlockBody get body => $_getN(0);
  @$pb.TagNumber(1)
  set body($4.BlockBody v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => clearField(1);
  @$pb.TagNumber(1)
  $4.BlockBody ensureBody() => $_ensure(0);
}

class GetFullBlockReq extends $pb.GeneratedMessage {
  factory GetFullBlockReq({
    $4.BlockId? blockId,
  }) {
    final $result = create();
    if (blockId != null) {
      $result.blockId = blockId;
    }
    return $result;
  }
  GetFullBlockReq._() : super();
  factory GetFullBlockReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetFullBlockReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetFullBlockReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.BlockId>(1, _omitFieldNames ? '' : 'blockId', protoName: 'blockId', subBuilder: $4.BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetFullBlockReq clone() => GetFullBlockReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetFullBlockReq copyWith(void Function(GetFullBlockReq) updates) => super.copyWith((message) => updates(message as GetFullBlockReq)) as GetFullBlockReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetFullBlockReq create() => GetFullBlockReq._();
  GetFullBlockReq createEmptyInstance() => create();
  static $pb.PbList<GetFullBlockReq> createRepeated() => $pb.PbList<GetFullBlockReq>();
  @$core.pragma('dart2js:noInline')
  static GetFullBlockReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetFullBlockReq>(create);
  static GetFullBlockReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($4.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $4.BlockId ensureBlockId() => $_ensure(0);
}

class GetFullBlockRes extends $pb.GeneratedMessage {
  factory GetFullBlockRes({
    $4.FullBlock? fullBlock,
  }) {
    final $result = create();
    if (fullBlock != null) {
      $result.fullBlock = fullBlock;
    }
    return $result;
  }
  GetFullBlockRes._() : super();
  factory GetFullBlockRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetFullBlockRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetFullBlockRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.FullBlock>(1, _omitFieldNames ? '' : 'fullBlock', protoName: 'fullBlock', subBuilder: $4.FullBlock.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetFullBlockRes clone() => GetFullBlockRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetFullBlockRes copyWith(void Function(GetFullBlockRes) updates) => super.copyWith((message) => updates(message as GetFullBlockRes)) as GetFullBlockRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetFullBlockRes create() => GetFullBlockRes._();
  GetFullBlockRes createEmptyInstance() => create();
  static $pb.PbList<GetFullBlockRes> createRepeated() => $pb.PbList<GetFullBlockRes>();
  @$core.pragma('dart2js:noInline')
  static GetFullBlockRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetFullBlockRes>(create);
  static GetFullBlockRes? _defaultInstance;

  @$pb.TagNumber(1)
  $4.FullBlock get fullBlock => $_getN(0);
  @$pb.TagNumber(1)
  set fullBlock($4.FullBlock v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFullBlock() => $_has(0);
  @$pb.TagNumber(1)
  void clearFullBlock() => clearField(1);
  @$pb.TagNumber(1)
  $4.FullBlock ensureFullBlock() => $_ensure(0);
}

class GetTransactionReq extends $pb.GeneratedMessage {
  factory GetTransactionReq({
    $4.TransactionId? transactionId,
  }) {
    final $result = create();
    if (transactionId != null) {
      $result.transactionId = transactionId;
    }
    return $result;
  }
  GetTransactionReq._() : super();
  factory GetTransactionReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetTransactionReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.TransactionId>(1, _omitFieldNames ? '' : 'transactionId', protoName: 'transactionId', subBuilder: $4.TransactionId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetTransactionReq clone() => GetTransactionReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetTransactionReq copyWith(void Function(GetTransactionReq) updates) => super.copyWith((message) => updates(message as GetTransactionReq)) as GetTransactionReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTransactionReq create() => GetTransactionReq._();
  GetTransactionReq createEmptyInstance() => create();
  static $pb.PbList<GetTransactionReq> createRepeated() => $pb.PbList<GetTransactionReq>();
  @$core.pragma('dart2js:noInline')
  static GetTransactionReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTransactionReq>(create);
  static GetTransactionReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.TransactionId get transactionId => $_getN(0);
  @$pb.TagNumber(1)
  set transactionId($4.TransactionId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransactionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransactionId() => clearField(1);
  @$pb.TagNumber(1)
  $4.TransactionId ensureTransactionId() => $_ensure(0);
}

class GetTransactionRes extends $pb.GeneratedMessage {
  factory GetTransactionRes({
    $4.Transaction? transaction,
  }) {
    final $result = create();
    if (transaction != null) {
      $result.transaction = transaction;
    }
    return $result;
  }
  GetTransactionRes._() : super();
  factory GetTransactionRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetTransactionRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.Transaction>(1, _omitFieldNames ? '' : 'transaction', subBuilder: $4.Transaction.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetTransactionRes clone() => GetTransactionRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetTransactionRes copyWith(void Function(GetTransactionRes) updates) => super.copyWith((message) => updates(message as GetTransactionRes)) as GetTransactionRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTransactionRes create() => GetTransactionRes._();
  GetTransactionRes createEmptyInstance() => create();
  static $pb.PbList<GetTransactionRes> createRepeated() => $pb.PbList<GetTransactionRes>();
  @$core.pragma('dart2js:noInline')
  static GetTransactionRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTransactionRes>(create);
  static GetTransactionRes? _defaultInstance;

  @$pb.TagNumber(1)
  $4.Transaction get transaction => $_getN(0);
  @$pb.TagNumber(1)
  set transaction($4.Transaction v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransaction() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransaction() => clearField(1);
  @$pb.TagNumber(1)
  $4.Transaction ensureTransaction() => $_ensure(0);
}

class FollowReq extends $pb.GeneratedMessage {
  factory FollowReq() => create();
  FollowReq._() : super();
  factory FollowReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FollowReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FollowReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FollowReq clone() => FollowReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FollowReq copyWith(void Function(FollowReq) updates) => super.copyWith((message) => updates(message as FollowReq)) as FollowReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FollowReq create() => FollowReq._();
  FollowReq createEmptyInstance() => create();
  static $pb.PbList<FollowReq> createRepeated() => $pb.PbList<FollowReq>();
  @$core.pragma('dart2js:noInline')
  static FollowReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FollowReq>(create);
  static FollowReq? _defaultInstance;
}

enum FollowRes_Step {
  adopted, 
  unadopted, 
  notSet
}

class FollowRes extends $pb.GeneratedMessage {
  factory FollowRes({
    $4.BlockId? adopted,
    $4.BlockId? unadopted,
  }) {
    final $result = create();
    if (adopted != null) {
      $result.adopted = adopted;
    }
    if (unadopted != null) {
      $result.unadopted = unadopted;
    }
    return $result;
  }
  FollowRes._() : super();
  factory FollowRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FollowRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, FollowRes_Step> _FollowRes_StepByTag = {
    1 : FollowRes_Step.adopted,
    2 : FollowRes_Step.unadopted,
    0 : FollowRes_Step.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FollowRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$4.BlockId>(1, _omitFieldNames ? '' : 'adopted', subBuilder: $4.BlockId.create)
    ..aOM<$4.BlockId>(2, _omitFieldNames ? '' : 'unadopted', subBuilder: $4.BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FollowRes clone() => FollowRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FollowRes copyWith(void Function(FollowRes) updates) => super.copyWith((message) => updates(message as FollowRes)) as FollowRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FollowRes create() => FollowRes._();
  FollowRes createEmptyInstance() => create();
  static $pb.PbList<FollowRes> createRepeated() => $pb.PbList<FollowRes>();
  @$core.pragma('dart2js:noInline')
  static FollowRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FollowRes>(create);
  static FollowRes? _defaultInstance;

  FollowRes_Step whichStep() => _FollowRes_StepByTag[$_whichOneof(0)]!;
  void clearStep() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $4.BlockId get adopted => $_getN(0);
  @$pb.TagNumber(1)
  set adopted($4.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAdopted() => $_has(0);
  @$pb.TagNumber(1)
  void clearAdopted() => clearField(1);
  @$pb.TagNumber(1)
  $4.BlockId ensureAdopted() => $_ensure(0);

  @$pb.TagNumber(2)
  $4.BlockId get unadopted => $_getN(1);
  @$pb.TagNumber(2)
  set unadopted($4.BlockId v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasUnadopted() => $_has(1);
  @$pb.TagNumber(2)
  void clearUnadopted() => clearField(2);
  @$pb.TagNumber(2)
  $4.BlockId ensureUnadopted() => $_ensure(1);
}

class GetBlockIdAtHeightReq extends $pb.GeneratedMessage {
  factory GetBlockIdAtHeightReq({
    $fixnum.Int64? height,
  }) {
    final $result = create();
    if (height != null) {
      $result.height = height;
    }
    return $result;
  }
  GetBlockIdAtHeightReq._() : super();
  factory GetBlockIdAtHeightReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockIdAtHeightReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockIdAtHeightReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'height')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockIdAtHeightReq clone() => GetBlockIdAtHeightReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockIdAtHeightReq copyWith(void Function(GetBlockIdAtHeightReq) updates) => super.copyWith((message) => updates(message as GetBlockIdAtHeightReq)) as GetBlockIdAtHeightReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockIdAtHeightReq create() => GetBlockIdAtHeightReq._();
  GetBlockIdAtHeightReq createEmptyInstance() => create();
  static $pb.PbList<GetBlockIdAtHeightReq> createRepeated() => $pb.PbList<GetBlockIdAtHeightReq>();
  @$core.pragma('dart2js:noInline')
  static GetBlockIdAtHeightReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockIdAtHeightReq>(create);
  static GetBlockIdAtHeightReq? _defaultInstance;

  /// Non-positive value -> Depth
  /// i.e. `0` returns canonical head, `-1` returns canonical head's parent
  @$pb.TagNumber(1)
  $fixnum.Int64 get height => $_getI64(0);
  @$pb.TagNumber(1)
  set height($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHeight() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeight() => clearField(1);
}

class GetBlockIdAtHeightRes extends $pb.GeneratedMessage {
  factory GetBlockIdAtHeightRes({
    $4.BlockId? blockId,
  }) {
    final $result = create();
    if (blockId != null) {
      $result.blockId = blockId;
    }
    return $result;
  }
  GetBlockIdAtHeightRes._() : super();
  factory GetBlockIdAtHeightRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockIdAtHeightRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockIdAtHeightRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.BlockId>(1, _omitFieldNames ? '' : 'blockId', protoName: 'blockId', subBuilder: $4.BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockIdAtHeightRes clone() => GetBlockIdAtHeightRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockIdAtHeightRes copyWith(void Function(GetBlockIdAtHeightRes) updates) => super.copyWith((message) => updates(message as GetBlockIdAtHeightRes)) as GetBlockIdAtHeightRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockIdAtHeightRes create() => GetBlockIdAtHeightRes._();
  GetBlockIdAtHeightRes createEmptyInstance() => create();
  static $pb.PbList<GetBlockIdAtHeightRes> createRepeated() => $pb.PbList<GetBlockIdAtHeightRes>();
  @$core.pragma('dart2js:noInline')
  static GetBlockIdAtHeightRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockIdAtHeightRes>(create);
  static GetBlockIdAtHeightRes? _defaultInstance;

  @$pb.TagNumber(1)
  $4.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($4.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $4.BlockId ensureBlockId() => $_ensure(0);
}

class GetAccountStateReq extends $pb.GeneratedMessage {
  factory GetAccountStateReq({
    $4.TransactionOutputReference? account,
  }) {
    final $result = create();
    if (account != null) {
      $result.account = account;
    }
    return $result;
  }
  GetAccountStateReq._() : super();
  factory GetAccountStateReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAccountStateReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAccountStateReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.TransactionOutputReference>(1, _omitFieldNames ? '' : 'account', subBuilder: $4.TransactionOutputReference.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAccountStateReq clone() => GetAccountStateReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAccountStateReq copyWith(void Function(GetAccountStateReq) updates) => super.copyWith((message) => updates(message as GetAccountStateReq)) as GetAccountStateReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAccountStateReq create() => GetAccountStateReq._();
  GetAccountStateReq createEmptyInstance() => create();
  static $pb.PbList<GetAccountStateReq> createRepeated() => $pb.PbList<GetAccountStateReq>();
  @$core.pragma('dart2js:noInline')
  static GetAccountStateReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAccountStateReq>(create);
  static GetAccountStateReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.TransactionOutputReference get account => $_getN(0);
  @$pb.TagNumber(1)
  set account($4.TransactionOutputReference v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearAccount() => clearField(1);
  @$pb.TagNumber(1)
  $4.TransactionOutputReference ensureAccount() => $_ensure(0);
}

class GetAccountStateRes extends $pb.GeneratedMessage {
  factory GetAccountStateRes({
    $core.Iterable<$4.TransactionOutputReference>? transactionOutputs,
  }) {
    final $result = create();
    if (transactionOutputs != null) {
      $result.transactionOutputs.addAll(transactionOutputs);
    }
    return $result;
  }
  GetAccountStateRes._() : super();
  factory GetAccountStateRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAccountStateRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAccountStateRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..pc<$4.TransactionOutputReference>(1, _omitFieldNames ? '' : 'transactionOutputs', $pb.PbFieldType.PM, protoName: 'transactionOutputs', subBuilder: $4.TransactionOutputReference.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAccountStateRes clone() => GetAccountStateRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAccountStateRes copyWith(void Function(GetAccountStateRes) updates) => super.copyWith((message) => updates(message as GetAccountStateRes)) as GetAccountStateRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAccountStateRes create() => GetAccountStateRes._();
  GetAccountStateRes createEmptyInstance() => create();
  static $pb.PbList<GetAccountStateRes> createRepeated() => $pb.PbList<GetAccountStateRes>();
  @$core.pragma('dart2js:noInline')
  static GetAccountStateRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAccountStateRes>(create);
  static GetAccountStateRes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$4.TransactionOutputReference> get transactionOutputs => $_getList(0);
}

class GetLockAddressStateReq extends $pb.GeneratedMessage {
  factory GetLockAddressStateReq({
    $4.LockAddress? address,
  }) {
    final $result = create();
    if (address != null) {
      $result.address = address;
    }
    return $result;
  }
  GetLockAddressStateReq._() : super();
  factory GetLockAddressStateReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetLockAddressStateReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetLockAddressStateReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.LockAddress>(1, _omitFieldNames ? '' : 'address', subBuilder: $4.LockAddress.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetLockAddressStateReq clone() => GetLockAddressStateReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetLockAddressStateReq copyWith(void Function(GetLockAddressStateReq) updates) => super.copyWith((message) => updates(message as GetLockAddressStateReq)) as GetLockAddressStateReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLockAddressStateReq create() => GetLockAddressStateReq._();
  GetLockAddressStateReq createEmptyInstance() => create();
  static $pb.PbList<GetLockAddressStateReq> createRepeated() => $pb.PbList<GetLockAddressStateReq>();
  @$core.pragma('dart2js:noInline')
  static GetLockAddressStateReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetLockAddressStateReq>(create);
  static GetLockAddressStateReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.LockAddress get address => $_getN(0);
  @$pb.TagNumber(1)
  set address($4.LockAddress v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddress() => clearField(1);
  @$pb.TagNumber(1)
  $4.LockAddress ensureAddress() => $_ensure(0);
}

class GetLockAddressStateRes extends $pb.GeneratedMessage {
  factory GetLockAddressStateRes({
    $core.Iterable<$4.TransactionOutputReference>? transactionOutputs,
  }) {
    final $result = create();
    if (transactionOutputs != null) {
      $result.transactionOutputs.addAll(transactionOutputs);
    }
    return $result;
  }
  GetLockAddressStateRes._() : super();
  factory GetLockAddressStateRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetLockAddressStateRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetLockAddressStateRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..pc<$4.TransactionOutputReference>(1, _omitFieldNames ? '' : 'transactionOutputs', $pb.PbFieldType.PM, protoName: 'transactionOutputs', subBuilder: $4.TransactionOutputReference.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetLockAddressStateRes clone() => GetLockAddressStateRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetLockAddressStateRes copyWith(void Function(GetLockAddressStateRes) updates) => super.copyWith((message) => updates(message as GetLockAddressStateRes)) as GetLockAddressStateRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLockAddressStateRes create() => GetLockAddressStateRes._();
  GetLockAddressStateRes createEmptyInstance() => create();
  static $pb.PbList<GetLockAddressStateRes> createRepeated() => $pb.PbList<GetLockAddressStateRes>();
  @$core.pragma('dart2js:noInline')
  static GetLockAddressStateRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetLockAddressStateRes>(create);
  static GetLockAddressStateRes? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$4.TransactionOutputReference> get transactionOutputs => $_getList(0);
}

class GetTransactionOutputReq extends $pb.GeneratedMessage {
  factory GetTransactionOutputReq({
    $4.TransactionOutputReference? reference,
  }) {
    final $result = create();
    if (reference != null) {
      $result.reference = reference;
    }
    return $result;
  }
  GetTransactionOutputReq._() : super();
  factory GetTransactionOutputReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionOutputReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetTransactionOutputReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.TransactionOutputReference>(1, _omitFieldNames ? '' : 'reference', subBuilder: $4.TransactionOutputReference.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetTransactionOutputReq clone() => GetTransactionOutputReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetTransactionOutputReq copyWith(void Function(GetTransactionOutputReq) updates) => super.copyWith((message) => updates(message as GetTransactionOutputReq)) as GetTransactionOutputReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTransactionOutputReq create() => GetTransactionOutputReq._();
  GetTransactionOutputReq createEmptyInstance() => create();
  static $pb.PbList<GetTransactionOutputReq> createRepeated() => $pb.PbList<GetTransactionOutputReq>();
  @$core.pragma('dart2js:noInline')
  static GetTransactionOutputReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTransactionOutputReq>(create);
  static GetTransactionOutputReq? _defaultInstance;

  @$pb.TagNumber(1)
  $4.TransactionOutputReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference($4.TransactionOutputReference v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => clearField(1);
  @$pb.TagNumber(1)
  $4.TransactionOutputReference ensureReference() => $_ensure(0);
}

class GetTransactionOutputRes extends $pb.GeneratedMessage {
  factory GetTransactionOutputRes({
    $4.TransactionOutput? transactionOutput,
  }) {
    final $result = create();
    if (transactionOutput != null) {
      $result.transactionOutput = transactionOutput;
    }
    return $result;
  }
  GetTransactionOutputRes._() : super();
  factory GetTransactionOutputRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionOutputRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetTransactionOutputRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.services'), createEmptyInstance: create)
    ..aOM<$4.TransactionOutput>(1, _omitFieldNames ? '' : 'transactionOutput', protoName: 'transactionOutput', subBuilder: $4.TransactionOutput.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetTransactionOutputRes clone() => GetTransactionOutputRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetTransactionOutputRes copyWith(void Function(GetTransactionOutputRes) updates) => super.copyWith((message) => updates(message as GetTransactionOutputRes)) as GetTransactionOutputRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTransactionOutputRes create() => GetTransactionOutputRes._();
  GetTransactionOutputRes createEmptyInstance() => create();
  static $pb.PbList<GetTransactionOutputRes> createRepeated() => $pb.PbList<GetTransactionOutputRes>();
  @$core.pragma('dart2js:noInline')
  static GetTransactionOutputRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTransactionOutputRes>(create);
  static GetTransactionOutputRes? _defaultInstance;

  @$pb.TagNumber(1)
  $4.TransactionOutput get transactionOutput => $_getN(0);
  @$pb.TagNumber(1)
  set transactionOutput($4.TransactionOutput v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransactionOutput() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransactionOutput() => clearField(1);
  @$pb.TagNumber(1)
  $4.TransactionOutput ensureTransactionOutput() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
