// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appearance_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppearanceState {

/// The name being edited.
 String get name;/// The id of the theme picked.
 String get themeId;/// The logo to save; `null` shows the name's initial. Compared by
/// identity with the saved one to know whether it changed.
 Uint8List? get logoPng;/// The themes that can be picked.
 List<OrganizationTheme> get themes; bool get isLoadingThemes; bool get isSaving; LogoSheet get sheet;/// Why the picked file cannot be used (with [LogoSheet.error]).
 String get sheetError;/// The converted logo waiting for "Usar este logo".
 Uint8List? get candidate;/// Why the last save failed; empty when it did not.
 String get errorMessage;
/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppearanceStateCopyWith<AppearanceState> get copyWith => _$AppearanceStateCopyWithImpl<AppearanceState>(this as AppearanceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppearanceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppearanceState&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.themeId, _this.themeId) || other.themeId == _this.themeId)&&const DeepCollectionEquality().equals(other.logoPng, _this.logoPng)&&const DeepCollectionEquality().equals(other.themes, _this.themes)&&(identical(other.isLoadingThemes, _this.isLoadingThemes) || other.isLoadingThemes == _this.isLoadingThemes)&&(identical(other.isSaving, _this.isSaving) || other.isSaving == _this.isSaving)&&(identical(other.sheet, _this.sheet) || other.sheet == _this.sheet)&&(identical(other.sheetError, _this.sheetError) || other.sheetError == _this.sheetError)&&const DeepCollectionEquality().equals(other.candidate, _this.candidate)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as AppearanceState;
  return Object.hash(runtimeType,_this.name,_this.themeId,const DeepCollectionEquality().hash(_this.logoPng),const DeepCollectionEquality().hash(_this.themes),_this.isLoadingThemes,_this.isSaving,_this.sheet,_this.sheetError,const DeepCollectionEquality().hash(_this.candidate),_this.errorMessage);
}

@override
String toString() {
  final _this = this as AppearanceState;
  return 'AppearanceState(name: ${_this.name}, themeId: ${_this.themeId}, logoPng: ${_this.logoPng}, themes: ${_this.themes}, isLoadingThemes: ${_this.isLoadingThemes}, isSaving: ${_this.isSaving}, sheet: ${_this.sheet}, sheetError: ${_this.sheetError}, candidate: ${_this.candidate}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $AppearanceStateCopyWith<$Res>  {
  factory $AppearanceStateCopyWith(AppearanceState value, $Res Function(AppearanceState) _then) = _$AppearanceStateCopyWithImpl;
@useResult
$Res call({
 String name, String themeId, Uint8List? logoPng, List<OrganizationTheme> themes, bool isLoadingThemes, bool isSaving, LogoSheet sheet, String sheetError, Uint8List? candidate, String errorMessage
});




}
/// @nodoc
class _$AppearanceStateCopyWithImpl<$Res>
    implements $AppearanceStateCopyWith<$Res> {
  _$AppearanceStateCopyWithImpl(this._self, this._then);

  final AppearanceState _self;
  final $Res Function(AppearanceState) _then;

/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? themeId = null,Object? logoPng = freezed,Object? themes = null,Object? isLoadingThemes = null,Object? isSaving = null,Object? sheet = null,Object? sheetError = null,Object? candidate = freezed,Object? errorMessage = null,}) {
  return _then(AppearanceState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,themeId: null == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as String,logoPng: freezed == logoPng ? _self.logoPng : logoPng // ignore: cast_nullable_to_non_nullable
as Uint8List?,themes: null == themes ? _self.themes : themes // ignore: cast_nullable_to_non_nullable
as List<OrganizationTheme>,isLoadingThemes: null == isLoadingThemes ? _self.isLoadingThemes : isLoadingThemes // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,sheet: null == sheet ? _self.sheet : sheet // ignore: cast_nullable_to_non_nullable
as LogoSheet,sheetError: null == sheetError ? _self.sheetError : sheetError // ignore: cast_nullable_to_non_nullable
as String,candidate: freezed == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as Uint8List?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppearanceState].
extension AppearanceStatePatterns on AppearanceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppearanceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppearanceState value)  $default,){
final _that = this;
switch (_that) {
case _AppearanceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppearanceState value)?  $default,){
final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String themeId,  Uint8List? logoPng,  List<OrganizationTheme> themes,  bool isLoadingThemes,  bool isSaving,  LogoSheet sheet,  String sheetError,  Uint8List? candidate,  String errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
return $default(_that.name,_that.themeId,_that.logoPng,_that.themes,_that.isLoadingThemes,_that.isSaving,_that.sheet,_that.sheetError,_that.candidate,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String themeId,  Uint8List? logoPng,  List<OrganizationTheme> themes,  bool isLoadingThemes,  bool isSaving,  LogoSheet sheet,  String sheetError,  Uint8List? candidate,  String errorMessage)  $default,) {final _that = this;
switch (_that) {
case _AppearanceState():
return $default(_that.name,_that.themeId,_that.logoPng,_that.themes,_that.isLoadingThemes,_that.isSaving,_that.sheet,_that.sheetError,_that.candidate,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String themeId,  Uint8List? logoPng,  List<OrganizationTheme> themes,  bool isLoadingThemes,  bool isSaving,  LogoSheet sheet,  String sheetError,  Uint8List? candidate,  String errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _AppearanceState() when $default != null:
return $default(_that.name,_that.themeId,_that.logoPng,_that.themes,_that.isLoadingThemes,_that.isSaving,_that.sheet,_that.sheetError,_that.candidate,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AppearanceState implements AppearanceState {
  const _AppearanceState({required this.name, required this.themeId, this.logoPng,  List<OrganizationTheme> themes = const [], this.isLoadingThemes = true, this.isSaving = false, this.sheet = LogoSheet.closed, this.sheetError = '', this.candidate, this.errorMessage = ''}): _themes = themes;
  

/// The name being edited.
@override final  String name;
/// The id of the theme picked.
@override final  String themeId;
/// The logo to save; `null` shows the name's initial. Compared by
/// identity with the saved one to know whether it changed.
@override final  Uint8List? logoPng;
/// The themes that can be picked.
 final  List<OrganizationTheme> _themes;
/// The themes that can be picked.
@override@JsonKey() List<OrganizationTheme> get themes {
  if (_themes is EqualUnmodifiableListView) return _themes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_themes);
}

@override@JsonKey() final  bool isLoadingThemes;
@override@JsonKey() final  bool isSaving;
@override@JsonKey() final  LogoSheet sheet;
/// Why the picked file cannot be used (with [LogoSheet.error]).
@override@JsonKey() final  String sheetError;
/// The converted logo waiting for "Usar este logo".
@override final  Uint8List? candidate;
/// Why the last save failed; empty when it did not.
@override@JsonKey() final  String errorMessage;

/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppearanceStateCopyWith<_AppearanceState> get copyWith => __$AppearanceStateCopyWithImpl<_AppearanceState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppearanceState&&(identical(other.name, name) || other.name == name)&&(identical(other.themeId, themeId) || other.themeId == themeId)&&const DeepCollectionEquality().equals(other.logoPng, logoPng)&&const DeepCollectionEquality().equals(other.themes, _themes)&&(identical(other.isLoadingThemes, isLoadingThemes) || other.isLoadingThemes == isLoadingThemes)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.sheet, sheet) || other.sheet == sheet)&&(identical(other.sheetError, sheetError) || other.sheetError == sheetError)&&const DeepCollectionEquality().equals(other.candidate, candidate)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,themeId,const DeepCollectionEquality().hash(logoPng),const DeepCollectionEquality().hash(_themes),isLoadingThemes,isSaving,sheet,sheetError,const DeepCollectionEquality().hash(candidate),errorMessage);
}

