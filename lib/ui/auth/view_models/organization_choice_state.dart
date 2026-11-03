import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/utils/failure.dart';

part 'organization_choice_state.freezed.dart';

/// What *Sem organização* and *Escolher organização* show, replaced whole by
/// `OrganizationChoiceViewModel`.
@freezed
abstract class OrganizationChoiceState with _$OrganizationChoiceState {
  const factory OrganizationChoiceState({
    /// E-mail of the Google account signed in to MonAmie (central project),
    /// shown with "Trocar".
    String? signedInEmail,

    /// Why the person is on *Sem organização* after trying to enter an
    /// organization or being removed from one (an [AccessLost] or a
    /// [RemovedFromOrganization]); `null` otherwise.
    Failure? noAccessReason,

    /// Organizations offered by the picker; none on *Sem organização*.
    @Default([]) List<OrganizationBinding> organizationChoices,

    /// Invites waiting for the signed-in account.
    @Default([]) List<Invite> pendingInvites,

    /// Name of the organization being entered, for its spinner.
    String? enteringOrganizationName,

    /// Why the last accept failed, shown on the invite card; `null` when it
    /// did not.
    Failure? inviteFailure,

    /// Whether a sign-out runs.
    @Default(false) bool isLoggingOut,
  }) = _OrganizationChoiceState;
}
