// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_send_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InviteSendResult {

/// The group invited to (just created, in first-group mode).
 String get groupId; String get groupName;/// E-mails invited (a pending invite exists for each).
 List<String> get sent;/// Invited, but the e-mail could not be sent: the person still sees the
/// invite when they sign in.
 List<String> get notEmailed;/// Not invited, with the reason ("Já está no grupo.").
 Map<String, String> get skipped;
/// Create a copy of InviteSendResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteSendResultCopyWith<InviteSendResult> get copyWith => _$InviteSendResultCopyWithImpl<InviteSendResult>(this as InviteSendResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InviteSendResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteSendResult&&(identical(other.groupId, _this.groupId) || other.groupId == _this.groupId)&&(identical(other.groupName, _this.groupName) || other.groupName == _this.groupName)&&const DeepCollectionEquality().equals(other.sent, _this.sent)&&const DeepCollectionEquality().equals(other.notEmailed, _this.notEmailed)&&const DeepCollectionEquality().equals(other.skipped, _this.skipped));
}


@override
int get hashCode {
  final _this = this as InviteSendResult;
  return Object.hash(runtimeType,_this.groupId,_this.groupName,const DeepCollectionEquality().hash(_this.sent),const DeepCollectionEquality().hash(_this.notEmailed),const DeepCollectionEquality().hash(_this.skipped));
}

@override
String toString() {
  final _this = this as InviteSendResult;
  return 'InviteSendResult(groupId: ${_this.groupId}, groupName: ${_this.groupName}, sent: ${_this.sent}, notEmailed: ${_this.notEmailed}, skipped: ${_this.skipped})';
}


}

/// @nodoc
abstract mixin class $InviteSendResultCopyWith<$Res>  {
  factory $InviteSendResultCopyWith(InviteSendResult value, $Res Function(InviteSendResult) _then) = _$InviteSendResultCopyWithImpl;
@useResult
$Res call({
 String groupId, String groupName, List<String> sent, List<String> notEmailed, Map<String, String> skipped
});




}
/// @nodoc
class _$InviteSendResultCopyWithImpl<$Res>
    implements $InviteSendResultCopyWith<$Res> {
  _$InviteSendResultCopyWithImpl(this._self, this._then);

  final InviteSendResult _self;
  final $Res Function(InviteSendResult) _then;

/// Create a copy of InviteSendResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupId = null,Object? groupName = null,Object? sent = null,Object? notEmailed = null,Object? skipped = null,}) {
  return _then(InviteSendResult(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as List<String>,notEmailed: null == notEmailed ? _self.notEmailed : notEmailed // ignore: cast_nullable_to_non_nullable
as List<String>,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteSendResult].
extension InviteSendResultPatterns on InviteSendResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteSendResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteSendResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteSendResult value)  $default,){
final _that = this;
switch (_that) {
case _InviteSendResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteSendResult value)?  $default,){
final _that = this;
switch (_that) {
case _InviteSendResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String groupId,  String groupName,  List<String> sent,  List<String> notEmailed,  Map<String, String> skipped)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteSendResult() when $default != null:
return $default(_that.groupId,_that.groupName,_that.sent,_that.notEmailed,_that.skipped);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String groupId,  String groupName,  List<String> sent,  List<String> notEmailed,  Map<String, String> skipped)  $default,) {final _that = this;
switch (_that) {
case _InviteSendResult():
return $default(_that.groupId,_that.groupName,_that.sent,_that.notEmailed,_that.skipped);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String groupId,  String groupName,  List<String> sent,  List<String> notEmailed,  Map<String, String> skipped)?  $default,) {final _that = this;
switch (_that) {
case _InviteSendResult() when $default != null:
return $default(_that.groupId,_that.groupName,_that.sent,_that.notEmailed,_that.skipped);case _:
  return null;

}
}

}

/// @nodoc


class _InviteSendResult implements InviteSendResult {
  const _InviteSendResult({required this.groupId, required this.groupName, required  List<String> sent, required  List<String> notEmailed, required  Map<String, String> skipped}): _sent = sent,_notEmailed = notEmailed,_skipped = skipped;
  

/// The group invited to (just created, in first-group mode).
@override final  String groupId;
@override final  String groupName;
/// E-mails invited (a pending invite exists for each).
 final  List<String> _sent;
/// E-mails invited (a pending invite exists for each).
@override List<String> get sent {
  if (_sent is EqualUnmodifiableListView) return _sent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sent);
}

/// Invited, but the e-mail could not be sent: the person still sees the
/// invite when they sign in.
 final  List<String> _notEmailed;
/// Invited, but the e-mail could not be sent: the person still sees the
/// invite when they sign in.
@override List<String> get notEmailed {
  if (_notEmailed is EqualUnmodifiableListView) return _notEmailed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notEmailed);
}

/// Not invited, with the reason ("Já está no grupo.").
 final  Map<String, String> _skipped;
/// Not invited, with the reason ("Já está no grupo.").
@override Map<String, String> get skipped {
  if (_skipped is EqualUnmodifiableMapView) return _skipped;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_skipped);
}


/// Create a copy of InviteSendResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteSendResultCopyWith<_InviteSendResult> get copyWith => __$InviteSendResultCopyWithImpl<_InviteSendResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteSendResult&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.groupName, groupName) || other.groupName == groupName)&&const DeepCollectionEquality().equals(other.sent, _sent)&&const DeepCollectionEquality().equals(other.notEmailed, _notEmailed)&&const DeepCollectionEquality().equals(other.skipped, _skipped));
}


@override
int get hashCode {
    return Object.hash(runtimeType,groupId,groupName,const DeepCollectionEquality().hash(_sent),const DeepCollectionEquality().hash(_notEmailed),const DeepCollectionEquality().hash(_skipped));
}

@override
String toString() {
    return 'InviteSendResult(groupId: $groupId, groupName: $groupName, sent: $sent, notEmailed: $notEmailed, skipped: $skipped)';
}


}

/// @nodoc
abstract mixin class _$InviteSendResultCopyWith<$Res> implements $InviteSendResultCopyWith<$Res> {
  factory _$InviteSendResultCopyWith(_InviteSendResult value, $Res Function(_InviteSendResult) _then) = __$InviteSendResultCopyWithImpl;
@override @useResult
$Res call({
 String groupId, String groupName, List<String> sent, List<String> notEmailed, Map<String, String> skipped
});




}
/// @nodoc
class __$InviteSendResultCopyWithImpl<$Res>
    implements _$InviteSendResultCopyWith<$Res> {
  __$InviteSendResultCopyWithImpl(this._self, this._then);

  final _InviteSendResult _self;
  final $Res Function(_InviteSendResult) _then;

/// Create a copy of InviteSendResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupId = null,Object? groupName = null,Object? sent = null,Object? notEmailed = null,Object? skipped = null,}) {
  return _then(_InviteSendResult(
groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,groupName: null == groupName ? _self.groupName : groupName // ignore: cast_nullable_to_non_nullable
as String,sent: null == sent ? _self._sent : sent // ignore: cast_nullable_to_non_nullable
as List<String>,notEmailed: null == notEmailed ? _self._notEmailed : notEmailed // ignore: cast_nullable_to_non_nullable
as List<String>,skipped: null == skipped ? _self._skipped : skipped // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
