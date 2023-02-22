///
//  Generated code. Do not modify.
//  source: models/core.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class BlockId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BlockId', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bytes', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  BlockId._() : super();
  factory BlockId({
    $core.List<$core.int>? bytes,
  }) {
    final _result = create();
    if (bytes != null) {
      _result.bytes = bytes;
    }
    return _result;
  }
  factory BlockId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BlockId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BlockId clone() => BlockId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BlockId copyWith(void Function(BlockId) updates) => super.copyWith((message) => updates(message as BlockId)) as BlockId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BlockId create() => BlockId._();
  BlockId createEmptyInstance() => create();
  static $pb.PbList<BlockId> createRepeated() => $pb.PbList<BlockId>();
  @$core.pragma('dart2js:noInline')
  static BlockId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BlockId>(create);
  static BlockId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get bytes => $_getN(0);
  @$pb.TagNumber(1)
  set bytes($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytes() => clearField(1);
}

class Block extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Block', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<BlockId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'parentHeaderId', protoName: 'parentHeaderId', subBuilder: BlockId.create)
    ..a<$fixnum.Int64>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'proof', $pb.PbFieldType.OY)
    ..pc<TransactionId>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transactionIds', $pb.PbFieldType.PM, protoName: 'transactionIds', subBuilder: TransactionId.create)
    ..aOM<TransactionOutput>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reward', subBuilder: TransactionOutput.create)
    ..hasRequiredFields = false
  ;

  Block._() : super();
  factory Block({
    BlockId? parentHeaderId,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? height,
    $core.List<$core.int>? proof,
    $core.Iterable<TransactionId>? transactionIds,
    TransactionOutput? reward,
  }) {
    final _result = create();
    if (parentHeaderId != null) {
      _result.parentHeaderId = parentHeaderId;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (height != null) {
      _result.height = height;
    }
    if (proof != null) {
      _result.proof = proof;
    }
    if (transactionIds != null) {
      _result.transactionIds.addAll(transactionIds);
    }
    if (reward != null) {
      _result.reward = reward;
    }
    return _result;
  }
  factory Block.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Block.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Block clone() => Block()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Block copyWith(void Function(Block) updates) => super.copyWith((message) => updates(message as Block)) as Block; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Block create() => Block._();
  Block createEmptyInstance() => create();
  static $pb.PbList<Block> createRepeated() => $pb.PbList<Block>();
  @$core.pragma('dart2js:noInline')
  static Block getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Block>(create);
  static Block? _defaultInstance;

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

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get height => $_getI64(2);
  @$pb.TagNumber(3)
  set height($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get proof => $_getN(3);
  @$pb.TagNumber(4)
  set proof($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasProof() => $_has(3);
  @$pb.TagNumber(4)
  void clearProof() => clearField(4);

  @$pb.TagNumber(7)
  $core.List<TransactionId> get transactionIds => $_getList(4);

  @$pb.TagNumber(8)
  TransactionOutput get reward => $_getN(5);
  @$pb.TagNumber(8)
  set reward(TransactionOutput v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasReward() => $_has(5);
  @$pb.TagNumber(8)
  void clearReward() => clearField(8);
  @$pb.TagNumber(8)
  TransactionOutput ensureReward() => $_ensure(5);
}

class FullBlock extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'FullBlock', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<BlockId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'parentHeaderId', protoName: 'parentHeaderId', subBuilder: BlockId.create)
    ..a<$fixnum.Int64>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timestamp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'height', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'proof', $pb.PbFieldType.OY)
    ..pc<Transaction>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transactions', $pb.PbFieldType.PM, subBuilder: Transaction.create)
    ..aOM<TransactionOutput>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reward', subBuilder: TransactionOutput.create)
    ..hasRequiredFields = false
  ;

  FullBlock._() : super();
  factory FullBlock({
    BlockId? parentHeaderId,
    $fixnum.Int64? timestamp,
    $fixnum.Int64? height,
    $core.List<$core.int>? proof,
    $core.Iterable<Transaction>? transactions,
    TransactionOutput? reward,
  }) {
    final _result = create();
    if (parentHeaderId != null) {
      _result.parentHeaderId = parentHeaderId;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (height != null) {
      _result.height = height;
    }
    if (proof != null) {
      _result.proof = proof;
    }
    if (transactions != null) {
      _result.transactions.addAll(transactions);
    }
    if (reward != null) {
      _result.reward = reward;
    }
    return _result;
  }
  factory FullBlock.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FullBlock.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FullBlock clone() => FullBlock()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FullBlock copyWith(void Function(FullBlock) updates) => super.copyWith((message) => updates(message as FullBlock)) as FullBlock; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static FullBlock create() => FullBlock._();
  FullBlock createEmptyInstance() => create();
  static $pb.PbList<FullBlock> createRepeated() => $pb.PbList<FullBlock>();
  @$core.pragma('dart2js:noInline')
  static FullBlock getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FullBlock>(create);
  static FullBlock? _defaultInstance;

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

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get height => $_getI64(2);
  @$pb.TagNumber(3)
  set height($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHeight() => $_has(2);
  @$pb.TagNumber(3)
  void clearHeight() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get proof => $_getN(3);
  @$pb.TagNumber(4)
  set proof($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasProof() => $_has(3);
  @$pb.TagNumber(4)
  void clearProof() => clearField(4);

  @$pb.TagNumber(7)
  $core.List<Transaction> get transactions => $_getList(4);

  @$pb.TagNumber(8)
  TransactionOutput get reward => $_getN(5);
  @$pb.TagNumber(8)
  set reward(TransactionOutput v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasReward() => $_has(5);
  @$pb.TagNumber(8)
  void clearReward() => clearField(8);
  @$pb.TagNumber(8)
  TransactionOutput ensureReward() => $_ensure(5);
}

class Transaction extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Transaction', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..pc<TransactionInput>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'inputs', $pb.PbFieldType.PM, subBuilder: TransactionInput.create)
    ..pc<TransactionOutput>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputs', $pb.PbFieldType.PM, subBuilder: TransactionOutput.create)
    ..pc<RewardInput>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'rewardInputs', $pb.PbFieldType.PM, protoName: 'rewardInputs', subBuilder: RewardInput.create)
    ..hasRequiredFields = false
  ;

  Transaction._() : super();
  factory Transaction({
    $core.Iterable<TransactionInput>? inputs,
    $core.Iterable<TransactionOutput>? outputs,
    $core.Iterable<RewardInput>? rewardInputs,
  }) {
    final _result = create();
    if (inputs != null) {
      _result.inputs.addAll(inputs);
    }
    if (outputs != null) {
      _result.outputs.addAll(outputs);
    }
    if (rewardInputs != null) {
      _result.rewardInputs.addAll(rewardInputs);
    }
    return _result;
  }
  factory Transaction.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Transaction.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Transaction clone() => Transaction()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Transaction copyWith(void Function(Transaction) updates) => super.copyWith((message) => updates(message as Transaction)) as Transaction; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Transaction create() => Transaction._();
  Transaction createEmptyInstance() => create();
  static $pb.PbList<Transaction> createRepeated() => $pb.PbList<Transaction>();
  @$core.pragma('dart2js:noInline')
  static Transaction getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Transaction>(create);
  static Transaction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<TransactionInput> get inputs => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<TransactionOutput> get outputs => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<RewardInput> get rewardInputs => $_getList(2);
}

class TransactionInput extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionInput', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<TransactionOutputReference>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'reference', subBuilder: TransactionOutputReference.create)
    ..aOM<Challenge>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'challenge', subBuilder: Challenge.create)
    ..p<$core.List<$core.int>>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'challengeArguments', $pb.PbFieldType.PY, protoName: 'challengeArguments')
    ..hasRequiredFields = false
  ;

  TransactionInput._() : super();
  factory TransactionInput({
    TransactionOutputReference? reference,
    Challenge? challenge,
    $core.Iterable<$core.List<$core.int>>? challengeArguments,
  }) {
    final _result = create();
    if (reference != null) {
      _result.reference = reference;
    }
    if (challenge != null) {
      _result.challenge = challenge;
    }
    if (challengeArguments != null) {
      _result.challengeArguments.addAll(challengeArguments);
    }
    return _result;
  }
  factory TransactionInput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionInput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionInput clone() => TransactionInput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionInput copyWith(void Function(TransactionInput) updates) => super.copyWith((message) => updates(message as TransactionInput)) as TransactionInput; // ignore: deprecated_member_use
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
  Challenge get challenge => $_getN(1);
  @$pb.TagNumber(2)
  set challenge(Challenge v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasChallenge() => $_has(1);
  @$pb.TagNumber(2)
  void clearChallenge() => clearField(2);
  @$pb.TagNumber(2)
  Challenge ensureChallenge() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.List<$core.int>> get challengeArguments => $_getList(2);
}

