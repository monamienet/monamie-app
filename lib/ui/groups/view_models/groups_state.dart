import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:monamie_app/domain/models/group.dart';

part 'groups_state.freezed.dart';

/// What the group screens show, replaced whole by `GroupsViewModel`.
@freezed
abstract class GroupsState with _$GroupsState {
  const factory GroupsState({
    /// The groups the person manages (every group for an administrator).
    @Default([]) List<Group> groups,

    /// Why the last load or operation failed; empty when it did not.
    @Default('') String errorMessage,

    /// The group deleted last, for *Grupo excluído*; `null` before one is.
    DeletedGroup? deleted,
  }) = _GroupsState;
}

/// A group just deleted: what *Grupo excluído* says about it.
@freezed
abstract class DeletedGroup with _$DeletedGroup {
  const factory DeletedGroup({
    required String id,
    required String name,

    /// How many people lost access to the organization with it.
    required int loses,
  }) = _DeletedGroup;
}
