// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'groups_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupsState {

/// The groups the person manages (every group for an administrator).
 List<Group> get groups;/// Why the last load or operation failed; empty when it did not.
 String get errorMessage;/// The group deleted last, for *Grupo excluído*; `null` before one is.
 DeletedGroup? get deleted;
/// Create a copy of GroupsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupsStateCopyWith<GroupsState> get copyWith => _$GroupsStateCopyWithImpl<GroupsState>(this as GroupsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GroupsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupsState&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.deleted, _this.deleted) || other.deleted == _this.deleted));
}


@override
int get hashCode {
  final _this = this as GroupsState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.groups),_this.errorMessage,_this.deleted);
}

@override
String toString() {
  final _this = this as GroupsState;
  return 'GroupsState(groups: ${_this.groups}, errorMessage: ${_this.errorMessage}, deleted: ${_this.deleted})';
}


}

/// @nodoc
abstract mixin class $GroupsStateCopyWith<$Res>  {
  factory $GroupsStateCopyWith(GroupsState value, $Res Function(GroupsState) _then) = _$GroupsStateCopyWithImpl;
@useResult
$Res call({
 List<Group> groups, String errorMessage, DeletedGroup? deleted
});


$DeletedGroupCopyWith<$Res>? get deleted;

}
/// @nodoc
class _$GroupsStateCopyWithImpl<$Res>
    implements $GroupsStateCopyWith<$Res> {
  _$GroupsStateCopyWithImpl(this._self, this._then);

  final GroupsState _self;
  final $Res Function(GroupsState) _then;

/// Create a copy of GroupsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groups = null,Object? errorMessage = null,Object? deleted = freezed,}) {
  return _then(GroupsState(
groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<Group>,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,deleted: freezed == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as DeletedGroup?,
  ));
}
/// Create a copy of GroupsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeletedGroupCopyWith<$Res>? get deleted {
    if (_self.deleted == null) {
    return null;
  }

  return $DeletedGroupCopyWith<$Res>(_self.deleted!, (value) {
    return _then(_self.copyWith(deleted: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupsState].
extension GroupsStatePatterns on GroupsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupsState value)  $default,){
final _that = this;
switch (_that) {
case _GroupsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupsState value)?  $default,){
final _that = this;
switch (_that) {
case _GroupsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Group> groups,  String errorMessage,  DeletedGroup? deleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupsState() when $default != null:
return $default(_that.groups,_that.errorMessage,_that.deleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Group> groups,  String errorMessage,  DeletedGroup? deleted)  $default,) {final _that = this;
switch (_that) {
case _GroupsState():
return $default(_that.groups,_that.errorMessage,_that.deleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Group> groups,  String errorMessage,  DeletedGroup? deleted)?  $default,) {final _that = this;
switch (_that) {
case _GroupsState() when $default != null:
return $default(_that.groups,_that.errorMessage,_that.deleted);case _:
  return null;

}
}

}

/// @nodoc


class _GroupsState implements GroupsState {
  const _GroupsState({ List<Group> groups = const [], this.errorMessage = '', this.deleted}): _groups = groups;
  

/// The groups the person manages (every group for an administrator).
 final  List<Group> _groups;
/// The groups the person manages (every group for an administrator).
@override@JsonKey() List<Group> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

/// Why the last load or operation failed; empty when it did not.
@override@JsonKey() final  String errorMessage;
/// The group deleted last, for *Grupo excluído*; `null` before one is.
@override final  DeletedGroup? deleted;

/// Create a copy of GroupsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupsStateCopyWith<_GroupsState> get copyWith => __$GroupsStateCopyWithImpl<_GroupsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupsState&&const DeepCollectionEquality().equals(other.groups, _groups)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.deleted, deleted) || other.deleted == deleted));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups),errorMessage,deleted);
}

@override
String toString() {
    return 'GroupsState(groups: $groups, errorMessage: $errorMessage, deleted: $deleted)';
}


}

/// @nodoc
abstract mixin class _$GroupsStateCopyWith<$Res> implements $GroupsStateCopyWith<$Res> {
  factory _$GroupsStateCopyWith(_GroupsState value, $Res Function(_GroupsState) _then) = __$GroupsStateCopyWithImpl;
@override @useResult
$Res call({
 List<Group> groups, String errorMessage, DeletedGroup? deleted
});


@override $DeletedGroupCopyWith<$Res>? get deleted;

}
/// @nodoc
class __$GroupsStateCopyWithImpl<$Res>
    implements _$GroupsStateCopyWith<$Res> {
  __$GroupsStateCopyWithImpl(this._self, this._then);

  final _GroupsState _self;
  final $Res Function(_GroupsState) _then;

/// Create a copy of GroupsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groups = null,Object? errorMessage = null,Object? deleted = freezed,}) {
  return _then(_GroupsState(
groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<Group>,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,deleted: freezed == deleted ? _self.deleted : deleted // ignore: cast_nullable_to_non_nullable
as DeletedGroup?,
  ));
}

/// Create a copy of GroupsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DeletedGroupCopyWith<$Res>? get deleted {
    if (_self.deleted == null) {
    return null;
  }

  return $DeletedGroupCopyWith<$Res>(_self.deleted!, (value) {
    return _then(_self.copyWith(deleted: value));
  });
}
}

