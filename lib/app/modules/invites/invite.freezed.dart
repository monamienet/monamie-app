// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteDraft {

 String get email; Set<GroupRole> get roles;
/// Create a copy of InviteDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteDraftCopyWith<InviteDraft> get copyWith => _$InviteDraftCopyWithImpl<InviteDraft>(this as InviteDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InviteDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteDraft&&(identical(other.email, _this.email) || other.email == _this.email)&&const DeepCollectionEquality().equals(other.roles, _this.roles));
}


@override
int get hashCode {
  final _this = this as InviteDraft;
  return Object.hash(runtimeType,_this.email,const DeepCollectionEquality().hash(_this.roles));
}

@override
String toString() {
  final _this = this as InviteDraft;
  return 'InviteDraft(email: ${_this.email}, roles: ${_this.roles})';
}


}

/// @nodoc
abstract mixin class $InviteDraftCopyWith<$Res>  {
  factory $InviteDraftCopyWith(InviteDraft value, $Res Function(InviteDraft) _then) = _$InviteDraftCopyWithImpl;
@useResult
$Res call({
 String email, Set<GroupRole> roles
});




}
/// @nodoc
class _$InviteDraftCopyWithImpl<$Res>
    implements $InviteDraftCopyWith<$Res> {
  _$InviteDraftCopyWithImpl(this._self, this._then);

  final InviteDraft _self;
  final $Res Function(InviteDraft) _then;

/// Create a copy of InviteDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? roles = null,}) {
  return _then(InviteDraft(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Set<GroupRole>,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteDraft].
extension InviteDraftPatterns on InviteDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteDraft value)  $default,){
final _that = this;
switch (_that) {
case _InviteDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteDraft value)?  $default,){
final _that = this;
switch (_that) {
case _InviteDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  Set<GroupRole> roles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteDraft() when $default != null:
return $default(_that.email,_that.roles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  Set<GroupRole> roles)  $default,) {final _that = this;
switch (_that) {
case _InviteDraft():
return $default(_that.email,_that.roles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  Set<GroupRole> roles)?  $default,) {final _that = this;
switch (_that) {
case _InviteDraft() when $default != null:
return $default(_that.email,_that.roles);case _:
  return null;

}
}

}

/// @nodoc


class _InviteDraft implements InviteDraft {
  const _InviteDraft(this.email, { Set<GroupRole> roles = const {GroupRole.publisher}}): _roles = roles;
  

@override final  String email;
 final  Set<GroupRole> _roles;
@override@JsonKey() Set<GroupRole> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}


/// Create a copy of InviteDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteDraftCopyWith<_InviteDraft> get copyWith => __$InviteDraftCopyWithImpl<_InviteDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteDraft&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.roles, _roles));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,const DeepCollectionEquality().hash(_roles));
}

@override
String toString() {
    return 'InviteDraft(email: $email, roles: $roles)';
}


}

/// @nodoc
abstract mixin class _$InviteDraftCopyWith<$Res> implements $InviteDraftCopyWith<$Res> {
  factory _$InviteDraftCopyWith(_InviteDraft value, $Res Function(_InviteDraft) _then) = __$InviteDraftCopyWithImpl;
@override @useResult
$Res call({
 String email, Set<GroupRole> roles
});




}
/// @nodoc
class __$InviteDraftCopyWithImpl<$Res>
    implements _$InviteDraftCopyWith<$Res> {
  __$InviteDraftCopyWithImpl(this._self, this._then);

  final _InviteDraft _self;
  final $Res Function(_InviteDraft) _then;

/// Create a copy of InviteDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? roles = null,}) {
  return _then(_InviteDraft(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<GroupRole>,
  ));
}


}

// dart format on
