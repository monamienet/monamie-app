// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_theme.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationTheme {

 String get id; String get name;/// Buttons, selected states, the logo tile.
 Color get primary;/// App bars and headers.
 Color get dark;/// Pale containers, with [dark] text on them.
 Color get light;/// Text and icons on [primary].
 Color get onPrimary;/// Text and icons on [dark].
 Color get onDark;/// Position in the picker.
 int get order;/// Inactive themes are hidden from the picker but still resolve, so a
/// organization that uses one keeps it.
 bool get active;
/// Create a copy of OrganizationTheme
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationThemeCopyWith<OrganizationTheme> get copyWith => _$OrganizationThemeCopyWithImpl<OrganizationTheme>(this as OrganizationTheme, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OrganizationTheme;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationTheme&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.primary, _this.primary) || other.primary == _this.primary)&&(identical(other.dark, _this.dark) || other.dark == _this.dark)&&(identical(other.light, _this.light) || other.light == _this.light)&&(identical(other.onPrimary, _this.onPrimary) || other.onPrimary == _this.onPrimary)&&(identical(other.onDark, _this.onDark) || other.onDark == _this.onDark)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.active, _this.active) || other.active == _this.active));
}


@override
int get hashCode {
  final _this = this as OrganizationTheme;
  return Object.hash(runtimeType,_this.id,_this.name,_this.primary,_this.dark,_this.light,_this.onPrimary,_this.onDark,_this.order,_this.active);
}

@override
String toString() {
  final _this = this as OrganizationTheme;
  return 'OrganizationTheme(id: ${_this.id}, name: ${_this.name}, primary: ${_this.primary}, dark: ${_this.dark}, light: ${_this.light}, onPrimary: ${_this.onPrimary}, onDark: ${_this.onDark}, order: ${_this.order}, active: ${_this.active})';
}


}

/// @nodoc
abstract mixin class $OrganizationThemeCopyWith<$Res>  {
  factory $OrganizationThemeCopyWith(OrganizationTheme value, $Res Function(OrganizationTheme) _then) = _$OrganizationThemeCopyWithImpl;
@useResult
$Res call({
 String id, String name, Color primary, Color dark, Color light, Color onPrimary, Color onDark, int order, bool active
});




}
/// @nodoc
class _$OrganizationThemeCopyWithImpl<$Res>
    implements $OrganizationThemeCopyWith<$Res> {
  _$OrganizationThemeCopyWithImpl(this._self, this._then);

  final OrganizationTheme _self;
  final $Res Function(OrganizationTheme) _then;

/// Create a copy of OrganizationTheme
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? primary = null,Object? dark = null,Object? light = null,Object? onPrimary = null,Object? onDark = null,Object? order = null,Object? active = null,}) {
  return _then(OrganizationTheme(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as Color,dark: null == dark ? _self.dark : dark // ignore: cast_nullable_to_non_nullable
as Color,light: null == light ? _self.light : light // ignore: cast_nullable_to_non_nullable
as Color,onPrimary: null == onPrimary ? _self.onPrimary : onPrimary // ignore: cast_nullable_to_non_nullable
as Color,onDark: null == onDark ? _self.onDark : onDark // ignore: cast_nullable_to_non_nullable
as Color,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationTheme].
extension OrganizationThemePatterns on OrganizationTheme {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationTheme value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationTheme() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationTheme value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationTheme():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationTheme value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationTheme() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Color primary,  Color dark,  Color light,  Color onPrimary,  Color onDark,  int order,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationTheme() when $default != null:
return $default(_that.id,_that.name,_that.primary,_that.dark,_that.light,_that.onPrimary,_that.onDark,_that.order,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Color primary,  Color dark,  Color light,  Color onPrimary,  Color onDark,  int order,  bool active)  $default,) {final _that = this;
switch (_that) {
case _OrganizationTheme():
return $default(_that.id,_that.name,_that.primary,_that.dark,_that.light,_that.onPrimary,_that.onDark,_that.order,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Color primary,  Color dark,  Color light,  Color onPrimary,  Color onDark,  int order,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationTheme() when $default != null:
return $default(_that.id,_that.name,_that.primary,_that.dark,_that.light,_that.onPrimary,_that.onDark,_that.order,_that.active);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationTheme extends OrganizationTheme {
  const _OrganizationTheme({required this.id, required this.name, required this.primary, required this.dark, required this.light, required this.onPrimary, required this.onDark, this.order = 0, this.active = true}): super._();
  

@override final  String id;
@override final  String name;
/// Buttons, selected states, the logo tile.
@override final  Color primary;
/// App bars and headers.
@override final  Color dark;
/// Pale containers, with [dark] text on them.
@override final  Color light;
/// Text and icons on [primary].
@override final  Color onPrimary;
/// Text and icons on [dark].
@override final  Color onDark;
/// Position in the picker.
@override@JsonKey() final  int order;
/// Inactive themes are hidden from the picker but still resolve, so a
/// organization that uses one keeps it.
@override@JsonKey() final  bool active;

/// Create a copy of OrganizationTheme
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationThemeCopyWith<_OrganizationTheme> get copyWith => __$OrganizationThemeCopyWithImpl<_OrganizationTheme>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationTheme&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.dark, dark) || other.dark == dark)&&(identical(other.light, light) || other.light == light)&&(identical(other.onPrimary, onPrimary) || other.onPrimary == onPrimary)&&(identical(other.onDark, onDark) || other.onDark == onDark)&&(identical(other.order, order) || other.order == order)&&(identical(other.active, active) || other.active == active));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,primary,dark,light,onPrimary,onDark,order,active);
}

@override
String toString() {
    return 'OrganizationTheme(id: $id, name: $name, primary: $primary, dark: $dark, light: $light, onPrimary: $onPrimary, onDark: $onDark, order: $order, active: $active)';
}


}

/// @nodoc
abstract mixin class _$OrganizationThemeCopyWith<$Res> implements $OrganizationThemeCopyWith<$Res> {
  factory _$OrganizationThemeCopyWith(_OrganizationTheme value, $Res Function(_OrganizationTheme) _then) = __$OrganizationThemeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Color primary, Color dark, Color light, Color onPrimary, Color onDark, int order, bool active
});




}
/// @nodoc
class __$OrganizationThemeCopyWithImpl<$Res>
    implements _$OrganizationThemeCopyWith<$Res> {
  __$OrganizationThemeCopyWithImpl(this._self, this._then);

  final _OrganizationTheme _self;
  final $Res Function(_OrganizationTheme) _then;

/// Create a copy of OrganizationTheme
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? primary = null,Object? dark = null,Object? light = null,Object? onPrimary = null,Object? onDark = null,Object? order = null,Object? active = null,}) {
  return _then(_OrganizationTheme(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as Color,dark: null == dark ? _self.dark : dark // ignore: cast_nullable_to_non_nullable
as Color,light: null == light ? _self.light : light // ignore: cast_nullable_to_non_nullable
as Color,onPrimary: null == onPrimary ? _self.onPrimary : onPrimary // ignore: cast_nullable_to_non_nullable
as Color,onDark: null == onDark ? _self.onDark : onDark // ignore: cast_nullable_to_non_nullable
as Color,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