class TransactionOutput extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionOutput', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<Value>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value', subBuilder: Value.create)
    ..aOM<Account>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'account', subBuilder: Account.create)
    ..hasRequiredFields = false
  ;

  TransactionOutput._() : super();
  factory TransactionOutput({
    Value? value,
    Account? account,
  }) {
    final _result = create();
    if (value != null) {
      _result.value = value;
    }
    if (account != null) {
      _result.account = account;
    }
    return _result;
  }
  factory TransactionOutput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionOutput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionOutput clone() => TransactionOutput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionOutput copyWith(void Function(TransactionOutput) updates) => super.copyWith((message) => updates(message as TransactionOutput)) as TransactionOutput; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TransactionOutput create() => TransactionOutput._();
  TransactionOutput createEmptyInstance() => create();
  static $pb.PbList<TransactionOutput> createRepeated() => $pb.PbList<TransactionOutput>();
  @$core.pragma('dart2js:noInline')
  static TransactionOutput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionOutput>(create);
  static TransactionOutput? _defaultInstance;

  @$pb.TagNumber(1)
  Value get value => $_getN(0);
  @$pb.TagNumber(1)
  set value(Value v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);
  @$pb.TagNumber(1)
  Value ensureValue() => $_ensure(0);

  @$pb.TagNumber(2)
  Account get account => $_getN(1);
  @$pb.TagNumber(2)
  set account(Account v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasAccount() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccount() => clearField(2);
  @$pb.TagNumber(2)
  Account ensureAccount() => $_ensure(1);
}

