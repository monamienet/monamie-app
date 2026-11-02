// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deletion_pending_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeletionPendingState {

/// The signed-in account's pending deletion.
 AccountDeletion? get accountDeletion; bool get cancellingDeletion;/// The deletion was cancelled: the screen says everything is back.
 bool get deletionRestored; String get deletionError;/// Whether entering ("Entrar", after the cancel) runs.
 bool get isLoading;/// Whether a sign-out runs.
 bool get isLoggingOut;
/// Create a copy of DeletionPendingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeletionPendingStateCopyWith<DeletionPendingState> get copyWith => _$DeletionPendingStateCopyWithImpl<DeletionPendingState>(this as DeletionPendingState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeletionPendingState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeletionPendingState&&(identical(other.accountDeletion, _this.accountDeletion) || other.accountDeletion == _this.accountDeletion)&&(identical(other.cancellingDeletion, _this.cancellingDeletion) || other.cancellingDeletion == _this.cancellingDeletion)&&(identical(other.deletionRestored, _this.deletionRestored) || other.deletionRestored == _this.deletionRestored)&&(identical(other.deletionError, _this.deletionError) || other.deletionError == _this.deletionError)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.isLoggingOut, _this.isLoggingOut) || other.isLoggingOut == _this.isLoggingOut));
}


@override
int get hashCode {
  final _this = this as DeletionPendingState;
  return Object.hash(runtimeType,_this.accountDeletion,_this.cancellingDeletion,_this.deletionRestored,_this.deletionError,_this.isLoading,_this.isLoggingOut);
}

@override
String toString() {
  final _this = this as DeletionPendingState;
  return 'DeletionPendingState(accountDeletion: ${_this.accountDeletion}, cancellingDeletion: ${_this.cancellingDeletion}, deletionRestored: ${_this.deletionRestored}, deletionError: ${_this.deletionError}, isLoading: ${_this.isLoading}, isLoggingOut: ${_this.isLoggingOut})';
}


}

