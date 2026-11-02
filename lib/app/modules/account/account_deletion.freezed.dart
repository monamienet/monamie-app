// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_deletion.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountDeletion {

 DateTime get deleteAt;/// Ids of the organizations deleted with the account.
 List<String> get ownedOrganizationIds; Map<String, String> get ownedOrganizationNames;
/// Create a copy of AccountDeletion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDeletionCopyWith<AccountDeletion> get copyWith => _$AccountDeletionCopyWithImpl<AccountDeletion>(this as AccountDeletion, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AccountDeletion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeletion&&(identical(other.deleteAt, _this.deleteAt) || other.deleteAt == _this.deleteAt)&&const DeepCollectionEquality().equals(other.ownedOrganizationIds, _this.ownedOrganizationIds)&&const DeepCollectionEquality().equals(other.ownedOrganizationNames, _this.ownedOrganizationNames));
}


@override
int get hashCode {
  final _this = this as AccountDeletion;
  return Object.hash(runtimeType,_this.deleteAt,const DeepCollectionEquality().hash(_this.ownedOrganizationIds),const DeepCollectionEquality().hash(_this.ownedOrganizationNames));
}

@override
String toString() {
  final _this = this as AccountDeletion;
  return 'AccountDeletion(deleteAt: ${_this.deleteAt}, ownedOrganizationIds: ${_this.ownedOrganizationIds}, ownedOrganizationNames: ${_this.ownedOrganizationNames})';
}


}

/// @nodoc
abstract mixin class $AccountDeletionCopyWith<$Res>  {
  factory $AccountDeletionCopyWith(AccountDeletion value, $Res Function(AccountDeletion) _then) = _$AccountDeletionCopyWithImpl;
@useResult
$Res call({
 DateTime deleteAt, List<String> ownedOrganizationIds, Map<String, String> ownedOrganizationNames
});




}
/// @nodoc
class _$AccountDeletionCopyWithImpl<$Res>
    implements $AccountDeletionCopyWith<$Res> {
  _$AccountDeletionCopyWithImpl(this._self, this._then);

  final AccountDeletion _self;
  final $Res Function(AccountDeletion) _then;

/// Create a copy of AccountDeletion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deleteAt = null,Object? ownedOrganizationIds = null,Object? ownedOrganizationNames = null,}) {
  return _then(AccountDeletion(
deleteAt: null == deleteAt ? _self.deleteAt : deleteAt // ignore: cast_nullable_to_non_nullable
as DateTime,ownedOrganizationIds: null == ownedOrganizationIds ? _self.ownedOrganizationIds : ownedOrganizationIds // ignore: cast_nullable_to_non_nullable
as List<String>,ownedOrganizationNames: null == ownedOrganizationNames ? _self.ownedOrganizationNames : ownedOrganizationNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountDeletion].
extension AccountDeletionPatterns on AccountDeletion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDeletion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDeletion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDeletion value)  $default,){
final _that = this;
switch (_that) {
case _AccountDeletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDeletion value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDeletion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime deleteAt,  List<String> ownedOrganizationIds,  Map<String, String> ownedOrganizationNames)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDeletion() when $default != null:
return $default(_that.deleteAt,_that.ownedOrganizationIds,_that.ownedOrganizationNames);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime deleteAt,  List<String> ownedOrganizationIds,  Map<String, String> ownedOrganizationNames)  $default,) {final _that = this;
switch (_that) {
case _AccountDeletion():
return $default(_that.deleteAt,_that.ownedOrganizationIds,_that.ownedOrganizationNames);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime deleteAt,  List<String> ownedOrganizationIds,  Map<String, String> ownedOrganizationNames)?  $default,) {final _that = this;
switch (_that) {
case _AccountDeletion() when $default != null:
return $default(_that.deleteAt,_that.ownedOrganizationIds,_that.ownedOrganizationNames);case _:
  return null;

}
}

}

/// @nodoc


class _AccountDeletion extends AccountDeletion {
  const _AccountDeletion({required this.deleteAt,  List<String> ownedOrganizationIds = const [],  Map<String, String> ownedOrganizationNames = const {}}): _ownedOrganizationIds = ownedOrganizationIds,_ownedOrganizationNames = ownedOrganizationNames,super._();
  

@override final  DateTime deleteAt;
/// Ids of the organizations deleted with the account.
 final  List<String> _ownedOrganizationIds;
/// Ids of the organizations deleted with the account.
@override@JsonKey() List<String> get ownedOrganizationIds {
  if (_ownedOrganizationIds is EqualUnmodifiableListView) return _ownedOrganizationIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ownedOrganizationIds);
}

 final  Map<String, String> _ownedOrganizationNames;
@override@JsonKey() Map<String, String> get ownedOrganizationNames {
  if (_ownedOrganizationNames is EqualUnmodifiableMapView) return _ownedOrganizationNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ownedOrganizationNames);
}


/// Create a copy of AccountDeletion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDeletionCopyWith<_AccountDeletion> get copyWith => __$AccountDeletionCopyWithImpl<_AccountDeletion>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDeletion&&(identical(other.deleteAt, deleteAt) || other.deleteAt == deleteAt)&&const DeepCollectionEquality().equals(other.ownedOrganizationIds, _ownedOrganizationIds)&&const DeepCollectionEquality().equals(other.ownedOrganizationNames, _ownedOrganizationNames));
}


@override
int get hashCode {
    return Object.hash(runtimeType,deleteAt,const DeepCollectionEquality().hash(_ownedOrganizationIds),const DeepCollectionEquality().hash(_ownedOrganizationNames));
}

@override
String toString() {
    return 'AccountDeletion(deleteAt: $deleteAt, ownedOrganizationIds: $ownedOrganizationIds, ownedOrganizationNames: $ownedOrganizationNames)';
}


}

/// @nodoc
abstract mixin class _$AccountDeletionCopyWith<$Res> implements $AccountDeletionCopyWith<$Res> {
  factory _$AccountDeletionCopyWith(_AccountDeletion value, $Res Function(_AccountDeletion) _then) = __$AccountDeletionCopyWithImpl;
@override @useResult
$Res call({
 DateTime deleteAt, List<String> ownedOrganizationIds, Map<String, String> ownedOrganizationNames
});




}
/// @nodoc
class __$AccountDeletionCopyWithImpl<$Res>
    implements _$AccountDeletionCopyWith<$Res> {
  __$AccountDeletionCopyWithImpl(this._self, this._then);

  final _AccountDeletion _self;
  final $Res Function(_AccountDeletion) _then;

/// Create a copy of AccountDeletion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deleteAt = null,Object? ownedOrganizationIds = null,Object? ownedOrganizationNames = null,}) {
  return _then(_AccountDeletion(
deleteAt: null == deleteAt ? _self.deleteAt : deleteAt // ignore: cast_nullable_to_non_nullable
as DateTime,ownedOrganizationIds: null == ownedOrganizationIds ? _self._ownedOrganizationIds : ownedOrganizationIds // ignore: cast_nullable_to_non_nullable
as List<String>,ownedOrganizationNames: null == ownedOrganizationNames ? _self._ownedOrganizationNames : ownedOrganizationNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
