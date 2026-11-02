// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_google_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthGoogleState {

/// Where the sign-in flow stands.
 SessionState get session;/// Whether Google Sign-In finished initializing (or failed to).
 bool get googleReady;/// Whether a sign-in or an organization entry runs.
 bool get isLoading;/// The login button was tapped and the sign-in has not finished:
/// Google's account chooser may be open. Guards against a second tap
/// without showing [isLoading]'s "Procurando sua organização…", which
/// only makes sense once an account is chosen.
 bool get isChoosingAccount;/// Whether a sign-out (tracking stop and sign-out) or a change of
/// organization runs.
 bool get isLoggingOut;/// The busy operation is a change of organization, not a sign-out: both
/// set [isLoggingOut] (the lock and the overlay), and this decides the
/// overlay's message.
 bool get isSwitchingOrganization;/// Name of the organization being entered, for "Entrando em ...".
 String? get enteringOrganizationName;/// E-mail of the Google account signed in to MonAmie (central project),
/// shown on MonAmie's own screens with "Trocar".
 String? get signedInEmail;/// Why the person is on *Sem organização* after trying to enter an
/// organization (no membership there any more); `null` otherwise.
 String? get noAccessReason;/// The signed-in account's pending deletion, shown on *Em exclusão*.
 AccountDeletion? get accountDeletion; bool get cancellingDeletion;/// The deletion was cancelled: *Em exclusão* says everything is back.
 bool get deletionRestored; String get deletionError;/// Invites waiting for the signed-in account, shown on *Sem
/// organização* and *Escolher organização*.
 List<Invite> get pendingInvites;/// Id of the invite being accepted (its button shows the pending state).
 String? get acceptingInvite;/// Error of the last accept, shown on the invite card.
 String get inviteError;/// The invite just accepted: *Boas-vindas* is shown once, after
/// entering its organization.
 Invite? get welcome;/// Whether the signed-in user owns each organization read so far (by
/// id); cleared on sign-out. The owner-only menu entries
/// (*Administradores*) follow it.
 Map<String, bool> get ownership;
/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthGoogleStateCopyWith<AuthGoogleState> get copyWith => _$AuthGoogleStateCopyWithImpl<AuthGoogleState>(this as AuthGoogleState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AuthGoogleState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthGoogleState&&(identical(other.session, _this.session) || other.session == _this.session)&&(identical(other.googleReady, _this.googleReady) || other.googleReady == _this.googleReady)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.isChoosingAccount, _this.isChoosingAccount) || other.isChoosingAccount == _this.isChoosingAccount)&&(identical(other.isLoggingOut, _this.isLoggingOut) || other.isLoggingOut == _this.isLoggingOut)&&(identical(other.isSwitchingOrganization, _this.isSwitchingOrganization) || other.isSwitchingOrganization == _this.isSwitchingOrganization)&&(identical(other.enteringOrganizationName, _this.enteringOrganizationName) || other.enteringOrganizationName == _this.enteringOrganizationName)&&(identical(other.signedInEmail, _this.signedInEmail) || other.signedInEmail == _this.signedInEmail)&&(identical(other.noAccessReason, _this.noAccessReason) || other.noAccessReason == _this.noAccessReason)&&(identical(other.accountDeletion, _this.accountDeletion) || other.accountDeletion == _this.accountDeletion)&&(identical(other.cancellingDeletion, _this.cancellingDeletion) || other.cancellingDeletion == _this.cancellingDeletion)&&(identical(other.deletionRestored, _this.deletionRestored) || other.deletionRestored == _this.deletionRestored)&&(identical(other.deletionError, _this.deletionError) || other.deletionError == _this.deletionError)&&const DeepCollectionEquality().equals(other.pendingInvites, _this.pendingInvites)&&(identical(other.acceptingInvite, _this.acceptingInvite) || other.acceptingInvite == _this.acceptingInvite)&&(identical(other.inviteError, _this.inviteError) || other.inviteError == _this.inviteError)&&(identical(other.welcome, _this.welcome) || other.welcome == _this.welcome)&&const DeepCollectionEquality().equals(other.ownership, _this.ownership));
}


