// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracking_settings_edit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackingSettingsEditState {

/// What is saved now.
 TrackingSettings get savedSettings;/// What an administrator is choosing.
 TrackingSettings get draft; TrackingPreset get preset;/// The plan's minimum period (Community: 15 min); presets below it are
/// not offered.
 int get minPeriodMinutes; bool get justSaved;/// Why the last save failed; `null` when it did not.
 Failure? get failure;
/// Create a copy of TrackingSettingsEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackingSettingsEditStateCopyWith<TrackingSettingsEditState> get copyWith => _$TrackingSettingsEditStateCopyWithImpl<TrackingSettingsEditState>(this as TrackingSettingsEditState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrackingSettingsEditState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackingSettingsEditState&&(identical(other.savedSettings, _this.savedSettings) || other.savedSettings == _this.savedSettings)&&(identical(other.draft, _this.draft) || other.draft == _this.draft)&&(identical(other.preset, _this.preset) || other.preset == _this.preset)&&(identical(other.minPeriodMinutes, _this.minPeriodMinutes) || other.minPeriodMinutes == _this.minPeriodMinutes)&&(identical(other.justSaved, _this.justSaved) || other.justSaved == _this.justSaved)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as TrackingSettingsEditState;
  return Object.hash(runtimeType,_this.savedSettings,_this.draft,_this.preset,_this.minPeriodMinutes,_this.justSaved,_this.failure);
}

@override
String toString() {
  final _this = this as TrackingSettingsEditState;
  return 'TrackingSettingsEditState(savedSettings: ${_this.savedSettings}, draft: ${_this.draft}, preset: ${_this.preset}, minPeriodMinutes: ${_this.minPeriodMinutes}, justSaved: ${_this.justSaved}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $TrackingSettingsEditStateCopyWith<$Res>  {
  factory $TrackingSettingsEditStateCopyWith(TrackingSettingsEditState value, $Res Function(TrackingSettingsEditState) _then) = _$TrackingSettingsEditStateCopyWithImpl;
@useResult
$Res call({
 TrackingSettings savedSettings, TrackingSettings draft, TrackingPreset preset, int minPeriodMinutes, bool justSaved, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$TrackingSettingsEditStateCopyWithImpl<$Res>
    implements $TrackingSettingsEditStateCopyWith<$Res> {
  _$TrackingSettingsEditStateCopyWithImpl(this._self, this._then);

  final TrackingSettingsEditState _self;
  final $Res Function(TrackingSettingsEditState) _then;

/// Create a copy of TrackingSettingsEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? savedSettings = null,Object? draft = null,Object? preset = null,Object? minPeriodMinutes = null,Object? justSaved = null,Object? failure = freezed,}) {
  return _then(TrackingSettingsEditState(
savedSettings: null == savedSettings ? _self.savedSettings : savedSettings // ignore: cast_nullable_to_non_nullable
as TrackingSettings,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as TrackingSettings,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as TrackingPreset,minPeriodMinutes: null == minPeriodMinutes ? _self.minPeriodMinutes : minPeriodMinutes // ignore: cast_nullable_to_non_nullable
as int,justSaved: null == justSaved ? _self.justSaved : justSaved // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of TrackingSettingsEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackingSettingsEditState].
extension TrackingSettingsEditStatePatterns on TrackingSettingsEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackingSettingsEditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackingSettingsEditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackingSettingsEditState value)  $default,){
final _that = this;
switch (_that) {
case _TrackingSettingsEditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackingSettingsEditState value)?  $default,){
final _that = this;
switch (_that) {
case _TrackingSettingsEditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TrackingSettings savedSettings,  TrackingSettings draft,  TrackingPreset preset,  int minPeriodMinutes,  bool justSaved,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackingSettingsEditState() when $default != null:
return $default(_that.savedSettings,_that.draft,_that.preset,_that.minPeriodMinutes,_that.justSaved,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TrackingSettings savedSettings,  TrackingSettings draft,  TrackingPreset preset,  int minPeriodMinutes,  bool justSaved,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _TrackingSettingsEditState():
return $default(_that.savedSettings,_that.draft,_that.preset,_that.minPeriodMinutes,_that.justSaved,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TrackingSettings savedSettings,  TrackingSettings draft,  TrackingPreset preset,  int minPeriodMinutes,  bool justSaved,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _TrackingSettingsEditState() when $default != null:
return $default(_that.savedSettings,_that.draft,_that.preset,_that.minPeriodMinutes,_that.justSaved,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _TrackingSettingsEditState implements TrackingSettingsEditState {
  const _TrackingSettingsEditState({required this.savedSettings, required this.draft, required this.preset, this.minPeriodMinutes = 0, this.justSaved = false, this.failure});
  

/// What is saved now.
@override final  TrackingSettings savedSettings;
/// What an administrator is choosing.
@override final  TrackingSettings draft;
@override final  TrackingPreset preset;
/// The plan's minimum period (Community: 15 min); presets below it are
/// not offered.
@override@JsonKey() final  int minPeriodMinutes;
@override@JsonKey() final  bool justSaved;
/// Why the last save failed; `null` when it did not.
@override final  Failure? failure;

/// Create a copy of TrackingSettingsEditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackingSettingsEditStateCopyWith<_TrackingSettingsEditState> get copyWith => __$TrackingSettingsEditStateCopyWithImpl<_TrackingSettingsEditState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackingSettingsEditState&&(identical(other.savedSettings, savedSettings) || other.savedSettings == savedSettings)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.preset, preset) || other.preset == preset)&&(identical(other.minPeriodMinutes, minPeriodMinutes) || other.minPeriodMinutes == minPeriodMinutes)&&(identical(other.justSaved, justSaved) || other.justSaved == justSaved)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,savedSettings,draft,preset,minPeriodMinutes,justSaved,failure);
}

@override
String toString() {
    return 'TrackingSettingsEditState(savedSettings: $savedSettings, draft: $draft, preset: $preset, minPeriodMinutes: $minPeriodMinutes, justSaved: $justSaved, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$TrackingSettingsEditStateCopyWith<$Res> implements $TrackingSettingsEditStateCopyWith<$Res> {
  factory _$TrackingSettingsEditStateCopyWith(_TrackingSettingsEditState value, $Res Function(_TrackingSettingsEditState) _then) = __$TrackingSettingsEditStateCopyWithImpl;
@override @useResult
$Res call({
 TrackingSettings savedSettings, TrackingSettings draft, TrackingPreset preset, int minPeriodMinutes, bool justSaved, Failure? failure
});


@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$TrackingSettingsEditStateCopyWithImpl<$Res>
    implements _$TrackingSettingsEditStateCopyWith<$Res> {
  __$TrackingSettingsEditStateCopyWithImpl(this._self, this._then);

  final _TrackingSettingsEditState _self;
  final $Res Function(_TrackingSettingsEditState) _then;

/// Create a copy of TrackingSettingsEditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? savedSettings = null,Object? draft = null,Object? preset = null,Object? minPeriodMinutes = null,Object? justSaved = null,Object? failure = freezed,}) {
  return _then(_TrackingSettingsEditState(
savedSettings: null == savedSettings ? _self.savedSettings : savedSettings // ignore: cast_nullable_to_non_nullable
as TrackingSettings,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as TrackingSettings,preset: null == preset ? _self.preset : preset // ignore: cast_nullable_to_non_nullable
as TrackingPreset,minPeriodMinutes: null == minPeriodMinutes ? _self.minPeriodMinutes : minPeriodMinutes // ignore: cast_nullable_to_non_nullable
as int,justSaved: null == justSaved ? _self.justSaved : justSaved // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of TrackingSettingsEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
