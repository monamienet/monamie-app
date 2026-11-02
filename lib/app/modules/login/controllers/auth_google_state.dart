import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/modules/account/account_deletion.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';

import 'session_state.dart';

part 'auth_google_state.freezed.dart';

/// What MonAmie's entry screens show (*Login*, *Escolher organização*, *Sem
/// organização*, *Em exclusão*, *Boas-vindas*) and the busy states of the
/// home screen's sign-out, replaced whole by `AuthGoogleController`.
@freezed
abstract class AuthGoogleState with _$AuthGoogleState {
  const factory AuthGoogleState({
    /// Where the sign-in flow stands.
    @Default(SessionState.signedOut()) SessionState session,

    /// Whether Google Sign-In finished initializing (or failed to).
    @Default(false) bool googleReady,

    /// Whether a sign-in or an organization entry runs.
    @Default(false) bool isLoading,

    /// The login button was tapped and the sign-in has not finished:
    /// Google's account chooser may be open. Guards against a second tap
    /// without showing [isLoading]'s "Procurando sua organização…", which
    /// only makes sense once an account is chosen.
    @Default(false) bool isChoosingAccount,

    /// Whether a sign-out (tracking stop and sign-out) or a change of
    /// organization runs.
    @Default(false) bool isLoggingOut,

    /// The busy operation is a change of organization, not a sign-out: both
    /// set [isLoggingOut] (the lock and the overlay), and this decides the
    /// overlay's message.
    @Default(false) bool isSwitchingOrganization,

    /// Name of the organization being entered, for "Entrando em ...".
    String? enteringOrganizationName,

    /// E-mail of the Google account signed in to MonAmie (central project),
    /// shown on MonAmie's own screens with "Trocar".
    String? signedInEmail,

    /// Why the person is on *Sem organização* after trying to enter an
    /// organization (no membership there any more); `null` otherwise.
    String? noAccessReason,

    /// The signed-in account's pending deletion, shown on *Em exclusão*.
    AccountDeletion? accountDeletion,
    @Default(false) bool cancellingDeletion,

    /// The deletion was cancelled: *Em exclusão* says everything is back.
    @Default(false) bool deletionRestored,
    @Default('') String deletionError,

    /// Invites waiting for the signed-in account, shown on *Sem
    /// organização* and *Escolher organização*.
    @Default([]) List<Invite> pendingInvites,

    /// Id of the invite being accepted (its button shows the pending state).
    String? acceptingInvite,

    /// Error of the last accept, shown on the invite card.
    @Default('') String inviteError,

    /// The invite just accepted: *Boas-vindas* is shown once, after
    /// entering its organization.
    Invite? welcome,

    /// Whether the signed-in user owns each organization read so far (by
    /// id); cleared on sign-out. The owner-only menu entries
    /// (*Administradores*) follow it.
    @Default({}) Map<String, bool> ownership,
  }) = _AuthGoogleState;

  const AuthGoogleState._();

  /// Organizations offered by the picker: those of [SessionState.picking],
  /// none otherwise.
  List<OrganizationBinding> get organizationChoices => switch (session) {
    SessionPicking(:final choices) => choices,
    _ => const [],
  };
}
