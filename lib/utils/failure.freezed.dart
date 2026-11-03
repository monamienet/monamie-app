// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Failure {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Failure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure()';
}


}

/// @nodoc
class $FailureCopyWith<$Res>  {
$FailureCopyWith(Failure _, $Res Function(Failure) __);
}


/// Adds pattern-matching-related methods to [Failure].
extension FailurePatterns on Failure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ConnectionFailure value)?  connection,TResult Function( LoadFailure value)?  load,TResult Function( ServerRefusal value)?  serverRefusal,TResult Function( UnexplainedRefusal value)?  unexplainedRefusal,TResult Function( UnexpectedResponse value)?  unexpectedResponse,TResult Function( OrganizationIdFailure value)?  organizationId,TResult Function( GroupNameTooShort value)?  groupNameTooShort,TResult Function( GroupNameTooLong value)?  groupNameTooLong,TResult Function( GroupNameTaken value)?  groupNameTaken,TResult Function( NoRoleChosen value)?  noRoleChosen,TResult Function( InvalidEmail value)?  invalidEmail,TResult Function( EmailAlreadyListed value)?  emailAlreadyListed,TResult Function( LogoTooLarge value)?  logoTooLarge,TResult Function( LogoUnreadable value)?  logoUnreadable,TResult Function( LogoNotConverted value)?  logoNotConverted,TResult Function( LogoNotOpened value)?  logoNotOpened,TResult Function( EntryFailure value)?  entry,TResult Function( OrganizationEntryFailure value)?  organizationEntry,TResult Function( GoogleAuthFailure value)?  googleAuth,TResult Function( GoogleRenewalFailure value)?  googleRenewal,TResult Function( SignOutFailure value)?  signOut,TResult Function( AccessLost value)?  accessLost,TResult Function( RemovedFromOrganization value)?  removedFromOrganization,TResult Function( SharingNotAllowed value)?  sharingNotAllowed,TResult Function( SharingNotChanged value)?  sharingNotChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ConnectionFailure() when connection != null:
return connection(_that);case LoadFailure() when load != null:
return load(_that);case ServerRefusal() when serverRefusal != null:
return serverRefusal(_that);case UnexplainedRefusal() when unexplainedRefusal != null:
return unexplainedRefusal(_that);case UnexpectedResponse() when unexpectedResponse != null:
return unexpectedResponse(_that);case OrganizationIdFailure() when organizationId != null:
return organizationId(_that);case GroupNameTooShort() when groupNameTooShort != null:
return groupNameTooShort(_that);case GroupNameTooLong() when groupNameTooLong != null:
return groupNameTooLong(_that);case GroupNameTaken() when groupNameTaken != null:
return groupNameTaken(_that);case NoRoleChosen() when noRoleChosen != null:
return noRoleChosen(_that);case InvalidEmail() when invalidEmail != null:
return invalidEmail(_that);case EmailAlreadyListed() when emailAlreadyListed != null:
return emailAlreadyListed(_that);case LogoTooLarge() when logoTooLarge != null:
return logoTooLarge(_that);case LogoUnreadable() when logoUnreadable != null:
return logoUnreadable(_that);case LogoNotConverted() when logoNotConverted != null:
return logoNotConverted(_that);case LogoNotOpened() when logoNotOpened != null:
return logoNotOpened(_that);case EntryFailure() when entry != null:
return entry(_that);case OrganizationEntryFailure() when organizationEntry != null:
return organizationEntry(_that);case GoogleAuthFailure() when googleAuth != null:
return googleAuth(_that);case GoogleRenewalFailure() when googleRenewal != null:
return googleRenewal(_that);case SignOutFailure() when signOut != null:
return signOut(_that);case AccessLost() when accessLost != null:
return accessLost(_that);case RemovedFromOrganization() when removedFromOrganization != null:
return removedFromOrganization(_that);case SharingNotAllowed() when sharingNotAllowed != null:
return sharingNotAllowed(_that);case SharingNotChanged() when sharingNotChanged != null:
return sharingNotChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ConnectionFailure value)  connection,required TResult Function( LoadFailure value)  load,required TResult Function( ServerRefusal value)  serverRefusal,required TResult Function( UnexplainedRefusal value)  unexplainedRefusal,required TResult Function( UnexpectedResponse value)  unexpectedResponse,required TResult Function( OrganizationIdFailure value)  organizationId,required TResult Function( GroupNameTooShort value)  groupNameTooShort,required TResult Function( GroupNameTooLong value)  groupNameTooLong,required TResult Function( GroupNameTaken value)  groupNameTaken,required TResult Function( NoRoleChosen value)  noRoleChosen,required TResult Function( InvalidEmail value)  invalidEmail,required TResult Function( EmailAlreadyListed value)  emailAlreadyListed,required TResult Function( LogoTooLarge value)  logoTooLarge,required TResult Function( LogoUnreadable value)  logoUnreadable,required TResult Function( LogoNotConverted value)  logoNotConverted,required TResult Function( LogoNotOpened value)  logoNotOpened,required TResult Function( EntryFailure value)  entry,required TResult Function( OrganizationEntryFailure value)  organizationEntry,required TResult Function( GoogleAuthFailure value)  googleAuth,required TResult Function( GoogleRenewalFailure value)  googleRenewal,required TResult Function( SignOutFailure value)  signOut,required TResult Function( AccessLost value)  accessLost,required TResult Function( RemovedFromOrganization value)  removedFromOrganization,required TResult Function( SharingNotAllowed value)  sharingNotAllowed,required TResult Function( SharingNotChanged value)  sharingNotChanged,}){
final _that = this;
switch (_that) {
case ConnectionFailure():
return connection(_that);case LoadFailure():
return load(_that);case ServerRefusal():
return serverRefusal(_that);case UnexplainedRefusal():
return unexplainedRefusal(_that);case UnexpectedResponse():
return unexpectedResponse(_that);case OrganizationIdFailure():
return organizationId(_that);case GroupNameTooShort():
return groupNameTooShort(_that);case GroupNameTooLong():
return groupNameTooLong(_that);case GroupNameTaken():
return groupNameTaken(_that);case NoRoleChosen():
return noRoleChosen(_that);case InvalidEmail():
return invalidEmail(_that);case EmailAlreadyListed():
return emailAlreadyListed(_that);case LogoTooLarge():
return logoTooLarge(_that);case LogoUnreadable():
return logoUnreadable(_that);case LogoNotConverted():
return logoNotConverted(_that);case LogoNotOpened():
return logoNotOpened(_that);case EntryFailure():
return entry(_that);case OrganizationEntryFailure():
return organizationEntry(_that);case GoogleAuthFailure():
return googleAuth(_that);case GoogleRenewalFailure():
return googleRenewal(_that);case SignOutFailure():
return signOut(_that);case AccessLost():
return accessLost(_that);case RemovedFromOrganization():
return removedFromOrganization(_that);case SharingNotAllowed():
return sharingNotAllowed(_that);case SharingNotChanged():
return sharingNotChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ConnectionFailure value)?  connection,TResult? Function( LoadFailure value)?  load,TResult? Function( ServerRefusal value)?  serverRefusal,TResult? Function( UnexplainedRefusal value)?  unexplainedRefusal,TResult? Function( UnexpectedResponse value)?  unexpectedResponse,TResult? Function( OrganizationIdFailure value)?  organizationId,TResult? Function( GroupNameTooShort value)?  groupNameTooShort,TResult? Function( GroupNameTooLong value)?  groupNameTooLong,TResult? Function( GroupNameTaken value)?  groupNameTaken,TResult? Function( NoRoleChosen value)?  noRoleChosen,TResult? Function( InvalidEmail value)?  invalidEmail,TResult? Function( EmailAlreadyListed value)?  emailAlreadyListed,TResult? Function( LogoTooLarge value)?  logoTooLarge,TResult? Function( LogoUnreadable value)?  logoUnreadable,TResult? Function( LogoNotConverted value)?  logoNotConverted,TResult? Function( LogoNotOpened value)?  logoNotOpened,TResult? Function( EntryFailure value)?  entry,TResult? Function( OrganizationEntryFailure value)?  organizationEntry,TResult? Function( GoogleAuthFailure value)?  googleAuth,TResult? Function( GoogleRenewalFailure value)?  googleRenewal,TResult? Function( SignOutFailure value)?  signOut,TResult? Function( AccessLost value)?  accessLost,TResult? Function( RemovedFromOrganization value)?  removedFromOrganization,TResult? Function( SharingNotAllowed value)?  sharingNotAllowed,TResult? Function( SharingNotChanged value)?  sharingNotChanged,}){
final _that = this;
switch (_that) {
case ConnectionFailure() when connection != null:
return connection(_that);case LoadFailure() when load != null:
return load(_that);case ServerRefusal() when serverRefusal != null:
return serverRefusal(_that);case UnexplainedRefusal() when unexplainedRefusal != null:
return unexplainedRefusal(_that);case UnexpectedResponse() when unexpectedResponse != null:
return unexpectedResponse(_that);case OrganizationIdFailure() when organizationId != null:
return organizationId(_that);case GroupNameTooShort() when groupNameTooShort != null:
return groupNameTooShort(_that);case GroupNameTooLong() when groupNameTooLong != null:
return groupNameTooLong(_that);case GroupNameTaken() when groupNameTaken != null:
return groupNameTaken(_that);case NoRoleChosen() when noRoleChosen != null:
return noRoleChosen(_that);case InvalidEmail() when invalidEmail != null:
return invalidEmail(_that);case EmailAlreadyListed() when emailAlreadyListed != null:
return emailAlreadyListed(_that);case LogoTooLarge() when logoTooLarge != null:
return logoTooLarge(_that);case LogoUnreadable() when logoUnreadable != null:
return logoUnreadable(_that);case LogoNotConverted() when logoNotConverted != null:
return logoNotConverted(_that);case LogoNotOpened() when logoNotOpened != null:
return logoNotOpened(_that);case EntryFailure() when entry != null:
return entry(_that);case OrganizationEntryFailure() when organizationEntry != null:
return organizationEntry(_that);case GoogleAuthFailure() when googleAuth != null:
return googleAuth(_that);case GoogleRenewalFailure() when googleRenewal != null:
return googleRenewal(_that);case SignOutFailure() when signOut != null:
return signOut(_that);case AccessLost() when accessLost != null:
return accessLost(_that);case RemovedFromOrganization() when removedFromOrganization != null:
return removedFromOrganization(_that);case SharingNotAllowed() when sharingNotAllowed != null:
return sharingNotAllowed(_that);case SharingNotChanged() when sharingNotChanged != null:
return sharingNotChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( FailedAction action)?  connection,TResult Function( LoadTarget target)?  load,TResult Function( String serverMessage)?  serverRefusal,TResult Function( RefusedAction action)?  unexplainedRefusal,TResult Function( bool creatingGroup)?  unexpectedResponse,TResult Function( OrganizationIdProblem problem,  int maxLength)?  organizationId,TResult Function()?  groupNameTooShort,TResult Function()?  groupNameTooLong,TResult Function( String existingName)?  groupNameTaken,TResult Function()?  noRoleChosen,TResult Function()?  invalidEmail,TResult Function( String email)?  emailAlreadyListed,TResult Function( int megabytes)?  logoTooLarge,TResult Function()?  logoUnreadable,TResult Function()?  logoNotConverted,TResult Function()?  logoNotOpened,TResult Function( EntryStage stage,  String detail)?  entry,TResult Function( String organizationName,  String detail)?  organizationEntry,TResult Function()?  googleAuth,TResult Function()?  googleRenewal,TResult Function( String detail)?  signOut,TResult Function( String organizationName)?  accessLost,TResult Function( String? organizationName)?  removedFromOrganization,TResult Function()?  sharingNotAllowed,TResult Function()?  sharingNotChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ConnectionFailure() when connection != null:
return connection(_that.action);case LoadFailure() when load != null:
return load(_that.target);case ServerRefusal() when serverRefusal != null:
return serverRefusal(_that.serverMessage);case UnexplainedRefusal() when unexplainedRefusal != null:
return unexplainedRefusal(_that.action);case UnexpectedResponse() when unexpectedResponse != null:
return unexpectedResponse(_that.creatingGroup);case OrganizationIdFailure() when organizationId != null:
return organizationId(_that.problem,_that.maxLength);case GroupNameTooShort() when groupNameTooShort != null:
return groupNameTooShort();case GroupNameTooLong() when groupNameTooLong != null:
return groupNameTooLong();case GroupNameTaken() when groupNameTaken != null:
return groupNameTaken(_that.existingName);case NoRoleChosen() when noRoleChosen != null:
return noRoleChosen();case InvalidEmail() when invalidEmail != null:
return invalidEmail();case EmailAlreadyListed() when emailAlreadyListed != null:
return emailAlreadyListed(_that.email);case LogoTooLarge() when logoTooLarge != null:
return logoTooLarge(_that.megabytes);case LogoUnreadable() when logoUnreadable != null:
return logoUnreadable();case LogoNotConverted() when logoNotConverted != null:
return logoNotConverted();case LogoNotOpened() when logoNotOpened != null:
return logoNotOpened();case EntryFailure() when entry != null:
return entry(_that.stage,_that.detail);case OrganizationEntryFailure() when organizationEntry != null:
return organizationEntry(_that.organizationName,_that.detail);case GoogleAuthFailure() when googleAuth != null:
return googleAuth();case GoogleRenewalFailure() when googleRenewal != null:
return googleRenewal();case SignOutFailure() when signOut != null:
return signOut(_that.detail);case AccessLost() when accessLost != null:
return accessLost(_that.organizationName);case RemovedFromOrganization() when removedFromOrganization != null:
return removedFromOrganization(_that.organizationName);case SharingNotAllowed() when sharingNotAllowed != null:
return sharingNotAllowed();case SharingNotChanged() when sharingNotChanged != null:
return sharingNotChanged();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( FailedAction action)  connection,required TResult Function( LoadTarget target)  load,required TResult Function( String serverMessage)  serverRefusal,required TResult Function( RefusedAction action)  unexplainedRefusal,required TResult Function( bool creatingGroup)  unexpectedResponse,required TResult Function( OrganizationIdProblem problem,  int maxLength)  organizationId,required TResult Function()  groupNameTooShort,required TResult Function()  groupNameTooLong,required TResult Function( String existingName)  groupNameTaken,required TResult Function()  noRoleChosen,required TResult Function()  invalidEmail,required TResult Function( String email)  emailAlreadyListed,required TResult Function( int megabytes)  logoTooLarge,required TResult Function()  logoUnreadable,required TResult Function()  logoNotConverted,required TResult Function()  logoNotOpened,required TResult Function( EntryStage stage,  String detail)  entry,required TResult Function( String organizationName,  String detail)  organizationEntry,required TResult Function()  googleAuth,required TResult Function()  googleRenewal,required TResult Function( String detail)  signOut,required TResult Function( String organizationName)  accessLost,required TResult Function( String? organizationName)  removedFromOrganization,required TResult Function()  sharingNotAllowed,required TResult Function()  sharingNotChanged,}) {final _that = this;
switch (_that) {
case ConnectionFailure():
return connection(_that.action);case LoadFailure():
return load(_that.target);case ServerRefusal():
return serverRefusal(_that.serverMessage);case UnexplainedRefusal():
return unexplainedRefusal(_that.action);case UnexpectedResponse():
return unexpectedResponse(_that.creatingGroup);case OrganizationIdFailure():
return organizationId(_that.problem,_that.maxLength);case GroupNameTooShort():
return groupNameTooShort();case GroupNameTooLong():
return groupNameTooLong();case GroupNameTaken():
return groupNameTaken(_that.existingName);case NoRoleChosen():
return noRoleChosen();case InvalidEmail():
return invalidEmail();case EmailAlreadyListed():
return emailAlreadyListed(_that.email);case LogoTooLarge():
return logoTooLarge(_that.megabytes);case LogoUnreadable():
return logoUnreadable();case LogoNotConverted():
return logoNotConverted();case LogoNotOpened():
return logoNotOpened();case EntryFailure():
return entry(_that.stage,_that.detail);case OrganizationEntryFailure():
return organizationEntry(_that.organizationName,_that.detail);case GoogleAuthFailure():
return googleAuth();case GoogleRenewalFailure():
return googleRenewal();case SignOutFailure():
return signOut(_that.detail);case AccessLost():
return accessLost(_that.organizationName);case RemovedFromOrganization():
return removedFromOrganization(_that.organizationName);case SharingNotAllowed():
return sharingNotAllowed();case SharingNotChanged():
return sharingNotChanged();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( FailedAction action)?  connection,TResult? Function( LoadTarget target)?  load,TResult? Function( String serverMessage)?  serverRefusal,TResult? Function( RefusedAction action)?  unexplainedRefusal,TResult? Function( bool creatingGroup)?  unexpectedResponse,TResult? Function( OrganizationIdProblem problem,  int maxLength)?  organizationId,TResult? Function()?  groupNameTooShort,TResult? Function()?  groupNameTooLong,TResult? Function( String existingName)?  groupNameTaken,TResult? Function()?  noRoleChosen,TResult? Function()?  invalidEmail,TResult? Function( String email)?  emailAlreadyListed,TResult? Function( int megabytes)?  logoTooLarge,TResult? Function()?  logoUnreadable,TResult? Function()?  logoNotConverted,TResult? Function()?  logoNotOpened,TResult? Function( EntryStage stage,  String detail)?  entry,TResult? Function( String organizationName,  String detail)?  organizationEntry,TResult? Function()?  googleAuth,TResult? Function()?  googleRenewal,TResult? Function( String detail)?  signOut,TResult? Function( String organizationName)?  accessLost,TResult? Function( String? organizationName)?  removedFromOrganization,TResult? Function()?  sharingNotAllowed,TResult? Function()?  sharingNotChanged,}) {final _that = this;
switch (_that) {
case ConnectionFailure() when connection != null:
return connection(_that.action);case LoadFailure() when load != null:
return load(_that.target);case ServerRefusal() when serverRefusal != null:
return serverRefusal(_that.serverMessage);case UnexplainedRefusal() when unexplainedRefusal != null:
return unexplainedRefusal(_that.action);case UnexpectedResponse() when unexpectedResponse != null:
return unexpectedResponse(_that.creatingGroup);case OrganizationIdFailure() when organizationId != null:
return organizationId(_that.problem,_that.maxLength);case GroupNameTooShort() when groupNameTooShort != null:
return groupNameTooShort();case GroupNameTooLong() when groupNameTooLong != null:
return groupNameTooLong();case GroupNameTaken() when groupNameTaken != null:
return groupNameTaken(_that.existingName);case NoRoleChosen() when noRoleChosen != null:
return noRoleChosen();case InvalidEmail() when invalidEmail != null:
return invalidEmail();case EmailAlreadyListed() when emailAlreadyListed != null:
return emailAlreadyListed(_that.email);case LogoTooLarge() when logoTooLarge != null:
return logoTooLarge(_that.megabytes);case LogoUnreadable() when logoUnreadable != null:
return logoUnreadable();case LogoNotConverted() when logoNotConverted != null:
return logoNotConverted();case LogoNotOpened() when logoNotOpened != null:
return logoNotOpened();case EntryFailure() when entry != null:
return entry(_that.stage,_that.detail);case OrganizationEntryFailure() when organizationEntry != null:
return organizationEntry(_that.organizationName,_that.detail);case GoogleAuthFailure() when googleAuth != null:
return googleAuth();case GoogleRenewalFailure() when googleRenewal != null:
return googleRenewal();case SignOutFailure() when signOut != null:
return signOut(_that.detail);case AccessLost() when accessLost != null:
return accessLost(_that.organizationName);case RemovedFromOrganization() when removedFromOrganization != null:
return removedFromOrganization(_that.organizationName);case SharingNotAllowed() when sharingNotAllowed != null:
return sharingNotAllowed();case SharingNotChanged() when sharingNotChanged != null:
return sharingNotChanged();case _:
  return null;

}
}

}

