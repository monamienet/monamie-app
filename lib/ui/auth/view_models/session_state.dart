import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/organization/organization_binding.dart';

part 'session_state.freezed.dart';

/// Where the sign-in flow stands: which of MonAmie's entry screens (or the
/// bound organization) the person should see. `AuthGoogleViewModel` sets it
/// right before each navigation, so the router can derive the destination
/// from it alone.
@freezed
sealed class SessionState with _$SessionState {
  /// Not signed in to MonAmie: *Login*. Also the state on start, while the
  /// login screen checks for a remembered session.
  const factory SessionState.signedOut() = SessionSignedOut;

  /// Signed in, but in no organization (or just lost access to one):
  /// *Sem organização*.
  const factory SessionState.noOrganization() = SessionNoOrganization;

  /// Signed in, choosing among [choices]: *Escolher organização*.
  const factory SessionState.picking(List<OrganizationBinding> choices) =
      SessionPicking;

  /// The account is scheduled for deletion (or the deletion was just
  /// cancelled and the person has not entered yet): *Em exclusão*.
  const factory SessionState.deletionPending() = SessionDeletionPending;

  /// Just entered the organization of an invite accepted: *Boas-vindas*,
  /// shown once before the map.
  const factory SessionState.welcome() = SessionWelcome;

  /// Bound to an organization and signed in to its project: the map.
  const factory SessionState.bound() = SessionBound;
}