/// @nodoc
abstract mixin class $DeletionPendingStateCopyWith<$Res>  {
  factory $DeletionPendingStateCopyWith(DeletionPendingState value, $Res Function(DeletionPendingState) _then) = _$DeletionPendingStateCopyWithImpl;
@useResult
$Res call({
 AccountDeletion? accountDeletion, bool cancellingDeletion, bool deletionRestored, String deletionError, bool isLoading, bool isLoggingOut
});


$AccountDeletionCopyWith<$Res>? get accountDeletion;

}
/// @nodoc
class _$DeletionPendingStateCopyWithImpl<$Res>
    implements $DeletionPendingStateCopyWith<$Res> {
  _$DeletionPendingStateCopyWithImpl(this._self, this._then);

  final DeletionPendingState _self;
  final $Res Function(DeletionPendingState) _then;

/// Create a copy of DeletionPendingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountDeletion = freezed,Object? cancellingDeletion = null,Object? deletionRestored = null,Object? deletionError = null,Object? isLoading = null,Object? isLoggingOut = null,}) {
  return _then(DeletionPendingState(
accountDeletion: freezed == accountDeletion ? _self.accountDeletion : accountDeletion // ignore: cast_nullable_to_non_nullable
as AccountDeletion?,cancellingDeletion: null == cancellingDeletion ? _self.cancellingDeletion : cancellingDeletion // ignore: cast_nullable_to_non_nullable
as bool,deletionRestored: null == deletionRestored ? _self.deletionRestored : deletionRestored // ignore: cast_nullable_to_non_nullable
as bool,deletionError: null == deletionError ? _self.deletionError : deletionError // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoggingOut: null == isLoggingOut ? _self.isLoggingOut : isLoggingOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DeletionPendingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountDeletionCopyWith<$Res>? get accountDeletion {
    if (_self.accountDeletion == null) {
    return null;
  }

  return $AccountDeletionCopyWith<$Res>(_self.accountDeletion!, (value) {
    return _then(_self.copyWith(accountDeletion: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeletionPendingState].
extension DeletionPendingStatePatterns on DeletionPendingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeletionPendingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeletionPendingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeletionPendingState value)  $default,){
final _that = this;
switch (_that) {
case _DeletionPendingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeletionPendingState value)?  $default,){
final _that = this;
switch (_that) {
case _DeletionPendingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccountDeletion? accountDeletion,  bool cancellingDeletion,  bool deletionRestored,  String deletionError,  bool isLoading,  bool isLoggingOut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeletionPendingState() when $default != null:
return $default(_that.accountDeletion,_that.cancellingDeletion,_that.deletionRestored,_that.deletionError,_that.isLoading,_that.isLoggingOut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccountDeletion? accountDeletion,  bool cancellingDeletion,  bool deletionRestored,  String deletionError,  bool isLoading,  bool isLoggingOut)  $default,) {final _that = this;
switch (_that) {
case _DeletionPendingState():
return $default(_that.accountDeletion,_that.cancellingDeletion,_that.deletionRestored,_that.deletionError,_that.isLoading,_that.isLoggingOut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccountDeletion? accountDeletion,  bool cancellingDeletion,  bool deletionRestored,  String deletionError,  bool isLoading,  bool isLoggingOut)?  $default,) {final _that = this;
switch (_that) {
case _DeletionPendingState() when $default != null:
return $default(_that.accountDeletion,_that.cancellingDeletion,_that.deletionRestored,_that.deletionError,_that.isLoading,_that.isLoggingOut);case _:
  return null;

}
}

}

/// @nodoc


class _DeletionPendingState implements DeletionPendingState {
  const _DeletionPendingState({this.accountDeletion, this.cancellingDeletion = false, this.deletionRestored = false, this.deletionError = '', this.isLoading = false, this.isLoggingOut = false});
  

/// The signed-in account's pending deletion.
@override final  AccountDeletion? accountDeletion;
@override@JsonKey() final  bool cancellingDeletion;
/// The deletion was cancelled: the screen says everything is back.
@override@JsonKey() final  bool deletionRestored;
@override@JsonKey() final  String deletionError;
/// Whether entering ("Entrar", after the cancel) runs.
@override@JsonKey() final  bool isLoading;
/// Whether a sign-out runs.
@override@JsonKey() final  bool isLoggingOut;

/// Create a copy of DeletionPendingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeletionPendingStateCopyWith<_DeletionPendingState> get copyWith => __$DeletionPendingStateCopyWithImpl<_DeletionPendingState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletionPendingState&&(identical(other.accountDeletion, accountDeletion) || other.accountDeletion == accountDeletion)&&(identical(other.cancellingDeletion, cancellingDeletion) || other.cancellingDeletion == cancellingDeletion)&&(identical(other.deletionRestored, deletionRestored) || other.deletionRestored == deletionRestored)&&(identical(other.deletionError, deletionError) || other.deletionError == deletionError)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoggingOut, isLoggingOut) || other.isLoggingOut == isLoggingOut));
}


@override
int get hashCode {
    return Object.hash(runtimeType,accountDeletion,cancellingDeletion,deletionRestored,deletionError,isLoading,isLoggingOut);
}

@override
String toString() {
    return 'DeletionPendingState(accountDeletion: $accountDeletion, cancellingDeletion: $cancellingDeletion, deletionRestored: $deletionRestored, deletionError: $deletionError, isLoading: $isLoading, isLoggingOut: $isLoggingOut)';
}


}

/// @nodoc
abstract mixin class _$DeletionPendingStateCopyWith<$Res> implements $DeletionPendingStateCopyWith<$Res> {
  factory _$DeletionPendingStateCopyWith(_DeletionPendingState value, $Res Function(_DeletionPendingState) _then) = __$DeletionPendingStateCopyWithImpl;
@override @useResult
$Res call({
 AccountDeletion? accountDeletion, bool cancellingDeletion, bool deletionRestored, String deletionError, bool isLoading, bool isLoggingOut
});


@override $AccountDeletionCopyWith<$Res>? get accountDeletion;

}
/// @nodoc
class __$DeletionPendingStateCopyWithImpl<$Res>
    implements _$DeletionPendingStateCopyWith<$Res> {
  __$DeletionPendingStateCopyWithImpl(this._self, this._then);

  final _DeletionPendingState _self;
  final $Res Function(_DeletionPendingState) _then;

/// Create a copy of DeletionPendingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountDeletion = freezed,Object? cancellingDeletion = null,Object? deletionRestored = null,Object? deletionError = null,Object? isLoading = null,Object? isLoggingOut = null,}) {
  return _then(_DeletionPendingState(
accountDeletion: freezed == accountDeletion ? _self.accountDeletion : accountDeletion // ignore: cast_nullable_to_non_nullable
as AccountDeletion?,cancellingDeletion: null == cancellingDeletion ? _self.cancellingDeletion : cancellingDeletion // ignore: cast_nullable_to_non_nullable
as bool,deletionRestored: null == deletionRestored ? _self.deletionRestored : deletionRestored // ignore: cast_nullable_to_non_nullable
as bool,deletionError: null == deletionError ? _self.deletionError : deletionError // ignore: cast_nullable_to_non_nullable
as String,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoggingOut: null == isLoggingOut ? _self.isLoggingOut : isLoggingOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DeletionPendingState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountDeletionCopyWith<$Res>? get accountDeletion {
    if (_self.accountDeletion == null) {
    return null;
  }

  return $AccountDeletionCopyWith<$Res>(_self.accountDeletion!, (value) {
    return _then(_self.copyWith(accountDeletion: value));
  });
}
}

// dart format on