/// @nodoc


class ConnectionFailure implements Failure {
  const ConnectionFailure(this.action);
  

 final  FailedAction action;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConnectionFailureCopyWith<ConnectionFailure> get copyWith => _$ConnectionFailureCopyWithImpl<ConnectionFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ConnectionFailure&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode {
    return Object.hash(runtimeType,action);
}

@override
String toString() {
    return 'Failure.connection(action: $action)';
}


}

/// @nodoc
abstract mixin class $ConnectionFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ConnectionFailureCopyWith(ConnectionFailure value, $Res Function(ConnectionFailure) _then) = _$ConnectionFailureCopyWithImpl;
@useResult
$Res call({
 FailedAction action
});




}
/// @nodoc
class _$ConnectionFailureCopyWithImpl<$Res>
    implements $ConnectionFailureCopyWith<$Res> {
  _$ConnectionFailureCopyWithImpl(this._self, this._then);

  final ConnectionFailure _self;
  final $Res Function(ConnectionFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(ConnectionFailure(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as FailedAction,
  ));
}


}

/// @nodoc


class LoadFailure implements Failure {
  const LoadFailure(this.target);
  

 final  LoadTarget target;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadFailureCopyWith<LoadFailure> get copyWith => _$LoadFailureCopyWithImpl<LoadFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadFailure&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode {
    return Object.hash(runtimeType,target);
}

@override
String toString() {
    return 'Failure.load(target: $target)';
}


}

