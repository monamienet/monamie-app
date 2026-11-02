// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_binding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationBinding {

 OrganizationConfig get organization; FirebaseOptions get options;
/// Create a copy of OrganizationBinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationBindingCopyWith<OrganizationBinding> get copyWith => _$OrganizationBindingCopyWithImpl<OrganizationBinding>(this as OrganizationBinding, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OrganizationBinding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationBinding&&(identical(other.organization, _this.organization) || other.organization == _this.organization)&&(identical(other.options, _this.options) || other.options == _this.options));
}


@override
int get hashCode {
  final _this = this as OrganizationBinding;
  return Object.hash(runtimeType,_this.organization,_this.options);
}

@override
String toString() {
  final _this = this as OrganizationBinding;
  return 'OrganizationBinding(organization: ${_this.organization}, options: ${_this.options})';
}


}

/// @nodoc
abstract mixin class $OrganizationBindingCopyWith<$Res>  {
  factory $OrganizationBindingCopyWith(OrganizationBinding value, $Res Function(OrganizationBinding) _then) = _$OrganizationBindingCopyWithImpl;
@useResult
$Res call({
 OrganizationConfig organization, FirebaseOptions options
});


$OrganizationConfigCopyWith<$Res> get organization;

}
/// @nodoc
class _$OrganizationBindingCopyWithImpl<$Res>
    implements $OrganizationBindingCopyWith<$Res> {
  _$OrganizationBindingCopyWithImpl(this._self, this._then);

  final OrganizationBinding _self;
  final $Res Function(OrganizationBinding) _then;

/// Create a copy of OrganizationBinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? organization = null,Object? options = null,}) {
  return _then(OrganizationBinding(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as OrganizationConfig,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as FirebaseOptions,
  ));
}
/// Create a copy of OrganizationBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationConfigCopyWith<$Res> get organization {
  
  return $OrganizationConfigCopyWith<$Res>(_self.organization, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrganizationBinding].
extension OrganizationBindingPatterns on OrganizationBinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationBinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationBinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationBinding value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationBinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationBinding value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationBinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OrganizationConfig organization,  FirebaseOptions options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationBinding() when $default != null:
return $default(_that.organization,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OrganizationConfig organization,  FirebaseOptions options)  $default,) {final _that = this;
switch (_that) {
case _OrganizationBinding():
return $default(_that.organization,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OrganizationConfig organization,  FirebaseOptions options)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationBinding() when $default != null:
return $default(_that.organization,_that.options);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationBinding extends OrganizationBinding {
  const _OrganizationBinding({required this.organization, required this.options}): super._();
  

@override final  OrganizationConfig organization;
@override final  FirebaseOptions options;

/// Create a copy of OrganizationBinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationBindingCopyWith<_OrganizationBinding> get copyWith => __$OrganizationBindingCopyWithImpl<_OrganizationBinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationBinding&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.options, options) || other.options == options));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organization,options);
}

@override
String toString() {
    return 'OrganizationBinding(organization: $organization, options: $options)';
}


}

/// @nodoc
abstract mixin class _$OrganizationBindingCopyWith<$Res> implements $OrganizationBindingCopyWith<$Res> {
  factory _$OrganizationBindingCopyWith(_OrganizationBinding value, $Res Function(_OrganizationBinding) _then) = __$OrganizationBindingCopyWithImpl;
@override @useResult
$Res call({
 OrganizationConfig organization, FirebaseOptions options
});


@override $OrganizationConfigCopyWith<$Res> get organization;

}
/// @nodoc
class __$OrganizationBindingCopyWithImpl<$Res>
    implements _$OrganizationBindingCopyWith<$Res> {
  __$OrganizationBindingCopyWithImpl(this._self, this._then);

  final _OrganizationBinding _self;
  final $Res Function(_OrganizationBinding) _then;

/// Create a copy of OrganizationBinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? organization = null,Object? options = null,}) {
  return _then(_OrganizationBinding(
organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as OrganizationConfig,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as FirebaseOptions,
  ));
}

/// Create a copy of OrganizationBinding
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationConfigCopyWith<$Res> get organization {
  
  return $OrganizationConfigCopyWith<$Res>(_self.organization, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}

// dart format on
