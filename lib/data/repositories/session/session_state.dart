import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/invite.dart';

part 'session_state.freezed.dart';

/// Where the sign-in flow stands: which of MonAmie's entry screens (or the
/// bound organization) the person should see, with what that screen opens
/// with. `SessionRepository` holds it; the use cases set it right before
/// each navigation, so the router can derive the destination from it alone.
@freezed
sealed class SessionState with _$SessionState {
  /// Not signed in to MonAmie: *Login*. Also the state on start, while the
  /// login screen checks for a remembered session.
  const factory SessionState.signedOut() = SessionSignedOut;

  /// Signed in, but in no organization (or just lost access to one):
  /// *Sem organização*. [reason] says why the person lost access, `null`
  /// otherwise; [invites] are the invites waiting for the account.
  const factory SessionState.noOrganization({
    String? reason,
    @Default([]) List<Invite> invites,
  }) = SessionNoOrganization;

  /// Signed in, choosing among [choices]: *Escolher organização*, with the
  /// [invites] waiting for the account above them.
  const factory SessionState.picking(
    List<OrganizationBinding> choices, {
    @Default([]) List<Invite> invites,
  }) = SessionPicking;

  /// The account is scheduled for [deletion] (or the deletion was just
  /// cancelled and the person has not entered yet): *Em exclusão*.
  const factory SessionState.deletionPending(AccountDeletion deletion) =
      SessionDeletionPending;

  /// Just entered the organization of [invite], accepted a moment ago:
  /// *Boas-vindas*, shown once before the map.
  const factory SessionState.welcome(Invite invite) = SessionWelcome;

  /// Bound to an organization and signed in to its project: the map.
  const factory SessionState.bound() = SessionBound;
}

/// How the person is leaving the bound organization, while it runs: the
/// home screen's overlay says which.
enum SessionExit {
  /// "Sair", losing access, deleting the account: signs out of everything.
  signOut,

  /// "Trocar de organização": keeps the Google sign-in.
  switchOrganization,
}