/// @nodoc
abstract mixin class $LoadFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $LoadFailureCopyWith(LoadFailure value, $Res Function(LoadFailure) _then) = _$LoadFailureCopyWithImpl;
@useResult
$Res call({
 LoadTarget target
});




}
/// @nodoc
class _$LoadFailureCopyWithImpl<$Res>
    implements $LoadFailureCopyWith<$Res> {
  _$LoadFailureCopyWithImpl(this._self, this._then);

  final LoadFailure _self;
  final $Res Function(LoadFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(LoadFailure(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as LoadTarget,
  ));
}


}

/// @nodoc


class ServerRefusal implements Failure {
  const ServerRefusal(this.serverMessage);
  

 final  String serverMessage;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerRefusalCopyWith<ServerRefusal> get copyWith => _$ServerRefusalCopyWithImpl<ServerRefusal>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerRefusal&&(identical(other.serverMessage, serverMessage) || other.serverMessage == serverMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,serverMessage);
}

@override
String toString() {
    return 'Failure.serverRefusal(serverMessage: $serverMessage)';
}


}

/// @nodoc
abstract mixin class $ServerRefusalCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $ServerRefusalCopyWith(ServerRefusal value, $Res Function(ServerRefusal) _then) = _$ServerRefusalCopyWithImpl;
@useResult
$Res call({
 String serverMessage
});




}
/// @nodoc
class _$ServerRefusalCopyWithImpl<$Res>
    implements $ServerRefusalCopyWith<$Res> {
  _$ServerRefusalCopyWithImpl(this._self, this._then);

  final ServerRefusal _self;
  final $Res Function(ServerRefusal) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? serverMessage = null,}) {
  return _then(ServerRefusal(
null == serverMessage ? _self.serverMessage : serverMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnexplainedRefusal implements Failure {
  const UnexplainedRefusal(this.action);
  

 final  RefusedAction action;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnexplainedRefusalCopyWith<UnexplainedRefusal> get copyWith => _$UnexplainedRefusalCopyWithImpl<UnexplainedRefusal>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnexplainedRefusal&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode {
    return Object.hash(runtimeType,action);
}

@override
String toString() {
    return 'Failure.unexplainedRefusal(action: $action)';
}


}

/// @nodoc
abstract mixin class $UnexplainedRefusalCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnexplainedRefusalCopyWith(UnexplainedRefusal value, $Res Function(UnexplainedRefusal) _then) = _$UnexplainedRefusalCopyWithImpl;
@useResult
$Res call({
 RefusedAction action
});




}
/// @nodoc
class _$UnexplainedRefusalCopyWithImpl<$Res>
    implements $UnexplainedRefusalCopyWith<$Res> {
  _$UnexplainedRefusalCopyWithImpl(this._self, this._then);

  final UnexplainedRefusal _self;
  final $Res Function(UnexplainedRefusal) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? action = null,}) {
  return _then(UnexplainedRefusal(
null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as RefusedAction,
  ));
}


}

