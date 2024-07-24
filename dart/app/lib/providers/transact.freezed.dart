// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TransactState {
  Set<TransactionOutputReference> get selectedInputs =>
      throw _privateConstructorUsedError;
  List<(String, String)> get newOutputEntries =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TransactStateCopyWith<TransactState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactStateCopyWith<$Res> {
  factory $TransactStateCopyWith(
          TransactState value, $Res Function(TransactState) then) =
      _$TransactStateCopyWithImpl<$Res, TransactState>;
  @useResult
  $Res call(
      {Set<TransactionOutputReference> selectedInputs,
      List<(String, String)> newOutputEntries});
}

/// @nodoc
class _$TransactStateCopyWithImpl<$Res, $Val extends TransactState>
    implements $TransactStateCopyWith<$Res> {
  _$TransactStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedInputs = null,
    Object? newOutputEntries = null,
  }) {
    return _then(_value.copyWith(
      selectedInputs: null == selectedInputs
          ? _value.selectedInputs
          : selectedInputs // ignore: cast_nullable_to_non_nullable
              as Set<TransactionOutputReference>,
      newOutputEntries: null == newOutputEntries
          ? _value.newOutputEntries
          : newOutputEntries // ignore: cast_nullable_to_non_nullable
              as List<(String, String)>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactStateImplCopyWith<$Res>
    implements $TransactStateCopyWith<$Res> {
  factory _$$TransactStateImplCopyWith(
          _$TransactStateImpl value, $Res Function(_$TransactStateImpl) then) =
      __$$TransactStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Set<TransactionOutputReference> selectedInputs,
      List<(String, String)> newOutputEntries});
}

/// @nodoc
class __$$TransactStateImplCopyWithImpl<$Res>
    extends _$TransactStateCopyWithImpl<$Res, _$TransactStateImpl>
    implements _$$TransactStateImplCopyWith<$Res> {
  __$$TransactStateImplCopyWithImpl(
      _$TransactStateImpl _value, $Res Function(_$TransactStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedInputs = null,
    Object? newOutputEntries = null,
  }) {
    return _then(_$TransactStateImpl(
      selectedInputs: null == selectedInputs
          ? _value._selectedInputs
          : selectedInputs // ignore: cast_nullable_to_non_nullable
              as Set<TransactionOutputReference>,
      newOutputEntries: null == newOutputEntries
          ? _value._newOutputEntries
          : newOutputEntries // ignore: cast_nullable_to_non_nullable
              as List<(String, String)>,
    ));
  }
}

/// @nodoc

class _$TransactStateImpl implements _TransactState {
  const _$TransactStateImpl(
      {required final Set<TransactionOutputReference> selectedInputs,
      required final List<(String, String)> newOutputEntries})
      : _selectedInputs = selectedInputs,
        _newOutputEntries = newOutputEntries;

  final Set<TransactionOutputReference> _selectedInputs;
  @override
  Set<TransactionOutputReference> get selectedInputs {
    if (_selectedInputs is EqualUnmodifiableSetView) return _selectedInputs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedInputs);
  }

  final List<(String, String)> _newOutputEntries;
  @override
  List<(String, String)> get newOutputEntries {
    if (_newOutputEntries is EqualUnmodifiableListView)
      return _newOutputEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_newOutputEntries);
  }

  @override
  String toString() {
    return 'TransactState(selectedInputs: $selectedInputs, newOutputEntries: $newOutputEntries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactStateImpl &&
            const DeepCollectionEquality()
                .equals(other._selectedInputs, _selectedInputs) &&
            const DeepCollectionEquality()
                .equals(other._newOutputEntries, _newOutputEntries));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_selectedInputs),
      const DeepCollectionEquality().hash(_newOutputEntries));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactStateImplCopyWith<_$TransactStateImpl> get copyWith =>
      __$$TransactStateImplCopyWithImpl<_$TransactStateImpl>(this, _$identity);
}

abstract class _TransactState implements TransactState {
  const factory _TransactState(
          {required final Set<TransactionOutputReference> selectedInputs,
          required final List<(String, String)> newOutputEntries}) =
      _$TransactStateImpl;

  @override
  Set<TransactionOutputReference> get selectedInputs;
  @override
  List<(String, String)> get newOutputEntries;
  @override
  @JsonKey(ignore: true)
  _$$TransactStateImplCopyWith<_$TransactStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
