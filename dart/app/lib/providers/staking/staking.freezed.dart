// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'staking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PodStakingState {
  Minting? get minting => throw _privateConstructorUsedError;
  Future<void> Function()? get stop => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PodStakingStateCopyWith<PodStakingState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PodStakingStateCopyWith<$Res> {
  factory $PodStakingStateCopyWith(
          PodStakingState value, $Res Function(PodStakingState) then) =
      _$PodStakingStateCopyWithImpl<$Res, PodStakingState>;
  @useResult
  $Res call({Minting? minting, Future<void> Function()? stop});
}

/// @nodoc
class _$PodStakingStateCopyWithImpl<$Res, $Val extends PodStakingState>
    implements $PodStakingStateCopyWith<$Res> {
  _$PodStakingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minting = freezed,
    Object? stop = freezed,
  }) {
    return _then(_value.copyWith(
      minting: freezed == minting
          ? _value.minting
          : minting // ignore: cast_nullable_to_non_nullable
              as Minting?,
      stop: freezed == stop
          ? _value.stop
          : stop // ignore: cast_nullable_to_non_nullable
              as Future<void> Function()?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PodStakingStateImplCopyWith<$Res>
    implements $PodStakingStateCopyWith<$Res> {
  factory _$$PodStakingStateImplCopyWith(_$PodStakingStateImpl value,
          $Res Function(_$PodStakingStateImpl) then) =
      __$$PodStakingStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Minting? minting, Future<void> Function()? stop});
}

/// @nodoc
class __$$PodStakingStateImplCopyWithImpl<$Res>
    extends _$PodStakingStateCopyWithImpl<$Res, _$PodStakingStateImpl>
    implements _$$PodStakingStateImplCopyWith<$Res> {
  __$$PodStakingStateImplCopyWithImpl(
      _$PodStakingStateImpl _value, $Res Function(_$PodStakingStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? minting = freezed,
    Object? stop = freezed,
  }) {
    return _then(_$PodStakingStateImpl(
      minting: freezed == minting
          ? _value.minting
          : minting // ignore: cast_nullable_to_non_nullable
              as Minting?,
      stop: freezed == stop
          ? _value.stop
          : stop // ignore: cast_nullable_to_non_nullable
              as Future<void> Function()?,
    ));
  }
}

/// @nodoc

class _$PodStakingStateImpl implements _PodStakingState {
  const _$PodStakingStateImpl({required this.minting, required this.stop});

  @override
  final Minting? minting;
  @override
  final Future<void> Function()? stop;

  @override
  String toString() {
    return 'PodStakingState(minting: $minting, stop: $stop)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PodStakingStateImpl &&
            (identical(other.minting, minting) || other.minting == minting) &&
            (identical(other.stop, stop) || other.stop == stop));
  }

  @override
  int get hashCode => Object.hash(runtimeType, minting, stop);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PodStakingStateImplCopyWith<_$PodStakingStateImpl> get copyWith =>
      __$$PodStakingStateImplCopyWithImpl<_$PodStakingStateImpl>(
          this, _$identity);
}

abstract class _PodStakingState implements PodStakingState {
  const factory _PodStakingState(
      {required final Minting? minting,
      required final Future<void> Function()? stop}) = _$PodStakingStateImpl;

  @override
  Minting? get minting;
  @override
  Future<void> Function()? get stop;
  @override
  @JsonKey(ignore: true)
  _$$PodStakingStateImplCopyWith<_$PodStakingStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
