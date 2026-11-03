// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_account_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MyAccountState {

/// Whether the person owns the bound organization; `null` while it is
/// being read or when it could not be read, and then nothing can be
/// deleted.
 bool? get isOwner;/// What the owner typed to confirm (the organization's id).
 String get confirmation;/// Why the last load or deletion failed; `null` when it did not.
 Failure? get failure;
/// Create a copy of MyAccountState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyAccountStateCopyWith<MyAccountState> get copyWith => _$MyAccountStateCopyWithImpl<MyAccountState>(this as MyAccountState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MyAccountState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyAccountState&&(identical(other.isOwner, _this.isOwner) || other.isOwner == _this.isOwner)&&(identical(other.confirmation, _this.confirmation) || other.confirmation == _this.confirmation)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as MyAccountState;
  return Object.hash(runtimeType,_this.isOwner,_this.confirmation,_this.failure);
}

@override
String toString() {
  final _this = this as MyAccountState;
  return 'MyAccountState(isOwner: ${_this.isOwner}, confirmation: ${_this.confirmation}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $MyAccountStateCopyWith<$Res>  {
  factory $MyAccountStateCopyWith(MyAccountState value, $Res Function(MyAccountState) _then) = _$MyAccountStateCopyWithImpl;
@useResult
$Res call({
 bool? isOwner, String confirmation, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$MyAccountStateCopyWithImpl<$Res>
    implements $MyAccountStateCopyWith<$Res> {
  _$MyAccountStateCopyWithImpl(this._self, this._then);

  final MyAccountState _self;
  final $Res Function(MyAccountState) _then;

/// Create a copy of MyAccountState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOwner = freezed,Object? confirmation = null,Object? failure = freezed,}) {
  return _then(MyAccountState(
isOwner: freezed == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool?,confirmation: null == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as String,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of MyAccountState
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


/// Adds pattern-matching-related methods to [MyAccountState].
extension MyAccountStatePatterns on MyAccountState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyAccountState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyAccountState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyAccountState value)  $default,){
final _that = this;
switch (_that) {
case _MyAccountState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyAccountState value)?  $default,){
final _that = this;
switch (_that) {
case _MyAccountState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? isOwner,  String confirmation,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyAccountState() when $default != null:
return $default(_that.isOwner,_that.confirmation,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? isOwner,  String confirmation,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _MyAccountState():
return $default(_that.isOwner,_that.confirmation,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? isOwner,  String confirmation,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _MyAccountState() when $default != null:
return $default(_that.isOwner,_that.confirmation,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _MyAccountState implements MyAccountState {
  const _MyAccountState({this.isOwner, this.confirmation = '', this.failure});
  

/// Whether the person owns the bound organization; `null` while it is
/// being read or when it could not be read, and then nothing can be
/// deleted.
@override final  bool? isOwner;
/// What the owner typed to confirm (the organization's id).
@override@JsonKey() final  String confirmation;
/// Why the last load or deletion failed; `null` when it did not.
@override final  Failure? failure;

/// Create a copy of MyAccountState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyAccountStateCopyWith<_MyAccountState> get copyWith => __$MyAccountStateCopyWithImpl<_MyAccountState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyAccountState&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&(identical(other.confirmation, confirmation) || other.confirmation == confirmation)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isOwner,confirmation,failure);
}

@override
String toString() {
    return 'MyAccountState(isOwner: $isOwner, confirmation: $confirmation, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$MyAccountStateCopyWith<$Res> implements $MyAccountStateCopyWith<$Res> {
  factory _$MyAccountStateCopyWith(_MyAccountState value, $Res Function(_MyAccountState) _then) = __$MyAccountStateCopyWithImpl;
@override @useResult
$Res call({
 bool? isOwner, String confirmation, Failure? failure
});


@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$MyAccountStateCopyWithImpl<$Res>
    implements _$MyAccountStateCopyWith<$Res> {
  __$MyAccountStateCopyWithImpl(this._self, this._then);

  final _MyAccountState _self;
  final $Res Function(_MyAccountState) _then;

/// Create a copy of MyAccountState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOwner = freezed,Object? confirmation = null,Object? failure = freezed,}) {
  return _then(_MyAccountState(
isOwner: freezed == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool?,confirmation: null == confirmation ? _self.confirmation : confirmation // ignore: cast_nullable_to_non_nullable
as String,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of MyAccountState
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
