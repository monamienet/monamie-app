// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_choice_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrganizationChoiceState {

/// E-mail of the Google account signed in to MonAmie (central project),
/// shown with "Trocar".
 String? get signedInEmail;/// Why the person is on *Sem organização* after trying to enter an
/// organization (no membership there any more); `null` otherwise.
 String? get noAccessReason;/// Organizations offered by the picker; none on *Sem organização*.
 List<OrganizationBinding> get organizationChoices;/// Invites waiting for the signed-in account.
 List<Invite> get pendingInvites;/// Name of the organization being entered, for its spinner.
 String? get enteringOrganizationName;/// Error of the last accept, shown on the invite card.
 String get inviteError;/// Whether a sign-out runs.
 bool get isLoggingOut;
/// Create a copy of OrganizationChoiceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationChoiceStateCopyWith<OrganizationChoiceState> get copyWith => _$OrganizationChoiceStateCopyWithImpl<OrganizationChoiceState>(this as OrganizationChoiceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OrganizationChoiceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationChoiceState&&(identical(other.signedInEmail, _this.signedInEmail) || other.signedInEmail == _this.signedInEmail)&&(identical(other.noAccessReason, _this.noAccessReason) || other.noAccessReason == _this.noAccessReason)&&const DeepCollectionEquality().equals(other.organizationChoices, _this.organizationChoices)&&const DeepCollectionEquality().equals(other.pendingInvites, _this.pendingInvites)&&(identical(other.enteringOrganizationName, _this.enteringOrganizationName) || other.enteringOrganizationName == _this.enteringOrganizationName)&&(identical(other.inviteError, _this.inviteError) || other.inviteError == _this.inviteError)&&(identical(other.isLoggingOut, _this.isLoggingOut) || other.isLoggingOut == _this.isLoggingOut));
}


@override
int get hashCode {
  final _this = this as OrganizationChoiceState;
  return Object.hash(runtimeType,_this.signedInEmail,_this.noAccessReason,const DeepCollectionEquality().hash(_this.organizationChoices),const DeepCollectionEquality().hash(_this.pendingInvites),_this.enteringOrganizationName,_this.inviteError,_this.isLoggingOut);
}

@override
String toString() {
  final _this = this as OrganizationChoiceState;
  return 'OrganizationChoiceState(signedInEmail: ${_this.signedInEmail}, noAccessReason: ${_this.noAccessReason}, organizationChoices: ${_this.organizationChoices}, pendingInvites: ${_this.pendingInvites}, enteringOrganizationName: ${_this.enteringOrganizationName}, inviteError: ${_this.inviteError}, isLoggingOut: ${_this.isLoggingOut})';
}


}

