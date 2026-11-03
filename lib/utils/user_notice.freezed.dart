// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_notice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserNotice {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UserNotice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UserNotice()';
}


}

/// @nodoc
class $UserNoticeCopyWith<$Res>  {
$UserNoticeCopyWith(UserNotice _, $Res Function(UserNotice) __);
}


/// Adds pattern-matching-related methods to [UserNotice].
extension UserNoticePatterns on UserNotice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WaitingForGpsNotice value)?  waitingForGps,TResult Function( TrackingAtRiskNotice value)?  trackingAtRisk,TResult Function( TrackingStopUnconfirmedNotice value)?  trackingStopUnconfirmed,TResult Function( BackgroundStillRestrictedNotice value)?  backgroundStillRestricted,TResult Function( FailureNotice value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WaitingForGpsNotice() when waitingForGps != null:
return waitingForGps(_that);case TrackingAtRiskNotice() when trackingAtRisk != null:
return trackingAtRisk(_that);case TrackingStopUnconfirmedNotice() when trackingStopUnconfirmed != null:
return trackingStopUnconfirmed(_that);case BackgroundStillRestrictedNotice() when backgroundStillRestricted != null:
return backgroundStillRestricted(_that);case FailureNotice() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WaitingForGpsNotice value)  waitingForGps,required TResult Function( TrackingAtRiskNotice value)  trackingAtRisk,required TResult Function( TrackingStopUnconfirmedNotice value)  trackingStopUnconfirmed,required TResult Function( BackgroundStillRestrictedNotice value)  backgroundStillRestricted,required TResult Function( FailureNotice value)  failure,}){
final _that = this;
switch (_that) {
case WaitingForGpsNotice():
return waitingForGps(_that);case TrackingAtRiskNotice():
return trackingAtRisk(_that);case TrackingStopUnconfirmedNotice():
return trackingStopUnconfirmed(_that);case BackgroundStillRestrictedNotice():
return backgroundStillRestricted(_that);case FailureNotice():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WaitingForGpsNotice value)?  waitingForGps,TResult? Function( TrackingAtRiskNotice value)?  trackingAtRisk,TResult? Function( TrackingStopUnconfirmedNotice value)?  trackingStopUnconfirmed,TResult? Function( BackgroundStillRestrictedNotice value)?  backgroundStillRestricted,TResult? Function( FailureNotice value)?  failure,}){
final _that = this;
switch (_that) {
case WaitingForGpsNotice() when waitingForGps != null:
return waitingForGps(_that);case TrackingAtRiskNotice() when trackingAtRisk != null:
return trackingAtRisk(_that);case TrackingStopUnconfirmedNotice() when trackingStopUnconfirmed != null:
return trackingStopUnconfirmed(_that);case BackgroundStillRestrictedNotice() when backgroundStillRestricted != null:
return backgroundStillRestricted(_that);case FailureNotice() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  waitingForGps,TResult Function()?  trackingAtRisk,TResult Function()?  trackingStopUnconfirmed,TResult Function()?  backgroundStillRestricted,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WaitingForGpsNotice() when waitingForGps != null:
return waitingForGps();case TrackingAtRiskNotice() when trackingAtRisk != null:
return trackingAtRisk();case TrackingStopUnconfirmedNotice() when trackingStopUnconfirmed != null:
return trackingStopUnconfirmed();case BackgroundStillRestrictedNotice() when backgroundStillRestricted != null:
return backgroundStillRestricted();case FailureNotice() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  waitingForGps,required TResult Function()  trackingAtRisk,required TResult Function()  trackingStopUnconfirmed,required TResult Function()  backgroundStillRestricted,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case WaitingForGpsNotice():
return waitingForGps();case TrackingAtRiskNotice():
return trackingAtRisk();case TrackingStopUnconfirmedNotice():
return trackingStopUnconfirmed();case BackgroundStillRestrictedNotice():
return backgroundStillRestricted();case FailureNotice():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  waitingForGps,TResult? Function()?  trackingAtRisk,TResult? Function()?  trackingStopUnconfirmed,TResult? Function()?  backgroundStillRestricted,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case WaitingForGpsNotice() when waitingForGps != null:
return waitingForGps();case TrackingAtRiskNotice() when trackingAtRisk != null:
return trackingAtRisk();case TrackingStopUnconfirmedNotice() when trackingStopUnconfirmed != null:
return trackingStopUnconfirmed();case BackgroundStillRestrictedNotice() when backgroundStillRestricted != null:
return backgroundStillRestricted();case FailureNotice() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class WaitingForGpsNotice implements UserNotice {
  const WaitingForGpsNotice();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is WaitingForGpsNotice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UserNotice.waitingForGps()';
}


}




/// @nodoc


class TrackingAtRiskNotice implements UserNotice {
  const TrackingAtRiskNotice();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackingAtRiskNotice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UserNotice.trackingAtRisk()';
}


}




/// @nodoc


class TrackingStopUnconfirmedNotice implements UserNotice {
  const TrackingStopUnconfirmedNotice();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackingStopUnconfirmedNotice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UserNotice.trackingStopUnconfirmed()';
}


}




/// @nodoc


class BackgroundStillRestrictedNotice implements UserNotice {
  const BackgroundStillRestrictedNotice();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundStillRestrictedNotice);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'UserNotice.backgroundStillRestricted()';
}


}




/// @nodoc


class FailureNotice implements UserNotice {
  const FailureNotice(this.failure);
  

 final  Failure failure;

/// Create a copy of UserNotice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FailureNoticeCopyWith<FailureNotice> get copyWith => _$FailureNoticeCopyWithImpl<FailureNotice>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FailureNotice&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'UserNotice.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FailureNoticeCopyWith<$Res> implements $UserNoticeCopyWith<$Res> {
  factory $FailureNoticeCopyWith(FailureNotice value, $Res Function(FailureNotice) _then) = _$FailureNoticeCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FailureNoticeCopyWithImpl<$Res>
    implements $FailureNoticeCopyWith<$Res> {
  _$FailureNoticeCopyWithImpl(this._self, this._then);

  final FailureNotice _self;
  final $Res Function(FailureNotice) _then;

/// Create a copy of UserNotice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FailureNotice(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of UserNotice
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
