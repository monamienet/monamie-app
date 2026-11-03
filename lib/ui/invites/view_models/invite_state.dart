import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/group.dart';

import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/invite_send_result.dart';
import 'package:monamie_app/utils/failure.dart';

part 'invite_state.freezed.dart';

/// What *Convidar pessoas* shows, replaced whole by `InviteViewModel`.
@freezed
abstract class InviteState with _$InviteState {
  const factory InviteState({
    /// The groups one may invite to.
    @Default([]) List<Group> groups,

    /// The chosen group's id, or `null` in first-group mode.
    String? groupId,

    /// The first group's name, when the organization has no group yet.
    @Default('') String firstGroupName,

    /// The people to invite, with their roles.
    @Default([]) List<InviteDraft> people,

    /// Why the last e-mail typed could not be added; `null` when it could.
    Failure? draftFailure,

    /// Why the last send failed; `null` when it did not.
    Failure? failure,

    /// The outcome of the last send, until "Convidar mais pessoas".
    InviteSendResult? result,
  }) = _InviteState;
}