@override
int get hashCode {
  final _this = this as AuthGoogleState;
  return Object.hash(runtimeType,_this.session,_this.googleReady,_this.isLoading,_this.isChoosingAccount,_this.isLoggingOut,_this.isSwitchingOrganization,_this.enteringOrganizationName,_this.signedInEmail,_this.noAccessReason,_this.accountDeletion,_this.cancellingDeletion,_this.deletionRestored,_this.deletionError,const DeepCollectionEquality().hash(_this.pendingInvites),_this.acceptingInvite,_this.inviteError,_this.welcome,const DeepCollectionEquality().hash(_this.ownership));
}

@override
String toString() {
  final _this = this as AuthGoogleState;
  return 'AuthGoogleState(session: ${_this.session}, googleReady: ${_this.googleReady}, isLoading: ${_this.isLoading}, isChoosingAccount: ${_this.isChoosingAccount}, isLoggingOut: ${_this.isLoggingOut}, isSwitchingOrganization: ${_this.isSwitchingOrganization}, enteringOrganizationName: ${_this.enteringOrganizationName}, signedInEmail: ${_this.signedInEmail}, noAccessReason: ${_this.noAccessReason}, accountDeletion: ${_this.accountDeletion}, cancellingDeletion: ${_this.cancellingDeletion}, deletionRestored: ${_this.deletionRestored}, deletionError: ${_this.deletionError}, pendingInvites: ${_this.pendingInvites}, acceptingInvite: ${_this.acceptingInvite}, inviteError: ${_this.inviteError}, welcome: ${_this.welcome}, ownership: ${_this.ownership})';
}


}

