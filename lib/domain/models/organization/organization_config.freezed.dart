// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationConfig {

/// Permanent organization id: `<id>` in `monamienet-<id>` and in
/// `organizations/<id>`.
 String get id;/// The organization's own name. Users see it alone: the MonAmie name and
/// a organization's name are never shown side by side.
 String get name;/// `themeId`: the catalog theme the organization picked, or `null`.
 String? get themeId;/// The catalog theme [themeId] resolved to, kept with the binding so the
/// first screen is branded without network. `null` while unresolved,
/// which shows the default theme.
 OrganizationTheme? get theme;/// `logoVersion`: set when an administrator uploads a logo, so devices
/// know to fetch it again. `null` when the organization has no logo.
 int? get logoVersion;/// The logo file (a square 512 px PNG) for [logoVersion], kept with the
/// binding. `null` when there is no logo or it was not downloaded yet.
 Uint8List? get logoPng;
/// Create a copy of OrganizationConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationConfigCopyWith<OrganizationConfig> get copyWith => _$OrganizationConfigCopyWithImpl<OrganizationConfig>(this as OrganizationConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OrganizationConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationConfig&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.themeId, _this.themeId) || other.themeId == _this.themeId)&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.logoVersion, _this.logoVersion) || other.logoVersion == _this.logoVersion)&&const DeepCollectionEquality().equals(other.logoPng, _this.logoPng));
}


@override
int get hashCode {
  final _this = this as OrganizationConfig;
  return Object.hash(runtimeType,_this.id,_this.name,_this.themeId,_this.theme,_this.logoVersion,const DeepCollectionEquality().hash(_this.logoPng));
}

@override
String toString() {
  final _this = this as OrganizationConfig;
  return 'OrganizationConfig(id: ${_this.id}, name: ${_this.name}, themeId: ${_this.themeId}, theme: ${_this.theme}, logoVersion: ${_this.logoVersion}, logoPng: ${_this.logoPng})';
}


}

/// @nodoc
abstract mixin class $OrganizationConfigCopyWith<$Res>  {
  factory $OrganizationConfigCopyWith(OrganizationConfig value, $Res Function(OrganizationConfig) _then) = _$OrganizationConfigCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? themeId, OrganizationTheme? theme, int? logoVersion, Uint8List? logoPng
});


$OrganizationThemeCopyWith<$Res>? get theme;

}
/// @nodoc
class _$OrganizationConfigCopyWithImpl<$Res>
    implements $OrganizationConfigCopyWith<$Res> {
  _$OrganizationConfigCopyWithImpl(this._self, this._then);

  final OrganizationConfig _self;
  final $Res Function(OrganizationConfig) _then;

/// Create a copy of OrganizationConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? themeId = freezed,Object? theme = freezed,Object? logoVersion = freezed,Object? logoPng = freezed,}) {
  return _then(OrganizationConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,themeId: freezed == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as String?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as OrganizationTheme?,logoVersion: freezed == logoVersion ? _self.logoVersion : logoVersion // ignore: cast_nullable_to_non_nullable
as int?,logoPng: freezed == logoPng ? _self.logoPng : logoPng // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}
/// Create a copy of OrganizationConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationThemeCopyWith<$Res>? get theme {
    if (_self.theme == null) {
    return null;
  }

  return $OrganizationThemeCopyWith<$Res>(_self.theme!, (value) {
    return _then(_self.copyWith(theme: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrganizationConfig].
extension OrganizationConfigPatterns on OrganizationConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationConfig value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationConfig value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? themeId,  OrganizationTheme? theme,  int? logoVersion,  Uint8List? logoPng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationConfig() when $default != null:
return $default(_that.id,_that.name,_that.themeId,_that.theme,_that.logoVersion,_that.logoPng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? themeId,  OrganizationTheme? theme,  int? logoVersion,  Uint8List? logoPng)  $default,) {final _that = this;
switch (_that) {
case _OrganizationConfig():
return $default(_that.id,_that.name,_that.themeId,_that.theme,_that.logoVersion,_that.logoPng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? themeId,  OrganizationTheme? theme,  int? logoVersion,  Uint8List? logoPng)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationConfig() when $default != null:
return $default(_that.id,_that.name,_that.themeId,_that.theme,_that.logoVersion,_that.logoPng);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationConfig extends OrganizationConfig {
  const _OrganizationConfig({required this.id, required this.name, this.themeId, this.theme, this.logoVersion, this.logoPng}): super._();
  

/// Permanent organization id: `<id>` in `monamienet-<id>` and in
/// `organizations/<id>`.
@override final  String id;
/// The organization's own name. Users see it alone: the MonAmie name and
/// a organization's name are never shown side by side.
@override final  String name;
/// `themeId`: the catalog theme the organization picked, or `null`.
@override final  String? themeId;
/// The catalog theme [themeId] resolved to, kept with the binding so the
/// first screen is branded without network. `null` while unresolved,
/// which shows the default theme.
@override final  OrganizationTheme? theme;
/// `logoVersion`: set when an administrator uploads a logo, so devices
/// know to fetch it again. `null` when the organization has no logo.
@override final  int? logoVersion;
/// The logo file (a square 512 px PNG) for [logoVersion], kept with the
/// binding. `null` when there is no logo or it was not downloaded yet.
@override final  Uint8List? logoPng;

/// Create a copy of OrganizationConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationConfigCopyWith<_OrganizationConfig> get copyWith => __$OrganizationConfigCopyWithImpl<_OrganizationConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationConfig&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.themeId, themeId) || other.themeId == themeId)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.logoVersion, logoVersion) || other.logoVersion == logoVersion)&&const DeepCollectionEquality().equals(other.logoPng, logoPng));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,themeId,theme,logoVersion,const DeepCollectionEquality().hash(logoPng));
}

@override
String toString() {
    return 'OrganizationConfig(id: $id, name: $name, themeId: $themeId, theme: $theme, logoVersion: $logoVersion, logoPng: $logoPng)';
}


}

/// @nodoc
abstract mixin class _$OrganizationConfigCopyWith<$Res> implements $OrganizationConfigCopyWith<$Res> {
  factory _$OrganizationConfigCopyWith(_OrganizationConfig value, $Res Function(_OrganizationConfig) _then) = __$OrganizationConfigCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? themeId, OrganizationTheme? theme, int? logoVersion, Uint8List? logoPng
});


@override $OrganizationThemeCopyWith<$Res>? get theme;

}
/// @nodoc
class __$OrganizationConfigCopyWithImpl<$Res>
    implements _$OrganizationConfigCopyWith<$Res> {
  __$OrganizationConfigCopyWithImpl(this._self, this._then);

  final _OrganizationConfig _self;
  final $Res Function(_OrganizationConfig) _then;

/// Create a copy of OrganizationConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? themeId = freezed,Object? theme = freezed,Object? logoVersion = freezed,Object? logoPng = freezed,}) {
  return _then(_OrganizationConfig(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,themeId: freezed == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as String?,theme: freezed == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as OrganizationTheme?,logoVersion: freezed == logoVersion ? _self.logoVersion : logoVersion // ignore: cast_nullable_to_non_nullable
as int?,logoPng: freezed == logoPng ? _self.logoPng : logoPng // ignore: cast_nullable_to_non_nullable
as Uint8List?,
  ));
}

/// Create a copy of OrganizationConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationThemeCopyWith<$Res>? get theme {
    if (_self.theme == null) {
    return null;
  }

  return $OrganizationThemeCopyWith<$Res>(_self.theme!, (value) {
    return _then(_self.copyWith(theme: value));
  });
}
}

// dart format on
