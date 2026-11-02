// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'administrators.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Administrator {

 String get email;/// Whether they are the owner (*Titular*): always an administrator,
/// never demoted.
 bool get owner;
/// Create a copy of Administrator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdministratorCopyWith<Administrator> get copyWith => _$AdministratorCopyWithImpl<Administrator>(this as Administrator, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Administrator;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Administrator&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.owner, _this.owner) || other.owner == _this.owner));
}


@override
int get hashCode {
  final _this = this as Administrator;
  return Object.hash(runtimeType,_this.email,_this.owner);
}

@override
String toString() {
  final _this = this as Administrator;
  return 'Administrator(email: ${_this.email}, owner: ${_this.owner})';
}


}

/// @nodoc
abstract mixin class $AdministratorCopyWith<$Res>  {
  factory $AdministratorCopyWith(Administrator value, $Res Function(Administrator) _then) = _$AdministratorCopyWithImpl;
@useResult
$Res call({
 String email, bool owner
});




}
/// @nodoc
class _$AdministratorCopyWithImpl<$Res>
    implements $AdministratorCopyWith<$Res> {
  _$AdministratorCopyWithImpl(this._self, this._then);

  final Administrator _self;
  final $Res Function(Administrator) _then;

/// Create a copy of Administrator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? owner = null,}) {
  return _then(Administrator(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Administrator].
extension AdministratorPatterns on Administrator {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Administrator value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Administrator() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Administrator value)  $default,){
final _that = this;
switch (_that) {
case _Administrator():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Administrator value)?  $default,){
final _that = this;
switch (_that) {
case _Administrator() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email,  bool owner)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Administrator() when $default != null:
return $default(_that.email,_that.owner);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email,  bool owner)  $default,) {final _that = this;
switch (_that) {
case _Administrator():
return $default(_that.email,_that.owner);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email,  bool owner)?  $default,) {final _that = this;
switch (_that) {
case _Administrator() when $default != null:
return $default(_that.email,_that.owner);case _:
  return null;

}
}

}

/// @nodoc


class _Administrator implements Administrator {
  const _Administrator({required this.email, this.owner = false});
  

@override final  String email;
/// Whether they are the owner (*Titular*): always an administrator,
/// never demoted.
@override@JsonKey() final  bool owner;

/// Create a copy of Administrator
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdministratorCopyWith<_Administrator> get copyWith => __$AdministratorCopyWithImpl<_Administrator>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Administrator&&(identical(other.email, email) || other.email == email)&&(identical(other.owner, owner) || other.owner == owner));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email,owner);
}

@override
String toString() {
    return 'Administrator(email: $email, owner: $owner)';
}


}

/// @nodoc
abstract mixin class _$AdministratorCopyWith<$Res> implements $AdministratorCopyWith<$Res> {
  factory _$AdministratorCopyWith(_Administrator value, $Res Function(_Administrator) _then) = __$AdministratorCopyWithImpl;
@override @useResult
$Res call({
 String email, bool owner
});




}
/// @nodoc
class __$AdministratorCopyWithImpl<$Res>
    implements _$AdministratorCopyWith<$Res> {
  __$AdministratorCopyWithImpl(this._self, this._then);

  final _Administrator _self;
  final $Res Function(_Administrator) _then;

/// Create a copy of Administrator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? owner = null,}) {
  return _then(_Administrator(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OrganizationAdministrators {

/// The owner first, then by e-mail (the server's order).
 List<Administrator> get administrators;/// E-mails of the members who are not administrators, by e-mail.
 List<String> get members;
/// Create a copy of OrganizationAdministrators
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationAdministratorsCopyWith<OrganizationAdministrators> get copyWith => _$OrganizationAdministratorsCopyWithImpl<OrganizationAdministrators>(this as OrganizationAdministrators, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OrganizationAdministrators;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationAdministrators&&const DeepCollectionEquality().equals(other.administrators, _this.administrators)&&const DeepCollectionEquality().equals(other.members, _this.members));
}


@override
int get hashCode {
  final _this = this as OrganizationAdministrators;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.administrators),const DeepCollectionEquality().hash(_this.members));
}

@override
String toString() {
  final _this = this as OrganizationAdministrators;
  return 'OrganizationAdministrators(administrators: ${_this.administrators}, members: ${_this.members})';
}


}

