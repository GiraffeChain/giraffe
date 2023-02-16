///
//  Generated code. Do not modify.
//  source: models/transaction.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Transaction extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Transaction', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..pc<TransactionInput>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'inputs', $pb.PbFieldType.PM, subBuilder: TransactionInput.create)
    ..pc<TransactionOutput>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'outputs', $pb.PbFieldType.PM, subBuilder: TransactionOutput.create)
    ..hasRequiredFields = false
  ;

  Transaction._() : super();
  factory Transaction({
    $core.Iterable<TransactionInput>? inputs,
    $core.Iterable<TransactionOutput>? outputs,
  }) {
    final _result = create();
    if (inputs != null) {
      _result.inputs.addAll(inputs);
    }
    if (outputs != null) {
      _result.outputs.addAll(outputs);
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
}

class TransactionInput extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionInput', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<TransactionOutputReference>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'spentTransactionOutput', protoName: 'spentTransactionOutput', subBuilder: TransactionOutputReference.create)
    ..p<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'challengeArguments', $pb.PbFieldType.PY, protoName: 'challengeArguments')
    ..hasRequiredFields = false
  ;

  TransactionInput._() : super();
  factory TransactionInput({
    TransactionOutputReference? spentTransactionOutput,
    $core.Iterable<$core.List<$core.int>>? challengeArguments,
  }) {
    final _result = create();
    if (spentTransactionOutput != null) {
      _result.spentTransactionOutput = spentTransactionOutput;
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
  TransactionOutputReference get spentTransactionOutput => $_getN(0);
  @$pb.TagNumber(1)
  set spentTransactionOutput(TransactionOutputReference v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSpentTransactionOutput() => $_has(0);
  @$pb.TagNumber(1)
  void clearSpentTransactionOutput() => clearField(1);
  @$pb.TagNumber(1)
  TransactionOutputReference ensureSpentTransactionOutput() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.List<$core.int>> get challengeArguments => $_getList(1);
}

class TransactionOutput extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TransactionOutput', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOM<Challenge>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'spendChallenge', protoName: 'spendChallenge', subBuilder: Challenge.create)
    ..aOM<Value>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value', subBuilder: Value.create)
    ..hasRequiredFields = false
  ;

  TransactionOutput._() : super();
  factory TransactionOutput({
    Challenge? spendChallenge,
    Value? value,
  }) {
    final _result = create();
    if (spendChallenge != null) {
      _result.spendChallenge = spendChallenge;
    }
    if (value != null) {
      _result.value = value;
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
  Challenge get spendChallenge => $_getN(0);
  @$pb.TagNumber(1)
  set spendChallenge(Challenge v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSpendChallenge() => $_has(0);
  @$pb.TagNumber(1)
  void clearSpendChallenge() => clearField(1);
  @$pb.TagNumber(1)
  Challenge ensureSpendChallenge() => $_ensure(0);

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

class Value_Coin extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Value.Coin', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'quantity', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  Value_Coin._() : super();
  factory Value_Coin({
    $fixnum.Int64? quantity,
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
  $fixnum.Int64 get quantity => $_getI64(0);
  @$pb.TagNumber(1)
  set quantity($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasQuantity() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuantity() => clearField(1);
}

class Value_Data extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Value.Data', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dataType', protoName: 'dataType')
    ..a<$core.List<$core.int>>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bytes', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  Value_Data._() : super();
  factory Value_Data({
    $core.String? dataType,
    $core.List<$core.int>? bytes,
  }) {
    final _result = create();
    if (dataType != null) {
      _result.dataType = dataType;
    }
    if (bytes != null) {
      _result.bytes = bytes;
    }
    return _result;
  }
  factory Value_Data.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Value_Data.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Value_Data clone() => Value_Data()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Value_Data copyWith(void Function(Value_Data) updates) => super.copyWith((message) => updates(message as Value_Data)) as Value_Data; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Value_Data create() => Value_Data._();
  Value_Data createEmptyInstance() => create();
  static $pb.PbList<Value_Data> createRepeated() => $pb.PbList<Value_Data>();
  @$core.pragma('dart2js:noInline')
  static Value_Data getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Value_Data>(create);
  static Value_Data? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get dataType => $_getSZ(0);
  @$pb.TagNumber(1)
  set dataType($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDataType() => $_has(0);
  @$pb.TagNumber(1)
  void clearDataType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get bytes => $_getN(1);
  @$pb.TagNumber(2)
  set bytes($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytes() => clearField(2);
}

enum Value_Value {
  coin, 
  data, 
  notSet
}

class Value extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Value_Value> _Value_ValueByTag = {
    1 : Value_Value.coin,
    2 : Value_Value.data,
    0 : Value_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Value', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'com.blockchain.models'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<Value_Coin>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'coin', subBuilder: Value_Coin.create)
    ..aOM<Value_Data>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', subBuilder: Value_Data.create)
    ..hasRequiredFields = false
  ;

  Value._() : super();
  factory Value({
    Value_Coin? coin,
    Value_Data? data,
  }) {
    final _result = create();
    if (coin != null) {
      _result.coin = coin;
    }
    if (data != null) {
      _result.data = data;
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

  @$pb.TagNumber(2)
  Value_Data get data => $_getN(1);
  @$pb.TagNumber(2)
  set data(Value_Data v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(2)
  void clearData() => clearField(2);
  @$pb.TagNumber(2)
  Value_Data ensureData() => $_ensure(1);
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

