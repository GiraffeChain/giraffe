///
//  Generated code. Do not modify.
//  source: services/node_rpc.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/transaction.pb.dart' as $1;
import '../models/block.pb.dart' as $2;

class BroadcastTransactionReq extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BroadcastTransactionReq', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.Transaction>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transaction', subBuilder: $1.Transaction.create)
    ..hasRequiredFields = false
  ;

  BroadcastTransactionReq._() : super();
  factory BroadcastTransactionReq({
    $1.Transaction? transaction,
  }) {
    final _result = create();
    if (transaction != null) {
      _result.transaction = transaction;
    }
    return _result;
  }
  factory BroadcastTransactionReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastTransactionReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastTransactionReq clone() => BroadcastTransactionReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastTransactionReq copyWith(void Function(BroadcastTransactionReq) updates) => super.copyWith((message) => updates(message as BroadcastTransactionReq)) as BroadcastTransactionReq; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionReq create() => BroadcastTransactionReq._();
  BroadcastTransactionReq createEmptyInstance() => create();
  static $pb.PbList<BroadcastTransactionReq> createRepeated() => $pb.PbList<BroadcastTransactionReq>();
  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastTransactionReq>(create);
  static BroadcastTransactionReq? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Transaction get transaction => $_getN(0);
  @$pb.TagNumber(1)
  set transaction($1.Transaction v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransaction() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransaction() => clearField(1);
  @$pb.TagNumber(1)
  $1.Transaction ensureTransaction() => $_ensure(0);
}

class BroadcastTransactionRes extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BroadcastTransactionRes', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  BroadcastTransactionRes._() : super();
  factory BroadcastTransactionRes() => create();
  factory BroadcastTransactionRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastTransactionRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastTransactionRes clone() => BroadcastTransactionRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastTransactionRes copyWith(void Function(BroadcastTransactionRes) updates) => super.copyWith((message) => updates(message as BroadcastTransactionRes)) as BroadcastTransactionRes; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionRes create() => BroadcastTransactionRes._();
  BroadcastTransactionRes createEmptyInstance() => create();
  static $pb.PbList<BroadcastTransactionRes> createRepeated() => $pb.PbList<BroadcastTransactionRes>();
  @$core.pragma('dart2js:noInline')
  static BroadcastTransactionRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastTransactionRes>(create);
  static BroadcastTransactionRes? _defaultInstance;
}

