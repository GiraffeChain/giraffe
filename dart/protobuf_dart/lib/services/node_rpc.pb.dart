//
//  Generated code. Do not modify.
//  source: services/node_rpc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../models/core.pb.dart' as $1;

class HandshakeReq extends $pb.GeneratedMessage {
  factory HandshakeReq() => create();
  HandshakeReq._() : super();
  factory HandshakeReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HandshakeReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HandshakeReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.BlockId>(1, _omitFieldNames ? '' : 'genesisBlockId', protoName: 'genesisBlockId', subBuilder: $1.BlockId.create)
    ..aOS(2, _omitFieldNames ? '' : 'p2pAddress', protoName: 'p2pAddress')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HandshakeReq clone() => HandshakeReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HandshakeReq copyWith(void Function(HandshakeReq) updates) => super.copyWith((message) => updates(message as HandshakeReq)) as HandshakeReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HandshakeReq create() => HandshakeReq._();
  HandshakeReq createEmptyInstance() => create();
  static $pb.PbList<HandshakeReq> createRepeated() => $pb.PbList<HandshakeReq>();
  @$core.pragma('dart2js:noInline')
  static HandshakeReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HandshakeReq>(create);
  static HandshakeReq? _defaultInstance;

  @$pb.TagNumber(1)
  $1.BlockId get genesisBlockId => $_getN(0);
  @$pb.TagNumber(1)
  set genesisBlockId($1.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasGenesisBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGenesisBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $1.BlockId ensureGenesisBlockId() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get p2pAddress => $_getSZ(1);
  @$pb.TagNumber(2)
  set p2pAddress($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasP2pAddress() => $_has(1);
  @$pb.TagNumber(2)
  void clearP2pAddress() => clearField(2);
}

class HandshakeRes extends $pb.GeneratedMessage {
  factory HandshakeRes() => create();
  HandshakeRes._() : super();
  factory HandshakeRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HandshakeRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HandshakeRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HandshakeRes clone() => HandshakeRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HandshakeRes copyWith(void Function(HandshakeRes) updates) => super.copyWith((message) => updates(message as HandshakeRes)) as HandshakeRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HandshakeRes create() => HandshakeRes._();
  HandshakeRes createEmptyInstance() => create();
  static $pb.PbList<HandshakeRes> createRepeated() => $pb.PbList<HandshakeRes>();
  @$core.pragma('dart2js:noInline')
  static HandshakeRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HandshakeRes>(create);
  static HandshakeRes? _defaultInstance;
}

class BroadcastTransactionReq extends $pb.GeneratedMessage {
  factory BroadcastTransactionReq() => create();
  BroadcastTransactionReq._() : super();
  factory BroadcastTransactionReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastTransactionReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BroadcastTransactionReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.Transaction>(1, _omitFieldNames ? '' : 'transaction', subBuilder: $1.Transaction.create)
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
  factory BroadcastTransactionRes() => create();
  BroadcastTransactionRes._() : super();
  factory BroadcastTransactionRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastTransactionRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BroadcastTransactionRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
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

class GetBlockReq extends $pb.GeneratedMessage {
  factory GetBlockReq() => create();
  GetBlockReq._() : super();
  factory GetBlockReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.BlockId>(1, _omitFieldNames ? '' : 'blockId', protoName: 'blockId', subBuilder: $1.BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockReq clone() => GetBlockReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockReq copyWith(void Function(GetBlockReq) updates) => super.copyWith((message) => updates(message as GetBlockReq)) as GetBlockReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockReq create() => GetBlockReq._();
  GetBlockReq createEmptyInstance() => create();
  static $pb.PbList<GetBlockReq> createRepeated() => $pb.PbList<GetBlockReq>();
  @$core.pragma('dart2js:noInline')
  static GetBlockReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockReq>(create);
  static GetBlockReq? _defaultInstance;

  @$pb.TagNumber(1)
  $1.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($1.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $1.BlockId ensureBlockId() => $_ensure(0);
}

class GetBlockRes extends $pb.GeneratedMessage {
  factory GetBlockRes() => create();
  GetBlockRes._() : super();
  factory GetBlockRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetBlockRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBlockRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.Block>(1, _omitFieldNames ? '' : 'block', subBuilder: $1.Block.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetBlockRes clone() => GetBlockRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetBlockRes copyWith(void Function(GetBlockRes) updates) => super.copyWith((message) => updates(message as GetBlockRes)) as GetBlockRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBlockRes create() => GetBlockRes._();
  GetBlockRes createEmptyInstance() => create();
  static $pb.PbList<GetBlockRes> createRepeated() => $pb.PbList<GetBlockRes>();
  @$core.pragma('dart2js:noInline')
  static GetBlockRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBlockRes>(create);
  static GetBlockRes? _defaultInstance;

  @$pb.TagNumber(1)
  $1.Block get block => $_getN(0);
  @$pb.TagNumber(1)
  set block($1.Block v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlock() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlock() => clearField(1);
  @$pb.TagNumber(1)
  $1.Block ensureBlock() => $_ensure(0);
}

class GetTransactionReq extends $pb.GeneratedMessage {
  factory GetTransactionReq() => create();
  GetTransactionReq._() : super();
  factory GetTransactionReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetTransactionReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.TransactionId>(1, _omitFieldNames ? '' : 'transactionId', protoName: 'transactionId', subBuilder: $1.TransactionId.create)
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
  factory GetTransactionRes() => create();
  GetTransactionRes._() : super();
  factory GetTransactionRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetTransactionRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetTransactionRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.Transaction>(1, _omitFieldNames ? '' : 'transaction', subBuilder: $1.Transaction.create)
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
  factory BlockIdGossipReq() => create();
  BlockIdGossipReq._() : super();
  factory BlockIdGossipReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockIdGossipReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BlockIdGossipReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockIdGossipReq clone() => BlockIdGossipReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockIdGossipReq copyWith(void Function(BlockIdGossipReq) updates) => super.copyWith((message) => updates(message as BlockIdGossipReq)) as BlockIdGossipReq;

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
  factory BlockIdGossipRes() => create();
  BlockIdGossipRes._() : super();
  factory BlockIdGossipRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockIdGossipRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BlockIdGossipRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.BlockId>(1, _omitFieldNames ? '' : 'blockId', protoName: 'blockId', subBuilder: $1.BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockIdGossipRes clone() => BlockIdGossipRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockIdGossipRes copyWith(void Function(BlockIdGossipRes) updates) => super.copyWith((message) => updates(message as BlockIdGossipRes)) as BlockIdGossipRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlockIdGossipRes create() => BlockIdGossipRes._();
  BlockIdGossipRes createEmptyInstance() => create();
  static $pb.PbList<BlockIdGossipRes> createRepeated() => $pb.PbList<BlockIdGossipRes>();
  @$core.pragma('dart2js:noInline')
  static BlockIdGossipRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockIdGossipRes>(create);
  static BlockIdGossipRes? _defaultInstance;

  @$pb.TagNumber(1)
  $1.BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId($1.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $1.BlockId ensureBlockId() => $_ensure(0);
}

class TransactionIdGossipReq extends $pb.GeneratedMessage {
  factory TransactionIdGossipReq() => create();
  TransactionIdGossipReq._() : super();
  factory TransactionIdGossipReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionIdGossipReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TransactionIdGossipReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionIdGossipReq clone() => TransactionIdGossipReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionIdGossipReq copyWith(void Function(TransactionIdGossipReq) updates) => super.copyWith((message) => updates(message as TransactionIdGossipReq)) as TransactionIdGossipReq;

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
  factory TransactionIdGossipRes() => create();
  TransactionIdGossipRes._() : super();
  factory TransactionIdGossipRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionIdGossipRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TransactionIdGossipRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$1.TransactionId>(1, _omitFieldNames ? '' : 'transactionId', protoName: 'transactionId', subBuilder: $1.TransactionId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionIdGossipRes clone() => TransactionIdGossipRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionIdGossipRes copyWith(void Function(TransactionIdGossipRes) updates) => super.copyWith((message) => updates(message as TransactionIdGossipRes)) as TransactionIdGossipRes;

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


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