/// @nodoc
abstract mixin class $OrganizationChoiceStateCopyWith<$Res>  {
  factory $OrganizationChoiceStateCopyWith(OrganizationChoiceState value, $Res Function(OrganizationChoiceState) _then) = _$OrganizationChoiceStateCopyWithImpl;
@useResult
$Res call({
 String? signedInEmail, String? noAccessReason, List<OrganizationBinding> organizationChoices, List<Invite> pendingInvites, String? enteringOrganizationName, String inviteError, bool isLoggingOut
});




}
/// @nodoc
class _$OrganizationChoiceStateCopyWithImpl<$Res>
    implements $OrganizationChoiceStateCopyWith<$Res> {
  _$OrganizationChoiceStateCopyWithImpl(this._self, this._then);

  final OrganizationChoiceState _self;
  final $Res Function(OrganizationChoiceState) _then;

/// Create a copy of OrganizationChoiceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? signedInEmail = freezed,Object? noAccessReason = freezed,Object? organizationChoices = null,Object? pendingInvites = null,Object? enteringOrganizationName = freezed,Object? inviteError = null,Object? isLoggingOut = null,}) {
  return _then(OrganizationChoiceState(
signedInEmail: freezed == signedInEmail ? _self.signedInEmail : signedInEmail // ignore: cast_nullable_to_non_nullable
as String?,noAccessReason: freezed == noAccessReason ? _self.noAccessReason : noAccessReason // ignore: cast_nullable_to_non_nullable
as String?,organizationChoices: null == organizationChoices ? _self.organizationChoices : organizationChoices // ignore: cast_nullable_to_non_nullable
as List<OrganizationBinding>,pendingInvites: null == pendingInvites ? _self.pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<Invite>,enteringOrganizationName: freezed == enteringOrganizationName ? _self.enteringOrganizationName : enteringOrganizationName // ignore: cast_nullable_to_non_nullable
as String?,inviteError: null == inviteError ? _self.inviteError : inviteError // ignore: cast_nullable_to_non_nullable
as String,isLoggingOut: null == isLoggingOut ? _self.isLoggingOut : isLoggingOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrganizationChoiceState].
extension OrganizationChoiceStatePatterns on OrganizationChoiceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrganizationChoiceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrganizationChoiceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrganizationChoiceState value)  $default,){
final _that = this;
switch (_that) {
case _OrganizationChoiceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrganizationChoiceState value)?  $default,){
final _that = this;
switch (_that) {
case _OrganizationChoiceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? signedInEmail,  String? noAccessReason,  List<OrganizationBinding> organizationChoices,  List<Invite> pendingInvites,  String? enteringOrganizationName,  String inviteError,  bool isLoggingOut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrganizationChoiceState() when $default != null:
return $default(_that.signedInEmail,_that.noAccessReason,_that.organizationChoices,_that.pendingInvites,_that.enteringOrganizationName,_that.inviteError,_that.isLoggingOut);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? signedInEmail,  String? noAccessReason,  List<OrganizationBinding> organizationChoices,  List<Invite> pendingInvites,  String? enteringOrganizationName,  String inviteError,  bool isLoggingOut)  $default,) {final _that = this;
switch (_that) {
case _OrganizationChoiceState():
return $default(_that.signedInEmail,_that.noAccessReason,_that.organizationChoices,_that.pendingInvites,_that.enteringOrganizationName,_that.inviteError,_that.isLoggingOut);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? signedInEmail,  String? noAccessReason,  List<OrganizationBinding> organizationChoices,  List<Invite> pendingInvites,  String? enteringOrganizationName,  String inviteError,  bool isLoggingOut)?  $default,) {final _that = this;
switch (_that) {
case _OrganizationChoiceState() when $default != null:
return $default(_that.signedInEmail,_that.noAccessReason,_that.organizationChoices,_that.pendingInvites,_that.enteringOrganizationName,_that.inviteError,_that.isLoggingOut);case _:
  return null;

}
}

}

/// @nodoc


class _OrganizationChoiceState implements OrganizationChoiceState {
  const _OrganizationChoiceState({this.signedInEmail, this.noAccessReason,  List<OrganizationBinding> organizationChoices = const [],  List<Invite> pendingInvites = const [], this.enteringOrganizationName, this.inviteError = '', this.isLoggingOut = false}): _organizationChoices = organizationChoices,_pendingInvites = pendingInvites;
  

/// E-mail of the Google account signed in to MonAmie (central project),
/// shown with "Trocar".
@override final  String? signedInEmail;
/// Why the person is on *Sem organização* after trying to enter an
/// organization (no membership there any more); `null` otherwise.
@override final  String? noAccessReason;
/// Organizations offered by the picker; none on *Sem organização*.
 final  List<OrganizationBinding> _organizationChoices;
/// Organizations offered by the picker; none on *Sem organização*.
@override@JsonKey() List<OrganizationBinding> get organizationChoices {
  if (_organizationChoices is EqualUnmodifiableListView) return _organizationChoices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_organizationChoices);
}

/// Invites waiting for the signed-in account.
 final  List<Invite> _pendingInvites;
/// Invites waiting for the signed-in account.
@override@JsonKey() List<Invite> get pendingInvites {
  if (_pendingInvites is EqualUnmodifiableListView) return _pendingInvites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingInvites);
}

