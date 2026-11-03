// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteState {

/// The groups one may invite to.
 List<Group> get groups;/// The chosen group's id, or `null` in first-group mode.
 String? get groupId;/// The first group's name, when the organization has no group yet.
 String get firstGroupName;/// The people to invite, with their roles.
 List<InviteDraft> get people;/// Why the last e-mail typed could not be added; empty when it could.
 String get draftError;/// Why the last send failed; empty when it did not.
 String get errorMessage;/// The outcome of the last send, until "Convidar mais pessoas".
 InviteSendResult? get result;
/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteStateCopyWith<InviteState> get copyWith => _$InviteStateCopyWithImpl<InviteState>(this as InviteState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InviteState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteState&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.firstGroupName, _this.firstGroupName) || other.firstGroupName == _this.firstGroupName)&&const DeepCollectionEquality().equals(other.people, _this.people)&&(identical(other.draftError, _this.draftError) || other.draftError == _this.draftError)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.result, _this.result) || other.result == _this.result));
}


@override
int get hashCode {
  final _this = this as InviteState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.groups),_this.groupId,_this.firstGroupName,const DeepCollectionEquality().hash(_this.people),_this.draftError,_this.errorMessage,_this.result);
}

@override
String toString() {
  final _this = this as InviteState;
  return 'InviteState(groups: ${_this.groups}, groupId: ${_this.groupId}, firstGroupName: ${_this.firstGroupName}, people: ${_this.people}, draftError: ${_this.draftError}, errorMessage: ${_this.errorMessage}, result: ${_this.result})';
}


}

/// @nodoc
abstract mixin class $InviteStateCopyWith<$Res>  {
  factory $InviteStateCopyWith(InviteState value, $Res Function(InviteState) _then) = _$InviteStateCopyWithImpl;
@useResult
$Res call({
 List<Group> groups, String? groupId, String firstGroupName, List<InviteDraft> people, String draftError, String errorMessage, InviteSendResult? result
});


$InviteSendResultCopyWith<$Res>? get result;

}
/// @nodoc
class _$InviteStateCopyWithImpl<$Res>
    implements $InviteStateCopyWith<$Res> {
  _$InviteStateCopyWithImpl(this._self, this._then);

  final InviteState _self;
  final $Res Function(InviteState) _then;

/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groups = null,Object? groupId = freezed,Object? firstGroupName = null,Object? people = null,Object? draftError = null,Object? errorMessage = null,Object? result = freezed,}) {
  return _then(InviteState(
groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<Group>,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,firstGroupName: null == firstGroupName ? _self.firstGroupName : firstGroupName // ignore: cast_nullable_to_non_nullable
as String,people: null == people ? _self.people : people // ignore: cast_nullable_to_non_nullable
as List<InviteDraft>,draftError: null == draftError ? _self.draftError : draftError // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as InviteSendResult?,
  ));
}
/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InviteSendResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $InviteSendResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [InviteState].
extension InviteStatePatterns on InviteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteState value)  $default,){
final _that = this;
switch (_that) {
case _InviteState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteState value)?  $default,){
final _that = this;
switch (_that) {
case _InviteState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Group> groups,  String? groupId,  String firstGroupName,  List<InviteDraft> people,  String draftError,  String errorMessage,  InviteSendResult? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteState() when $default != null:
return $default(_that.groups,_that.groupId,_that.firstGroupName,_that.people,_that.draftError,_that.errorMessage,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Group> groups,  String? groupId,  String firstGroupName,  List<InviteDraft> people,  String draftError,  String errorMessage,  InviteSendResult? result)  $default,) {final _that = this;
switch (_that) {
case _InviteState():
return $default(_that.groups,_that.groupId,_that.firstGroupName,_that.people,_that.draftError,_that.errorMessage,_that.result);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Group> groups,  String? groupId,  String firstGroupName,  List<InviteDraft> people,  String draftError,  String errorMessage,  InviteSendResult? result)?  $default,) {final _that = this;
switch (_that) {
case _InviteState() when $default != null:
return $default(_that.groups,_that.groupId,_that.firstGroupName,_that.people,_that.draftError,_that.errorMessage,_that.result);case _:
  return null;

}
}

}

/// @nodoc


class _InviteState implements InviteState {
  const _InviteState({ List<Group> groups = const [], this.groupId, this.firstGroupName = '',  List<InviteDraft> people = const [], this.draftError = '', this.errorMessage = '', this.result}): _groups = groups,_people = people;
  

/// The groups one may invite to.
 final  List<Group> _groups;
/// The groups one may invite to.
@override@JsonKey() List<Group> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

/// The chosen group's id, or `null` in first-group mode.
@override final  String? groupId;
/// The first group's name, when the organization has no group yet.
@override@JsonKey() final  String firstGroupName;
/// The people to invite, with their roles.
 final  List<InviteDraft> _people;
/// The people to invite, with their roles.
@override@JsonKey() List<InviteDraft> get people {
  if (_people is EqualUnmodifiableListView) return _people;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_people);
}

/// Why the last e-mail typed could not be added; empty when it could.
@override@JsonKey() final  String draftError;
/// Why the last send failed; empty when it did not.
@override@JsonKey() final  String errorMessage;
/// The outcome of the last send, until "Convidar mais pessoas".
@override final  InviteSendResult? result;

/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteStateCopyWith<_InviteState> get copyWith => __$InviteStateCopyWithImpl<_InviteState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteState&&const DeepCollectionEquality().equals(other.groups, _groups)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.firstGroupName, firstGroupName) || other.firstGroupName == firstGroupName)&&const DeepCollectionEquality().equals(other.people, _people)&&(identical(other.draftError, draftError) || other.draftError == draftError)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups),groupId,firstGroupName,const DeepCollectionEquality().hash(_people),draftError,errorMessage,result);
}

@override
String toString() {
    return 'InviteState(groups: $groups, groupId: $groupId, firstGroupName: $firstGroupName, people: $people, draftError: $draftError, errorMessage: $errorMessage, result: $result)';
}


}

/// @nodoc
abstract mixin class _$InviteStateCopyWith<$Res> implements $InviteStateCopyWith<$Res> {
  factory _$InviteStateCopyWith(_InviteState value, $Res Function(_InviteState) _then) = __$InviteStateCopyWithImpl;
@override @useResult
$Res call({
 List<Group> groups, String? groupId, String firstGroupName, List<InviteDraft> people, String draftError, String errorMessage, InviteSendResult? result
});


@override $InviteSendResultCopyWith<$Res>? get result;

}
/// @nodoc
class __$InviteStateCopyWithImpl<$Res>
    implements _$InviteStateCopyWith<$Res> {
  __$InviteStateCopyWithImpl(this._self, this._then);

  final _InviteState _self;
  final $Res Function(_InviteState) _then;

/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groups = null,Object? groupId = freezed,Object? firstGroupName = null,Object? people = null,Object? draftError = null,Object? errorMessage = null,Object? result = freezed,}) {
  return _then(_InviteState(
groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<Group>,groupId: freezed == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String?,firstGroupName: null == firstGroupName ? _self.firstGroupName : firstGroupName // ignore: cast_nullable_to_non_nullable
as String,people: null == people ? _self._people : people // ignore: cast_nullable_to_non_nullable
as List<InviteDraft>,draftError: null == draftError ? _self.draftError : draftError // ignore: cast_nullable_to_non_nullable
as String,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as InviteSendResult?,
  ));
}

/// Create a copy of InviteState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InviteSendResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $InviteSendResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
