// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_organization_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateOrganizationState {

 String get name; String get id; IdCheck get idCheck;/// Why [id] cannot be used; empty when it can or is being checked.
 String get idProblem;/// The themes that can be picked.
 List<OrganizationTheme> get themes; String get themeId; String get plan; bool get isCreating;/// Why the last creation failed; empty when it did not.
 String get errorMessage;/// The status after creating (`active`, `awaiting_billing`, `failed`).
 String? get result;
/// Create a copy of CreateOrganizationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateOrganizationStateCopyWith<CreateOrganizationState> get copyWith => _$CreateOrganizationStateCopyWithImpl<CreateOrganizationState>(this as CreateOrganizationState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CreateOrganizationState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateOrganizationState&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.idCheck, _this.idCheck) || other.idCheck == _this.idCheck)&&(identical(other.idProblem, _this.idProblem) || other.idProblem == _this.idProblem)&&const DeepCollectionEquality().equals(other.themes, _this.themes)&&(identical(other.themeId, _this.themeId) || other.themeId == _this.themeId)&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.isCreating, _this.isCreating) || other.isCreating == _this.isCreating)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.result, _this.result) || other.result == _this.result));
}


@override
int get hashCode {
  final _this = this as CreateOrganizationState;
  return Object.hash(runtimeType,_this.name,_this.id,_this.idCheck,_this.idProblem,const DeepCollectionEquality().hash(_this.themes),_this.themeId,_this.plan,_this.isCreating,_this.errorMessage,_this.result);
}

@override
String toString() {
  final _this = this as CreateOrganizationState;
  return 'CreateOrganizationState(name: ${_this.name}, id: ${_this.id}, idCheck: ${_this.idCheck}, idProblem: ${_this.idProblem}, themes: ${_this.themes}, themeId: ${_this.themeId}, plan: ${_this.plan}, isCreating: ${_this.isCreating}, errorMessage: ${_this.errorMessage}, result: ${_this.result})';
}


}

