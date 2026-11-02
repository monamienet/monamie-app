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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  signedOut,TResult Function()?  noOrganization,TResult Function( List<OrganizationBinding> choices)?  picking,TResult Function()?  deletionPending,TResult Function()?  welcome,TResult Function()?  bound,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionSignedOut() when signedOut != null:
return signedOut();case SessionNoOrganization() when noOrganization != null:
return noOrganization();case SessionPicking() when picking != null:
return picking(_that.choices);case SessionDeletionPending() when deletionPending != null:
return deletionPending();case SessionWelcome() when welcome != null:
return welcome();case SessionBound() when bound != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  signedOut,required TResult Function()  noOrganization,required TResult Function( List<OrganizationBinding> choices)  picking,required TResult Function()  deletionPending,required TResult Function()  welcome,required TResult Function()  bound,}) {final _that = this;
switch (_that) {
case SessionSignedOut():
return signedOut();case SessionNoOrganization():
return noOrganization();case SessionPicking():
return picking(_that.choices);case SessionDeletionPending():
return deletionPending();case SessionWelcome():
return welcome();case SessionBound():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  signedOut,TResult? Function()?  noOrganization,TResult? Function( List<OrganizationBinding> choices)?  picking,TResult? Function()?  deletionPending,TResult? Function()?  welcome,TResult? Function()?  bound,}) {final _that = this;
switch (_that) {
case SessionSignedOut() when signedOut != null:
return signedOut();case SessionNoOrganization() when noOrganization != null:
return noOrganization();case SessionPicking() when picking != null:
return picking(_that.choices);case SessionDeletionPending() when deletionPending != null:
return deletionPending();case SessionWelcome() when welcome != null:
return welcome();case SessionBound() when bound != null:
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
  const SessionNoOrganization();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionNoOrganization);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState.noOrganization()';
}


}




/// @nodoc


class SessionPicking implements SessionState {
  const SessionPicking( List<OrganizationBinding> choices): _choices = choices;
  

 final  List<OrganizationBinding> _choices;
 List<OrganizationBinding> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionPickingCopyWith<SessionPicking> get copyWith => _$SessionPickingCopyWithImpl<SessionPicking>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionPicking&&const DeepCollectionEquality().equals(other.choices, _choices));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_choices));
}

@override
String toString() {
    return 'SessionState.picking(choices: $choices)';
}


}

/// @nodoc
abstract mixin class $SessionPickingCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory $SessionPickingCopyWith(SessionPicking value, $Res Function(SessionPicking) _then) = _$SessionPickingCopyWithImpl;
@useResult
$Res call({
 List<OrganizationBinding> choices
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
@pragma('vm:prefer-inline') $Res call({Object? choices = null,}) {
  return _then(SessionPicking(
null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<OrganizationBinding>,
  ));
}


}

/// @nodoc


class SessionDeletionPending implements SessionState {
  const SessionDeletionPending();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionDeletionPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState.deletionPending()';
}


}




/// @nodoc


class SessionWelcome implements SessionState {
  const SessionWelcome();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionWelcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SessionState.welcome()';
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
