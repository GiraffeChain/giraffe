//
//  Generated code. Do not modify.
//  source: models/core.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../google/protobuf/struct.pb.dart' as $0;
import '../google/protobuf/wrappers.pb.dart' as $1;

class BlockId extends $pb.GeneratedMessage {
  factory BlockId({
    $core.String? value,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  BlockId._() : super();
  factory BlockId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BlockId', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockId clone() => BlockId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockId copyWith(void Function(BlockId) updates) => super.copyWith((message) => updates(message as BlockId)) as BlockId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlockId create() => BlockId._();
  BlockId createEmptyInstance() => create();
  static $pb.PbList<BlockId> createRepeated() => $pb.PbList<BlockId>();
  @$core.pragma('dart2js:noInline')
  static BlockId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockId>(create);
  static BlockId? _defaultInstance;

  /// Base58 encoded
  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

/// Captures a block producer's consensus-commitment to a new block
class BlockHeader extends $pb.GeneratedMessage {
  factory BlockHeader({
    BlockId? parentHeaderId,
    $fixnum.Int64? parentSlot,
    $core.String? txRoot,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? height,
    $fixnum.Int64? slot,
    StakerCertificate? stakerCertificate,
    TransactionOutputReference? account,
    $core.Map<$core.String, $core.String>? settings,
    BlockId? headerId,
  }) {
    final $result = create();
    if (parentHeaderId != null) {
      $result.parentHeaderId = parentHeaderId;
    }
    if (parentSlot != null) {
      $result.parentSlot = parentSlot;
    }
    if (txRoot != null) {
      $result.txRoot = txRoot;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (height != null) {
      $result.height = height;
    }
    if (slot != null) {
      $result.slot = slot;
    }
    if (stakerCertificate != null) {
      $result.stakerCertificate = stakerCertificate;
    }
    if (account != null) {
      $result.account = account;
    }
    if (settings != null) {
      $result.settings.addAll(settings);
    }
    if (headerId != null) {
      $result.headerId = headerId;
    }
    return $result;
  }
  BlockHeader._() : super();
  factory BlockHeader.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockHeader.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BlockHeader', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<BlockId>(1, _omitFieldNames ? '' : 'parentHeaderId', protoName: 'parentHeaderId', subBuilder: BlockId.create)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'parentSlot', $pb.PbFieldType.OU6, protoName: 'parentSlot', defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(3, _omitFieldNames ? '' : 'txRoot', protoName: 'txRoot')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'height', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'slot', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<StakerCertificate>(7, _omitFieldNames ? '' : 'stakerCertificate', protoName: 'stakerCertificate', subBuilder: StakerCertificate.create)
    ..aOM<TransactionOutputReference>(8, _omitFieldNames ? '' : 'account', subBuilder: TransactionOutputReference.create)
    ..m<$core.String, $core.String>(9, _omitFieldNames ? '' : 'settings', entryClassName: 'BlockHeader.SettingsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('blockchain.models'))
    ..aOM<BlockId>(12, _omitFieldNames ? '' : 'headerId', protoName: 'headerId', subBuilder: BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockHeader clone() => BlockHeader()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockHeader copyWith(void Function(BlockHeader) updates) => super.copyWith((message) => updates(message as BlockHeader)) as BlockHeader;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlockHeader create() => BlockHeader._();
  BlockHeader createEmptyInstance() => create();
  static $pb.PbList<BlockHeader> createRepeated() => $pb.PbList<BlockHeader>();
  @$core.pragma('dart2js:noInline')
  static BlockHeader getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockHeader>(create);
  static BlockHeader? _defaultInstance;

  /// The parent block's ID.  Each header builds from a single parent.
  @$pb.TagNumber(1)
  BlockId get parentHeaderId => $_getN(0);
  @$pb.TagNumber(1)
  set parentHeaderId(BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasParentHeaderId() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentHeaderId() => clearField(1);
  @$pb.TagNumber(1)
  BlockId ensureParentHeaderId() => $_ensure(0);

  /// The slot of the parent block
  @$pb.TagNumber(2)
  $fixnum.Int64 get parentSlot => $_getI64(1);
  @$pb.TagNumber(2)
  set parentSlot($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasParentSlot() => $_has(1);
  @$pb.TagNumber(2)
  void clearParentSlot() => clearField(2);

  /// The commitment/accumulator of the block body
  /// length = 32
  @$pb.TagNumber(3)
  $core.String get txRoot => $_getSZ(2);
  @$pb.TagNumber(3)
  set txRoot($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTxRoot() => $_has(2);
  @$pb.TagNumber(3)
  void clearTxRoot() => clearField(3);

  /// The UTC UNIX timestamp (ms) when the block was created
  @$pb.TagNumber(4)
  $fixnum.Int64 get timestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set timestamp($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimestamp() => clearField(4);

  /// The 1-based index of this block in the blockchain
  @$pb.TagNumber(5)
  $fixnum.Int64 get height => $_getI64(4);
  @$pb.TagNumber(5)
  set height($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasHeight() => $_has(4);
  @$pb.TagNumber(5)
  void clearHeight() => clearField(5);

  /// The time-slot in which the block producer created the block
  @$pb.TagNumber(6)
  $fixnum.Int64 get slot => $_getI64(5);
  @$pb.TagNumber(6)
  set slot($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSlot() => $_has(5);
  @$pb.TagNumber(6)
  void clearSlot() => clearField(6);

  /// A certificate indicating that the block producer was eligible to make this block
  @$pb.TagNumber(7)
  StakerCertificate get stakerCertificate => $_getN(6);
  @$pb.TagNumber(7)
  set stakerCertificate(StakerCertificate v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasStakerCertificate() => $_has(6);
  @$pb.TagNumber(7)
  void clearStakerCertificate() => clearField(7);
  @$pb.TagNumber(7)
  StakerCertificate ensureStakerCertificate() => $_ensure(6);

  /// The operator's staking account location
  @$pb.TagNumber(8)
  TransactionOutputReference get account => $_getN(7);
  @$pb.TagNumber(8)
  set account(TransactionOutputReference v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasAccount() => $_has(7);
  @$pb.TagNumber(8)
  void clearAccount() => clearField(8);
  @$pb.TagNumber(8)
  TransactionOutputReference ensureAccount() => $_ensure(7);

  /// Configuration or protocol changes
  @$pb.TagNumber(9)
  $core.Map<$core.String, $core.String> get settings => $_getMap(8);

  /// The ID of _this_ block header.  This value is optional and its contents are not included in the signable or identifiable data.  Clients which _can_ verify
  /// this value should verify this value, but some clients may not be able to or need to, in which case this field acts as a convenience.
  @$pb.TagNumber(12)
  BlockId get headerId => $_getN(9);
  @$pb.TagNumber(12)
  set headerId(BlockId v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasHeaderId() => $_has(9);
  @$pb.TagNumber(12)
  void clearHeaderId() => clearField(12);
  @$pb.TagNumber(12)
  BlockId ensureHeaderId() => $_ensure(9);
}

/// A certificate proving the operator's election
class StakerCertificate extends $pb.GeneratedMessage {
  factory StakerCertificate({
    $core.String? blockSignature,
    $core.String? vrfSignature,
    $core.String? vrfVK,
    $core.String? thresholdEvidence,
    $core.String? eta,
  }) {
    final $result = create();
    if (blockSignature != null) {
      $result.blockSignature = blockSignature;
    }
    if (vrfSignature != null) {
      $result.vrfSignature = vrfSignature;
    }
    if (vrfVK != null) {
      $result.vrfVK = vrfVK;
    }
    if (thresholdEvidence != null) {
      $result.thresholdEvidence = thresholdEvidence;
    }
    if (eta != null) {
      $result.eta = eta;
    }
    return $result;
  }
  StakerCertificate._() : super();
  factory StakerCertificate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StakerCertificate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StakerCertificate', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'blockSignature', protoName: 'blockSignature')
    ..aOS(2, _omitFieldNames ? '' : 'vrfSignature', protoName: 'vrfSignature')
    ..aOS(3, _omitFieldNames ? '' : 'vrfVK', protoName: 'vrfVK')
    ..aOS(4, _omitFieldNames ? '' : 'thresholdEvidence', protoName: 'thresholdEvidence')
    ..aOS(5, _omitFieldNames ? '' : 'eta')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StakerCertificate clone() => StakerCertificate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StakerCertificate copyWith(void Function(StakerCertificate) updates) => super.copyWith((message) => updates(message as StakerCertificate)) as StakerCertificate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StakerCertificate create() => StakerCertificate._();
  StakerCertificate createEmptyInstance() => create();
  static $pb.PbList<StakerCertificate> createRepeated() => $pb.PbList<StakerCertificate>();
  @$core.pragma('dart2js:noInline')
  static StakerCertificate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StakerCertificate>(create);
  static StakerCertificate? _defaultInstance;

  /// Signs the block
  /// Base58 encoded
  /// length = 64
  @$pb.TagNumber(1)
  $core.String get blockSignature => $_getSZ(0);
  @$pb.TagNumber(1)
  set blockSignature($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockSignature() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockSignature() => clearField(1);

  /// Signs `eta ++ slot` using the `vrfSK`
  /// Base58 encoded
  /// length = 80
  @$pb.TagNumber(2)
  $core.String get vrfSignature => $_getSZ(1);
  @$pb.TagNumber(2)
  set vrfSignature($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVrfSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearVrfSignature() => clearField(2);

  /// The VRF VK
  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(3)
  $core.String get vrfVK => $_getSZ(2);
  @$pb.TagNumber(3)
  set vrfVK($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVrfVK() => $_has(2);
  @$pb.TagNumber(3)
  void clearVrfVK() => clearField(3);

  /// Hash of the operator's `threshold`
  /// routine = blake2b256
  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(4)
  $core.String get thresholdEvidence => $_getSZ(3);
  @$pb.TagNumber(4)
  set thresholdEvidence($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasThresholdEvidence() => $_has(3);
  @$pb.TagNumber(4)
  void clearThresholdEvidence() => clearField(4);

  /// The epoch's randomness
  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(5)
  $core.String get eta => $_getSZ(4);
  @$pb.TagNumber(5)
  set eta($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasEta() => $_has(4);
  @$pb.TagNumber(5)
  void clearEta() => clearField(5);
}

/// A glorified tuple
class SlotId extends $pb.GeneratedMessage {
  factory SlotId({
    $fixnum.Int64? slot,
    BlockId? blockId,
  }) {
    final $result = create();
    if (slot != null) {
      $result.slot = slot;
    }
    if (blockId != null) {
      $result.blockId = blockId;
    }
    return $result;
  }
  SlotId._() : super();
  factory SlotId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SlotId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SlotId', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'slot', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<BlockId>(2, _omitFieldNames ? '' : 'blockId', protoName: 'blockId', subBuilder: BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SlotId clone() => SlotId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SlotId copyWith(void Function(SlotId) updates) => super.copyWith((message) => updates(message as SlotId)) as SlotId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SlotId create() => SlotId._();
  SlotId createEmptyInstance() => create();
  static $pb.PbList<SlotId> createRepeated() => $pb.PbList<SlotId>();
  @$core.pragma('dart2js:noInline')
  static SlotId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SlotId>(create);
  static SlotId? _defaultInstance;

  /// The slot in which a block was created
  @$pb.TagNumber(1)
  $fixnum.Int64 get slot => $_getI64(0);
  @$pb.TagNumber(1)
  set slot($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSlot() => $_has(0);
  @$pb.TagNumber(1)
  void clearSlot() => clearField(1);

  /// The ID of the block
  @$pb.TagNumber(2)
  BlockId get blockId => $_getN(1);
  @$pb.TagNumber(2)
  set blockId(BlockId v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasBlockId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBlockId() => clearField(2);
  @$pb.TagNumber(2)
  BlockId ensureBlockId() => $_ensure(1);
}

/// Captures the ordering of transaction IDs within a block
class BlockBody extends $pb.GeneratedMessage {
  factory BlockBody({
    $core.Iterable<TransactionId>? transactionIds,
  }) {
    final $result = create();
    if (transactionIds != null) {
      $result.transactionIds.addAll(transactionIds);
    }
    return $result;
  }
  BlockBody._() : super();
  factory BlockBody.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockBody.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BlockBody', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..pc<TransactionId>(1, _omitFieldNames ? '' : 'transactionIds', $pb.PbFieldType.PM, protoName: 'transactionIds', subBuilder: TransactionId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockBody clone() => BlockBody()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockBody copyWith(void Function(BlockBody) updates) => super.copyWith((message) => updates(message as BlockBody)) as BlockBody;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BlockBody create() => BlockBody._();
  BlockBody createEmptyInstance() => create();
  static $pb.PbList<BlockBody> createRepeated() => $pb.PbList<BlockBody>();
  @$core.pragma('dart2js:noInline')
  static BlockBody getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockBody>(create);
  static BlockBody? _defaultInstance;

  /// A list of Transaction IDs included in this block
  @$pb.TagNumber(1)
  $core.List<TransactionId> get transactionIds => $_getList(0);
}

/// Captures the ordering of transactions (not just IDs) within a block
class FullBlockBody extends $pb.GeneratedMessage {
  factory FullBlockBody({
    $core.Iterable<Transaction>? transactions,
  }) {
    final $result = create();
    if (transactions != null) {
      $result.transactions.addAll(transactions);
    }
    return $result;
  }
  FullBlockBody._() : super();
  factory FullBlockBody.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FullBlockBody.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FullBlockBody', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..pc<Transaction>(1, _omitFieldNames ? '' : 'transactions', $pb.PbFieldType.PM, subBuilder: Transaction.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FullBlockBody clone() => FullBlockBody()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FullBlockBody copyWith(void Function(FullBlockBody) updates) => super.copyWith((message) => updates(message as FullBlockBody)) as FullBlockBody;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FullBlockBody create() => FullBlockBody._();
  FullBlockBody createEmptyInstance() => create();
  static $pb.PbList<FullBlockBody> createRepeated() => $pb.PbList<FullBlockBody>();
  @$core.pragma('dart2js:noInline')
  static FullBlockBody getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FullBlockBody>(create);
  static FullBlockBody? _defaultInstance;

  /// A list of Transactions included in this block
  @$pb.TagNumber(1)
  $core.List<Transaction> get transactions => $_getList(0);
}

/// Captures the header and all transactions in a block
class Block extends $pb.GeneratedMessage {
  factory Block({
    BlockHeader? header,
    BlockBody? body,
  }) {
    final $result = create();
    if (header != null) {
      $result.header = header;
    }
    if (body != null) {
      $result.body = body;
    }
    return $result;
  }
  Block._() : super();
  factory Block.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Block.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Block', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<BlockHeader>(1, _omitFieldNames ? '' : 'header', subBuilder: BlockHeader.create)
    ..aOM<BlockBody>(2, _omitFieldNames ? '' : 'body', subBuilder: BlockBody.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Block clone() => Block()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Block copyWith(void Function(Block) updates) => super.copyWith((message) => updates(message as Block)) as Block;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Block create() => Block._();
  Block createEmptyInstance() => create();
  static $pb.PbList<Block> createRepeated() => $pb.PbList<Block>();
  @$core.pragma('dart2js:noInline')
  static Block getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Block>(create);
  static Block? _defaultInstance;

  /// The block's header
  @$pb.TagNumber(1)
  BlockHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(BlockHeader v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => clearField(1);
  @$pb.TagNumber(1)
  BlockHeader ensureHeader() => $_ensure(0);

  /// The block's body
  @$pb.TagNumber(2)
  BlockBody get body => $_getN(1);
  @$pb.TagNumber(2)
  set body(BlockBody v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => clearField(2);
  @$pb.TagNumber(2)
  BlockBody ensureBody() => $_ensure(1);
}

/// Captures the header and all transactions in a block
class FullBlock extends $pb.GeneratedMessage {
  factory FullBlock({
    BlockHeader? header,
    FullBlockBody? fullBody,
  }) {
    final $result = create();
    if (header != null) {
      $result.header = header;
    }
    if (fullBody != null) {
      $result.fullBody = fullBody;
    }
    return $result;
  }
  FullBlock._() : super();
  factory FullBlock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FullBlock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FullBlock', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<BlockHeader>(1, _omitFieldNames ? '' : 'header', subBuilder: BlockHeader.create)
    ..aOM<FullBlockBody>(2, _omitFieldNames ? '' : 'fullBody', protoName: 'fullBody', subBuilder: FullBlockBody.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FullBlock clone() => FullBlock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FullBlock copyWith(void Function(FullBlock) updates) => super.copyWith((message) => updates(message as FullBlock)) as FullBlock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FullBlock create() => FullBlock._();
  FullBlock createEmptyInstance() => create();
  static $pb.PbList<FullBlock> createRepeated() => $pb.PbList<FullBlock>();
  @$core.pragma('dart2js:noInline')
  static FullBlock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FullBlock>(create);
  static FullBlock? _defaultInstance;

  /// The block's header
  @$pb.TagNumber(1)
  BlockHeader get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(BlockHeader v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => clearField(1);
  @$pb.TagNumber(1)
  BlockHeader ensureHeader() => $_ensure(0);

  /// The block's full body
  @$pb.TagNumber(2)
  FullBlockBody get fullBody => $_getN(1);
  @$pb.TagNumber(2)
  set fullBody(FullBlockBody v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFullBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearFullBody() => clearField(2);
  @$pb.TagNumber(2)
  FullBlockBody ensureFullBody() => $_ensure(1);
}

/// Represents the identifier of a Transction.  It is constructed from the evidence of the signable bytes of the Transaction.
class TransactionId extends $pb.GeneratedMessage {
  factory TransactionId({
    $core.String? value,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  TransactionId._() : super();
  factory TransactionId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TransactionId', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionId clone() => TransactionId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionId copyWith(void Function(TransactionId) updates) => super.copyWith((message) => updates(message as TransactionId)) as TransactionId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransactionId create() => TransactionId._();
  TransactionId createEmptyInstance() => create();
  static $pb.PbList<TransactionId> createRepeated() => $pb.PbList<TransactionId>();
  @$core.pragma('dart2js:noInline')
  static TransactionId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionId>(create);
  static TransactionId? _defaultInstance;

  /// The evidence of the Transaction's signable bytes
  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class Transaction extends $pb.GeneratedMessage {
  factory Transaction({
    TransactionId? transactionId,
    $core.Iterable<TransactionInput>? inputs,
    $core.Iterable<TransactionOutput>? outputs,
    $core.Iterable<Witness>? attestation,
    BlockId? rewardParentBlockId,
  }) {
    final $result = create();
    if (transactionId != null) {
      $result.transactionId = transactionId;
    }
    if (inputs != null) {
      $result.inputs.addAll(inputs);
    }
    if (outputs != null) {
      $result.outputs.addAll(outputs);
    }
    if (attestation != null) {
      $result.attestation.addAll(attestation);
    }
    if (rewardParentBlockId != null) {
      $result.rewardParentBlockId = rewardParentBlockId;
    }
    return $result;
  }
  Transaction._() : super();
  factory Transaction.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Transaction.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Transaction', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<TransactionId>(1, _omitFieldNames ? '' : 'transactionId', protoName: 'transactionId', subBuilder: TransactionId.create)
    ..pc<TransactionInput>(2, _omitFieldNames ? '' : 'inputs', $pb.PbFieldType.PM, subBuilder: TransactionInput.create)
    ..pc<TransactionOutput>(3, _omitFieldNames ? '' : 'outputs', $pb.PbFieldType.PM, subBuilder: TransactionOutput.create)
    ..pc<Witness>(4, _omitFieldNames ? '' : 'attestation', $pb.PbFieldType.PM, subBuilder: Witness.create)
    ..aOM<BlockId>(5, _omitFieldNames ? '' : 'rewardParentBlockId', protoName: 'rewardParentBlockId', subBuilder: BlockId.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Transaction clone() => Transaction()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Transaction copyWith(void Function(Transaction) updates) => super.copyWith((message) => updates(message as Transaction)) as Transaction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Transaction create() => Transaction._();
  Transaction createEmptyInstance() => create();
  static $pb.PbList<Transaction> createRepeated() => $pb.PbList<Transaction>();
  @$core.pragma('dart2js:noInline')
  static Transaction getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Transaction>(create);
  static Transaction? _defaultInstance;

  @$pb.TagNumber(1)
  TransactionId get transactionId => $_getN(0);
  @$pb.TagNumber(1)
  set transactionId(TransactionId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransactionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransactionId() => clearField(1);
  @$pb.TagNumber(1)
  TransactionId ensureTransactionId() => $_ensure(0);

  /// If this is a reward transaction, this field should be empty
  @$pb.TagNumber(2)
  $core.List<TransactionInput> get inputs => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<TransactionOutput> get outputs => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<Witness> get attestation => $_getList(3);

  /// User transactions should leave this empty.
  /// When not null, this Transaction is assumed to be a reward transaction, and the value of this field should be the parent block ID
  @$pb.TagNumber(5)
  BlockId get rewardParentBlockId => $_getN(4);
  @$pb.TagNumber(5)
  set rewardParentBlockId(BlockId v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasRewardParentBlockId() => $_has(4);
  @$pb.TagNumber(5)
  void clearRewardParentBlockId() => clearField(5);
  @$pb.TagNumber(5)
  BlockId ensureRewardParentBlockId() => $_ensure(4);
}

class Witness extends $pb.GeneratedMessage {
  factory Witness({
    Lock? lock,
    Key? key,
    LockAddress? lockAddress,
  }) {
    final $result = create();
    if (lock != null) {
      $result.lock = lock;
    }
    if (key != null) {
      $result.key = key;
    }
    if (lockAddress != null) {
      $result.lockAddress = lockAddress;
    }
    return $result;
  }
  Witness._() : super();
  factory Witness.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Witness.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Witness', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<Lock>(1, _omitFieldNames ? '' : 'lock', subBuilder: Lock.create)
    ..aOM<Key>(2, _omitFieldNames ? '' : 'key', subBuilder: Key.create)
    ..aOM<LockAddress>(3, _omitFieldNames ? '' : 'lockAddress', protoName: 'lockAddress', subBuilder: LockAddress.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Witness clone() => Witness()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Witness copyWith(void Function(Witness) updates) => super.copyWith((message) => updates(message as Witness)) as Witness;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Witness create() => Witness._();
  Witness createEmptyInstance() => create();
  static $pb.PbList<Witness> createRepeated() => $pb.PbList<Witness>();
  @$core.pragma('dart2js:noInline')
  static Witness getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Witness>(create);
  static Witness? _defaultInstance;

  @$pb.TagNumber(1)
  Lock get lock => $_getN(0);
  @$pb.TagNumber(1)
  set lock(Lock v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasLock() => $_has(0);
  @$pb.TagNumber(1)
  void clearLock() => clearField(1);
  @$pb.TagNumber(1)
  Lock ensureLock() => $_ensure(0);

  @$pb.TagNumber(2)
  Key get key => $_getN(1);
  @$pb.TagNumber(2)
  set key(Key v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => clearField(2);
  @$pb.TagNumber(2)
  Key ensureKey() => $_ensure(1);

  @$pb.TagNumber(3)
  LockAddress get lockAddress => $_getN(2);
  @$pb.TagNumber(3)
  set lockAddress(LockAddress v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasLockAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearLockAddress() => clearField(3);
  @$pb.TagNumber(3)
  LockAddress ensureLockAddress() => $_ensure(2);
}

class TransactionInput extends $pb.GeneratedMessage {
  factory TransactionInput({
    TransactionOutputReference? reference,
    Value? value,
  }) {
    final $result = create();
    if (reference != null) {
      $result.reference = reference;
    }
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  TransactionInput._() : super();
  factory TransactionInput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionInput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TransactionInput', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<TransactionOutputReference>(1, _omitFieldNames ? '' : 'reference', subBuilder: TransactionOutputReference.create)
    ..aOM<Value>(2, _omitFieldNames ? '' : 'value', subBuilder: Value.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionInput clone() => TransactionInput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionInput copyWith(void Function(TransactionInput) updates) => super.copyWith((message) => updates(message as TransactionInput)) as TransactionInput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransactionInput create() => TransactionInput._();
  TransactionInput createEmptyInstance() => create();
  static $pb.PbList<TransactionInput> createRepeated() => $pb.PbList<TransactionInput>();
  @$core.pragma('dart2js:noInline')
  static TransactionInput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionInput>(create);
  static TransactionInput? _defaultInstance;

  @$pb.TagNumber(1)
  TransactionOutputReference get reference => $_getN(0);
  @$pb.TagNumber(1)
  set reference(TransactionOutputReference v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => clearField(1);
  @$pb.TagNumber(1)
  TransactionOutputReference ensureReference() => $_ensure(0);

  @$pb.TagNumber(2)
  Value get value => $_getN(1);
  @$pb.TagNumber(2)
  set value(Value v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
  @$pb.TagNumber(2)
  Value ensureValue() => $_ensure(1);
}

class TransactionOutputReference extends $pb.GeneratedMessage {
  factory TransactionOutputReference({
    TransactionId? transactionId,
    $core.int? index,
  }) {
    final $result = create();
    if (transactionId != null) {
      $result.transactionId = transactionId;
    }
    if (index != null) {
      $result.index = index;
    }
    return $result;
  }
  TransactionOutputReference._() : super();
  factory TransactionOutputReference.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionOutputReference.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TransactionOutputReference', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<TransactionId>(1, _omitFieldNames ? '' : 'transactionId', protoName: 'transactionId', subBuilder: TransactionId.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'index', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionOutputReference clone() => TransactionOutputReference()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionOutputReference copyWith(void Function(TransactionOutputReference) updates) => super.copyWith((message) => updates(message as TransactionOutputReference)) as TransactionOutputReference;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransactionOutputReference create() => TransactionOutputReference._();
  TransactionOutputReference createEmptyInstance() => create();
  static $pb.PbList<TransactionOutputReference> createRepeated() => $pb.PbList<TransactionOutputReference>();
  @$core.pragma('dart2js:noInline')
  static TransactionOutputReference getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionOutputReference>(create);
  static TransactionOutputReference? _defaultInstance;

  @$pb.TagNumber(1)
  TransactionId get transactionId => $_getN(0);
  @$pb.TagNumber(1)
  set transactionId(TransactionId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTransactionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransactionId() => clearField(1);
  @$pb.TagNumber(1)
  TransactionId ensureTransactionId() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get index => $_getIZ(1);
  @$pb.TagNumber(2)
  set index($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearIndex() => clearField(2);
}

class TransactionOutput extends $pb.GeneratedMessage {
  factory TransactionOutput({
    LockAddress? lockAddress,
    Value? value,
    TransactionOutputReference? account,
  }) {
    final $result = create();
    if (lockAddress != null) {
      $result.lockAddress = lockAddress;
    }
    if (value != null) {
      $result.value = value;
    }
    if (account != null) {
      $result.account = account;
    }
    return $result;
  }
  TransactionOutput._() : super();
  factory TransactionOutput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionOutput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TransactionOutput', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<LockAddress>(1, _omitFieldNames ? '' : 'lockAddress', protoName: 'lockAddress', subBuilder: LockAddress.create)
    ..aOM<Value>(2, _omitFieldNames ? '' : 'value', subBuilder: Value.create)
    ..aOM<TransactionOutputReference>(3, _omitFieldNames ? '' : 'account', subBuilder: TransactionOutputReference.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionOutput clone() => TransactionOutput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionOutput copyWith(void Function(TransactionOutput) updates) => super.copyWith((message) => updates(message as TransactionOutput)) as TransactionOutput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TransactionOutput create() => TransactionOutput._();
  TransactionOutput createEmptyInstance() => create();
  static $pb.PbList<TransactionOutput> createRepeated() => $pb.PbList<TransactionOutput>();
  @$core.pragma('dart2js:noInline')
  static TransactionOutput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionOutput>(create);
  static TransactionOutput? _defaultInstance;

  @$pb.TagNumber(1)
  LockAddress get lockAddress => $_getN(0);
  @$pb.TagNumber(1)
  set lockAddress(LockAddress v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasLockAddress() => $_has(0);
  @$pb.TagNumber(1)
  void clearLockAddress() => clearField(1);
  @$pb.TagNumber(1)
  LockAddress ensureLockAddress() => $_ensure(0);

  @$pb.TagNumber(2)
  Value get value => $_getN(1);
  @$pb.TagNumber(2)
  set value(Value v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
  @$pb.TagNumber(2)
  Value ensureValue() => $_ensure(1);

  /// Optional
  @$pb.TagNumber(3)
  TransactionOutputReference get account => $_getN(2);
  @$pb.TagNumber(3)
  set account(TransactionOutputReference v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasAccount() => $_has(2);
  @$pb.TagNumber(3)
  void clearAccount() => clearField(3);
  @$pb.TagNumber(3)
  TransactionOutputReference ensureAccount() => $_ensure(2);
}

class Value extends $pb.GeneratedMessage {
  factory Value({
    $fixnum.Int64? quantity,
    AccountRegistration? accountRegistration,
    GraphEntry? graphEntry,
  }) {
    final $result = create();
    if (quantity != null) {
      $result.quantity = quantity;
    }
    if (accountRegistration != null) {
      $result.accountRegistration = accountRegistration;
    }
    if (graphEntry != null) {
      $result.graphEntry = graphEntry;
    }
    return $result;
  }
  Value._() : super();
  factory Value.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Value.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Value', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'quantity', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<AccountRegistration>(2, _omitFieldNames ? '' : 'accountRegistration', protoName: 'accountRegistration', subBuilder: AccountRegistration.create)
    ..aOM<GraphEntry>(3, _omitFieldNames ? '' : 'graphEntry', protoName: 'graphEntry', subBuilder: GraphEntry.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Value clone() => Value()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Value copyWith(void Function(Value) updates) => super.copyWith((message) => updates(message as Value)) as Value;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Value create() => Value._();
  Value createEmptyInstance() => create();
  static $pb.PbList<Value> createRepeated() => $pb.PbList<Value>();
  @$core.pragma('dart2js:noInline')
  static Value getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Value>(create);
  static Value? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get quantity => $_getI64(0);
  @$pb.TagNumber(1)
  set quantity($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasQuantity() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuantity() => clearField(1);

  @$pb.TagNumber(2)
  AccountRegistration get accountRegistration => $_getN(1);
  @$pb.TagNumber(2)
  set accountRegistration(AccountRegistration v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccountRegistration() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccountRegistration() => clearField(2);
  @$pb.TagNumber(2)
  AccountRegistration ensureAccountRegistration() => $_ensure(1);

  /// Optional
  @$pb.TagNumber(3)
  GraphEntry get graphEntry => $_getN(2);
  @$pb.TagNumber(3)
  set graphEntry(GraphEntry v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGraphEntry() => $_has(2);
  @$pb.TagNumber(3)
  void clearGraphEntry() => clearField(3);
  @$pb.TagNumber(3)
  GraphEntry ensureGraphEntry() => $_ensure(2);
}

class AccountRegistration extends $pb.GeneratedMessage {
  factory AccountRegistration({
    LockAddress? associationLock,
    StakingRegistration? stakingRegistration,
  }) {
    final $result = create();
    if (associationLock != null) {
      $result.associationLock = associationLock;
    }
    if (stakingRegistration != null) {
      $result.stakingRegistration = stakingRegistration;
    }
    return $result;
  }
  AccountRegistration._() : super();
  factory AccountRegistration.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AccountRegistration.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AccountRegistration', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<LockAddress>(1, _omitFieldNames ? '' : 'associationLock', protoName: 'associationLock', subBuilder: LockAddress.create)
    ..aOM<StakingRegistration>(2, _omitFieldNames ? '' : 'stakingRegistration', protoName: 'stakingRegistration', subBuilder: StakingRegistration.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AccountRegistration clone() => AccountRegistration()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AccountRegistration copyWith(void Function(AccountRegistration) updates) => super.copyWith((message) => updates(message as AccountRegistration)) as AccountRegistration;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AccountRegistration create() => AccountRegistration._();
  AccountRegistration createEmptyInstance() => create();
  static $pb.PbList<AccountRegistration> createRepeated() => $pb.PbList<AccountRegistration>();
  @$core.pragma('dart2js:noInline')
  static AccountRegistration getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AccountRegistration>(create);
  static AccountRegistration? _defaultInstance;

  @$pb.TagNumber(1)
  LockAddress get associationLock => $_getN(0);
  @$pb.TagNumber(1)
  set associationLock(LockAddress v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAssociationLock() => $_has(0);
  @$pb.TagNumber(1)
  void clearAssociationLock() => clearField(1);
  @$pb.TagNumber(1)
  LockAddress ensureAssociationLock() => $_ensure(0);

  /// Optional.  If provided, introduces a new staker to the chain.
  @$pb.TagNumber(2)
  StakingRegistration get stakingRegistration => $_getN(1);
  @$pb.TagNumber(2)
  set stakingRegistration(StakingRegistration v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasStakingRegistration() => $_has(1);
  @$pb.TagNumber(2)
  void clearStakingRegistration() => clearField(2);
  @$pb.TagNumber(2)
  StakingRegistration ensureStakingRegistration() => $_ensure(1);
}

/// A proof-of-stake registration
class StakingRegistration extends $pb.GeneratedMessage {
  factory StakingRegistration({
    $core.String? commitmentSignature,
    $core.String? vk,
  }) {
    final $result = create();
    if (commitmentSignature != null) {
      $result.commitmentSignature = commitmentSignature;
    }
    if (vk != null) {
      $result.vk = vk;
    }
    return $result;
  }
  StakingRegistration._() : super();
  factory StakingRegistration.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StakingRegistration.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StakingRegistration', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'commitmentSignature', protoName: 'commitmentSignature')
    ..aOS(2, _omitFieldNames ? '' : 'vk')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StakingRegistration clone() => StakingRegistration()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StakingRegistration copyWith(void Function(StakingRegistration) updates) => super.copyWith((message) => updates(message as StakingRegistration)) as StakingRegistration;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StakingRegistration create() => StakingRegistration._();
  StakingRegistration createEmptyInstance() => create();
  static $pb.PbList<StakingRegistration> createRepeated() => $pb.PbList<StakingRegistration>();
  @$core.pragma('dart2js:noInline')
  static StakingRegistration getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StakingRegistration>(create);
  static StakingRegistration? _defaultInstance;

  /// Ed25519 Signature of the VRF VK that is stamped on each header
  /// Base58 encoded
  /// length = 64
  @$pb.TagNumber(1)
  $core.String get commitmentSignature => $_getSZ(0);
  @$pb.TagNumber(1)
  set commitmentSignature($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCommitmentSignature() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommitmentSignature() => clearField(1);

  /// Ed25519
  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(2)
  $core.String get vk => $_getSZ(1);
  @$pb.TagNumber(2)
  set vk($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVk() => $_has(1);
  @$pb.TagNumber(2)
  void clearVk() => clearField(2);
}

enum GraphEntry_Entry {
  vertex, 
  edge, 
  notSet
}

class GraphEntry extends $pb.GeneratedMessage {
  factory GraphEntry({
    Vertex? vertex,
    Edge? edge,
  }) {
    final $result = create();
    if (vertex != null) {
      $result.vertex = vertex;
    }
    if (edge != null) {
      $result.edge = edge;
    }
    return $result;
  }
  GraphEntry._() : super();
  factory GraphEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GraphEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, GraphEntry_Entry> _GraphEntry_EntryByTag = {
    1 : GraphEntry_Entry.vertex,
    2 : GraphEntry_Entry.edge,
    0 : GraphEntry_Entry.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GraphEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<Vertex>(1, _omitFieldNames ? '' : 'vertex', subBuilder: Vertex.create)
    ..aOM<Edge>(2, _omitFieldNames ? '' : 'edge', subBuilder: Edge.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GraphEntry clone() => GraphEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GraphEntry copyWith(void Function(GraphEntry) updates) => super.copyWith((message) => updates(message as GraphEntry)) as GraphEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GraphEntry create() => GraphEntry._();
  GraphEntry createEmptyInstance() => create();
  static $pb.PbList<GraphEntry> createRepeated() => $pb.PbList<GraphEntry>();
  @$core.pragma('dart2js:noInline')
  static GraphEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GraphEntry>(create);
  static GraphEntry? _defaultInstance;

  GraphEntry_Entry whichEntry() => _GraphEntry_EntryByTag[$_whichOneof(0)]!;
  void clearEntry() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Vertex get vertex => $_getN(0);
  @$pb.TagNumber(1)
  set vertex(Vertex v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasVertex() => $_has(0);
  @$pb.TagNumber(1)
  void clearVertex() => clearField(1);
  @$pb.TagNumber(1)
  Vertex ensureVertex() => $_ensure(0);

  @$pb.TagNumber(2)
  Edge get edge => $_getN(1);
  @$pb.TagNumber(2)
  set edge(Edge v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasEdge() => $_has(1);
  @$pb.TagNumber(2)
  void clearEdge() => clearField(2);
  @$pb.TagNumber(2)
  Edge ensureEdge() => $_ensure(1);
}

class Vertex extends $pb.GeneratedMessage {
  factory Vertex({
    $core.String? label,
    $0.Struct? data,
    LockAddress? edgeLockAddress,
  }) {
    final $result = create();
    if (label != null) {
      $result.label = label;
    }
    if (data != null) {
      $result.data = data;
    }
    if (edgeLockAddress != null) {
      $result.edgeLockAddress = edgeLockAddress;
    }
    return $result;
  }
  Vertex._() : super();
  factory Vertex.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Vertex.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Vertex', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOM<$0.Struct>(2, _omitFieldNames ? '' : 'data', subBuilder: $0.Struct.create)
    ..aOM<LockAddress>(3, _omitFieldNames ? '' : 'edgeLockAddress', protoName: 'edgeLockAddress', subBuilder: LockAddress.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Vertex clone() => Vertex()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Vertex copyWith(void Function(Vertex) updates) => super.copyWith((message) => updates(message as Vertex)) as Vertex;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Vertex create() => Vertex._();
  Vertex createEmptyInstance() => create();
  static $pb.PbList<Vertex> createRepeated() => $pb.PbList<Vertex>();
  @$core.pragma('dart2js:noInline')
  static Vertex getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Vertex>(create);
  static Vertex? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => clearField(1);

  @$pb.TagNumber(2)
  $0.Struct get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($0.Struct v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
  @$pb.TagNumber(2)
  $0.Struct ensureData() => $_ensure(1);

  @$pb.TagNumber(3)
  LockAddress get edgeLockAddress => $_getN(2);
  @$pb.TagNumber(3)
  set edgeLockAddress(LockAddress v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEdgeLockAddress() => $_has(2);
  @$pb.TagNumber(3)
  void clearEdgeLockAddress() => clearField(3);
  @$pb.TagNumber(3)
  LockAddress ensureEdgeLockAddress() => $_ensure(2);
}

class Edge extends $pb.GeneratedMessage {
  factory Edge({
    $core.String? label,
    $0.Struct? data,
    TransactionOutputReference? a,
    TransactionOutputReference? b,
  }) {
    final $result = create();
    if (label != null) {
      $result.label = label;
    }
    if (data != null) {
      $result.data = data;
    }
    if (a != null) {
      $result.a = a;
    }
    if (b != null) {
      $result.b = b;
    }
    return $result;
  }
  Edge._() : super();
  factory Edge.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Edge.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Edge', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'label')
    ..aOM<$0.Struct>(2, _omitFieldNames ? '' : 'data', subBuilder: $0.Struct.create)
    ..aOM<TransactionOutputReference>(3, _omitFieldNames ? '' : 'a', subBuilder: TransactionOutputReference.create)
    ..aOM<TransactionOutputReference>(4, _omitFieldNames ? '' : 'b', subBuilder: TransactionOutputReference.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Edge clone() => Edge()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Edge copyWith(void Function(Edge) updates) => super.copyWith((message) => updates(message as Edge)) as Edge;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Edge create() => Edge._();
  Edge createEmptyInstance() => create();
  static $pb.PbList<Edge> createRepeated() => $pb.PbList<Edge>();
  @$core.pragma('dart2js:noInline')
  static Edge getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Edge>(create);
  static Edge? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get label => $_getSZ(0);
  @$pb.TagNumber(1)
  set label($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLabel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLabel() => clearField(1);

  @$pb.TagNumber(2)
  $0.Struct get data => $_getN(1);
  @$pb.TagNumber(2)
  set data($0.Struct v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
  @$pb.TagNumber(2)
  $0.Struct ensureData() => $_ensure(1);

  @$pb.TagNumber(3)
  TransactionOutputReference get a => $_getN(2);
  @$pb.TagNumber(3)
  set a(TransactionOutputReference v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasA() => $_has(2);
  @$pb.TagNumber(3)
  void clearA() => clearField(3);
  @$pb.TagNumber(3)
  TransactionOutputReference ensureA() => $_ensure(2);

  @$pb.TagNumber(4)
  TransactionOutputReference get b => $_getN(3);
  @$pb.TagNumber(4)
  set b(TransactionOutputReference v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasB() => $_has(3);
  @$pb.TagNumber(4)
  void clearB() => clearField(4);
  @$pb.TagNumber(4)
  TransactionOutputReference ensureB() => $_ensure(3);
}

/// An active, registered participate in the consensus protocol, for a particular epoch.
class ActiveStaker extends $pb.GeneratedMessage {
  factory ActiveStaker({
    StakingRegistration? registration,
    $fixnum.Int64? quantity,
  }) {
    final $result = create();
    if (registration != null) {
      $result.registration = registration;
    }
    if (quantity != null) {
      $result.quantity = quantity;
    }
    return $result;
  }
  ActiveStaker._() : super();
  factory ActiveStaker.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ActiveStaker.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ActiveStaker', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<StakingRegistration>(1, _omitFieldNames ? '' : 'registration', subBuilder: StakingRegistration.create)
    ..aInt64(2, _omitFieldNames ? '' : 'quantity')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ActiveStaker clone() => ActiveStaker()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ActiveStaker copyWith(void Function(ActiveStaker) updates) => super.copyWith((message) => updates(message as ActiveStaker)) as ActiveStaker;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ActiveStaker create() => ActiveStaker._();
  ActiveStaker createEmptyInstance() => create();
  static $pb.PbList<ActiveStaker> createRepeated() => $pb.PbList<ActiveStaker>();
  @$core.pragma('dart2js:noInline')
  static ActiveStaker getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ActiveStaker>(create);
  static ActiveStaker? _defaultInstance;

  /// The staker's registration.  If not provided, the StakingAddress is not associated with a StakingRegistration
  @$pb.TagNumber(1)
  StakingRegistration get registration => $_getN(0);
  @$pb.TagNumber(1)
  set registration(StakingRegistration v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRegistration() => $_has(0);
  @$pb.TagNumber(1)
  void clearRegistration() => clearField(1);
  @$pb.TagNumber(1)
  StakingRegistration ensureRegistration() => $_ensure(0);

  /// the quantity of staked tokens for the epoch
  @$pb.TagNumber(2)
  $fixnum.Int64 get quantity => $_getI64(1);
  @$pb.TagNumber(2)
  set quantity($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasQuantity() => $_has(1);
  @$pb.TagNumber(2)
  void clearQuantity() => clearField(2);
}

class LockAddress extends $pb.GeneratedMessage {
  factory LockAddress({
    $core.String? value,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  LockAddress._() : super();
  factory LockAddress.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LockAddress.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LockAddress', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LockAddress clone() => LockAddress()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LockAddress copyWith(void Function(LockAddress) updates) => super.copyWith((message) => updates(message as LockAddress)) as LockAddress;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LockAddress create() => LockAddress._();
  LockAddress createEmptyInstance() => create();
  static $pb.PbList<LockAddress> createRepeated() => $pb.PbList<LockAddress>();
  @$core.pragma('dart2js:noInline')
  static LockAddress getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LockAddress>(create);
  static LockAddress? _defaultInstance;

  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class Lock_Ed25519 extends $pb.GeneratedMessage {
  factory Lock_Ed25519({
    $core.String? vk,
  }) {
    final $result = create();
    if (vk != null) {
      $result.vk = vk;
    }
    return $result;
  }
  Lock_Ed25519._() : super();
  factory Lock_Ed25519.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Lock_Ed25519.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Lock.Ed25519', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'vk')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Lock_Ed25519 clone() => Lock_Ed25519()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Lock_Ed25519 copyWith(void Function(Lock_Ed25519) updates) => super.copyWith((message) => updates(message as Lock_Ed25519)) as Lock_Ed25519;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Lock_Ed25519 create() => Lock_Ed25519._();
  Lock_Ed25519 createEmptyInstance() => create();
  static $pb.PbList<Lock_Ed25519> createRepeated() => $pb.PbList<Lock_Ed25519>();
  @$core.pragma('dart2js:noInline')
  static Lock_Ed25519 getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Lock_Ed25519>(create);
  static Lock_Ed25519? _defaultInstance;

  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(1)
  $core.String get vk => $_getSZ(0);
  @$pb.TagNumber(1)
  set vk($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVk() => $_has(0);
  @$pb.TagNumber(1)
  void clearVk() => clearField(1);
}

enum Lock_Value {
  ed25519, 
  notSet
}

class Lock extends $pb.GeneratedMessage {
  factory Lock({
    Lock_Ed25519? ed25519,
  }) {
    final $result = create();
    if (ed25519 != null) {
      $result.ed25519 = ed25519;
    }
    return $result;
  }
  Lock._() : super();
  factory Lock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Lock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Lock_Value> _Lock_ValueByTag = {
    1 : Lock_Value.ed25519,
    0 : Lock_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Lock', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<Lock_Ed25519>(1, _omitFieldNames ? '' : 'ed25519', subBuilder: Lock_Ed25519.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Lock clone() => Lock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Lock copyWith(void Function(Lock) updates) => super.copyWith((message) => updates(message as Lock)) as Lock;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Lock create() => Lock._();
  Lock createEmptyInstance() => create();
  static $pb.PbList<Lock> createRepeated() => $pb.PbList<Lock>();
  @$core.pragma('dart2js:noInline')
  static Lock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Lock>(create);
  static Lock? _defaultInstance;

  Lock_Value whichValue() => _Lock_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Lock_Ed25519 get ed25519 => $_getN(0);
  @$pb.TagNumber(1)
  set ed25519(Lock_Ed25519 v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasEd25519() => $_has(0);
  @$pb.TagNumber(1)
  void clearEd25519() => clearField(1);
  @$pb.TagNumber(1)
  Lock_Ed25519 ensureEd25519() => $_ensure(0);
}

class Key_Ed25519 extends $pb.GeneratedMessage {
  factory Key_Ed25519({
    $core.String? signature,
  }) {
    final $result = create();
    if (signature != null) {
      $result.signature = signature;
    }
    return $result;
  }
  Key_Ed25519._() : super();
  factory Key_Ed25519.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Key_Ed25519.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Key.Ed25519', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'signature')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Key_Ed25519 clone() => Key_Ed25519()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Key_Ed25519 copyWith(void Function(Key_Ed25519) updates) => super.copyWith((message) => updates(message as Key_Ed25519)) as Key_Ed25519;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Key_Ed25519 create() => Key_Ed25519._();
  Key_Ed25519 createEmptyInstance() => create();
  static $pb.PbList<Key_Ed25519> createRepeated() => $pb.PbList<Key_Ed25519>();
  @$core.pragma('dart2js:noInline')
  static Key_Ed25519 getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Key_Ed25519>(create);
  static Key_Ed25519? _defaultInstance;

  /// Base58 encoded
  /// length = 64
  @$pb.TagNumber(1)
  $core.String get signature => $_getSZ(0);
  @$pb.TagNumber(1)
  set signature($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSignature() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignature() => clearField(1);
}

enum Key_Value {
  ed25519, 
  notSet
}

class Key extends $pb.GeneratedMessage {
  factory Key({
    Key_Ed25519? ed25519,
  }) {
    final $result = create();
    if (ed25519 != null) {
      $result.ed25519 = ed25519;
    }
    return $result;
  }
  Key._() : super();
  factory Key.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Key.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Key_Value> _Key_ValueByTag = {
    1 : Key_Value.ed25519,
    0 : Key_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Key', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<Key_Ed25519>(1, _omitFieldNames ? '' : 'ed25519', subBuilder: Key_Ed25519.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Key clone() => Key()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Key copyWith(void Function(Key) updates) => super.copyWith((message) => updates(message as Key)) as Key;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Key create() => Key._();
  Key createEmptyInstance() => create();
  static $pb.PbList<Key> createRepeated() => $pb.PbList<Key>();
  @$core.pragma('dart2js:noInline')
  static Key getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Key>(create);
  static Key? _defaultInstance;

  Key_Value whichValue() => _Key_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Key_Ed25519 get ed25519 => $_getN(0);
  @$pb.TagNumber(1)
  set ed25519(Key_Ed25519 v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasEd25519() => $_has(0);
  @$pb.TagNumber(1)
  void clearEd25519() => clearField(1);
  @$pb.TagNumber(1)
  Key_Ed25519 ensureEd25519() => $_ensure(0);
}

class PeerId extends $pb.GeneratedMessage {
  factory PeerId({
    $core.String? value,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  PeerId._() : super();
  factory PeerId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PeerId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PeerId', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PeerId clone() => PeerId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PeerId copyWith(void Function(PeerId) updates) => super.copyWith((message) => updates(message as PeerId)) as PeerId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PeerId create() => PeerId._();
  PeerId createEmptyInstance() => create();
  static $pb.PbList<PeerId> createRepeated() => $pb.PbList<PeerId>();
  @$core.pragma('dart2js:noInline')
  static PeerId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PeerId>(create);
  static PeerId? _defaultInstance;

  /// Base58 encoded
  /// length = 32
  @$pb.TagNumber(1)
  $core.String get value => $_getSZ(0);
  @$pb.TagNumber(1)
  set value($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
}

class PublicP2PState extends $pb.GeneratedMessage {
  factory PublicP2PState({
    ConnectedPeer? localPeer,
    $core.Iterable<ConnectedPeer>? peers,
  }) {
    final $result = create();
    if (localPeer != null) {
      $result.localPeer = localPeer;
    }
    if (peers != null) {
      $result.peers.addAll(peers);
    }
    return $result;
  }
  PublicP2PState._() : super();
  factory PublicP2PState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PublicP2PState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PublicP2PState', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<ConnectedPeer>(1, _omitFieldNames ? '' : 'localPeer', protoName: 'localPeer', subBuilder: ConnectedPeer.create)
    ..pc<ConnectedPeer>(2, _omitFieldNames ? '' : 'peers', $pb.PbFieldType.PM, subBuilder: ConnectedPeer.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PublicP2PState clone() => PublicP2PState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PublicP2PState copyWith(void Function(PublicP2PState) updates) => super.copyWith((message) => updates(message as PublicP2PState)) as PublicP2PState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublicP2PState create() => PublicP2PState._();
  PublicP2PState createEmptyInstance() => create();
  static $pb.PbList<PublicP2PState> createRepeated() => $pb.PbList<PublicP2PState>();
  @$core.pragma('dart2js:noInline')
  static PublicP2PState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PublicP2PState>(create);
  static PublicP2PState? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectedPeer get localPeer => $_getN(0);
  @$pb.TagNumber(1)
  set localPeer(ConnectedPeer v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasLocalPeer() => $_has(0);
  @$pb.TagNumber(1)
  void clearLocalPeer() => clearField(1);
  @$pb.TagNumber(1)
  ConnectedPeer ensureLocalPeer() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<ConnectedPeer> get peers => $_getList(1);
}

class ConnectedPeer extends $pb.GeneratedMessage {
  factory ConnectedPeer({
    PeerId? peerId,
    $1.StringValue? host,
    $1.UInt32Value? port,
  }) {
    final $result = create();
    if (peerId != null) {
      $result.peerId = peerId;
    }
    if (host != null) {
      $result.host = host;
    }
    if (port != null) {
      $result.port = port;
    }
    return $result;
  }
  ConnectedPeer._() : super();
  factory ConnectedPeer.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConnectedPeer.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConnectedPeer', package: const $pb.PackageName(_omitMessageNames ? '' : 'blockchain.models'), createEmptyInstance: create)
    ..aOM<PeerId>(1, _omitFieldNames ? '' : 'peerId', protoName: 'peerId', subBuilder: PeerId.create)
    ..aOM<$1.StringValue>(2, _omitFieldNames ? '' : 'host', subBuilder: $1.StringValue.create)
    ..aOM<$1.UInt32Value>(3, _omitFieldNames ? '' : 'port', subBuilder: $1.UInt32Value.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConnectedPeer clone() => ConnectedPeer()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConnectedPeer copyWith(void Function(ConnectedPeer) updates) => super.copyWith((message) => updates(message as ConnectedPeer)) as ConnectedPeer;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectedPeer create() => ConnectedPeer._();
  ConnectedPeer createEmptyInstance() => create();
  static $pb.PbList<ConnectedPeer> createRepeated() => $pb.PbList<ConnectedPeer>();
  @$core.pragma('dart2js:noInline')
  static ConnectedPeer getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectedPeer>(create);
  static ConnectedPeer? _defaultInstance;

  @$pb.TagNumber(1)
  PeerId get peerId => $_getN(0);
  @$pb.TagNumber(1)
  set peerId(PeerId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasPeerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPeerId() => clearField(1);
  @$pb.TagNumber(1)
  PeerId ensurePeerId() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.StringValue get host => $_getN(1);
  @$pb.TagNumber(2)
  set host($1.StringValue v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasHost() => $_has(1);
  @$pb.TagNumber(2)
  void clearHost() => clearField(2);
  @$pb.TagNumber(2)
  $1.StringValue ensureHost() => $_ensure(1);

  @$pb.TagNumber(3)
  $1.UInt32Value get port => $_getN(2);
  @$pb.TagNumber(3)
  set port($1.UInt32Value v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasPort() => $_has(2);
  @$pb.TagNumber(3)
  void clearPort() => clearField(3);
  @$pb.TagNumber(3)
  $1.UInt32Value ensurePort() => $_ensure(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
