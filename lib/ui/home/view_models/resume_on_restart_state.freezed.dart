// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'resume_on_restart_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResumeOnRestartState {

/// Whether the device can resume sharing by itself (Android only); the
/// row is hidden otherwise.
 bool get available;/// Whether the person chose to resume sharing.
 bool get enabled;/// What would keep it from resuming, `null` for nothing (or while the
/// option is off).
 ResumeBlocker? get blocker;
/// Create a copy of ResumeOnRestartState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResumeOnRestartStateCopyWith<ResumeOnRestartState> get copyWith => _$ResumeOnRestartStateCopyWithImpl<ResumeOnRestartState>(this as ResumeOnRestartState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ResumeOnRestartState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResumeOnRestartState&&(identical(other.available, _this.available) || other.available == _this.available)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.blocker, _this.blocker) || other.blocker == _this.blocker));
}


@override
int get hashCode {
  final _this = this as ResumeOnRestartState;
  return Object.hash(runtimeType,_this.available,_this.enabled,_this.blocker);
}

@override
String toString() {
  final _this = this as ResumeOnRestartState;
  return 'ResumeOnRestartState(available: ${_this.available}, enabled: ${_this.enabled}, blocker: ${_this.blocker})';
}


}

/// @nodoc
abstract mixin class $ResumeOnRestartStateCopyWith<$Res>  {
  factory $ResumeOnRestartStateCopyWith(ResumeOnRestartState value, $Res Function(ResumeOnRestartState) _then) = _$ResumeOnRestartStateCopyWithImpl;
@useResult
$Res call({
 bool available, bool enabled, ResumeBlocker? blocker
});




}
/// @nodoc
class _$ResumeOnRestartStateCopyWithImpl<$Res>
    implements $ResumeOnRestartStateCopyWith<$Res> {
  _$ResumeOnRestartStateCopyWithImpl(this._self, this._then);

  final ResumeOnRestartState _self;
  final $Res Function(ResumeOnRestartState) _then;

/// Create a copy of ResumeOnRestartState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? available = null,Object? enabled = null,Object? blocker = freezed,}) {
  return _then(ResumeOnRestartState(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,blocker: freezed == blocker ? _self.blocker : blocker // ignore: cast_nullable_to_non_nullable
as ResumeBlocker?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResumeOnRestartState].
extension ResumeOnRestartStatePatterns on ResumeOnRestartState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResumeOnRestartState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResumeOnRestartState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResumeOnRestartState value)  $default,){
final _that = this;
switch (_that) {
case _ResumeOnRestartState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResumeOnRestartState value)?  $default,){
final _that = this;
switch (_that) {
case _ResumeOnRestartState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool available,  bool enabled,  ResumeBlocker? blocker)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResumeOnRestartState() when $default != null:
return $default(_that.available,_that.enabled,_that.blocker);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool available,  bool enabled,  ResumeBlocker? blocker)  $default,) {final _that = this;
switch (_that) {
case _ResumeOnRestartState():
return $default(_that.available,_that.enabled,_that.blocker);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool available,  bool enabled,  ResumeBlocker? blocker)?  $default,) {final _that = this;
switch (_that) {
case _ResumeOnRestartState() when $default != null:
return $default(_that.available,_that.enabled,_that.blocker);case _:
  return null;

}
}

}

/// @nodoc


class _ResumeOnRestartState implements ResumeOnRestartState {
  const _ResumeOnRestartState({required this.available, required this.enabled, this.blocker});
  

/// Whether the device can resume sharing by itself (Android only); the
/// row is hidden otherwise.
@override final  bool available;
/// Whether the person chose to resume sharing.
@override final  bool enabled;
/// What would keep it from resuming, `null` for nothing (or while the
/// option is off).
@override final  ResumeBlocker? blocker;

/// Create a copy of ResumeOnRestartState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResumeOnRestartStateCopyWith<_ResumeOnRestartState> get copyWith => __$ResumeOnRestartStateCopyWithImpl<_ResumeOnRestartState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResumeOnRestartState&&(identical(other.available, available) || other.available == available)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.blocker, blocker) || other.blocker == blocker));
}


@override
int get hashCode {
    return Object.hash(runtimeType,available,enabled,blocker);
}

@override
String toString() {
    return 'ResumeOnRestartState(available: $available, enabled: $enabled, blocker: $blocker)';
}


}

/// @nodoc
abstract mixin class _$ResumeOnRestartStateCopyWith<$Res> implements $ResumeOnRestartStateCopyWith<$Res> {
  factory _$ResumeOnRestartStateCopyWith(_ResumeOnRestartState value, $Res Function(_ResumeOnRestartState) _then) = __$ResumeOnRestartStateCopyWithImpl;
@override @useResult
$Res call({
 bool available, bool enabled, ResumeBlocker? blocker
});




}
/// @nodoc
class __$ResumeOnRestartStateCopyWithImpl<$Res>
    implements _$ResumeOnRestartStateCopyWith<$Res> {
  __$ResumeOnRestartStateCopyWithImpl(this._self, this._then);

  final _ResumeOnRestartState _self;
  final $Res Function(_ResumeOnRestartState) _then;

/// Create a copy of ResumeOnRestartState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? available = null,Object? enabled = null,Object? blocker = freezed,}) {
  return _then(_ResumeOnRestartState(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,blocker: freezed == blocker ? _self.blocker : blocker // ignore: cast_nullable_to_non_nullable
as ResumeBlocker?,
  ));
}


}

// dart format on
