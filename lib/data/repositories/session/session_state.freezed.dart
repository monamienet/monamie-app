// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState()';
}


}

/// @nodoc
class $SessionStateCopyWith<$Res>  {
$SessionStateCopyWith(SessionState _, $Res Function(SessionState) __);
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionSignedOut value)?  signedOut,TResult Function( SessionNoOrganization value)?  noOrganization,TResult Function( SessionPicking value)?  picking,TResult Function( SessionDeletionPending value)?  deletionPending,TResult Function( SessionWelcome value)?  welcome,TResult Function( SessionBound value)?  bound,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionSignedOut() when signedOut != null:
return signedOut(_that);case SessionNoOrganization() when noOrganization != null:
return noOrganization(_that);case SessionPicking() when picking != null:
return picking(_that);case SessionDeletionPending() when deletionPending != null:
return deletionPending(_that);case SessionWelcome() when welcome != null:
return welcome(_that);case SessionBound() when bound != null:
return bound(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionSignedOut value)  signedOut,required TResult Function( SessionNoOrganization value)  noOrganization,required TResult Function( SessionPicking value)  picking,required TResult Function( SessionDeletionPending value)  deletionPending,required TResult Function( SessionWelcome value)  welcome,required TResult Function( SessionBound value)  bound,}){
final _that = this;
switch (_that) {
case SessionSignedOut():
return signedOut(_that);case SessionNoOrganization():
return noOrganization(_that);case SessionPicking():
return picking(_that);case SessionDeletionPending():
return deletionPending(_that);case SessionWelcome():
return welcome(_that);case SessionBound():
return bound(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionSignedOut value)?  signedOut,TResult? Function( SessionNoOrganization value)?  noOrganization,TResult? Function( SessionPicking value)?  picking,TResult? Function( SessionDeletionPending value)?  deletionPending,TResult? Function( SessionWelcome value)?  welcome,TResult? Function( SessionBound value)?  bound,}){
final _that = this;
switch (_that) {
case SessionSignedOut() when signedOut != null:
return signedOut(_that);case SessionNoOrganization() when noOrganization != null:
return noOrganization(_that);case SessionPicking() when picking != null:
return picking(_that);case SessionDeletionPending() when deletionPending != null:
return deletionPending(_that);case SessionWelcome() when welcome != null:
return welcome(_that);case SessionBound() when bound != null:
return bound(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  signedOut,TResult Function( String? reason,  List<Invite> invites)?  noOrganization,TResult Function( List<OrganizationBinding> choices,  List<Invite> invites)?  picking,TResult Function( AccountDeletion deletion)?  deletionPending,TResult Function( Invite invite)?  welcome,TResult Function()?  bound,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionSignedOut() when signedOut != null:
return signedOut();case SessionNoOrganization() when noOrganization != null:
return noOrganization(_that.reason,_that.invites);case SessionPicking() when picking != null:
return picking(_that.choices,_that.invites);case SessionDeletionPending() when deletionPending != null:
return deletionPending(_that.deletion);case SessionWelcome() when welcome != null:
return welcome(_that.invite);case SessionBound() when bound != null:
return bound();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  signedOut,required TResult Function( String? reason,  List<Invite> invites)  noOrganization,required TResult Function( List<OrganizationBinding> choices,  List<Invite> invites)  picking,required TResult Function( AccountDeletion deletion)  deletionPending,required TResult Function( Invite invite)  welcome,required TResult Function()  bound,}) {final _that = this;
switch (_that) {
case SessionSignedOut():
return signedOut();case SessionNoOrganization():
return noOrganization(_that.reason,_that.invites);case SessionPicking():
return picking(_that.choices,_that.invites);case SessionDeletionPending():
return deletionPending(_that.deletion);case SessionWelcome():
return welcome(_that.invite);case SessionBound():
return bound();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  signedOut,TResult? Function( String? reason,  List<Invite> invites)?  noOrganization,TResult? Function( List<OrganizationBinding> choices,  List<Invite> invites)?  picking,TResult? Function( AccountDeletion deletion)?  deletionPending,TResult? Function( Invite invite)?  welcome,TResult? Function()?  bound,}) {final _that = this;
switch (_that) {
case SessionSignedOut() when signedOut != null:
return signedOut();case SessionNoOrganization() when noOrganization != null:
return noOrganization(_that.reason,_that.invites);case SessionPicking() when picking != null:
return picking(_that.choices,_that.invites);case SessionDeletionPending() when deletionPending != null:
return deletionPending(_that.deletion);case SessionWelcome() when welcome != null:
return welcome(_that.invite);case SessionBound() when bound != null:
return bound();case _:
  return null;

}
}

}

/// @nodoc


class SessionSignedOut implements SessionState {
  const SessionSignedOut();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSignedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState.signedOut()';
}


}




/// @nodoc


class SessionNoOrganization implements SessionState {
  const SessionNoOrganization({this.reason,  List<Invite> invites = const []}): _invites = invites;
  

 final  String? reason;
 final  List<Invite> _invites;
@JsonKey() List<Invite> get invites {
  if (_invites is EqualUnmodifiableListView) return _invites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invites);
}


/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionNoOrganizationCopyWith<SessionNoOrganization> get copyWith => _$SessionNoOrganizationCopyWithImpl<SessionNoOrganization>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionNoOrganization&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.invites, _invites));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason,const DeepCollectionEquality().hash(_invites));
}

@override
String toString() {
    return 'SessionState.noOrganization(reason: $reason, invites: $invites)';
}


}

