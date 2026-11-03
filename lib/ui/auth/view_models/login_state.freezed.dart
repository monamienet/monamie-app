// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginState {

/// Whether a session remembered from a previous run is being checked.
 bool get isRestoringSession;/// Whether Google Sign-In finished initializing (or failed to).
 bool get googleReady;/// Whether an account was chosen and the organization is being looked
/// for or entered ("Procurando sua organização…"), after the button or
/// a web sign-in. While Google's account chooser is open only
/// `LoginViewModel.loginGoogle` runs, without this spinner.
 bool get isLoading;/// Name of the organization being entered, for "Entrando em ...".
 String? get enteringOrganizationName;
/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginStateCopyWith<LoginState> get copyWith => _$LoginStateCopyWithImpl<LoginState>(this as LoginState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoginState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginState&&(identical(other.isRestoringSession, _this.isRestoringSession) || other.isRestoringSession == _this.isRestoringSession)&&(identical(other.googleReady, _this.googleReady) || other.googleReady == _this.googleReady)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.enteringOrganizationName, _this.enteringOrganizationName) || other.enteringOrganizationName == _this.enteringOrganizationName));
}


@override
int get hashCode {
  final _this = this as LoginState;
  return Object.hash(runtimeType,_this.isRestoringSession,_this.googleReady,_this.isLoading,_this.enteringOrganizationName);
}

@override
String toString() {
  final _this = this as LoginState;
  return 'LoginState(isRestoringSession: ${_this.isRestoringSession}, googleReady: ${_this.googleReady}, isLoading: ${_this.isLoading}, enteringOrganizationName: ${_this.enteringOrganizationName})';
}


}

/// @nodoc
abstract mixin class $LoginStateCopyWith<$Res>  {
  factory $LoginStateCopyWith(LoginState value, $Res Function(LoginState) _then) = _$LoginStateCopyWithImpl;
@useResult
$Res call({
 bool isRestoringSession, bool googleReady, bool isLoading, String? enteringOrganizationName
});




}
/// @nodoc
class _$LoginStateCopyWithImpl<$Res>
    implements $LoginStateCopyWith<$Res> {
  _$LoginStateCopyWithImpl(this._self, this._then);

  final LoginState _self;
  final $Res Function(LoginState) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isRestoringSession = null,Object? googleReady = null,Object? isLoading = null,Object? enteringOrganizationName = freezed,}) {
  return _then(LoginState(
isRestoringSession: null == isRestoringSession ? _self.isRestoringSession : isRestoringSession // ignore: cast_nullable_to_non_nullable
as bool,googleReady: null == googleReady ? _self.googleReady : googleReady // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,enteringOrganizationName: freezed == enteringOrganizationName ? _self.enteringOrganizationName : enteringOrganizationName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginState].
extension LoginStatePatterns on LoginState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoginState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoginState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoginState value)  $default,){
final _that = this;
switch (_that) {
case _LoginState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoginState value)?  $default,){
final _that = this;
switch (_that) {
case _LoginState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isRestoringSession,  bool googleReady,  bool isLoading,  String? enteringOrganizationName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoginState() when $default != null:
return $default(_that.isRestoringSession,_that.googleReady,_that.isLoading,_that.enteringOrganizationName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isRestoringSession,  bool googleReady,  bool isLoading,  String? enteringOrganizationName)  $default,) {final _that = this;
switch (_that) {
case _LoginState():
return $default(_that.isRestoringSession,_that.googleReady,_that.isLoading,_that.enteringOrganizationName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isRestoringSession,  bool googleReady,  bool isLoading,  String? enteringOrganizationName)?  $default,) {final _that = this;
switch (_that) {
case _LoginState() when $default != null:
return $default(_that.isRestoringSession,_that.googleReady,_that.isLoading,_that.enteringOrganizationName);case _:
  return null;

}
}

}

/// @nodoc


class _LoginState implements LoginState {
  const _LoginState({this.isRestoringSession = true, this.googleReady = false, this.isLoading = false, this.enteringOrganizationName});
  

/// Whether a session remembered from a previous run is being checked.
@override@JsonKey() final  bool isRestoringSession;
/// Whether Google Sign-In finished initializing (or failed to).
@override@JsonKey() final  bool googleReady;
/// Whether an account was chosen and the organization is being looked
/// for or entered ("Procurando sua organização…"), after the button or
/// a web sign-in. While Google's account chooser is open only
/// `LoginViewModel.loginGoogle` runs, without this spinner.
@override@JsonKey() final  bool isLoading;
/// Name of the organization being entered, for "Entrando em ...".
@override final  String? enteringOrganizationName;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoginStateCopyWith<_LoginState> get copyWith => __$LoginStateCopyWithImpl<_LoginState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoginState&&(identical(other.isRestoringSession, isRestoringSession) || other.isRestoringSession == isRestoringSession)&&(identical(other.googleReady, googleReady) || other.googleReady == googleReady)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.enteringOrganizationName, enteringOrganizationName) || other.enteringOrganizationName == enteringOrganizationName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isRestoringSession,googleReady,isLoading,enteringOrganizationName);
}

@override
String toString() {
    return 'LoginState(isRestoringSession: $isRestoringSession, googleReady: $googleReady, isLoading: $isLoading, enteringOrganizationName: $enteringOrganizationName)';
}


}

/// @nodoc
abstract mixin class _$LoginStateCopyWith<$Res> implements $LoginStateCopyWith<$Res> {
  factory _$LoginStateCopyWith(_LoginState value, $Res Function(_LoginState) _then) = __$LoginStateCopyWithImpl;
@override @useResult
$Res call({
 bool isRestoringSession, bool googleReady, bool isLoading, String? enteringOrganizationName
});




}
/// @nodoc
class __$LoginStateCopyWithImpl<$Res>
    implements _$LoginStateCopyWith<$Res> {
  __$LoginStateCopyWithImpl(this._self, this._then);

  final _LoginState _self;
  final $Res Function(_LoginState) _then;

/// Create a copy of LoginState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isRestoringSession = null,Object? googleReady = null,Object? isLoading = null,Object? enteringOrganizationName = freezed,}) {
  return _then(_LoginState(
isRestoringSession: null == isRestoringSession ? _self.isRestoringSession : isRestoringSession // ignore: cast_nullable_to_non_nullable
as bool,googleReady: null == googleReady ? _self.googleReady : googleReady // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,enteringOrganizationName: freezed == enteringOrganizationName ? _self.enteringOrganizationName : enteringOrganizationName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