/// @nodoc


class UnexpectedResponse implements Failure {
  const UnexpectedResponse({this.creatingGroup = false});
  

@JsonKey() final  bool creatingGroup;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnexpectedResponseCopyWith<UnexpectedResponse> get copyWith => _$UnexpectedResponseCopyWithImpl<UnexpectedResponse>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is UnexpectedResponse&&(identical(other.creatingGroup, creatingGroup) || other.creatingGroup == creatingGroup));
}


@override
int get hashCode {
    return Object.hash(runtimeType,creatingGroup);
}

@override
String toString() {
    return 'Failure.unexpectedResponse(creatingGroup: $creatingGroup)';
}


}

/// @nodoc
abstract mixin class $UnexpectedResponseCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $UnexpectedResponseCopyWith(UnexpectedResponse value, $Res Function(UnexpectedResponse) _then) = _$UnexpectedResponseCopyWithImpl;
@useResult
$Res call({
 bool creatingGroup
});




}
/// @nodoc
class _$UnexpectedResponseCopyWithImpl<$Res>
    implements $UnexpectedResponseCopyWith<$Res> {
  _$UnexpectedResponseCopyWithImpl(this._self, this._then);

  final UnexpectedResponse _self;
  final $Res Function(UnexpectedResponse) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? creatingGroup = null,}) {
  return _then(UnexpectedResponse(
creatingGroup: null == creatingGroup ? _self.creatingGroup : creatingGroup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class OrganizationIdFailure implements Failure {
  const OrganizationIdFailure(this.problem, {this.maxLength = 20});
  

 final  OrganizationIdProblem problem;
@JsonKey() final  int maxLength;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationIdFailureCopyWith<OrganizationIdFailure> get copyWith => _$OrganizationIdFailureCopyWithImpl<OrganizationIdFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationIdFailure&&(identical(other.problem, problem) || other.problem == problem)&&(identical(other.maxLength, maxLength) || other.maxLength == maxLength));
}


@override
int get hashCode {
    return Object.hash(runtimeType,problem,maxLength);
}

@override
String toString() {
    return 'Failure.organizationId(problem: $problem, maxLength: $maxLength)';
}


}

/// @nodoc
abstract mixin class $OrganizationIdFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $OrganizationIdFailureCopyWith(OrganizationIdFailure value, $Res Function(OrganizationIdFailure) _then) = _$OrganizationIdFailureCopyWithImpl;
@useResult
$Res call({
 OrganizationIdProblem problem, int maxLength
});




}
/// @nodoc
class _$OrganizationIdFailureCopyWithImpl<$Res>
    implements $OrganizationIdFailureCopyWith<$Res> {
  _$OrganizationIdFailureCopyWithImpl(this._self, this._then);

  final OrganizationIdFailure _self;
  final $Res Function(OrganizationIdFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problem = null,Object? maxLength = null,}) {
  return _then(OrganizationIdFailure(
null == problem ? _self.problem : problem // ignore: cast_nullable_to_non_nullable
as OrganizationIdProblem,maxLength: null == maxLength ? _self.maxLength : maxLength // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class GroupNameTooShort implements Failure {
  const GroupNameTooShort();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupNameTooShort);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.groupNameTooShort()';
}


}