/// @nodoc
abstract mixin class $SessionNoOrganizationCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionNoOrganizationCopyWith(SessionNoOrganization value, $Res Function(SessionNoOrganization) _then) = _$SessionNoOrganizationCopyWithImpl;
@useResult
$Res call({
 String? reason, List<Invite> invites
});




}
/// @nodoc
class _$SessionNoOrganizationCopyWithImpl<$Res>
    implements $SessionNoOrganizationCopyWith<$Res> {
  _$SessionNoOrganizationCopyWithImpl(this._self, this._then);

  final SessionNoOrganization _self;
  final $Res Function(SessionNoOrganization) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = freezed,Object? invites = null,}) {
  return _then(SessionNoOrganization(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,invites: null == invites ? _self._invites : invites // ignore: cast_nullable_to_non_nullable
as List<Invite>,
  ));
}


}

/// @nodoc


class SessionPicking implements SessionState {
  const SessionPicking( List<OrganizationBinding> choices, { List<Invite> invites = const []}): _choices = choices,_invites = invites;
  

 final  List<OrganizationBinding> _choices;
 List<OrganizationBinding> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}

 final  List<Invite> _invites;
@JsonKey() List<Invite> get invites {
  if (_invites is EqualUnmodifiableListView) return _invites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_invites);
}


/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionPickingCopyWith<SessionPicking> get copyWith => _$SessionPickingCopyWithImpl<SessionPicking>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionPicking&&const DeepCollectionEquality().equals(other.choices, _choices)&&const DeepCollectionEquality().equals(other.invites, _invites));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_choices),const DeepCollectionEquality().hash(_invites));
}

@override
String toString() {
    return 'SessionState.picking(choices: $choices, invites: $invites)';
}


}

/// @nodoc
abstract mixin class $SessionPickingCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionPickingCopyWith(SessionPicking value, $Res Function(SessionPicking) _then) = _$SessionPickingCopyWithImpl;
@useResult
$Res call({
 List<OrganizationBinding> choices, List<Invite> invites
});




}
/// @nodoc
class _$SessionPickingCopyWithImpl<$Res>
    implements $SessionPickingCopyWith<$Res> {
  _$SessionPickingCopyWithImpl(this._self, this._then);

  final SessionPicking _self;
  final $Res Function(SessionPicking) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? choices = null,Object? invites = null,}) {
  return _then(SessionPicking(
null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<OrganizationBinding>,invites: null == invites ? _self._invites : invites // ignore: cast_nullable_to_non_nullable
as List<Invite>,
  ));
}


}

/// @nodoc


class SessionDeletionPending implements SessionState {
  const SessionDeletionPending(this.deletion);
  

 final  AccountDeletion deletion;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionDeletionPendingCopyWith<SessionDeletionPending> get copyWith => _$SessionDeletionPendingCopyWithImpl<SessionDeletionPending>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionDeletionPending&&(identical(other.deletion, deletion) || other.deletion == deletion));
}


@override
int get hashCode {
    return Object.hash(runtimeType,deletion);
}

@override
String toString() {
    return 'SessionState.deletionPending(deletion: $deletion)';
}


}

/// @nodoc
abstract mixin class $SessionDeletionPendingCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionDeletionPendingCopyWith(SessionDeletionPending value, $Res Function(SessionDeletionPending) _then) = _$SessionDeletionPendingCopyWithImpl;
@useResult
$Res call({
 AccountDeletion deletion
});


$AccountDeletionCopyWith<$Res> get deletion;

}
/// @nodoc
class _$SessionDeletionPendingCopyWithImpl<$Res>
    implements $SessionDeletionPendingCopyWith<$Res> {
  _$SessionDeletionPendingCopyWithImpl(this._self, this._then);

  final SessionDeletionPending _self;
  final $Res Function(SessionDeletionPending) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deletion = null,}) {
  return _then(SessionDeletionPending(
null == deletion ? _self.deletion : deletion // ignore: cast_nullable_to_non_nullable
as AccountDeletion,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountDeletionCopyWith<$Res> get deletion {
  
  return $AccountDeletionCopyWith<$Res>(_self.deletion, (value) {
    return _then(_self.copyWith(deletion: value));
  });
}
}

/// @nodoc


class SessionWelcome implements SessionState {
  const SessionWelcome(this.invite);
  

 final  Invite invite;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionWelcomeCopyWith<SessionWelcome> get copyWith => _$SessionWelcomeCopyWithImpl<SessionWelcome>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionWelcome&&(identical(other.invite, invite) || other.invite == invite));
}


@override
int get hashCode {
    return Object.hash(runtimeType,invite);
}

@override
String toString() {
    return 'SessionState.welcome(invite: $invite)';
}


}

/// @nodoc
abstract mixin class $SessionWelcomeCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionWelcomeCopyWith(SessionWelcome value, $Res Function(SessionWelcome) _then) = _$SessionWelcomeCopyWithImpl;
@useResult
$Res call({
 Invite invite
});


$InviteCopyWith<$Res> get invite;

}
/// @nodoc
class _$SessionWelcomeCopyWithImpl<$Res>
    implements $SessionWelcomeCopyWith<$Res> {
  _$SessionWelcomeCopyWithImpl(this._self, this._then);

  final SessionWelcome _self;
  final $Res Function(SessionWelcome) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? invite = null,}) {
  return _then(SessionWelcome(
null == invite ? _self.invite : invite // ignore: cast_nullable_to_non_nullable
as Invite,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InviteCopyWith<$Res> get invite {
  
  return $InviteCopyWith<$Res>(_self.invite, (value) {
    return _then(_self.copyWith(invite: value));
  });
}
}

/// @nodoc


class SessionBound implements SessionState {
  const SessionBound();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionBound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState.bound()';
}


}




// dart format on
