import 'package:flutter/foundation.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/utils/result.dart';
import 'groups_state.dart';

export 'groups_state.dart';

/// State of the group screens (*Grupos*, *Criar grupo*, *Grupo*) for an
/// administrator, who manages every group, or a group's maintainer
/// (*Gestor do grupo*), who sees only the groups they maintain and manages
/// their people, invites and name. The server checks the same; [isAdmin]
/// only hides what the person may not do. One operation at a time:
/// [GroupsState.isWorking] guards reentrancy and drives the pending states;
/// it always resets in `finally`. The screen calls [load] when it opens.
///
/// The map under these screens needs no notice: it follows the groups in
/// Firestore by itself.
class GroupsViewModel extends ChangeNotifier {
  GroupsViewModel({
    required this.organizationId,
    required this._repository,
    this.isAdmin = false,
  });

  final String organizationId;

  /// Whether the person administers the organization: creates and deletes
  /// groups and gives *Gestor do grupo*. Otherwise they maintain the groups
  /// listed.
  final bool isAdmin;

  /// The roles the person may give in the role picker.
  List<GroupRole> get assignableRoles => assignableRolesFor(byAdmin: isAdmin);

  /// Whether the person may remove [person] from a group.
  bool canRemove(GroupPerson person) =>
      canRemoveFromGroup(person, byAdmin: isAdmin);
  final GroupsRepository _repository;

  GroupsState _state = const GroupsState();
  bool _disposed = false;

  /// What the screens show; replaced whole, never changed in place.
  GroupsState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(GroupsState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Group? byId(String groupId) =>
      _state.groups.where((g) => g.id == groupId).firstOrNull;

  /// Why [name] cannot be a new group (or the new name of group [renaming]).
  String? nameProblem(String name, {String? renaming}) => groupNameProblem(
    name,
    _state.groups.where((g) => g.id != renaming).map((g) => g.name),
  );

  Future<void> load() async {
    if (_state.isLoading) return;
    _emit(_state.copyWith(isLoading: true, errorMessage: ''));
    try {
      switch (await _repository.list(organizationId)) {
        case Ok(value: final groups):
          _emit(_state.copyWith(groups: groups));
        case Err(:final message):
          _emit(_state.copyWith(errorMessage: message));
      }
    } finally {
      _emit(_state.copyWith(isLoading: false));
    }
  }

  /// Runs [operation] guarded, then [onDone] with its value; returns
  /// [onDone]'s result, or `null` when it did not run or failed (the
  /// message is in [GroupsState.errorMessage]).
  Future<R?> _guarded<T, R>(
    Future<Result<T>> Function() operation,
    Future<R> Function(T value) onDone,
  ) async {
    if (_state.isWorking) return null;
    _emit(_state.copyWith(isWorking: true, errorMessage: ''));
    try {
      switch (await operation()) {
        case Ok(:final value):
          return await onDone(value);
        case Err(:final message):
          _emit(_state.copyWith(errorMessage: message));
          return null;
      }
    } finally {
      _emit(_state.copyWith(isWorking: false));
    }
  }

  /// Creates a group; returns it, or `null` on failure.
  Future<Group?> create(String name) => _guarded(
    () => _repository.create(organizationId, name.trim()),
    (group) async {
      _emit(_state.copyWith(groups: [..._state.groups, group]));
      return group;
    },
  );

  /// Runs [operation] guarded and reloads the groups after it; returns
  /// whether it worked.
  Future<bool> _changeAndReload(
    Future<Result<void>> Function() operation,
  ) async =>
      await _guarded(operation, (_) async {
        await load();
        return true;
      }) ??
      false;

  Future<bool> rename(String groupId, String name) => _changeAndReload(
    () => _repository.rename(organizationId, groupId, name.trim()),
  );

  Future<({List<String> loses, List<String> stays})?> deletionImpact(
    String groupId,
  ) => _guarded(
    () => _repository.deletionImpact(organizationId, groupId),
    (impact) async => impact,
  );

  Future<bool> delete(String groupId) async =>
      await _guarded(() => _repository.delete(organizationId, groupId), (
        _,
      ) async {
        _emit(
          _state.copyWith(
            groups: [
              for (final g in _state.groups)
                if (g.id != groupId) g,
            ],
          ),
        );
        return true;
      }) ??
      false;

  /// Sets [email]'s roles in group [groupId]; never none (see
  /// [rolesChoiceProblem]).
  Future<bool> setRoles(
    String groupId,
    String email,
    Set<GroupRole> roles,
  ) async {
    final problem = rolesChoiceProblem(roles, byAdmin: isAdmin);
    if (problem != null) {
      _emit(_state.copyWith(errorMessage: problem));
      return false;
    }
    return _changeAndReload(
      () => _repository.setRoles(organizationId, groupId, email, roles),
    );
  }

  Future<bool> remove(String groupId, String email) => _changeAndReload(
    () => _repository.remove(organizationId, groupId, email),
  );
}