/// @nodoc


class GroupNameTooLong implements Failure {
  const GroupNameTooLong();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupNameTooLong);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.groupNameTooLong()';
}


}




/// @nodoc


class GroupNameTaken implements Failure {
  const GroupNameTaken(this.existingName);
  

 final  String existingName;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupNameTakenCopyWith<GroupNameTaken> get copyWith => _$GroupNameTakenCopyWithImpl<GroupNameTaken>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupNameTaken&&(identical(other.existingName, existingName) || other.existingName == existingName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,existingName);
}

@override
String toString() {
    return 'Failure.groupNameTaken(existingName: $existingName)';
}


}

/// @nodoc
abstract mixin class $GroupNameTakenCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $GroupNameTakenCopyWith(GroupNameTaken value, $Res Function(GroupNameTaken) _then) = _$GroupNameTakenCopyWithImpl;
@useResult
$Res call({
 String existingName
});




}
/// @nodoc
class _$GroupNameTakenCopyWithImpl<$Res>
    implements $GroupNameTakenCopyWith<$Res> {
  _$GroupNameTakenCopyWithImpl(this._self, this._then);

  final GroupNameTaken _self;
  final $Res Function(GroupNameTaken) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? existingName = null,}) {
  return _then(GroupNameTaken(
null == existingName ? _self.existingName : existingName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class NoRoleChosen implements Failure {
  const NoRoleChosen();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NoRoleChosen);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.noRoleChosen()';
}


}




/// @nodoc


class InvalidEmail implements Failure {
  const InvalidEmail();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is InvalidEmail);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.invalidEmail()';
}


}




