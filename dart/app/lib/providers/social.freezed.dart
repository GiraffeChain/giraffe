// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'social.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Social {
  TransactionOutputReference get user => throw _privateConstructorUsedError;
  TransactionOutputReference get profile => throw _privateConstructorUsedError;
  ProfileData get profileData => throw _privateConstructorUsedError;
  FriendData get friendData => throw _privateConstructorUsedError;

  /// Create a copy of Social
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SocialCopyWith<Social> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SocialCopyWith<$Res> {
  factory $SocialCopyWith(Social value, $Res Function(Social) then) =
      _$SocialCopyWithImpl<$Res, Social>;
  @useResult
  $Res call(
      {TransactionOutputReference user,
      TransactionOutputReference profile,
      ProfileData profileData,
      FriendData friendData});

  $ProfileDataCopyWith<$Res> get profileData;
  $FriendDataCopyWith<$Res> get friendData;
}

/// @nodoc
class _$SocialCopyWithImpl<$Res, $Val extends Social>
    implements $SocialCopyWith<$Res> {
  _$SocialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Social
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? profile = null,
    Object? profileData = null,
    Object? friendData = null,
  }) {
    return _then(_value.copyWith(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as TransactionOutputReference,
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as TransactionOutputReference,
      profileData: null == profileData
          ? _value.profileData
          : profileData // ignore: cast_nullable_to_non_nullable
              as ProfileData,
      friendData: null == friendData
          ? _value.friendData
          : friendData // ignore: cast_nullable_to_non_nullable
              as FriendData,
    ) as $Val);
  }

  /// Create a copy of Social
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProfileDataCopyWith<$Res> get profileData {
    return $ProfileDataCopyWith<$Res>(_value.profileData, (value) {
      return _then(_value.copyWith(profileData: value) as $Val);
    });
  }

  /// Create a copy of Social
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FriendDataCopyWith<$Res> get friendData {
    return $FriendDataCopyWith<$Res>(_value.friendData, (value) {
      return _then(_value.copyWith(friendData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SocialImplCopyWith<$Res> implements $SocialCopyWith<$Res> {
  factory _$$SocialImplCopyWith(
          _$SocialImpl value, $Res Function(_$SocialImpl) then) =
      __$$SocialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {TransactionOutputReference user,
      TransactionOutputReference profile,
      ProfileData profileData,
      FriendData friendData});

  @override
  $ProfileDataCopyWith<$Res> get profileData;
  @override
  $FriendDataCopyWith<$Res> get friendData;
}

/// @nodoc
class __$$SocialImplCopyWithImpl<$Res>
    extends _$SocialCopyWithImpl<$Res, _$SocialImpl>
    implements _$$SocialImplCopyWith<$Res> {
  __$$SocialImplCopyWithImpl(
      _$SocialImpl _value, $Res Function(_$SocialImpl) _then)
      : super(_value, _then);

  /// Create a copy of Social
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? profile = null,
    Object? profileData = null,
    Object? friendData = null,
  }) {
    return _then(_$SocialImpl(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as TransactionOutputReference,
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as TransactionOutputReference,
      profileData: null == profileData
          ? _value.profileData
          : profileData // ignore: cast_nullable_to_non_nullable
              as ProfileData,
      friendData: null == friendData
          ? _value.friendData
          : friendData // ignore: cast_nullable_to_non_nullable
              as FriendData,
    ));
  }
}

/// @nodoc

class _$SocialImpl implements _Social {
  const _$SocialImpl(
      {required this.user,
      required this.profile,
      required this.profileData,
      required this.friendData});

  @override
  final TransactionOutputReference user;
  @override
  final TransactionOutputReference profile;
  @override
  final ProfileData profileData;
  @override
  final FriendData friendData;

  @override
  String toString() {
    return 'Social(user: $user, profile: $profile, profileData: $profileData, friendData: $friendData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SocialImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.profile, profile) || other.profile == profile) &&
            (identical(other.profileData, profileData) ||
                other.profileData == profileData) &&
            (identical(other.friendData, friendData) ||
                other.friendData == friendData));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, user, profile, profileData, friendData);

  /// Create a copy of Social
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SocialImplCopyWith<_$SocialImpl> get copyWith =>
      __$$SocialImplCopyWithImpl<_$SocialImpl>(this, _$identity);
}

abstract class _Social implements Social {
  const factory _Social(
      {required final TransactionOutputReference user,
      required final TransactionOutputReference profile,
      required final ProfileData profileData,
      required final FriendData friendData}) = _$SocialImpl;

  @override
  TransactionOutputReference get user;
  @override
  TransactionOutputReference get profile;
  @override
  ProfileData get profileData;
  @override
  FriendData get friendData;

  /// Create a copy of Social
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SocialImplCopyWith<_$SocialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ProfileData {
  String? get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;

  /// Create a copy of ProfileData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileDataCopyWith<ProfileData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileDataCopyWith<$Res> {
  factory $ProfileDataCopyWith(
          ProfileData value, $Res Function(ProfileData) then) =
      _$ProfileDataCopyWithImpl<$Res, ProfileData>;
  @useResult
  $Res call({String? firstName, String? lastName});
}

/// @nodoc
class _$ProfileDataCopyWithImpl<$Res, $Val extends ProfileData>
    implements $ProfileDataCopyWith<$Res> {
  _$ProfileDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
  }) {
    return _then(_value.copyWith(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileDataImplCopyWith<$Res>
    implements $ProfileDataCopyWith<$Res> {
  factory _$$ProfileDataImplCopyWith(
          _$ProfileDataImpl value, $Res Function(_$ProfileDataImpl) then) =
      __$$ProfileDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? firstName, String? lastName});
}

/// @nodoc
class __$$ProfileDataImplCopyWithImpl<$Res>
    extends _$ProfileDataCopyWithImpl<$Res, _$ProfileDataImpl>
    implements _$$ProfileDataImplCopyWith<$Res> {
  __$$ProfileDataImplCopyWithImpl(
      _$ProfileDataImpl _value, $Res Function(_$ProfileDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? firstName = freezed,
    Object? lastName = freezed,
  }) {
    return _then(_$ProfileDataImpl(
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ProfileDataImpl implements _ProfileData {
  const _$ProfileDataImpl({this.firstName, this.lastName});

  @override
  final String? firstName;
  @override
  final String? lastName;

  @override
  String toString() {
    return 'ProfileData(firstName: $firstName, lastName: $lastName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileDataImpl &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, firstName, lastName);

  /// Create a copy of ProfileData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileDataImplCopyWith<_$ProfileDataImpl> get copyWith =>
      __$$ProfileDataImplCopyWithImpl<_$ProfileDataImpl>(this, _$identity);
}

abstract class _ProfileData implements ProfileData {
  const factory _ProfileData(
      {final String? firstName, final String? lastName}) = _$ProfileDataImpl;

  @override
  String? get firstName;
  @override
  String? get lastName;

  /// Create a copy of ProfileData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileDataImplCopyWith<_$ProfileDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$FriendData {
  List<TransactionOutputReference> get outgoingFriendRequests =>
      throw _privateConstructorUsedError;
  List<TransactionOutputReference> get incomingFriendRequests =>
      throw _privateConstructorUsedError;
  List<TransactionOutputReference> get friends =>
      throw _privateConstructorUsedError;

  /// Create a copy of FriendData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendDataCopyWith<FriendData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendDataCopyWith<$Res> {
  factory $FriendDataCopyWith(
          FriendData value, $Res Function(FriendData) then) =
      _$FriendDataCopyWithImpl<$Res, FriendData>;
  @useResult
  $Res call(
      {List<TransactionOutputReference> outgoingFriendRequests,
      List<TransactionOutputReference> incomingFriendRequests,
      List<TransactionOutputReference> friends});
}

/// @nodoc
class _$FriendDataCopyWithImpl<$Res, $Val extends FriendData>
    implements $FriendDataCopyWith<$Res> {
  _$FriendDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outgoingFriendRequests = null,
    Object? incomingFriendRequests = null,
    Object? friends = null,
  }) {
    return _then(_value.copyWith(
      outgoingFriendRequests: null == outgoingFriendRequests
          ? _value.outgoingFriendRequests
          : outgoingFriendRequests // ignore: cast_nullable_to_non_nullable
              as List<TransactionOutputReference>,
      incomingFriendRequests: null == incomingFriendRequests
          ? _value.incomingFriendRequests
          : incomingFriendRequests // ignore: cast_nullable_to_non_nullable
              as List<TransactionOutputReference>,
      friends: null == friends
          ? _value.friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<TransactionOutputReference>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FriendDataImplCopyWith<$Res>
    implements $FriendDataCopyWith<$Res> {
  factory _$$FriendDataImplCopyWith(
          _$FriendDataImpl value, $Res Function(_$FriendDataImpl) then) =
      __$$FriendDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<TransactionOutputReference> outgoingFriendRequests,
      List<TransactionOutputReference> incomingFriendRequests,
      List<TransactionOutputReference> friends});
}

/// @nodoc
class __$$FriendDataImplCopyWithImpl<$Res>
    extends _$FriendDataCopyWithImpl<$Res, _$FriendDataImpl>
    implements _$$FriendDataImplCopyWith<$Res> {
  __$$FriendDataImplCopyWithImpl(
      _$FriendDataImpl _value, $Res Function(_$FriendDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of FriendData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outgoingFriendRequests = null,
    Object? incomingFriendRequests = null,
    Object? friends = null,
  }) {
    return _then(_$FriendDataImpl(
      outgoingFriendRequests: null == outgoingFriendRequests
          ? _value._outgoingFriendRequests
          : outgoingFriendRequests // ignore: cast_nullable_to_non_nullable
              as List<TransactionOutputReference>,
      incomingFriendRequests: null == incomingFriendRequests
          ? _value._incomingFriendRequests
          : incomingFriendRequests // ignore: cast_nullable_to_non_nullable
              as List<TransactionOutputReference>,
      friends: null == friends
          ? _value._friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<TransactionOutputReference>,
    ));
  }
}

/// @nodoc

class _$FriendDataImpl implements _FriendData {
  const _$FriendDataImpl(
      {required final List<TransactionOutputReference> outgoingFriendRequests,
      required final List<TransactionOutputReference> incomingFriendRequests,
      required final List<TransactionOutputReference> friends})
      : _outgoingFriendRequests = outgoingFriendRequests,
        _incomingFriendRequests = incomingFriendRequests,
        _friends = friends;

  final List<TransactionOutputReference> _outgoingFriendRequests;
  @override
  List<TransactionOutputReference> get outgoingFriendRequests {
    if (_outgoingFriendRequests is EqualUnmodifiableListView)
      return _outgoingFriendRequests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_outgoingFriendRequests);
  }

  final List<TransactionOutputReference> _incomingFriendRequests;
  @override
  List<TransactionOutputReference> get incomingFriendRequests {
    if (_incomingFriendRequests is EqualUnmodifiableListView)
      return _incomingFriendRequests;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_incomingFriendRequests);
  }

  final List<TransactionOutputReference> _friends;
  @override
  List<TransactionOutputReference> get friends {
    if (_friends is EqualUnmodifiableListView) return _friends;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_friends);
  }

  @override
  String toString() {
    return 'FriendData(outgoingFriendRequests: $outgoingFriendRequests, incomingFriendRequests: $incomingFriendRequests, friends: $friends)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendDataImpl &&
            const DeepCollectionEquality().equals(
                other._outgoingFriendRequests, _outgoingFriendRequests) &&
            const DeepCollectionEquality().equals(
                other._incomingFriendRequests, _incomingFriendRequests) &&
            const DeepCollectionEquality().equals(other._friends, _friends));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_outgoingFriendRequests),
      const DeepCollectionEquality().hash(_incomingFriendRequests),
      const DeepCollectionEquality().hash(_friends));

  /// Create a copy of FriendData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendDataImplCopyWith<_$FriendDataImpl> get copyWith =>
      __$$FriendDataImplCopyWithImpl<_$FriendDataImpl>(this, _$identity);
}

abstract class _FriendData implements FriendData {
  const factory _FriendData(
      {required final List<TransactionOutputReference> outgoingFriendRequests,
      required final List<TransactionOutputReference> incomingFriendRequests,
      required final List<TransactionOutputReference>
          friends}) = _$FriendDataImpl;

  @override
  List<TransactionOutputReference> get outgoingFriendRequests;
  @override
  List<TransactionOutputReference> get incomingFriendRequests;
  @override
  List<TransactionOutputReference> get friends;

  /// Create a copy of FriendData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendDataImplCopyWith<_$FriendDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
