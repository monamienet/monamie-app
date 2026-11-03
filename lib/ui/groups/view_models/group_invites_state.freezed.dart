// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_invites_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupInvitesState {

/// The group's pending invites; `null` until the first load works.
 List<Invite>? get invites;/// Why the last load failed; empty when it did not. Shown only while
/// [invites] is `null`.
 String get errorMessage;
/// Create a copy of GroupInvitesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupInvitesStateCopyWith<GroupInvitesState> get copyWith => _$GroupInvitesStateCopyWithImpl<GroupInvitesState>(this as GroupInvitesState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupInvitesState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupInvitesState&&const DeepCollectionEquality().equals(other.invites, _this.invites)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as GroupInvitesState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.invites),_this.errorMessage);
}

@override
String toString() {
  final _this = this as GroupInvitesState;
  return 'GroupInvitesState(invites: ${_this.invites}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $GroupInvitesStateCopyWith<$Res>  {
  factory $GroupInvitesStateCopyWith(GroupInvitesState value, $Res Function(GroupInvitesState) _then) = _$GroupInvitesStateCopyWithImpl;
@useResult
$Res call({
 List<Invite>? invites, String errorMessage
});




}
/// @nodoc
class _$GroupInvitesStateCopyWithImpl<$Res>
    implements $GroupInvitesStateCopyWith<$Res> {
  _$GroupInvitesStateCopyWithImpl(this._self, this._then);

  final GroupInvitesState _self;
  final $Res Function(GroupInvitesState) _then;

/// Create a copy of GroupInvitesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invites = freezed,Object? errorMessage = null,}) {
  return _then(GroupInvitesState(
invites: freezed == invites ? _self.invites : invites // ignore: cast_nullable_to_non_nullable
as List<Invite>?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupInvitesState].
extension GroupInvitesStatePatterns on GroupInvitesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupInvitesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupInvitesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupInvitesState value)  $default,){
final _that = this;
switch (_that) {
case _GroupInvitesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupInvitesState value)?  $default,){
final _that = this;
switch (_that) {
case _GroupInvitesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Invite>? invites,  String errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupInvitesState() when $default != null:
return $default(_that.invites,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Invite>? invites,  String errorMessage)  $default,) {final _that = this;
switch (_that) {
case _GroupInvitesState():
return $default(_that.invites,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Invite>? invites,  String errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _GroupInvitesState() when $default != null:
return $default(_that.invites,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _GroupInvitesState implements GroupInvitesState {
  const _GroupInvitesState({ List<Invite>? invites, this.errorMessage = ''}): _invites = invites;
  

/// The group's pending invites; `null` until the first load works.
 final  List<Invite>? _invites;
/// The group's pending invites; `null` until the first load works.
@override List<Invite>? get invites {
  final value = _invites;
  if (value == null) return null;
  if (_invites is EqualUnmodifiableListView) return _invites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Why the last load failed; empty when it did not. Shown only while
/// [invites] is `null`.
@override@JsonKey() final  String errorMessage;

/// Create a copy of GroupInvitesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupInvitesStateCopyWith<_GroupInvitesState> get copyWith => __$GroupInvitesStateCopyWithImpl<_GroupInvitesState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupInvitesState&&const DeepCollectionEquality().equals(other.invites, _invites)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_invites),errorMessage);
}

@override
String toString() {
    return 'GroupInvitesState(invites: $invites, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$GroupInvitesStateCopyWith<$Res> implements $GroupInvitesStateCopyWith<$Res> {
  factory _$GroupInvitesStateCopyWith(_GroupInvitesState value, $Res Function(_GroupInvitesState) _then) = __$GroupInvitesStateCopyWithImpl;
@override @useResult
$Res call({
 List<Invite>? invites, String errorMessage
});




}
/// @nodoc
class __$GroupInvitesStateCopyWithImpl<$Res>
    implements _$GroupInvitesStateCopyWith<$Res> {
  __$GroupInvitesStateCopyWithImpl(this._self, this._then);

  final _GroupInvitesState _self;
  final $Res Function(_GroupInvitesState) _then;

/// Create a copy of GroupInvitesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invites = freezed,Object? errorMessage = null,}) {
  return _then(_GroupInvitesState(
invites: freezed == invites ? _self._invites : invites // ignore: cast_nullable_to_non_nullable
as List<Invite>?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