@override
String toString() {
    return 'AppearanceState(name: $name, themeId: $themeId, logoPng: $logoPng, themes: $themes, isLoadingThemes: $isLoadingThemes, isSaving: $isSaving, sheet: $sheet, sheetError: $sheetError, candidate: $candidate, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AppearanceStateCopyWith<$Res> implements $AppearanceStateCopyWith<$Res> {
  factory _$AppearanceStateCopyWith(_AppearanceState value, $Res Function(_AppearanceState) _then) = __$AppearanceStateCopyWithImpl;
@override @useResult
$Res call({
 String name, String themeId, Uint8List? logoPng, List<OrganizationTheme> themes, bool isLoadingThemes, bool isSaving, LogoSheet sheet, String sheetError, Uint8List? candidate, String errorMessage
});




}
/// @nodoc
class __$AppearanceStateCopyWithImpl<$Res>
    implements _$AppearanceStateCopyWith<$Res> {
  __$AppearanceStateCopyWithImpl(this._self, this._then);

  final _AppearanceState _self;
  final $Res Function(_AppearanceState) _then;

/// Create a copy of AppearanceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? themeId = null,Object? logoPng = freezed,Object? themes = null,Object? isLoadingThemes = null,Object? isSaving = null,Object? sheet = null,Object? sheetError = null,Object? candidate = freezed,Object? errorMessage = null,}) {
  return _then(_AppearanceState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,themeId: null == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as String,logoPng: freezed == logoPng ? _self.logoPng : logoPng // ignore: cast_nullable_to_non_nullable
as Uint8List?,themes: null == themes ? _self._themes : themes // ignore: cast_nullable_to_non_nullable
as List<OrganizationTheme>,isLoadingThemes: null == isLoadingThemes ? _self.isLoadingThemes : isLoadingThemes // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,sheet: null == sheet ? _self.sheet : sheet // ignore: cast_nullable_to_non_nullable
as LogoSheet,sheetError: null == sheetError ? _self.sheetError : sheetError // ignore: cast_nullable_to_non_nullable
as String,candidate: freezed == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as Uint8List?,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