class RewardInput extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RewardInput', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<BlockId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'blockId', protoName: 'blockId', subBuilder: BlockId.create)
    ..hasRequiredFields = false
  ;

  RewardInput._() : super();
  factory RewardInput({
    BlockId? blockId,
  }) {
    final _result = create();
    if (blockId != null) {
      _result.blockId = blockId;
    }
    return _result;
  }
  factory RewardInput.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RewardInput.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RewardInput clone() => RewardInput()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RewardInput copyWith(void Function(RewardInput) updates) => super.copyWith((message) => updates(message as RewardInput)) as RewardInput; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RewardInput create() => RewardInput._();
  RewardInput createEmptyInstance() => create();
  static $pb.PbList<RewardInput> createRepeated() => $pb.PbList<RewardInput>();
  @$core.pragma('dart2js:noInline')
  static RewardInput getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RewardInput>(create);
  static RewardInput? _defaultInstance;

  @$pb.TagNumber(1)
  BlockId get blockId => $_getN(0);
  @$pb.TagNumber(1)
  set blockId(BlockId v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBlockId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBlockId() => clearField(1);
  @$pb.TagNumber(1)
  BlockId ensureBlockId() => $_ensure(0);
}

class Value_Coin extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Value.Coin', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'quantity')
    ..hasRequiredFields = false
  ;

  Value_Coin._() : super();
  factory Value_Coin({
    $core.String? quantity,
  }) {
    final _result = create();
    if (quantity != null) {
      _result.quantity = quantity;
    }
    return _result;
  }
  factory Value_Coin.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Value_Coin.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Value_Coin clone() => Value_Coin()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Value_Coin copyWith(void Function(Value_Coin) updates) => super.copyWith((message) => updates(message as Value_Coin)) as Value_Coin; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Value_Coin create() => Value_Coin._();
  Value_Coin createEmptyInstance() => create();
  static $pb.PbList<Value_Coin> createRepeated() => $pb.PbList<Value_Coin>();
  @$core.pragma('dart2js:noInline')
  static Value_Coin getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Value_Coin>(create);
  static Value_Coin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get quantity => $_getSZ(0);
  @$pb.TagNumber(1)
  set quantity($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasQuantity() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuantity() => clearField(1);
}

enum Value_Value {
  coin, 
  notSet
}