/// @nodoc
abstract mixin class $CreateOrganizationStateCopyWith<$Res>  {
  factory $CreateOrganizationStateCopyWith(CreateOrganizationState value, $Res Function(CreateOrganizationState) _then) = _$CreateOrganizationStateCopyWithImpl;
@useResult
$Res call({
 String name, String id, IdCheck idCheck, String idProblem, List<OrganizationTheme> themes, String themeId, String plan, bool isCreating, String errorMessage, String? result
});




}
/// @nodoc
class _$CreateOrganizationStateCopyWithImpl<$Res>
    implements $CreateOrganizationStateCopyWith<$Res> {
  _$CreateOrganizationStateCopyWithImpl(this._self, this._then);

  final CreateOrganizationState _self;
  final $Res Function(CreateOrganizationState) _then;

/// Create a copy of CreateOrganizationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? id = null,Object? idCheck = null,Object? idProblem = null,Object? themes = null,Object? themeId = null,Object? plan = null,Object? isCreating = null,Object? errorMessage = null,Object? result = freezed,}) {
  return _then(CreateOrganizationState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,idCheck: null == idCheck ? _self.idCheck : idCheck // ignore: cast_nullable_to_non_nullable
as IdCheck,idProblem: null == idProblem ? _self.idProblem : idProblem // ignore: cast_nullable_to_non_nullable
as String,themes: null == themes ? _self.themes : themes // ignore: cast_nullable_to_non_nullable
as List<OrganizationTheme>,themeId: null == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,isCreating: null == isCreating ? _self.isCreating : isCreating // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateOrganizationState].
extension CreateOrganizationStatePatterns on CreateOrganizationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateOrganizationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateOrganizationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateOrganizationState value)  $default,){
final _that = this;
switch (_that) {
case _CreateOrganizationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateOrganizationState value)?  $default,){
final _that = this;
switch (_that) {
case _CreateOrganizationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String id,  IdCheck idCheck,  String idProblem,  List<OrganizationTheme> themes,  String themeId,  String plan,  bool isCreating,  String errorMessage,  String? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateOrganizationState() when $default != null:
return $default(_that.name,_that.id,_that.idCheck,_that.idProblem,_that.themes,_that.themeId,_that.plan,_that.isCreating,_that.errorMessage,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String id,  IdCheck idCheck,  String idProblem,  List<OrganizationTheme> themes,  String themeId,  String plan,  bool isCreating,  String errorMessage,  String? result)  $default,) {final _that = this;
switch (_that) {
case _CreateOrganizationState():
return $default(_that.name,_that.id,_that.idCheck,_that.idProblem,_that.themes,_that.themeId,_that.plan,_that.isCreating,_that.errorMessage,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String id,  IdCheck idCheck,  String idProblem,  List<OrganizationTheme> themes,  String themeId,  String plan,  bool isCreating,  String errorMessage,  String? result)?  $default,) {final _that = this;
switch (_that) {
case _CreateOrganizationState() when $default != null:
return $default(_that.name,_that.id,_that.idCheck,_that.idProblem,_that.themes,_that.themeId,_that.plan,_that.isCreating,_that.errorMessage,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _CreateOrganizationState implements CreateOrganizationState {
  const _CreateOrganizationState({this.name = '', this.id = '', this.idCheck = IdCheck.idle, this.idProblem = '',  List<OrganizationTheme> themes = const [], required this.themeId, this.plan = 'community', this.isCreating = false, this.errorMessage = '', this.result}): _themes = themes;
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String id;
@override@JsonKey() final  IdCheck idCheck;
/// Why [id] cannot be used; empty when it can or is being checked.
@override@JsonKey() final  String idProblem;
/// The themes that can be picked.
 final  List<OrganizationTheme> _themes;
/// The themes that can be picked.
@override@JsonKey() List<OrganizationTheme> get themes {
  if (_themes is EqualUnmodifiableListView) return _themes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_themes);
}

@override final  String themeId;
@override@JsonKey() final  String plan;
@override@JsonKey() final  bool isCreating;
/// Why the last creation failed; empty when it did not.
@override@JsonKey() final  String errorMessage;
/// The status after creating (`active`, `awaiting_billing`, `failed`).
@override final  String? result;

/// Create a copy of CreateOrganizationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateOrganizationStateCopyWith<_CreateOrganizationState> get copyWith => __$CreateOrganizationStateCopyWithImpl<_CreateOrganizationState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateOrganizationState&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.idCheck, idCheck) || other.idCheck == idCheck)&&(identical(other.idProblem, idProblem) || other.idProblem == idProblem)&&const DeepCollectionEquality().equals(other.themes, _themes)&&(identical(other.themeId, themeId) || other.themeId == themeId)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.isCreating, isCreating) || other.isCreating == isCreating)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,id,idCheck,idProblem,const DeepCollectionEquality().hash(_themes),themeId,plan,isCreating,errorMessage,result);
}

@override
String toString() {
    return 'CreateOrganizationState(name: $name, id: $id, idCheck: $idCheck, idProblem: $idProblem, themes: $themes, themeId: $themeId, plan: $plan, isCreating: $isCreating, errorMessage: $errorMessage, result: $result)';
}


}

/// @nodoc
abstract mixin class _$CreateOrganizationStateCopyWith<$Res> implements $CreateOrganizationStateCopyWith<$Res> {
  factory _$CreateOrganizationStateCopyWith(_CreateOrganizationState value, $Res Function(_CreateOrganizationState) _then) = __$CreateOrganizationStateCopyWithImpl;
@override @useResult
$Res call({
 String name, String id, IdCheck idCheck, String idProblem, List<OrganizationTheme> themes, String themeId, String plan, bool isCreating, String errorMessage, String? result
});




}
/// @nodoc
class __$CreateOrganizationStateCopyWithImpl<$Res>
    implements _$CreateOrganizationStateCopyWith<$Res> {
  __$CreateOrganizationStateCopyWithImpl(this._self, this._then);

  final _CreateOrganizationState _self;
  final $Res Function(_CreateOrganizationState) _then;

/// Create a copy of CreateOrganizationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? id = null,Object? idCheck = null,Object? idProblem = null,Object? themes = null,Object? themeId = null,Object? plan = null,Object? isCreating = null,Object? errorMessage = null,Object? result = freezed,}) {
  return _then(_CreateOrganizationState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,idCheck: null == idCheck ? _self.idCheck : idCheck // ignore: cast_nullable_to_non_nullable
as IdCheck,idProblem: null == idProblem ? _self.idProblem : idProblem // ignore: cast_nullable_to_non_nullable
as String,themes: null == themes ? _self._themes : themes // ignore: cast_nullable_to_non_nullable
as List<OrganizationTheme>,themeId: null == themeId ? _self.themeId : themeId // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as String,isCreating: null == isCreating ? _self.isCreating : isCreating // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
