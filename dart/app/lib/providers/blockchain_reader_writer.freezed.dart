// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blockchain_reader_writer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BlockchainReaderWriter {
  BlockchainView get view => throw _privateConstructorUsedError;
  BlockchainWriter get writer => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BlockchainReaderWriterCopyWith<BlockchainReaderWriter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BlockchainReaderWriterCopyWith<$Res> {
  factory $BlockchainReaderWriterCopyWith(BlockchainReaderWriter value,
          $Res Function(BlockchainReaderWriter) then) =
      _$BlockchainReaderWriterCopyWithImpl<$Res, BlockchainReaderWriter>;
  @useResult
  $Res call({BlockchainView view, BlockchainWriter writer});
}

/// @nodoc
class _$BlockchainReaderWriterCopyWithImpl<$Res,
        $Val extends BlockchainReaderWriter>
    implements $BlockchainReaderWriterCopyWith<$Res> {
  _$BlockchainReaderWriterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? view = null,
    Object? writer = null,
  }) {
    return _then(_value.copyWith(
      view: null == view
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as BlockchainView,
      writer: null == writer
          ? _value.writer
          : writer // ignore: cast_nullable_to_non_nullable
              as BlockchainWriter,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BlockchainReaderWriterImplCopyWith<$Res>
    implements $BlockchainReaderWriterCopyWith<$Res> {
  factory _$$BlockchainReaderWriterImplCopyWith(
          _$BlockchainReaderWriterImpl value,
          $Res Function(_$BlockchainReaderWriterImpl) then) =
      __$$BlockchainReaderWriterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({BlockchainView view, BlockchainWriter writer});
}

/// @nodoc
class __$$BlockchainReaderWriterImplCopyWithImpl<$Res>
    extends _$BlockchainReaderWriterCopyWithImpl<$Res,
        _$BlockchainReaderWriterImpl>
    implements _$$BlockchainReaderWriterImplCopyWith<$Res> {
  __$$BlockchainReaderWriterImplCopyWithImpl(
      _$BlockchainReaderWriterImpl _value,
      $Res Function(_$BlockchainReaderWriterImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? view = null,
    Object? writer = null,
  }) {
    return _then(_$BlockchainReaderWriterImpl(
      view: null == view
          ? _value.view
          : view // ignore: cast_nullable_to_non_nullable
              as BlockchainView,
      writer: null == writer
          ? _value.writer
          : writer // ignore: cast_nullable_to_non_nullable
              as BlockchainWriter,
    ));
  }
}

/// @nodoc

class _$BlockchainReaderWriterImpl implements _BlockchainReaderWriter {
  const _$BlockchainReaderWriterImpl(
      {required this.view, required this.writer});

  @override
  final BlockchainView view;
  @override
  final BlockchainWriter writer;

  @override
  String toString() {
    return 'BlockchainReaderWriter(view: $view, writer: $writer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BlockchainReaderWriterImpl &&
            (identical(other.view, view) || other.view == view) &&
            (identical(other.writer, writer) || other.writer == writer));
  }

  @override
  int get hashCode => Object.hash(runtimeType, view, writer);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BlockchainReaderWriterImplCopyWith<_$BlockchainReaderWriterImpl>
      get copyWith => __$$BlockchainReaderWriterImplCopyWithImpl<
          _$BlockchainReaderWriterImpl>(this, _$identity);
}

abstract class _BlockchainReaderWriter implements BlockchainReaderWriter {
  const factory _BlockchainReaderWriter(
      {required final BlockchainView view,
      required final BlockchainWriter writer}) = _$BlockchainReaderWriterImpl;

  @override
  BlockchainView get view;
  @override
  BlockchainWriter get writer;
  @override
  @JsonKey(ignore: true)
  _$$BlockchainReaderWriterImplCopyWith<_$BlockchainReaderWriterImpl>
      get copyWith => throw _privateConstructorUsedError;
}