/// @nodoc
abstract mixin class $AuthGoogleStateCopyWith<$Res>  {
  factory $AuthGoogleStateCopyWith(AuthGoogleState value, $Res Function(AuthGoogleState) _then) = _$AuthGoogleStateCopyWithImpl;
@useResult
$Res call({
 SessionState session, bool googleReady, bool isLoading, bool isChoosingAccount, bool isLoggingOut, bool isSwitchingOrganization, String? enteringOrganizationName, String? signedInEmail, String? noAccessReason, AccountDeletion? accountDeletion, bool cancellingDeletion, bool deletionRestored, String deletionError, List<Invite> pendingInvites, String? acceptingInvite, String inviteError, Invite? welcome, Map<String, bool> ownership
});


$SessionStateCopyWith<$Res> get session;$AccountDeletionCopyWith<$Res>? get accountDeletion;$InviteCopyWith<$Res>? get welcome;

}
/// @nodoc
class _$AuthGoogleStateCopyWithImpl<$Res>
    implements $AuthGoogleStateCopyWith<$Res> {
  _$AuthGoogleStateCopyWithImpl(this._self, this._then);

  final AuthGoogleState _self;
  final $Res Function(AuthGoogleState) _then;

/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? googleReady = null,Object? isLoading = null,Object? isChoosingAccount = null,Object? isLoggingOut = null,Object? isSwitchingOrganization = null,Object? enteringOrganizationName = freezed,Object? signedInEmail = freezed,Object? noAccessReason = freezed,Object? accountDeletion = freezed,Object? cancellingDeletion = null,Object? deletionRestored = null,Object? deletionError = null,Object? pendingInvites = null,Object? acceptingInvite = freezed,Object? inviteError = null,Object? welcome = freezed,Object? ownership = null,}) {
  return _then(AuthGoogleState(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SessionState,googleReady: null == googleReady ? _self.googleReady : googleReady // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isChoosingAccount: null == isChoosingAccount ? _self.isChoosingAccount : isChoosingAccount // ignore: cast_nullable_to_non_nullable
as bool,isLoggingOut: null == isLoggingOut ? _self.isLoggingOut : isLoggingOut // ignore: cast_nullable_to_non_nullable
as bool,isSwitchingOrganization: null == isSwitchingOrganization ? _self.isSwitchingOrganization : isSwitchingOrganization // ignore: cast_nullable_to_non_nullable
as bool,enteringOrganizationName: freezed == enteringOrganizationName ? _self.enteringOrganizationName : enteringOrganizationName // ignore: cast_nullable_to_non_nullable
as String?,signedInEmail: freezed == signedInEmail ? _self.signedInEmail : signedInEmail // ignore: cast_nullable_to_non_nullable
as String?,noAccessReason: freezed == noAccessReason ? _self.noAccessReason : noAccessReason // ignore: cast_nullable_to_non_nullable
as String?,accountDeletion: freezed == accountDeletion ? _self.accountDeletion : accountDeletion // ignore: cast_nullable_to_non_nullable
as AccountDeletion?,cancellingDeletion: null == cancellingDeletion ? _self.cancellingDeletion : cancellingDeletion // ignore: cast_nullable_to_non_nullable
as bool,deletionRestored: null == deletionRestored ? _self.deletionRestored : deletionRestored // ignore: cast_nullable_to_non_nullable
as bool,deletionError: null == deletionError ? _self.deletionError : deletionError // ignore: cast_nullable_to_non_nullable
as String,pendingInvites: null == pendingInvites ? _self.pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<Invite>,acceptingInvite: freezed == acceptingInvite ? _self.acceptingInvite : acceptingInvite // ignore: cast_nullable_to_non_nullable
as String?,inviteError: null == inviteError ? _self.inviteError : inviteError // ignore: cast_nullable_to_non_nullable
as String,welcome: freezed == welcome ? _self.welcome : welcome // ignore: cast_nullable_to_non_nullable
as Invite?,ownership: null == ownership ? _self.ownership : ownership // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}
/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionStateCopyWith<$Res> get session {
  
  return $SessionStateCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountDeletionCopyWith<$Res>? get accountDeletion {
    if (_self.accountDeletion == null) {
    return null;
  }

  return $AccountDeletionCopyWith<$Res>(_self.accountDeletion!, (value) {
    return _then(_self.copyWith(accountDeletion: value));
  });
}/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InviteCopyWith<$Res>? get welcome {
    if (_self.welcome == null) {
    return null;
  }

  return $InviteCopyWith<$Res>(_self.welcome!, (value) {
    return _then(_self.copyWith(welcome: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthGoogleState].
extension AuthGoogleStatePatterns on AuthGoogleState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthGoogleState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthGoogleState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthGoogleState value)  $default,){
final _that = this;
switch (_that) {
case _AuthGoogleState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthGoogleState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthGoogleState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SessionState session,  bool googleReady,  bool isLoading,  bool isChoosingAccount,  bool isLoggingOut,  bool isSwitchingOrganization,  String? enteringOrganizationName,  String? signedInEmail,  String? noAccessReason,  AccountDeletion? accountDeletion,  bool cancellingDeletion,  bool deletionRestored,  String deletionError,  List<Invite> pendingInvites,  String? acceptingInvite,  String inviteError,  Invite? welcome,  Map<String, bool> ownership)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthGoogleState() when $default != null:
return $default(_that.session,_that.googleReady,_that.isLoading,_that.isChoosingAccount,_that.isLoggingOut,_that.isSwitchingOrganization,_that.enteringOrganizationName,_that.signedInEmail,_that.noAccessReason,_that.accountDeletion,_that.cancellingDeletion,_that.deletionRestored,_that.deletionError,_that.pendingInvites,_that.acceptingInvite,_that.inviteError,_that.welcome,_that.ownership);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SessionState session,  bool googleReady,  bool isLoading,  bool isChoosingAccount,  bool isLoggingOut,  bool isSwitchingOrganization,  String? enteringOrganizationName,  String? signedInEmail,  String? noAccessReason,  AccountDeletion? accountDeletion,  bool cancellingDeletion,  bool deletionRestored,  String deletionError,  List<Invite> pendingInvites,  String? acceptingInvite,  String inviteError,  Invite? welcome,  Map<String, bool> ownership)  $default,) {final _that = this;
switch (_that) {
case _AuthGoogleState():
return $default(_that.session,_that.googleReady,_that.isLoading,_that.isChoosingAccount,_that.isLoggingOut,_that.isSwitchingOrganization,_that.enteringOrganizationName,_that.signedInEmail,_that.noAccessReason,_that.accountDeletion,_that.cancellingDeletion,_that.deletionRestored,_that.deletionError,_that.pendingInvites,_that.acceptingInvite,_that.inviteError,_that.welcome,_that.ownership);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SessionState session,  bool googleReady,  bool isLoading,  bool isChoosingAccount,  bool isLoggingOut,  bool isSwitchingOrganization,  String? enteringOrganizationName,  String? signedInEmail,  String? noAccessReason,  AccountDeletion? accountDeletion,  bool cancellingDeletion,  bool deletionRestored,  String deletionError,  List<Invite> pendingInvites,  String? acceptingInvite,  String inviteError,  Invite? welcome,  Map<String, bool> ownership)?  $default,) {final _that = this;
switch (_that) {
case _AuthGoogleState() when $default != null:
return $default(_that.session,_that.googleReady,_that.isLoading,_that.isChoosingAccount,_that.isLoggingOut,_that.isSwitchingOrganization,_that.enteringOrganizationName,_that.signedInEmail,_that.noAccessReason,_that.accountDeletion,_that.cancellingDeletion,_that.deletionRestored,_that.deletionError,_that.pendingInvites,_that.acceptingInvite,_that.inviteError,_that.welcome,_that.ownership);case _:
  return null;

}
}

}

/// @nodoc


class _AuthGoogleState extends AuthGoogleState {
  const _AuthGoogleState({this.session = const SessionState.signedOut(), this.googleReady = false, this.isLoading = false, this.isChoosingAccount = false, this.isLoggingOut = false, this.isSwitchingOrganization = false, this.enteringOrganizationName, this.signedInEmail, this.noAccessReason, this.accountDeletion, this.cancellingDeletion = false, this.deletionRestored = false, this.deletionError = '',  List<Invite> pendingInvites = const [], this.acceptingInvite, this.inviteError = '', this.welcome,  Map<String, bool> ownership = const {}}): _pendingInvites = pendingInvites,_ownership = ownership,super._();
  

/// Where the sign-in flow stands.
@override@JsonKey() final  SessionState session;
/// Whether Google Sign-In finished initializing (or failed to).
@override@JsonKey() final  bool googleReady;
/// Whether a sign-in or an organization entry runs.
@override@JsonKey() final  bool isLoading;
/// The login button was tapped and the sign-in has not finished:
/// Google's account chooser may be open. Guards against a second tap
/// without showing [isLoading]'s "Procurando sua organização…", which
/// only makes sense once an account is chosen.
@override@JsonKey() final  bool isChoosingAccount;
/// Whether a sign-out (tracking stop and sign-out) or a change of
/// organization runs.
@override@JsonKey() final  bool isLoggingOut;
/// The busy operation is a change of organization, not a sign-out: both
/// set [isLoggingOut] (the lock and the overlay), and this decides the
/// overlay's message.
@override@JsonKey() final  bool isSwitchingOrganization;
/// Name of the organization being entered, for "Entrando em ...".
@override final  String? enteringOrganizationName;
/// E-mail of the Google account signed in to MonAmie (central project),
/// shown on MonAmie's own screens with "Trocar".
@override final  String? signedInEmail;
/// Why the person is on *Sem organização* after trying to enter an
/// organization (no membership there any more); `null` otherwise.
@override final  String? noAccessReason;
/// The signed-in account's pending deletion, shown on *Em exclusão*.
@override final  AccountDeletion? accountDeletion;
@override@JsonKey() final  bool cancellingDeletion;
/// The deletion was cancelled: *Em exclusão* says everything is back.
@override@JsonKey() final  bool deletionRestored;
@override@JsonKey() final  String deletionError;
/// Invites waiting for the signed-in account, shown on *Sem
/// organização* and *Escolher organização*.
 final  List<Invite> _pendingInvites;
/// Invites waiting for the signed-in account, shown on *Sem
/// organização* and *Escolher organização*.
@override@JsonKey() List<Invite> get pendingInvites {
  if (_pendingInvites is EqualUnmodifiableListView) return _pendingInvites;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingInvites);
}

/// Id of the invite being accepted (its button shows the pending state).
@override final  String? acceptingInvite;
/// Error of the last accept, shown on the invite card.
@override@JsonKey() final  String inviteError;
/// The invite just accepted: *Boas-vindas* is shown once, after
/// entering its organization.
@override final  Invite? welcome;
/// Whether the signed-in user owns each organization read so far (by
/// id); cleared on sign-out. The owner-only menu entries
/// (*Administradores*) follow it.
 final  Map<String, bool> _ownership;
/// Whether the signed-in user owns each organization read so far (by
/// id); cleared on sign-out. The owner-only menu entries
/// (*Administradores*) follow it.
@override@JsonKey() Map<String, bool> get ownership {
  if (_ownership is EqualUnmodifiableMapView) return _ownership;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ownership);
}


/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthGoogleStateCopyWith<_AuthGoogleState> get copyWith => __$AuthGoogleStateCopyWithImpl<_AuthGoogleState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthGoogleState&&(identical(other.session, session) || other.session == session)&&(identical(other.googleReady, googleReady) || other.googleReady == googleReady)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isChoosingAccount, isChoosingAccount) || other.isChoosingAccount == isChoosingAccount)&&(identical(other.isLoggingOut, isLoggingOut) || other.isLoggingOut == isLoggingOut)&&(identical(other.isSwitchingOrganization, isSwitchingOrganization) || other.isSwitchingOrganization == isSwitchingOrganization)&&(identical(other.enteringOrganizationName, enteringOrganizationName) || other.enteringOrganizationName == enteringOrganizationName)&&(identical(other.signedInEmail, signedInEmail) || other.signedInEmail == signedInEmail)&&(identical(other.noAccessReason, noAccessReason) || other.noAccessReason == noAccessReason)&&(identical(other.accountDeletion, accountDeletion) || other.accountDeletion == accountDeletion)&&(identical(other.cancellingDeletion, cancellingDeletion) || other.cancellingDeletion == cancellingDeletion)&&(identical(other.deletionRestored, deletionRestored) || other.deletionRestored == deletionRestored)&&(identical(other.deletionError, deletionError) || other.deletionError == deletionError)&&const DeepCollectionEquality().equals(other.pendingInvites, _pendingInvites)&&(identical(other.acceptingInvite, acceptingInvite) || other.acceptingInvite == acceptingInvite)&&(identical(other.inviteError, inviteError) || other.inviteError == inviteError)&&(identical(other.welcome, welcome) || other.welcome == welcome)&&const DeepCollectionEquality().equals(other.ownership, _ownership));
}