class GetBlockReq extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetBlockReq', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.BlockId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId', protoName: 'blockId', subBuilder: $2.BlockId.create)
    ..hasRequiredFields = false
  ;

  GetBlockReq._() : super();
  factory GetBlockReq({
    $2.BlockId? blockId,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    return _result;
  }
  factory GetBlockReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockReq clone() => GetBlockReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockReq copyWith(void Function(GetBlockReq) updates) => super.copyWith((message) => updates(message as GetBlockReq)) as GetBlockReq; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetBlockReq create() => GetBlockReq._();
  GetBlockReq createEmptyInstance() => create();
  static $pb.PbList<GetBlockReq> createRepeated() => $pb.PbList<GetBlockReq>();
  @$core.pragma('dart2js:noInline')
  static GetBlockReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockReq>(create);
  static GetBlockReq? _defaultInstance;

  @$pb.TagNumber(1)
  $2.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($2.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $2.BlockId ensureBlockId() => $_ensure(0);
}

class GetBlockRes extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetBlockRes', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.Block>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'block', subBuilder: $2.Block.create)
    ..hasRequiredFields = false
  ;

  GetBlockRes._() : super();
  factory GetBlockRes({
    $2.Block? block,
  }) {
    final _result = create();
    if (block != null) {
      _result.block = block;
    }
    return _result;
  }
  factory GetBlockRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockRes clone() => GetBlockRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockRes copyWith(void Function(GetBlockRes) updates) => super.copyWith((message) => updates(message as GetBlockRes)) as GetBlockRes; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetBlockRes create() => GetBlockRes._();
  GetBlockRes createEmptyInstance() => create();
  static $pb.PbList<GetBlockRes> createRepeated() => $pb.PbList<GetBlockRes>();
  @$core.pragma('dart2js:noInline')
  static GetBlockRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockRes>(create);
  static GetBlockRes? _defaultInstance;

  @$pb.TagNumber(1)
  $2.Block get block => $_getN(0);
  @$pb.TagNumber(1)
  set block($2.Block v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlock() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlock() => clearField(1);
  @$pb.TagNumber(1)
  $2.Block ensureBlock() => $_ensure(0);
}

class GetTransactionReq extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetTransactionReq', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.TransactionId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transactionId', protoName: 'transactionId', subBuilder: $1.TransactionId.create)
    ..hasRequiredFields = false
  ;

  GetTransactionReq._() : super();
  factory GetTransactionReq({
    $1.TransactionId? transactionId,
  }) {
    final _result = create();
    if (transactionId != null) {
      _result.transactionId = transactionId;
    }
    return _result;
  }
  factory GetTransactionReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetTransactionReq clone() => GetTransactionReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetTransactionReq copyWith(void Function(GetTransactionReq) updates) => super.copyWith((message) => updates(message as GetTransactionReq)) as GetTransactionReq; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetTransactionReq create() => GetTransactionReq._();
  GetTransactionReq createEmptyInstance() => create();
  static $pb.PbList<GetTransactionReq> createRepeated() => $pb.PbList<GetTransactionReq>();
  @$core.pragma('dart2js:noInline')
  static GetTransactionReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTransactionReq>(create);
  static GetTransactionReq? _defaultInstance;

  @$pb.TagNumber(1)
  $1.TransactionId get transactionId => $_getN(0);
  @$pb.TagNumber(1)
  set transactionId($1.TransactionId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransactionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransactionId() => clearField(1);
  @$pb.TagNumber(1)
  $1.TransactionId ensureTransactionId() => $_ensure(0);
}

class GetTransactionRes extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'GetTransactionRes', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.Transaction>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transaction', subBuilder: $1.Transaction.create)
    ..hasRequiredFields = false
  ;

  GetTransactionRes._() : super();
  factory GetTransactionRes({
    $1.Transaction? transaction,
  }) {
    final _result = create();
    if (transaction != null) {
      _result.transaction = transaction;
    }
    return _result;
  }
  factory GetTransactionRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetTransactionRes clone() => GetTransactionRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetTransactionRes copyWith(void Function(GetTransactionRes) updates) => super.copyWith((message) => updates(message as GetTransactionRes)) as GetTransactionRes; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static GetTransactionRes create() => GetTransactionRes._();
  GetTransactionRes createEmptyInstance() => create();
  static $pb.PbList<GetTransactionRes> createRepeated() => $pb.PbList<GetTransactionRes>();
  @$core.pragma('dart2js:noInline')
  static GetTransactionRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetTransactionRes>(create);
  static GetTransactionRes? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Transaction get transaction => $_getN(0);
  @$pb.TagNumber(1)
  set transaction($1.Transaction v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransaction() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransaction() => clearField(1);
  @$pb.TagNumber(1)
  $1.Transaction ensureTransaction() => $_ensure(0);
}

class BlockIdGossipReq extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlockIdGossipReq', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  BlockIdGossipReq._() : super();
  factory BlockIdGossipReq() => create();
  factory BlockIdGossipReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockIdGossipReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockIdGossipReq clone() => BlockIdGossipReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockIdGossipReq copyWith(void Function(BlockIdGossipReq) updates) => super.copyWith((message) => updates(message as BlockIdGossipReq)) as BlockIdGossipReq; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlockIdGossipReq create() => BlockIdGossipReq._();
  BlockIdGossipReq createEmptyInstance() => create();
  static $pb.PbList<BlockIdGossipReq> createRepeated() => $pb.PbList<BlockIdGossipReq>();
  @$core.pragma('dart2js:noInline')
  static BlockIdGossipReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockIdGossipReq>(create);
  static BlockIdGossipReq? _defaultInstance;
}

