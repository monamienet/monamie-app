// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserState {

/// The person as the map knows them (e-mail and name), or `null` when
/// no profile was saved at sign-in.
 UserModel? get user;/// The profile saved at sign-in (Hive), with the avatar. Compared by
/// identity: each read is a new object.
 UserGoogleModel? get googleUser;/// Until the profile is first read.
 bool get isLoading;
/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserStateCopyWith<UserState> get copyWith => _$UserStateCopyWithImpl<UserState>(this as UserState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserState&&(identical(other.user, _this.user) || other.user == _this.user)&&(identical(other.googleUser, _this.googleUser) || other.googleUser == _this.googleUser)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading));
}


@override
int get hashCode {
  final _this = this as UserState;
  return Object.hash(runtimeType,_this.user,_this.googleUser,_this.isLoading);
}

@override
String toString() {
  final _this = this as UserState;
  return 'UserState(user: ${_this.user}, googleUser: ${_this.googleUser}, isLoading: ${_this.isLoading})';
}


}

/// @nodoc
abstract mixin class $UserStateCopyWith<$Res>  {
  factory $UserStateCopyWith(UserState value, $Res Function(UserState) _then) = _$UserStateCopyWithImpl;
@useResult
$Res call({
 UserModel? user, UserGoogleModel? googleUser, bool isLoading
});


$UserModelCopyWith<$Res>? get user;

}
/// @nodoc
class _$UserStateCopyWithImpl<$Res>
    implements $UserStateCopyWith<$Res> {
  _$UserStateCopyWithImpl(this._self, this._then);

  final UserState _self;
  final $Res Function(UserState) _then;

/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = freezed,Object? googleUser = freezed,Object? isLoading = null,}) {
  return _then(UserState(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserModel?,googleUser: freezed == googleUser ? _self.googleUser : googleUser // ignore: cast_nullable_to_non_nullable
as UserGoogleModel?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [UserState].
extension UserStatePatterns on UserState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserState value)  $default,){
final _that = this;
switch (_that) {
case _UserState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserState value)?  $default,){
final _that = this;
switch (_that) {
case _UserState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserModel? user,  UserGoogleModel? googleUser,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserState() when $default != null:
return $default(_that.user,_that.googleUser,_that.isLoading);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserModel? user,  UserGoogleModel? googleUser,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _UserState():
return $default(_that.user,_that.googleUser,_that.isLoading);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserModel? user,  UserGoogleModel? googleUser,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _UserState() when $default != null:
return $default(_that.user,_that.googleUser,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _UserState implements UserState {
  const _UserState({this.user, this.googleUser, this.isLoading = true});
  

/// The person as the map knows them (e-mail and name), or `null` when
/// no profile was saved at sign-in.
@override final  UserModel? user;
/// The profile saved at sign-in (Hive), with the avatar. Compared by
/// identity: each read is a new object.
@override final  UserGoogleModel? googleUser;
/// Until the profile is first read.
@override@JsonKey() final  bool isLoading;

/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserStateCopyWith<_UserState> get copyWith => __$UserStateCopyWithImpl<_UserState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserState&&(identical(other.user, user) || other.user == user)&&(identical(other.googleUser, googleUser) || other.googleUser == googleUser)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode {
    return Object.hash(runtimeType,user,googleUser,isLoading);
}

@override
String toString() {
    return 'UserState(user: $user, googleUser: $googleUser, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$UserStateCopyWith<$Res> implements $UserStateCopyWith<$Res> {
  factory _$UserStateCopyWith(_UserState value, $Res Function(_UserState) _then) = __$UserStateCopyWithImpl;
@override @useResult
$Res call({
 UserModel? user, UserGoogleModel? googleUser, bool isLoading
});


@override $UserModelCopyWith<$Res>? get user;

}
/// @nodoc
class __$UserStateCopyWithImpl<$Res>
    implements _$UserStateCopyWith<$Res> {
  __$UserStateCopyWithImpl(this._self, this._then);

  final _UserState _self;
  final $Res Function(_UserState) _then;

/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = freezed,Object? googleUser = freezed,Object? isLoading = null,}) {
  return _then(_UserState(
user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserModel?,googleUser: freezed == googleUser ? _self.googleUser : googleUser // ignore: cast_nullable_to_non_nullable
as UserGoogleModel?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of UserState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserModelCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserModelCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
