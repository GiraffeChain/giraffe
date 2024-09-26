// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'block_production.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ActivePodBlockProductionState {
  Future<void> Function()? get stop => throw _privateConstructorUsedError;

  /// Create a copy of ActivePodBlockProductionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivePodBlockProductionStateCopyWith<ActivePodBlockProductionState>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivePodBlockProductionStateCopyWith<$Res> {
  factory $ActivePodBlockProductionStateCopyWith(
          ActivePodBlockProductionState value,
          $Res Function(ActivePodBlockProductionState) then) =
      _$ActivePodBlockProductionStateCopyWithImpl<$Res,
          ActivePodBlockProductionState>;
  @useResult
  $Res call({Future<void> Function()? stop});
}

/// @nodoc
class _$ActivePodBlockProductionStateCopyWithImpl<$Res,
        $Val extends ActivePodBlockProductionState>
    implements $ActivePodBlockProductionStateCopyWith<$Res> {
  _$ActivePodBlockProductionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivePodBlockProductionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stop = freezed,
  }) {
    return _then(_value.copyWith(
      stop: freezed == stop
          ? _value.stop
          : stop // ignore: cast_nullable_to_non_nullable
              as Future<void> Function()?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActivePodBlockProductionStateImplCopyWith<$Res>
    implements $ActivePodBlockProductionStateCopyWith<$Res> {
  factory _$$ActivePodBlockProductionStateImplCopyWith(
          _$ActivePodBlockProductionStateImpl value,
          $Res Function(_$ActivePodBlockProductionStateImpl) then) =
      __$$ActivePodBlockProductionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Future<void> Function()? stop});
}

/// @nodoc
class __$$ActivePodBlockProductionStateImplCopyWithImpl<$Res>
    extends _$ActivePodBlockProductionStateCopyWithImpl<$Res,
        _$ActivePodBlockProductionStateImpl>
    implements _$$ActivePodBlockProductionStateImplCopyWith<$Res> {
  __$$ActivePodBlockProductionStateImplCopyWithImpl(
      _$ActivePodBlockProductionStateImpl _value,
      $Res Function(_$ActivePodBlockProductionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActivePodBlockProductionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stop = freezed,
  }) {
    return _then(_$ActivePodBlockProductionStateImpl(
      stop: freezed == stop
          ? _value.stop
          : stop // ignore: cast_nullable_to_non_nullable
              as Future<void> Function()?,
    ));
  }
}

/// @nodoc

class _$ActivePodBlockProductionStateImpl
    implements _ActivePodBlockProductionState {
  const _$ActivePodBlockProductionStateImpl({required this.stop});

  @override
  final Future<void> Function()? stop;

  @override
  String toString() {
    return 'ActivePodBlockProductionState(stop: $stop)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivePodBlockProductionStateImpl &&
            (identical(other.stop, stop) || other.stop == stop));
  }

  @override
  int get hashCode => Object.hash(runtimeType, stop);

  /// Create a copy of ActivePodBlockProductionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivePodBlockProductionStateImplCopyWith<
          _$ActivePodBlockProductionStateImpl>
      get copyWith => __$$ActivePodBlockProductionStateImplCopyWithImpl<
          _$ActivePodBlockProductionStateImpl>(this, _$identity);
}

abstract class _ActivePodBlockProductionState
    implements ActivePodBlockProductionState {
  const factory _ActivePodBlockProductionState(
          {required final Future<void> Function()? stop}) =
      _$ActivePodBlockProductionStateImpl;

  @override
  Future<void> Function()? get stop;

  /// Create a copy of ActivePodBlockProductionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivePodBlockProductionStateImplCopyWith<
          _$ActivePodBlockProductionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
