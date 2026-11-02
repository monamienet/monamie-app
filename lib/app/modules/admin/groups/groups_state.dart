import 'package:freezed_annotation/freezed_annotation.dart';

import 'group.dart';

part 'groups_state.freezed.dart';

/// What the group screens show, replaced whole by `GroupsController`.
@freezed
abstract class GroupsState with _$GroupsState {
  const factory GroupsState({
    /// The groups the person manages (every group for an administrator).
    @Default([]) List<Group> groups,

    /// Whether the list is being (re)loaded.
    @Default(false) bool isLoading,

    /// Whether an operation (create, rename, delete, roles, remove) runs.
    @Default(false) bool isWorking,

    /// Why the last load or operation failed; empty when it did not.
    @Default('') String errorMessage,
  }) = _GroupsState;
}