@override
int get hashCode {
    return Object.hash(runtimeType,session,googleReady,isLoading,isChoosingAccount,isLoggingOut,isSwitchingOrganization,enteringOrganizationName,signedInEmail,noAccessReason,accountDeletion,cancellingDeletion,deletionRestored,deletionError,const DeepCollectionEquality().hash(_pendingInvites),acceptingInvite,inviteError,welcome,const DeepCollectionEquality().hash(_ownership));
}

@override
String toString() {
    return 'AuthGoogleState(session: $session, googleReady: $googleReady, isLoading: $isLoading, isChoosingAccount: $isChoosingAccount, isLoggingOut: $isLoggingOut, isSwitchingOrganization: $isSwitchingOrganization, enteringOrganizationName: $enteringOrganizationName, signedInEmail: $signedInEmail, noAccessReason: $noAccessReason, accountDeletion: $accountDeletion, cancellingDeletion: $cancellingDeletion, deletionRestored: $deletionRestored, deletionError: $deletionError, pendingInvites: $pendingInvites, acceptingInvite: $acceptingInvite, inviteError: $inviteError, welcome: $welcome, ownership: $ownership)';
}


}

/// @nodoc
abstract mixin class _$AuthGoogleStateCopyWith<$Res> implements $AuthGoogleStateCopyWith<$Res> {
  factory _$AuthGoogleStateCopyWith(_AuthGoogleState value, $Res Function(_AuthGoogleState) _then) = __$AuthGoogleStateCopyWithImpl;
@override @useResult
$Res call({
 SessionState session, bool googleReady, bool isLoading, bool isChoosingAccount, bool isLoggingOut, bool isSwitchingOrganization, String? enteringOrganizationName, String? signedInEmail, String? noAccessReason, AccountDeletion? accountDeletion, bool cancellingDeletion, bool deletionRestored, String deletionError, List<Invite> pendingInvites, String? acceptingInvite, String inviteError, Invite? welcome, Map<String, bool> ownership
});


@override $SessionStateCopyWith<$Res> get session;@override $AccountDeletionCopyWith<$Res>? get accountDeletion;@override $InviteCopyWith<$Res>? get welcome;

}
/// @nodoc
class __$AuthGoogleStateCopyWithImpl<$Res>
    implements _$AuthGoogleStateCopyWith<$Res> {
  __$AuthGoogleStateCopyWithImpl(this._self, this._then);

  final _AuthGoogleState _self;
  final $Res Function(_AuthGoogleState) _then;

/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? googleReady = null,Object? isLoading = null,Object? isChoosingAccount = null,Object? isLoggingOut = null,Object? isSwitchingOrganization = null,Object? enteringOrganizationName = freezed,Object? signedInEmail = freezed,Object? noAccessReason = freezed,Object? accountDeletion = freezed,Object? cancellingDeletion = null,Object? deletionRestored = null,Object? deletionError = null,Object? pendingInvites = null,Object? acceptingInvite = freezed,Object? inviteError = null,Object? welcome = freezed,Object? ownership = null,}) {
  return _then(_AuthGoogleState(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as SessionState,googleReady: null == googleReady ? _self.googleReady : googleReady // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isChoosingAccount: null == isChoosingAccount ? _self.isChoosingAccount : isChoosingAccount // ignore: cast_nullable_to_non_nullable
as bool,isLoggingOut: null == isLoggingOut ? _self.isLoggingOut : isLoggingOut // ignore: cast_nullable_to_non_nullable
as bool,isSwitchingOrganization: null == isSwitchingOrganization ? _self.isSwitchingOrganization : isSwitchingOrganization // ignore: cast_nullable_to_non_nullable
as bool,enteringOrganizationName: freezed == enteringOrganizationName ? _self.enteringOrganizationName : enteringOrganizationName // ignore: cast_nullable_to_non_nullable
as String?,signedInEmail: freezed == signedInEmail ? _self.signedInEmail : signedInEmail // ignore: cast_nullable_to_non_nullable
as String?,noAccessReason: freezed == noAccessReason ? _self.noAccessReason : noAccessReason // ignore: cast_nullable_to_non_nullable
as String?,accountDeletion: freezed == accountDeletion ? _self.accountDeletion : accountDeletion // ignore: cast_nullable_to_non_nullable
as AccountDeletion?,cancellingDeletion: null == cancellingDeletion ? _self.cancellingDeletion : cancellingDeletion // ignore: cast_nullable_to_non_nullable
as bool,deletionRestored: null == deletionRestored ? _self.deletionRestored : deletionRestored // ignore: cast_nullable_to_non_nullable
as bool,deletionError: null == deletionError ? _self.deletionError : deletionError // ignore: cast_nullable_to_non_nullable
as String,pendingInvites: null == pendingInvites ? _self._pendingInvites : pendingInvites // ignore: cast_nullable_to_non_nullable
as List<Invite>,acceptingInvite: freezed == acceptingInvite ? _self.acceptingInvite : acceptingInvite // ignore: cast_nullable_to_non_nullable
as String?,inviteError: null == inviteError ? _self.inviteError : inviteError // ignore: cast_nullable_to_non_nullable
as String,welcome: freezed == welcome ? _self.welcome : welcome // ignore: cast_nullable_to_non_nullable
as Invite?,ownership: null == ownership ? _self._ownership : ownership // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SessionStateCopyWith<$Res> get session {
  
  return $SessionStateCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccountDeletionCopyWith<$Res>? get accountDeletion {
    if (_self.accountDeletion == null) {
    return null;
  }

  return $AccountDeletionCopyWith<$Res>(_self.accountDeletion!, (value) {
    return _then(_self.copyWith(accountDeletion: value));
  });
}/// Create a copy of AuthGoogleState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InviteCopyWith<$Res>? get welcome {
    if (_self.welcome == null) {
    return null;
  }

  return $InviteCopyWith<$Res>(_self.welcome!, (value) {
    return _then(_self.copyWith(welcome: value));
  });
}
}

// dart format on