/// Name of the organization being entered, for its spinner.
@override final  String? enteringOrganizationName;
/// Error of the last accept, shown on the invite card.
@override@JsonKey() final  String inviteError;
/// Whether a sign-out runs.
@override@JsonKey() final  bool isLoggingOut;

/// Create a copy of OrganizationChoiceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationChoiceStateCopyWith<_OrganizationChoiceState> get copyWith => __$OrganizationChoiceStateCopyWithImpl<_OrganizationChoiceState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationChoiceState&&(identical(other.signedInEmail, signedInEmail) || other.signedInEmail == signedInEmail)&&(identical(other.noAccessReason, noAccessReason) || other.noAccessReason == noAccessReason)&&const DeepCollectionEquality().equals(other.organizationChoices, _organizationChoices)&&const DeepCollectionEquality().equals(other.pendingInvites, _pendingInvites)&&(identical(other.enteringOrganizationName, enteringOrganizationName) || other.enteringOrganizationName == enteringOrganizationName)&&(identical(other.inviteError, inviteError) || other.inviteError == inviteError)&&(identical(other.isLoggingOut, isLoggingOut) || other.isLoggingOut == isLoggingOut));
}


@override
int get hashCode {
    return Object.hash(runtimeType,signedInEmail,noAccessReason,const DeepCollectionEquality().hash(_organizationChoices),const DeepCollectionEquality().hash(_pendingInvites),enteringOrganizationName,inviteError,isLoggingOut);
}

@override
String toString() {
    return 'OrganizationChoiceState(signedInEmail: $signedInEmail, noAccessReason: $noAccessReason, organizationChoices: $organizationChoices, pendingInvites: $pendingInvites, enteringOrganizationName: $enteringOrganizationName, inviteError: $inviteError, isLoggingOut: $isLoggingOut)';
}


}

/// @nodoc
abstract mixin class _$OrganizationChoiceStateCopyWith<$Res> implements $OrganizationChoiceStateCopyWith<$Res> {
  factory _$OrganizationChoiceStateCopyWith(_OrganizationChoiceState value, $Res Function(_OrganizationChoiceState) _then) = __$OrganizationChoiceStateCopyWithImpl;
@override @useResult
$Res call({
 String? signedInEmail, String? noAccessReason, List<OrganizationBinding> organizationChoices, List<Invite> pendingInvites, String? enteringOrganizationName, String inviteError, bool isLoggingOut
});




}
/// @nodoc
class __$OrganizationChoiceStateCopyWithImpl<$Res>
    implements _$OrganizationChoiceStateCopyWith<$Res> {
  __$OrganizationChoiceStateCopyWithImpl(this._self, this._then);

  final _OrganizationChoiceState _self;
  final $Res Function(_OrganizationChoiceState) _then;

/// Create a copy of OrganizationChoiceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? signedInEmail = freezed,Object? noAccessReason = freezed,Object? organizationChoices = null,Object? pendingInvites = null,Object? enteringOrganizationName = freezed,Object? inviteError = null,Object? isLoggingOut = null,}) {
  return _then(_OrganizationChoiceState(
signedInEmail: freezed == signedInEmail ? _self.signedInEmail : signedInEmail // ignore: cast_nullable_to_non_nullable
as String?,noAccessReason: freezed == noAccessReason ? _self.noAccessReason : noAccessReason // ignore: cast_nullable_to_non_nullable
as String?,organizationChoices: null == organizationChoices ? _self._organizationChoices : organizationChoices // ignore: cast_nullable_to_non_nullable
as List<OrganizationBinding>,pendingInvites: null == pendingInvites ? _self._pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<Invite>,enteringOrganizationName: freezed == enteringOrganizationName ? _self.enteringOrganizationName : enteringOrganizationName // ignore: cast_nullable_to_non_nullable
as String?,inviteError: null == inviteError ? _self.inviteError : inviteError // ignore: cast_nullable_to_non_nullable
as String,isLoggingOut: null == isLoggingOut ? _self.isLoggingOut : isLoggingOut // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
