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
mixin _$Invite {

 String get id; String get organizationId; String get organizationName; String get groupId;/// The group's name; `null` when the server sent none, and the screens
/// then name it ("Grupo") in the device's language.
 String? get groupName; String get email; Set<GroupRole> get roles; String get inviterName; DateTime? get expiresAt;/// Past its 14 days: shown as *Expirado* with *Reenviar*.
 bool get expired;
/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteCopyWith<Invite> get copyWith => _$InviteCopyWithImpl<Invite>(this as Invite, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Invite;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invite&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.organizationId, _this.organizationId) || other.organizationId == _this.organizationId)&&(identical(other.organizationName, _this.organizationName) || other.organizationName == _this.organizationName)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.groupName, _this.groupName) || other.groupName == _this.groupName)&&(identical(other.email, _this.email) || other.email == _this.email)&&const DeepCollectionEquality().equals(other.roles, _this.roles)&&(identical(other.inviterName, _this.inviterName) || other.inviterName == _this.inviterName)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.expired, _this.expired) || other.expired == _this.expired));
}


@override
int get hashCode {
  final _this = this as Invite;
  return Object.hash(runtimeType,_this.id,_this.organizationId,_this.organizationName,_this.groupId,_this.groupName,_this.email,const DeepCollectionEquality().hash(_this.roles),_this.inviterName,_this.expiresAt,_this.expired);
}

@override
String toString() {
  final _this = this as Invite;
  return 'Invite(id: ${_this.id}, organizationId: ${_this.organizationId}, organizationName: ${_this.organizationName}, groupId: ${_this.groupId}, groupName: ${_this.groupName}, email: ${_this.email}, roles: ${_this.roles}, inviterName: ${_this.inviterName}, expiresAt: ${_this.expiresAt}, expired: ${_this.expired})';
}


}

/// @nodoc
abstract mixin class $InviteCopyWith<$Res>  {
  factory $InviteCopyWith(Invite value, $Res Function(Invite) _then) = _$InviteCopyWithImpl;
@useResult
$Res call({
 String id, String organizationId, String organizationName, String groupId, String? groupName, String email, Set<GroupRole> roles, String inviterName, DateTime? expiresAt, bool expired
});




}
/// @nodoc
class _$InviteCopyWithImpl<$Res>
    implements $InviteCopyWith<$Res> {
  _$InviteCopyWithImpl(this._self, this._then);

  final Invite _self;
  final $Res Function(Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? organizationId = null,Object? organizationName = null,Object? groupId = null,Object? groupName = freezed,Object? email = null,Object? roles = null,Object? inviterName = null,Object? expiresAt = freezed,Object? expired = null,}) {
  return _then(Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as Set<GroupRole>,inviterName: null == inviterName ? _self.inviterName : inviterName // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Invite].
extension InvitePatterns on Invite {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invite value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invite value)  $default,){
final _that = this;
switch (_that) {
case _Invite():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invite value)?  $default,){
final _that = this;
switch (_that) {
case _Invite() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String organizationId,  String organizationName,  String groupId,  String? groupName,  String email,  Set<GroupRole> roles,  String inviterName,  DateTime? expiresAt,  bool expired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.organizationId,_that.organizationName,_that.groupId,_that.groupName,_that.email,_that.roles,_that.inviterName,_that.expiresAt,_that.expired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String organizationId,  String organizationName,  String groupId,  String? groupName,  String email,  Set<GroupRole> roles,  String inviterName,  DateTime? expiresAt,  bool expired)  $default,) {final _that = this;
switch (_that) {
case _Invite():
return $default(_that.id,_that.organizationId,_that.organizationName,_that.groupId,_that.groupName,_that.email,_that.roles,_that.inviterName,_that.expiresAt,_that.expired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String organizationId,  String organizationName,  String groupId,  String? groupName,  String email,  Set<GroupRole> roles,  String inviterName,  DateTime? expiresAt,  bool expired)?  $default,) {final _that = this;
switch (_that) {
case _Invite() when $default != null:
return $default(_that.id,_that.organizationId,_that.organizationName,_that.groupId,_that.groupName,_that.email,_that.roles,_that.inviterName,_that.expiresAt,_that.expired);case _:
  return null;

}
}

}

/// @nodoc


class _Invite extends Invite {
  const _Invite({required this.id, required this.organizationId, required this.organizationName, required this.groupId, required this.groupName, required this.email, required  Set<GroupRole> roles, required this.inviterName, required this.expiresAt, this.expired = false}): _roles = roles,super._();
  

@override final  String id;
@override final  String organizationId;
@override final  String organizationName;
@override final  String groupId;
/// The group's name; `null` when the server sent none, and the screens
/// then name it ("Grupo") in the device's language.
@override final  String? groupName;
@override final  String email;
 final  Set<GroupRole> _roles;
@override Set<GroupRole> get roles {
  if (_roles is EqualUnmodifiableSetView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_roles);
}

@override final  String inviterName;
@override final  DateTime? expiresAt;
/// Past its 14 days: shown as *Expirado* with *Reenviar*.
@override@JsonKey() final  bool expired;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteCopyWith<_Invite> get copyWith => __$InviteCopyWithImpl<_Invite>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invite&&(identical(other.id, id) || other.id == id)&&(identical(other.organizationId, organizationId) || other.organizationId == organizationId)&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.roles, _roles)&&(identical(other.inviterName, inviterName) || other.inviterName == inviterName)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.expired, expired) || other.expired == expired));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,organizationId,organizationName,groupId,groupName,email,const DeepCollectionEquality().hash(_roles),inviterName,expiresAt,expired);
}

@override
String toString() {
    return 'Invite(id: $id, organizationId: $organizationId, organizationName: $organizationName, groupId: $groupId, groupName: $groupName, email: $email, roles: $roles, inviterName: $inviterName, expiresAt: $expiresAt, expired: $expired)';
}


}

/// @nodoc
abstract mixin class _$InviteCopyWith<$Res> implements $InviteCopyWith<$Res> {
  factory _$InviteCopyWith(_Invite value, $Res Function(_Invite) _then) = __$InviteCopyWithImpl;
@override @useResult
$Res call({
 String id, String organizationId, String organizationName, String groupId, String? groupName, String email, Set<GroupRole> roles, String inviterName, DateTime? expiresAt, bool expired
});




}
/// @nodoc
class __$InviteCopyWithImpl<$Res>
    implements _$InviteCopyWith<$Res> {
  __$InviteCopyWithImpl(this._self, this._then);

  final _Invite _self;
  final $Res Function(_Invite) _then;

/// Create a copy of Invite
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? organizationId = null,Object? organizationName = null,Object? groupId = null,Object? groupName = freezed,Object? email = null,Object? roles = null,Object? inviterName = null,Object? expiresAt = freezed,Object? expired = null,}) {
  return _then(_Invite(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,organizationId: null == organizationId ? _self.organizationId : organizationId // ignore: cast_nullable_to_non_nullable
as String,organizationName: null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,groupName: freezed == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String?,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as Set<GroupRole>,inviterName: null == inviterName ? _self.inviterName : inviterName // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,expired: null == expired ? _self.expired : expired // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

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