/// @nodoc
abstract mixin class $OrganizationAdministratorsCopyWith<$Res>  {
  factory $OrganizationAdministratorsCopyWith(OrganizationAdministrators value, $Res Function(OrganizationAdministrators) _then) = _$OrganizationAdministratorsCopyWithImpl;
@useResult
$Res call({
 List<Administrator> administrators, List<String> members
});




}
/// @nodoc
class _$OrganizationAdministratorsCopyWithImpl<$Res>
    implements $OrganizationAdministratorsCopyWith<$Res> {
  _$OrganizationAdministratorsCopyWithImpl(this._self, this._then);

  final OrganizationAdministrators _self;
  final $Res Function(OrganizationAdministrators) _then;

/// Create a copy of OrganizationAdministrators
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? administrators = null,Object? members = null,}) {
  return _then(OrganizationAdministrators(
administrators: null == administrators ? _self.administrators : administrators // ignore: cast_nullable_to_non_nullable
as List<Administrator>,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationAdministrators].
extension OrganizationAdministratorsPatterns on OrganizationAdministrators {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationAdministrators value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationAdministrators() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationAdministrators value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationAdministrators():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationAdministrators value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationAdministrators() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Administrator> administrators,  List<String> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationAdministrators() when $default != null:
return $default(_that.administrators,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Administrator> administrators,  List<String> members)  $default,) {final _that = this;
switch (_that) {
case _OrganizationAdministrators():
return $default(_that.administrators,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Administrator> administrators,  List<String> members)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationAdministrators() when $default != null:
return $default(_that.administrators,_that.members);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationAdministrators implements OrganizationAdministrators {
  const _OrganizationAdministrators({ List<Administrator> administrators = const [],  List<String> members = const []}): _administrators = administrators,_members = members;
  

/// The owner first, then by e-mail (the server's order).
 final  List<Administrator> _administrators;
/// The owner first, then by e-mail (the server's order).
@override@JsonKey() List<Administrator> get administrators {
  if (_administrators is EqualUnmodifiableListView) return _administrators;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_administrators);
}

/// E-mails of the members who are not administrators, by e-mail.
 final  List<String> _members;
/// E-mails of the members who are not administrators, by e-mail.
@override@JsonKey() List<String> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of OrganizationAdministrators
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationAdministratorsCopyWith<_OrganizationAdministrators> get copyWith => __$OrganizationAdministratorsCopyWithImpl<_OrganizationAdministrators>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationAdministrators&&const DeepCollectionEquality().equals(other.administrators, _administrators)&&const DeepCollectionEquality().equals(other.members, _members));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_administrators),const DeepCollectionEquality().hash(_members));
}

@override
String toString() {
    return 'OrganizationAdministrators(administrators: $administrators, members: $members)';
}


}

/// @nodoc
abstract mixin class _$OrganizationAdministratorsCopyWith<$Res> implements $OrganizationAdministratorsCopyWith<$Res> {
  factory _$OrganizationAdministratorsCopyWith(_OrganizationAdministrators value, $Res Function(_OrganizationAdministrators) _then) = __$OrganizationAdministratorsCopyWithImpl;
@override @useResult
$Res call({
 List<Administrator> administrators, List<String> members
});




}
/// @nodoc
class __$OrganizationAdministratorsCopyWithImpl<$Res>
    implements _$OrganizationAdministratorsCopyWith<$Res> {
  __$OrganizationAdministratorsCopyWithImpl(this._self, this._then);

  final _OrganizationAdministrators _self;
  final $Res Function(_OrganizationAdministrators) _then;

/// Create a copy of OrganizationAdministrators
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? administrators = null,Object? members = null,}) {
  return _then(_OrganizationAdministrators(
administrators: null == administrators ? _self._administrators : administrators // ignore: cast_nullable_to_non_nullable
as List<Administrator>,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
