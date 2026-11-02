// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeSessionState {

/// How the person is leaving the organization, `null` when they are not.
 SessionExit? get leaving;/// Whether the signed-in user owns each organization read so far (by
/// id). The owner-only menu entries (*Administradores*) follow it.
 Map<String, bool> get ownership;
/// Create a copy of HomeSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSessionStateCopyWith<HomeSessionState> get copyWith => _$HomeSessionStateCopyWithImpl<HomeSessionState>(this as HomeSessionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HomeSessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSessionState&&(identical(other.leaving, _this.leaving) || other.leaving == _this.leaving)&&const DeepCollectionEquality().equals(other.ownership, _this.ownership));
}


@override
int get hashCode {
  final _this = this as HomeSessionState;
  return Object.hash(runtimeType,_this.leaving,const DeepCollectionEquality().hash(_this.ownership));
}

@override
String toString() {
  final _this = this as HomeSessionState;
  return 'HomeSessionState(leaving: ${_this.leaving}, ownership: ${_this.ownership})';
}


}

/// @nodoc
abstract mixin class $HomeSessionStateCopyWith<$Res>  {
  factory $HomeSessionStateCopyWith(HomeSessionState value, $Res Function(HomeSessionState) _then) = _$HomeSessionStateCopyWithImpl;
@useResult
$Res call({
 SessionExit? leaving, Map<String, bool> ownership
});




}
/// @nodoc
class _$HomeSessionStateCopyWithImpl<$Res>
    implements $HomeSessionStateCopyWith<$Res> {
  _$HomeSessionStateCopyWithImpl(this._self, this._then);

  final HomeSessionState _self;
  final $Res Function(HomeSessionState) _then;

/// Create a copy of HomeSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? leaving = freezed,Object? ownership = null,}) {
  return _then(HomeSessionState(
leaving: freezed == leaving ? _self.leaving : leaving // ignore: cast_nullable_to_non_nullable
as SessionExit?,ownership: null == ownership ? _self.ownership : ownership // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeSessionState].
extension HomeSessionStatePatterns on HomeSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeSessionState value)  $default,){
final _that = this;
switch (_that) {
case _HomeSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SessionExit? leaving,  Map<String, bool> ownership)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSessionState() when $default != null:
return $default(_that.leaving,_that.ownership);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SessionExit? leaving,  Map<String, bool> ownership)  $default,) {final _that = this;
switch (_that) {
case _HomeSessionState():
return $default(_that.leaving,_that.ownership);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SessionExit? leaving,  Map<String, bool> ownership)?  $default,) {final _that = this;
switch (_that) {
case _HomeSessionState() when $default != null:
return $default(_that.leaving,_that.ownership);case _:
  return null;

}
}

}

/// @nodoc


class _HomeSessionState extends HomeSessionState {
  const _HomeSessionState({this.leaving,  Map<String, bool> ownership = const {}}): _ownership = ownership,super._();
  

/// How the person is leaving the organization, `null` when they are not.
@override final  SessionExit? leaving;
/// Whether the signed-in user owns each organization read so far (by
/// id). The owner-only menu entries (*Administradores*) follow it.
 final  Map<String, bool> _ownership;
/// Whether the signed-in user owns each organization read so far (by
/// id). The owner-only menu entries (*Administradores*) follow it.
@override@JsonKey() Map<String, bool> get ownership {
  if (_ownership is EqualUnmodifiableMapView) return _ownership;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ownership);
}


/// Create a copy of HomeSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeSessionStateCopyWith<_HomeSessionState> get copyWith => __$HomeSessionStateCopyWithImpl<_HomeSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSessionState&&(identical(other.leaving, leaving) || other.leaving == leaving)&&const DeepCollectionEquality().equals(other.ownership, _ownership));
}


@override
int get hashCode {
    return Object.hash(runtimeType,leaving,const DeepCollectionEquality().hash(_ownership));
}

@override
String toString() {
    return 'HomeSessionState(leaving: $leaving, ownership: $ownership)';
}


}

/// @nodoc
abstract mixin class _$HomeSessionStateCopyWith<$Res> implements $HomeSessionStateCopyWith<$Res> {
  factory _$HomeSessionStateCopyWith(_HomeSessionState value, $Res Function(_HomeSessionState) _then) = __$HomeSessionStateCopyWithImpl;
@override @useResult
$Res call({
 SessionExit? leaving, Map<String, bool> ownership
});




}
/// @nodoc
class __$HomeSessionStateCopyWithImpl<$Res>
    implements _$HomeSessionStateCopyWith<$Res> {
  __$HomeSessionStateCopyWithImpl(this._self, this._then);

  final _HomeSessionState _self;
  final $Res Function(_HomeSessionState) _then;

/// Create a copy of HomeSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? leaving = freezed,Object? ownership = null,}) {
  return _then(_HomeSessionState(
leaving: freezed == leaving ? _self.leaving : leaving // ignore: cast_nullable_to_non_nullable
as SessionExit?,ownership: null == ownership ? _self._ownership : ownership // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}


}

// dart format on