/// @nodoc


class EmailAlreadyListed implements Failure {
  const EmailAlreadyListed(this.email);
  

 final  String email;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmailAlreadyListedCopyWith<EmailAlreadyListed> get copyWith => _$EmailAlreadyListedCopyWithImpl<EmailAlreadyListed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EmailAlreadyListed&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode {
    return Object.hash(runtimeType,email);
}

@override
String toString() {
    return 'Failure.emailAlreadyListed(email: $email)';
}


}

/// @nodoc
abstract mixin class $EmailAlreadyListedCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $EmailAlreadyListedCopyWith(EmailAlreadyListed value, $Res Function(EmailAlreadyListed) _then) = _$EmailAlreadyListedCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$EmailAlreadyListedCopyWithImpl<$Res>
    implements $EmailAlreadyListedCopyWith<$Res> {
  _$EmailAlreadyListedCopyWithImpl(this._self, this._then);

  final EmailAlreadyListed _self;
  final $Res Function(EmailAlreadyListed) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(EmailAlreadyListed(
null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LogoTooLarge implements Failure {
  const LogoTooLarge(this.megabytes);
  

 final  int megabytes;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoTooLargeCopyWith<LogoTooLarge> get copyWith => _$LogoTooLargeCopyWithImpl<LogoTooLarge>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoTooLarge&&(identical(other.megabytes, megabytes) || other.megabytes == megabytes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,megabytes);
}

@override
String toString() {
    return 'Failure.logoTooLarge(megabytes: $megabytes)';
}


}

/// @nodoc
abstract mixin class $LogoTooLargeCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $LogoTooLargeCopyWith(LogoTooLarge value, $Res Function(LogoTooLarge) _then) = _$LogoTooLargeCopyWithImpl;
@useResult
$Res call({
 int megabytes
});




}
/// @nodoc
class _$LogoTooLargeCopyWithImpl<$Res>
    implements $LogoTooLargeCopyWith<$Res> {
  _$LogoTooLargeCopyWithImpl(this._self, this._then);

  final LogoTooLarge _self;
  final $Res Function(LogoTooLarge) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? megabytes = null,}) {
  return _then(LogoTooLarge(
null == megabytes ? _self.megabytes : megabytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class LogoUnreadable implements Failure {
  const LogoUnreadable();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoUnreadable);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.logoUnreadable()';
}


}




/// @nodoc


class LogoNotConverted implements Failure {
  const LogoNotConverted();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoNotConverted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.logoNotConverted()';
}


}




