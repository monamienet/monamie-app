import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';

import 'invite.dart';
import 'invites_backend.dart';

part 'invite_state.freezed.dart';

/// What *Convidar pessoas* shows, replaced whole by `InviteController`.
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

    /// Why the last e-mail typed could not be added; empty when it could.
    @Default('') String draftError,
    @Default(false) bool isSending,

    /// Why the last send failed; empty when it did not.
    @Default('') String errorMessage,

    /// The outcome of the last send, until "Convidar mais pessoas".
    InviteSendResult? result,
  }) = _InviteState;
}
