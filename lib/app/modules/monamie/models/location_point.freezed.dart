// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocationPoint {

 double get lat; double get lng; DateTime get receivedAt;
/// Create a copy of LocationPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationPointCopyWith<LocationPoint> get copyWith => _$LocationPointCopyWithImpl<LocationPoint>(this as LocationPoint, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LocationPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationPoint&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng)&&(identical(other.receivedAt, _this.receivedAt) || other.receivedAt == _this.receivedAt));
}


@override
int get hashCode {
  final _this = this as LocationPoint;
  return Object.hash(runtimeType,_this.lat,_this.lng,_this.receivedAt);
}

@override
String toString() {
  final _this = this as LocationPoint;
  return 'LocationPoint(lat: ${_this.lat}, lng: ${_this.lng}, receivedAt: ${_this.receivedAt})';
}


}

/// @nodoc
abstract mixin class $LocationPointCopyWith<$Res>  {
  factory $LocationPointCopyWith(LocationPoint value, $Res Function(LocationPoint) _then) = _$LocationPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, DateTime receivedAt
});




}
/// @nodoc
class _$LocationPointCopyWithImpl<$Res>
    implements $LocationPointCopyWith<$Res> {
  _$LocationPointCopyWithImpl(this._self, this._then);

  final LocationPoint _self;
  final $Res Function(LocationPoint) _then;

/// Create a copy of LocationPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? receivedAt = null,}) {
  return _then(LocationPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationPoint].
extension LocationPointPatterns on LocationPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocationPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocationPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocationPoint value)  $default,){
final _that = this;
switch (_that) {
case _LocationPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocationPoint value)?  $default,){
final _that = this;
switch (_that) {
case _LocationPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  DateTime receivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocationPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.receivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  DateTime receivedAt)  $default,) {final _that = this;
switch (_that) {
case _LocationPoint():
return $default(_that.lat,_that.lng,_that.receivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  DateTime receivedAt)?  $default,) {final _that = this;
switch (_that) {
case _LocationPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.receivedAt);case _:
  return null;

}
}

}

/// @nodoc


class _LocationPoint extends LocationPoint {
  const _LocationPoint({required this.lat, required this.lng, required this.receivedAt}): super._();
  

@override final  double lat;
@override final  double lng;
@override final  DateTime receivedAt;

/// Create a copy of LocationPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationPointCopyWith<_LocationPoint> get copyWith => __$LocationPointCopyWithImpl<_LocationPoint>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,lat,lng,receivedAt);
}

@override
String toString() {
    return 'LocationPoint(lat: $lat, lng: $lng, receivedAt: $receivedAt)';
}


}

/// @nodoc
abstract mixin class _$LocationPointCopyWith<$Res> implements $LocationPointCopyWith<$Res> {
  factory _$LocationPointCopyWith(_LocationPoint value, $Res Function(_LocationPoint) _then) = __$LocationPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, DateTime receivedAt
});




}
/// @nodoc
class __$LocationPointCopyWithImpl<$Res>
    implements _$LocationPointCopyWith<$Res> {
  __$LocationPointCopyWithImpl(this._self, this._then);

  final _LocationPoint _self;
  final $Res Function(_LocationPoint) _then;

/// Create a copy of LocationPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? receivedAt = null,}) {
  return _then(_LocationPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,receivedAt: null == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