/// @nodoc


class LogoNotOpened implements Failure {
  const LogoNotOpened();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoNotOpened);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.logoNotOpened()';
}


}




/// @nodoc


class EntryFailure implements Failure {
  const EntryFailure(this.stage, this.detail);
  

 final  EntryStage stage;
 final  String detail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntryFailureCopyWith<EntryFailure> get copyWith => _$EntryFailureCopyWithImpl<EntryFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EntryFailure&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,stage,detail);
}

@override
String toString() {
    return 'Failure.entry(stage: $stage, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $EntryFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $EntryFailureCopyWith(EntryFailure value, $Res Function(EntryFailure) _then) = _$EntryFailureCopyWithImpl;
@useResult
$Res call({
 EntryStage stage, String detail
});




}
/// @nodoc
class _$EntryFailureCopyWithImpl<$Res>
    implements $EntryFailureCopyWith<$Res> {
  _$EntryFailureCopyWithImpl(this._self, this._then);

  final EntryFailure _self;
  final $Res Function(EntryFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? detail = null,}) {
  return _then(EntryFailure(
null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as EntryStage,null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class OrganizationEntryFailure implements Failure {
  const OrganizationEntryFailure(this.organizationName, this.detail);
  

 final  String organizationName;
 final  String detail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationEntryFailureCopyWith<OrganizationEntryFailure> get copyWith => _$OrganizationEntryFailureCopyWithImpl<OrganizationEntryFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationEntryFailure&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName)&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationName,detail);
}

@override
String toString() {
    return 'Failure.organizationEntry(organizationName: $organizationName, detail: $detail)';
}


}