class Value extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Value_Value> _Value_ValueByTag = {
    1 : Value_Value.coin,
    0 : Value_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Value', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<Value_Coin>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'coin', subBuilder: Value_Coin.create)
    ..hasRequiredFields = false
  ;

  Value._() : super();
  factory Value({
    Value_Coin? coin,
  }) {
    final _result = create();
    if (coin != null) {
      _result.coin = coin;
    }
    return _result;
  }
  factory Value.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Value.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Value clone() => Value()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Value copyWith(void Function(Value) updates) => super.copyWith((message) => updates(message as Value)) as Value; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Value create() => Value._();
  Value createEmptyInstance() => create();
  static $pb.PbList<Value> createRepeated() => $pb.PbList<Value>();
  @$core.pragma('dart2js:noInline')
  static Value getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Value>(create);
  static Value? _defaultInstance;

  Value_Value whichValue() => _Value_ValueByTag[$_whichOneof(0)]!;
  void clearValue() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Value_Coin get coin => $_getN(0);
  @$pb.TagNumber(1)
  set coin(Value_Coin v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCoin() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoin() => clearField(1);
  @$pb.TagNumber(1)
  Value_Coin ensureCoin() => $_ensure(0);
}

class TransactionId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionId', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bytes', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  TransactionId._() : super();
  factory TransactionId({
    $core.List<$core.int>? bytes,
  }) {
    final _result = create();
    if (bytes != null) {
      _result.bytes = bytes;
    }
    return _result;
  }
  factory TransactionId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionId clone() => TransactionId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionId copyWith(void Function(TransactionId) updates) => super.copyWith((message) => updates(message as TransactionId)) as TransactionId; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TransactionId create() => TransactionId._();
  TransactionId createEmptyInstance() => create();
  static $pb.PbList<TransactionId> createRepeated() => $pb.PbList<TransactionId>();
  @$core.pragma('dart2js:noInline')
  static TransactionId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TransactionId>(create);
  static TransactionId? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get bytes => $_getN(0);
  @$pb.TagNumber(1)
  set bytes($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytes() => clearField(1);
}

class TransactionOutputReference extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionOutputReference', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<TransactionId>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'transactionId', protoName: 'transactionId', subBuilder: TransactionId.create)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'index', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  TransactionOutputReference._() : super();
  factory TransactionOutputReference({
    TransactionId? transactionId,
    $core.int? index,
  }) {
    final _result = create();
    if (transactionId != null) {
      _result.transactionId = transactionId;
    }
    if (index != null) {
      _result.index = index;
    }
    return _result;
  }
  factory TransactionOutputReference.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TransactionOutputReference.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TransactionOutputReference clone() => TransactionOutputReference()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TransactionOutputReference copyWith(void Function(TransactionOutputReference) updates) => super.copyWith((message) => updates(message as TransactionOutputReference)) as TransactionOutputReference; // ignore: deprecated_member_use
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

class Account extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Account', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  Account._() : super();
  factory Account({
    $core.List<$core.int>? id,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    return _result;
  }
  factory Account.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Account.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Account clone() => Account()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Account copyWith(void Function(Account) updates) => super.copyWith((message) => updates(message as Account)) as Account; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Account create() => Account._();
  Account createEmptyInstance() => create();
  static $pb.PbList<Account> createRepeated() => $pb.PbList<Account>();
  @$core.pragma('dart2js:noInline')
  static Account getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Account>(create);
  static Account? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
}

class Challenge extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Challenge', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'script')
    ..hasRequiredFields = false
  ;

  Challenge._() : super();
  factory Challenge({
    $core.String? script,
  }) {
    final _result = create();
    if (script != null) {
      _result.script = script;
    }
    return _result;
  }
  factory Challenge.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Challenge.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Challenge clone() => Challenge()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Challenge copyWith(void Function(Challenge) updates) => super.copyWith((message) => updates(message as Challenge)) as Challenge; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Challenge create() => Challenge._();
  Challenge createEmptyInstance() => create();
  static $pb.PbList<Challenge> createRepeated() => $pb.PbList<Challenge>();
  @$core.pragma('dart2js:noInline')
  static Challenge getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Challenge>(create);
  static Challenge? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get script => $_getSZ(0);
  @$pb.TagNumber(1)
  set script($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasScript() => $_has(0);
  @$pb.TagNumber(1)
  void clearScript() => clearField(1);
}