class BlockIdGossipRes extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlockIdGossipRes', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.BlockId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId', protoName: 'blockId', subBuilder: $2.BlockId.create)
    ..hasRequiredFields = false
  ;

  BlockIdGossipRes._() : super();
  factory BlockIdGossipRes({
    $2.BlockId? blockId,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    return _result;
  }
  factory BlockIdGossipRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockIdGossipRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockIdGossipRes clone() => BlockIdGossipRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockIdGossipRes copyWith(void Function(BlockIdGossipRes) updates) => super.copyWith((message) => updates(message as BlockIdGossipRes)) as BlockIdGossipRes; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlockIdGossipRes create() => BlockIdGossipRes._();
  BlockIdGossipRes createEmptyInstance() => create();
  static $pb.PbList<BlockIdGossipRes> createRepeated() => $pb.PbList<BlockIdGossipRes>();
  @$core.pragma('dart2js:noInline')
  static BlockIdGossipRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockIdGossipRes>(create);
  static BlockIdGossipRes? _defaultInstance;

  @$pb.TagNumber(1)
  $2.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($2.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $2.BlockId ensureBlockId() => $_ensure(0);
}

class TransactionIdGossipReq extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionIdGossipReq', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  TransactionIdGossipReq._() : super();
  factory TransactionIdGossipReq() => create();
  factory TransactionIdGossipReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionIdGossipReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionIdGossipReq clone() => TransactionIdGossipReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionIdGossipReq copyWith(void Function(TransactionIdGossipReq) updates) => super.copyWith((message) => updates(message as TransactionIdGossipReq)) as TransactionIdGossipReq; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TransactionIdGossipReq create() => TransactionIdGossipReq._();
  TransactionIdGossipReq createEmptyInstance() => create();
  static $pb.PbList<TransactionIdGossipReq> createRepeated() => $pb.PbList<TransactionIdGossipReq>();
  @$core.pragma('dart2js:noInline')
  static TransactionIdGossipReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionIdGossipReq>(create);
  static TransactionIdGossipReq? _defaultInstance;
}

class TransactionIdGossipRes extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionIdGossipRes', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.TransactionId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transactionId', protoName: 'transactionId', subBuilder: $1.TransactionId.create)
    ..hasRequiredFields = false
  ;

  TransactionIdGossipRes._() : super();
  factory TransactionIdGossipRes({
    $1.TransactionId? transactionId,
  }) {
    final _result = create();
    if (transactionId != null) {
      _result.transactionId = transactionId;
    }
    return _result;
  }
  factory TransactionIdGossipRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionIdGossipRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionIdGossipRes clone() => TransactionIdGossipRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionIdGossipRes copyWith(void Function(TransactionIdGossipRes) updates) => super.copyWith((message) => updates(message as TransactionIdGossipRes)) as TransactionIdGossipRes; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TransactionIdGossipRes create() => TransactionIdGossipRes._();
  TransactionIdGossipRes createEmptyInstance() => create();
  static $pb.PbList<TransactionIdGossipRes> createRepeated() => $pb.PbList<TransactionIdGossipRes>();
  @$core.pragma('dart2js:noInline')
  static TransactionIdGossipRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionIdGossipRes>(create);
  static TransactionIdGossipRes? _defaultInstance;

  @$pb.TagNumber(1)
  $1.TransactionId get transactionId => $_getN(0);
  @$pb.TagNumber(1)
  set transactionId($1.TransactionId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransactionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransactionId() => clearField(1);
  @$pb.TagNumber(1)
  $1.TransactionId ensureTransactionId() => $_ensure(0);
}