/// @nodoc
abstract mixin class $OrganizationEntryFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $OrganizationEntryFailureCopyWith(OrganizationEntryFailure value, $Res Function(OrganizationEntryFailure) _then) = _$OrganizationEntryFailureCopyWithImpl;
@useResult
$Res call({
 String organizationName, String detail
});




}
/// @nodoc
class _$OrganizationEntryFailureCopyWithImpl<$Res>
    implements $OrganizationEntryFailureCopyWith<$Res> {
  _$OrganizationEntryFailureCopyWithImpl(this._self, this._then);

  final OrganizationEntryFailure _self;
  final $Res Function(OrganizationEntryFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationName = null,Object? detail = null,}) {
  return _then(OrganizationEntryFailure(
null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GoogleAuthFailure implements Failure {
  const GoogleAuthFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GoogleAuthFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.googleAuth()';
}


}




/// @nodoc


class GoogleRenewalFailure implements Failure {
  const GoogleRenewalFailure();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GoogleRenewalFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.googleRenewal()';
}


}




/// @nodoc


class SignOutFailure implements Failure {
  const SignOutFailure(this.detail);
  

 final  String detail;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignOutFailureCopyWith<SignOutFailure> get copyWith => _$SignOutFailureCopyWithImpl<SignOutFailure>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SignOutFailure&&(identical(other.detail, detail) || other.detail == detail));
}


@override
int get hashCode {
    return Object.hash(runtimeType,detail);
}

@override
String toString() {
    return 'Failure.signOut(detail: $detail)';
}


}

/// @nodoc
abstract mixin class $SignOutFailureCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $SignOutFailureCopyWith(SignOutFailure value, $Res Function(SignOutFailure) _then) = _$SignOutFailureCopyWithImpl;
@useResult
$Res call({
 String detail
});




}
/// @nodoc
class _$SignOutFailureCopyWithImpl<$Res>
    implements $SignOutFailureCopyWith<$Res> {
  _$SignOutFailureCopyWithImpl(this._self, this._then);

  final SignOutFailure _self;
  final $Res Function(SignOutFailure) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? detail = null,}) {
  return _then(SignOutFailure(
null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AccessLost implements Failure {
  const AccessLost(this.organizationName);
  

 final  String organizationName;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccessLostCopyWith<AccessLost> get copyWith => _$AccessLostCopyWithImpl<AccessLost>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessLost&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationName);
}

@override
String toString() {
    return 'Failure.accessLost(organizationName: $organizationName)';
}


}

/// @nodoc
abstract mixin class $AccessLostCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $AccessLostCopyWith(AccessLost value, $Res Function(AccessLost) _then) = _$AccessLostCopyWithImpl;
@useResult
$Res call({
 String organizationName
});




}
/// @nodoc
class _$AccessLostCopyWithImpl<$Res>
    implements $AccessLostCopyWith<$Res> {
  _$AccessLostCopyWithImpl(this._self, this._then);

  final AccessLost _self;
  final $Res Function(AccessLost) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationName = null,}) {
  return _then(AccessLost(
null == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class RemovedFromOrganization implements Failure {
  const RemovedFromOrganization(this.organizationName);
  

 final  String? organizationName;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RemovedFromOrganizationCopyWith<RemovedFromOrganization> get copyWith => _$RemovedFromOrganizationCopyWithImpl<RemovedFromOrganization>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RemovedFromOrganization&&(identical(other.organizationName, organizationName) || other.organizationName == organizationName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,organizationName);
}

@override
String toString() {
    return 'Failure.removedFromOrganization(organizationName: $organizationName)';
}


}

/// @nodoc
abstract mixin class $RemovedFromOrganizationCopyWith<$Res> implements $FailureCopyWith<$Res> {
  factory $RemovedFromOrganizationCopyWith(RemovedFromOrganization value, $Res Function(RemovedFromOrganization) _then) = _$RemovedFromOrganizationCopyWithImpl;
@useResult
$Res call({
 String? organizationName
});




}
/// @nodoc
class _$RemovedFromOrganizationCopyWithImpl<$Res>
    implements $RemovedFromOrganizationCopyWith<$Res> {
  _$RemovedFromOrganizationCopyWithImpl(this._self, this._then);

  final RemovedFromOrganization _self;
  final $Res Function(RemovedFromOrganization) _then;

/// Create a copy of Failure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? organizationName = freezed,}) {
  return _then(RemovedFromOrganization(
freezed == organizationName ? _self.organizationName : organizationName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SharingNotAllowed implements Failure {
  const SharingNotAllowed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SharingNotAllowed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.sharingNotAllowed()';
}


}




/// @nodoc


class SharingNotChanged implements Failure {
  const SharingNotChanged();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SharingNotChanged);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Failure.sharingNotChanged()';
}


}




// dart format on
