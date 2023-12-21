//
//  Generated code. Do not modify.
//  source: services/staker_support_rpc.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../models/core.pb.dart' as $2;

class BroadcastBlockReq extends $pb.GeneratedMessage {
  factory BroadcastBlockReq() => create();
  BroadcastBlockReq._() : super();
  factory BroadcastBlockReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastBlockReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BroadcastBlockReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.Block>(1, _omitFieldNames ? '' : 'block', subBuilder: $2.Block.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastBlockReq clone() => BroadcastBlockReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastBlockReq copyWith(void Function(BroadcastBlockReq) updates) => super.copyWith((message) => updates(message as BroadcastBlockReq)) as BroadcastBlockReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BroadcastBlockReq create() => BroadcastBlockReq._();
  BroadcastBlockReq createEmptyInstance() => create();
  static $pb.PbList<BroadcastBlockReq> createRepeated() => $pb.PbList<BroadcastBlockReq>();
  @$core.pragma('dart2js:noInline')
  static BroadcastBlockReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastBlockReq>(create);
  static BroadcastBlockReq? _defaultInstance;

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

class BroadcastBlockRes extends $pb.GeneratedMessage {
  factory BroadcastBlockRes() => create();
  BroadcastBlockRes._() : super();
  factory BroadcastBlockRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BroadcastBlockRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BroadcastBlockRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BroadcastBlockRes clone() => BroadcastBlockRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BroadcastBlockRes copyWith(void Function(BroadcastBlockRes) updates) => super.copyWith((message) => updates(message as BroadcastBlockRes)) as BroadcastBlockRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BroadcastBlockRes create() => BroadcastBlockRes._();
  BroadcastBlockRes createEmptyInstance() => create();
  static $pb.PbList<BroadcastBlockRes> createRepeated() => $pb.PbList<BroadcastBlockRes>();
  @$core.pragma('dart2js:noInline')
  static BroadcastBlockRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BroadcastBlockRes>(create);
  static BroadcastBlockRes? _defaultInstance;
}

class GetStakerReq extends $pb.GeneratedMessage {
  factory GetStakerReq() => create();
  GetStakerReq._() : super();
  factory GetStakerReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStakerReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStakerReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.StakingAddress>(1, _omitFieldNames ? '' : 'stakingAddress', protoName: 'stakingAddress', subBuilder: $2.StakingAddress.create)
    ..aOM<$2.BlockId>(2, _omitFieldNames ? '' : 'parentBlockId', protoName: 'parentBlockId', subBuilder: $2.BlockId.create)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'slot', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetStakerReq clone() => GetStakerReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetStakerReq copyWith(void Function(GetStakerReq) updates) => super.copyWith((message) => updates(message as GetStakerReq)) as GetStakerReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStakerReq create() => GetStakerReq._();
  GetStakerReq createEmptyInstance() => create();
  static $pb.PbList<GetStakerReq> createRepeated() => $pb.PbList<GetStakerReq>();
  @$core.pragma('dart2js:noInline')
  static GetStakerReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStakerReq>(create);
  static GetStakerReq? _defaultInstance;

  @$pb.TagNumber(1)
  $2.StakingAddress get stakingAddress => $_getN(0);
  @$pb.TagNumber(1)
  set stakingAddress($2.StakingAddress v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStakingAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearStakingAddress() => clearField(1);
  @$pb.TagNumber(1)
  $2.StakingAddress ensureStakingAddress() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.BlockId get parentBlockId => $_getN(1);
  @$pb.TagNumber(2)
  set parentBlockId($2.BlockId v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasParentBlockId() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentBlockId() => clearField(2);
  @$pb.TagNumber(2)
  $2.BlockId ensureParentBlockId() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get slot => $_getI64(2);
  @$pb.TagNumber(3)
  set slot($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSlot() => $_has(2);
  @$pb.TagNumber(3)
  void clearSlot() => clearField(3);
}

class GetStakerRes extends $pb.GeneratedMessage {
  factory GetStakerRes() => create();
  GetStakerRes._() : super();
  factory GetStakerRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStakerRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStakerRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.ActiveStaker>(1, _omitFieldNames ? '' : 'staker', subBuilder: $2.ActiveStaker.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetStakerRes clone() => GetStakerRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetStakerRes copyWith(void Function(GetStakerRes) updates) => super.copyWith((message) => updates(message as GetStakerRes)) as GetStakerRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStakerRes create() => GetStakerRes._();
  GetStakerRes createEmptyInstance() => create();
  static $pb.PbList<GetStakerRes> createRepeated() => $pb.PbList<GetStakerRes>();
  @$core.pragma('dart2js:noInline')
  static GetStakerRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStakerRes>(create);
  static GetStakerRes? _defaultInstance;

  @$pb.TagNumber(1)
  $2.ActiveStaker get staker => $_getN(0);
  @$pb.TagNumber(1)
  set staker($2.ActiveStaker v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStaker() => $_has(0);
  @$pb.TagNumber(1)
  void clearStaker() => clearField(1);
  @$pb.TagNumber(1)
  $2.ActiveStaker ensureStaker() => $_ensure(0);
}

class PackBlockReq extends $pb.GeneratedMessage {
  factory PackBlockReq() => create();
  PackBlockReq._() : super();
  factory PackBlockReq.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PackBlockReq.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PackBlockReq', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.BlockId>(1, _omitFieldNames ? '' : 'parentBlockId', protoName: 'parentBlockId', subBuilder: $2.BlockId.create)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'untilSlot', $pb.PbFieldType.OU6, protoName: 'untilSlot', defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PackBlockReq clone() => PackBlockReq()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PackBlockReq copyWith(void Function(PackBlockReq) updates) => super.copyWith((message) => updates(message as PackBlockReq)) as PackBlockReq;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PackBlockReq create() => PackBlockReq._();
  PackBlockReq createEmptyInstance() => create();
  static $pb.PbList<PackBlockReq> createRepeated() => $pb.PbList<PackBlockReq>();
  @$core.pragma('dart2js:noInline')
  static PackBlockReq getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PackBlockReq>(create);
  static PackBlockReq? _defaultInstance;

  @$pb.TagNumber(1)
  $2.BlockId get parentBlockId => $_getN(0);
  @$pb.TagNumber(1)
  set parentBlockId($2.BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasParentBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentBlockId() => clearField(1);
  @$pb.TagNumber(1)
  $2.BlockId ensureParentBlockId() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get untilSlot => $_getI64(1);
  @$pb.TagNumber(2)
  set untilSlot($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUntilSlot() => $_has(1);
  @$pb.TagNumber(2)
  void clearUntilSlot() => clearField(2);
}

class PackBlockRes extends $pb.GeneratedMessage {
  factory PackBlockRes() => create();
  PackBlockRes._() : super();
  factory PackBlockRes.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PackBlockRes.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PackBlockRes', package: const $pb.PackageName(_omitMessageNames ? '' : 'com.blockchain.services'), createEmptyInstance: create)
    ..aOM<$2.BlockBody>(1, _omitFieldNames ? '' : 'body', subBuilder: $2.BlockBody.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PackBlockRes clone() => PackBlockRes()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PackBlockRes copyWith(void Function(PackBlockRes) updates) => super.copyWith((message) => updates(message as PackBlockRes)) as PackBlockRes;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PackBlockRes create() => PackBlockRes._();
  PackBlockRes createEmptyInstance() => create();
  static $pb.PbList<PackBlockRes> createRepeated() => $pb.PbList<PackBlockRes>();
  @$core.pragma('dart2js:noInline')
  static PackBlockRes getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PackBlockRes>(create);
  static PackBlockRes? _defaultInstance;

  @$pb.TagNumber(1)
  $2.BlockBody get body => $_getN(0);
  @$pb.TagNumber(1)
  set body($2.BlockBody v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => clearField(1);
  @$pb.TagNumber(1)
  $2.BlockBody ensureBody() => $_ensure(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
