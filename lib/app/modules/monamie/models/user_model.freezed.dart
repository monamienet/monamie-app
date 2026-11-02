// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserModel {

 String get email; String? get name; double? get lat; double? get lng;/// When the device captured the position (device clock).
 DateTime? get capturedAt; bool? get isPublishing;
/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserModelCopyWith<UserModel> get copyWith => _$UserModelCopyWithImpl<UserModel>(this as UserModel, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserModel&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.lat, _this.lat) || other.lat == _this.lat)&&(identical(other.lng, _this.lng) || other.lng == _this.lng)&&(identical(other.capturedAt, _this.capturedAt) || other.capturedAt == _this.capturedAt)&&(identical(other.isPublishing, _this.isPublishing) || other.isPublishing == _this.isPublishing));
}


@override
int get hashCode {
  final _this = this as UserModel;
  return Object.hash(runtimeType,_this.email,_this.name,_this.lat,_this.lng,_this.capturedAt,_this.isPublishing);
}

@override
String toString() {
  final _this = this as UserModel;
  return 'UserModel(email: ${_this.email}, name: ${_this.name}, lat: ${_this.lat}, lng: ${_this.lng}, capturedAt: ${_this.capturedAt}, isPublishing: ${_this.isPublishing})';
}


}

/// @nodoc
abstract mixin class $UserModelCopyWith<$Res>  {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) _then) = _$UserModelCopyWithImpl;
@useResult
$Res call({
 String email, String? name, double? lat, double? lng, DateTime? capturedAt, bool? isPublishing
});




}
/// @nodoc
class _$UserModelCopyWithImpl<$Res>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._self, this._then);

  final UserModel _self;
  final $Res Function(UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? name = freezed,Object? lat = freezed,Object? lng = freezed,Object? capturedAt = freezed,Object? isPublishing = freezed,}) {
  return _then(UserModel(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isPublishing: freezed == isPublishing ? _self.isPublishing : isPublishing // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserModel].
extension UserModelPatterns on UserModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserModel value)  $default,){
final _that = this;
switch (_that) {
case _UserModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  String? name,  double? lat,  double? lng,  DateTime? capturedAt,  bool? isPublishing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.email,_that.name,_that.lat,_that.lng,_that.capturedAt,_that.isPublishing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  String? name,  double? lat,  double? lng,  DateTime? capturedAt,  bool? isPublishing)  $default,) {final _that = this;
switch (_that) {
case _UserModel():
return $default(_that.email,_that.name,_that.lat,_that.lng,_that.capturedAt,_that.isPublishing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  String? name,  double? lat,  double? lng,  DateTime? capturedAt,  bool? isPublishing)?  $default,) {final _that = this;
switch (_that) {
case _UserModel() when $default != null:
return $default(_that.email,_that.name,_that.lat,_that.lng,_that.capturedAt,_that.isPublishing);case _:
  return null;

}
}

}

/// @nodoc


class _UserModel extends UserModel {
  const _UserModel({required this.email, this.name, this.lat, this.lng, this.capturedAt, this.isPublishing}): super._();
  

@override final  String email;
@override final  String? name;
@override final  double? lat;
@override final  double? lng;
/// When the device captured the position (device clock).
@override final  DateTime? capturedAt;
@override final  bool? isPublishing;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserModelCopyWith<_UserModel> get copyWith => __$UserModelCopyWithImpl<_UserModel>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserModel&&(identical(other.email, email) || other.email == email)&&(identical(other.name, name) || other.name == name)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.capturedAt, capturedAt) || other.capturedAt == capturedAt)&&(identical(other.isPublishing, isPublishing) || other.isPublishing == isPublishing));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,name,lat,lng,capturedAt,isPublishing);
}

@override
String toString() {
    return 'UserModel(email: $email, name: $name, lat: $lat, lng: $lng, capturedAt: $capturedAt, isPublishing: $isPublishing)';
}


}

/// @nodoc
abstract mixin class _$UserModelCopyWith<$Res> implements $UserModelCopyWith<$Res> {
  factory _$UserModelCopyWith(_UserModel value, $Res Function(_UserModel) _then) = __$UserModelCopyWithImpl;
@override @useResult
$Res call({
 String email, String? name, double? lat, double? lng, DateTime? capturedAt, bool? isPublishing
});




}
/// @nodoc
class __$UserModelCopyWithImpl<$Res>
    implements _$UserModelCopyWith<$Res> {
  __$UserModelCopyWithImpl(this._self, this._then);

  final _UserModel _self;
  final $Res Function(_UserModel) _then;

/// Create a copy of UserModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? name = freezed,Object? lat = freezed,Object? lng = freezed,Object? capturedAt = freezed,Object? isPublishing = freezed,}) {
  return _then(_UserModel(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,capturedAt: freezed == capturedAt ? _self.capturedAt : capturedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isPublishing: freezed == isPublishing ? _self.isPublishing : isPublishing // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
