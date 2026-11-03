// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'administrators_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AdministratorsState {

/// The administrators and the members who may be appointed.
 OrganizationAdministrators get people;/// Why the last load or change failed; empty when it did not.
 String get errorMessage;
/// Create a copy of AdministratorsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdministratorsStateCopyWith<AdministratorsState> get copyWith => _$AdministratorsStateCopyWithImpl<AdministratorsState>(this as AdministratorsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AdministratorsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdministratorsState&&(identical(other.people, _this.people) || other.people == _this.people)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as AdministratorsState;
  return Object.hash(runtimeType,_this.people,_this.errorMessage);
}

@override
String toString() {
  final _this = this as AdministratorsState;
  return 'AdministratorsState(people: ${_this.people}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $AdministratorsStateCopyWith<$Res>  {
  factory $AdministratorsStateCopyWith(AdministratorsState value, $Res Function(AdministratorsState) _then) = _$AdministratorsStateCopyWithImpl;
@useResult
$Res call({
 OrganizationAdministrators people, String errorMessage
});


$OrganizationAdministratorsCopyWith<$Res> get people;

}
/// @nodoc
class _$AdministratorsStateCopyWithImpl<$Res>
    implements $AdministratorsStateCopyWith<$Res> {
  _$AdministratorsStateCopyWithImpl(this._self, this._then);

  final AdministratorsState _self;
  final $Res Function(AdministratorsState) _then;

/// Create a copy of AdministratorsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? people = null,Object? errorMessage = null,}) {
  return _then(AdministratorsState(
people: null == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as OrganizationAdministrators,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of AdministratorsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationAdministratorsCopyWith<$Res> get people {
  
  return $OrganizationAdministratorsCopyWith<$Res>(_self.people, (value) {
    return _then(_self.copyWith(people: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdministratorsState].
extension AdministratorsStatePatterns on AdministratorsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdministratorsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdministratorsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdministratorsState value)  $default,){
final _that = this;
switch (_that) {
case _AdministratorsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdministratorsState value)?  $default,){
final _that = this;
switch (_that) {
case _AdministratorsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrganizationAdministrators people,  String errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdministratorsState() when $default != null:
return $default(_that.people,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrganizationAdministrators people,  String errorMessage)  $default,) {final _that = this;
switch (_that) {
case _AdministratorsState():
return $default(_that.people,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrganizationAdministrators people,  String errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _AdministratorsState() when $default != null:
return $default(_that.people,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AdministratorsState implements AdministratorsState {
  const _AdministratorsState({this.people = const OrganizationAdministrators(), this.errorMessage = ''});
  

/// The administrators and the members who may be appointed.
@override@JsonKey() final  OrganizationAdministrators people;
/// Why the last load or change failed; empty when it did not.
@override@JsonKey() final  String errorMessage;

/// Create a copy of AdministratorsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdministratorsStateCopyWith<_AdministratorsState> get copyWith => __$AdministratorsStateCopyWithImpl<_AdministratorsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdministratorsState&&(identical(other.people, people) || other.people == people)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,people,errorMessage);
}

@override
String toString() {
    return 'AdministratorsState(people: $people, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AdministratorsStateCopyWith<$Res> implements $AdministratorsStateCopyWith<$Res> {
  factory _$AdministratorsStateCopyWith(_AdministratorsState value, $Res Function(_AdministratorsState) _then) = __$AdministratorsStateCopyWithImpl;
@override @useResult
$Res call({
 OrganizationAdministrators people, String errorMessage
});


@override $OrganizationAdministratorsCopyWith<$Res> get people;

}
/// @nodoc
class __$AdministratorsStateCopyWithImpl<$Res>
    implements _$AdministratorsStateCopyWith<$Res> {
  __$AdministratorsStateCopyWithImpl(this._self, this._then);

  final _AdministratorsState _self;
  final $Res Function(_AdministratorsState) _then;

/// Create a copy of AdministratorsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? people = null,Object? errorMessage = null,}) {
  return _then(_AdministratorsState(
people: null == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as OrganizationAdministrators,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AdministratorsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationAdministratorsCopyWith<$Res> get people {
  
  return $OrganizationAdministratorsCopyWith<$Res>(_self.people, (value) {
    return _then(_self.copyWith(people: value));
  });
}
}

// dart format on
