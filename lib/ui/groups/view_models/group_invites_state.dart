import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/utils/failure.dart';

part 'group_invites_state.freezed.dart';

/// What the invites tab of *Grupo* shows, replaced whole by
/// `GroupInvitesViewModel`.
@freezed
abstract class GroupInvitesState with _$GroupInvitesState {
  const factory GroupInvitesState({
    /// The group's pending invites; `null` until the first load works.
    List<Invite>? invites,

    /// Why the last load failed; `null` when it did not. Shown only while
    /// [invites] is `null`.
    Failure? failure,
  }) = _GroupInvitesState;
}
