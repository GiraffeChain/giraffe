// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'genesis_builder_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$GenesisBuilderState {
  String get seed => throw _privateConstructorUsedError;
  List<(LockAddress, Int64)> get stakers => throw _privateConstructorUsedError;
  List<(LockAddress, Int64)> get unstaked => throw _privateConstructorUsedError;
  Directory? get savedDir => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $GenesisBuilderStateCopyWith<GenesisBuilderState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GenesisBuilderStateCopyWith<$Res> {
  factory $GenesisBuilderStateCopyWith(
          GenesisBuilderState value, $Res Function(GenesisBuilderState) then) =
      _$GenesisBuilderStateCopyWithImpl<$Res, GenesisBuilderState>;
  @useResult
  $Res call(
      {String seed,
      List<(LockAddress, Int64)> stakers,
      List<(LockAddress, Int64)> unstaked,
      Directory? savedDir});
}

/// @nodoc
class _$GenesisBuilderStateCopyWithImpl<$Res, $Val extends GenesisBuilderState>
    implements $GenesisBuilderStateCopyWith<$Res> {
  _$GenesisBuilderStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seed = null,
    Object? stakers = null,
    Object? unstaked = null,
    Object? savedDir = freezed,
  }) {
    return _then(_value.copyWith(
      seed: null == seed
          ? _value.seed
          : seed // ignore: cast_nullable_to_non_nullable
              as String,
      stakers: null == stakers
          ? _value.stakers
          : stakers // ignore: cast_nullable_to_non_nullable
              as List<(LockAddress, Int64)>,
      unstaked: null == unstaked
          ? _value.unstaked
          : unstaked // ignore: cast_nullable_to_non_nullable
              as List<(LockAddress, Int64)>,
      savedDir: freezed == savedDir
          ? _value.savedDir
          : savedDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GenesisBuilderStateImplCopyWith<$Res>
    implements $GenesisBuilderStateCopyWith<$Res> {
  factory _$$GenesisBuilderStateImplCopyWith(_$GenesisBuilderStateImpl value,
          $Res Function(_$GenesisBuilderStateImpl) then) =
      __$$GenesisBuilderStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String seed,
      List<(LockAddress, Int64)> stakers,
      List<(LockAddress, Int64)> unstaked,
      Directory? savedDir});
}

/// @nodoc
class __$$GenesisBuilderStateImplCopyWithImpl<$Res>
    extends _$GenesisBuilderStateCopyWithImpl<$Res, _$GenesisBuilderStateImpl>
    implements _$$GenesisBuilderStateImplCopyWith<$Res> {
  __$$GenesisBuilderStateImplCopyWithImpl(_$GenesisBuilderStateImpl _value,
      $Res Function(_$GenesisBuilderStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seed = null,
    Object? stakers = null,
    Object? unstaked = null,
    Object? savedDir = freezed,
  }) {
    return _then(_$GenesisBuilderStateImpl(
      seed: null == seed
          ? _value.seed
          : seed // ignore: cast_nullable_to_non_nullable
              as String,
      stakers: null == stakers
          ? _value.stakers
          : stakers // ignore: cast_nullable_to_non_nullable
              as List<(LockAddress, Int64)>,
      unstaked: null == unstaked
          ? _value.unstaked
          : unstaked // ignore: cast_nullable_to_non_nullable
              as List<(LockAddress, Int64)>,
      savedDir: freezed == savedDir
          ? _value.savedDir
          : savedDir // ignore: cast_nullable_to_non_nullable
              as Directory?,
    ));
  }
}

/// @nodoc

class _$GenesisBuilderStateImpl implements _GenesisBuilderState {
  const _$GenesisBuilderStateImpl(
      {required this.seed,
      required this.stakers,
      required this.unstaked,
      required this.savedDir});

  @override
  final String seed;
  @override
  final List<(LockAddress, Int64)> stakers;
  @override
  final List<(LockAddress, Int64)> unstaked;
  @override
  final Directory? savedDir;

  @override
  String toString() {
    return 'GenesisBuilderState(seed: $seed, stakers: $stakers, unstaked: $unstaked, savedDir: $savedDir)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GenesisBuilderStateImpl &&
            (identical(other.seed, seed) || other.seed == seed) &&
            const DeepCollectionEquality().equals(other.stakers, stakers) &&
            const DeepCollectionEquality().equals(other.unstaked, unstaked) &&
            (identical(other.savedDir, savedDir) ||
                other.savedDir == savedDir));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      seed,
      const DeepCollectionEquality().hash(stakers),
      const DeepCollectionEquality().hash(unstaked),
      savedDir);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GenesisBuilderStateImplCopyWith<_$GenesisBuilderStateImpl> get copyWith =>
      __$$GenesisBuilderStateImplCopyWithImpl<_$GenesisBuilderStateImpl>(
          this, _$identity);
}

abstract class _GenesisBuilderState implements GenesisBuilderState {
  const factory _GenesisBuilderState(
      {required final String seed,
      required final List<(LockAddress, Int64)> stakers,
      required final List<(LockAddress, Int64)> unstaked,
      required final Directory? savedDir}) = _$GenesisBuilderStateImpl;

  @override
  String get seed;
  @override
  List<(LockAddress, Int64)> get stakers;
  @override
  List<(LockAddress, Int64)> get unstaked;
  @override
  Directory? get savedDir;
  @override
  @JsonKey(ignore: true)
  _$$GenesisBuilderStateImplCopyWith<_$GenesisBuilderStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