/// @nodoc
mixin _$DeletedGroup {

 String get id; String get name;/// How many people lost access to the organization with it.
 int get loses;
/// Create a copy of DeletedGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeletedGroupCopyWith<DeletedGroup> get copyWith => _$DeletedGroupCopyWithImpl<DeletedGroup>(this as DeletedGroup, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DeletedGroup;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeletedGroup&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.loses, _this.loses) || other.loses == _this.loses));
}


@override
int get hashCode {
  final _this = this as DeletedGroup;
  return Object.hash(runtimeType,_this.id,_this.name,_this.loses);
}

@override
String toString() {
  final _this = this as DeletedGroup;
  return 'DeletedGroup(id: ${_this.id}, name: ${_this.name}, loses: ${_this.loses})';
}


}

/// @nodoc
abstract mixin class $DeletedGroupCopyWith<$Res>  {
  factory $DeletedGroupCopyWith(DeletedGroup value, $Res Function(DeletedGroup) _then) = _$DeletedGroupCopyWithImpl;
@useResult
$Res call({
 String id, String name, int loses
});




}
/// @nodoc
class _$DeletedGroupCopyWithImpl<$Res>
    implements $DeletedGroupCopyWith<$Res> {
  _$DeletedGroupCopyWithImpl(this._self, this._then);

  final DeletedGroup _self;
  final $Res Function(DeletedGroup) _then;

/// Create a copy of DeletedGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? loses = null,}) {
  return _then(DeletedGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,loses: null == loses ? _self.loses : loses // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DeletedGroup].
extension DeletedGroupPatterns on DeletedGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeletedGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeletedGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeletedGroup value)  $default,){
final _that = this;
switch (_that) {
case _DeletedGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeletedGroup value)?  $default,){
final _that = this;
switch (_that) {
case _DeletedGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  int loses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeletedGroup() when $default != null:
return $default(_that.id,_that.name,_that.loses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  int loses)  $default,) {final _that = this;
switch (_that) {
case _DeletedGroup():
return $default(_that.id,_that.name,_that.loses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  int loses)?  $default,) {final _that = this;
switch (_that) {
case _DeletedGroup() when $default != null:
return $default(_that.id,_that.name,_that.loses);case _:
  return null;

}
}

}

/// @nodoc


class _DeletedGroup implements DeletedGroup {
  const _DeletedGroup({required this.id, required this.name, required this.loses});
  

@override final  String id;
@override final  String name;
/// How many people lost access to the organization with it.
@override final  int loses;

/// Create a copy of DeletedGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeletedGroupCopyWith<_DeletedGroup> get copyWith => __$DeletedGroupCopyWithImpl<_DeletedGroup>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletedGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.loses, loses) || other.loses == loses));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,loses);
}

@override
String toString() {
    return 'DeletedGroup(id: $id, name: $name, loses: $loses)';
}


}

/// @nodoc
abstract mixin class _$DeletedGroupCopyWith<$Res> implements $DeletedGroupCopyWith<$Res> {
  factory _$DeletedGroupCopyWith(_DeletedGroup value, $Res Function(_DeletedGroup) _then) = __$DeletedGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, int loses
});




}
/// @nodoc
class __$DeletedGroupCopyWithImpl<$Res>
    implements _$DeletedGroupCopyWith<$Res> {
  __$DeletedGroupCopyWithImpl(this._self, this._then);

  final _DeletedGroup _self;
  final $Res Function(_DeletedGroup) _then;

/// Create a copy of DeletedGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? loses = null,}) {
  return _then(_DeletedGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,loses: null == loses ? _self.loses : loses // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
