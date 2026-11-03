import 'package:flutter/foundation.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'groups_state.dart';

export 'groups_state.dart';

/// State of the group screens (*Grupos*, *Criar grupo*, *Grupo*) for an
/// administrator, who manages every group, or a group's maintainer
/// (*Gestor do grupo*), who sees only the groups they maintain and manages
/// their people, invites and name. The server checks the same; [isAdmin]
/// only hides what the person may not do. One operation at a time: each
/// operation is a command that ignores a call while any of them runs
/// ([isWorking]). The screen runs [load] when it opens.
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
    for (final command in _operations) {
      command.dispose();
    }
    load.dispose();
    super.dispose();
  }

  Group? byId(String groupId) =>
      _state.groups.where((g) => g.id == groupId).firstOrNull;

  /// Why [name] cannot be a new group (or the new name of group [renaming]).
  Failure? nameProblem(String name, {String? renaming}) => groupNameProblem(
    name,
    _state.groups.where((g) => g.id != renaming).map((g) => g.name),
  );

  /// What *Criar grupo* says about the name [typed]: nothing while it is
  /// empty, else [nameProblem].
  Failure? newNameProblem(String typed) {
    final name = typed.trim();
    return name.isEmpty ? null : nameProblem(name);
  }

  /// Whether *Criar grupo* may create a group named [typed].
  bool canCreate(String typed) =>
      typed.trim().isNotEmpty && newNameProblem(typed) == null;

  /// [typed] as a group name: single spaces, trimmed.
  String tidyName(String typed) => typed.replaceAll(RegExp(r'\s+'), ' ').trim();

  /// What the rename sheet says about the name [typed] for [group]: nothing
  /// while it is empty, else [nameProblem].
  Failure? renameProblem(Group group, String typed) {
    final name = tidyName(typed);
    return name.isEmpty ? null : nameProblem(name, renaming: group.id);
  }

  /// Whether [group] may be renamed to [typed]: a new, valid name.
  bool canRename(Group group, String typed) {
    final name = tidyName(typed);
    return name.isNotEmpty &&
        name != group.name &&
        renameProblem(group, typed) == null;
  }

  /// Why [roles] cannot be given (see [rolesChoiceProblem]), or `null`.
  Failure? rolesProblem(Set<GroupRole> roles) =>
      rolesChoiceProblem(roles, byAdmin: isAdmin);

  /// Whether [roles] may replace [person]'s: valid and different.
  bool canSetRoles(GroupPerson person, Set<GroupRole> roles) =>
      rolesProblem(roles) == null &&
      !(roles.length == person.roles.length && roles.containsAll(person.roles));

  /// Reads the groups. The failure is also kept in
  /// [GroupsState.failure], as are the operations' below.
  late final Command0<void> load = Command0(_load);

  /// Creates a group with the name given; [Ok] holds it.
  late final Command1<Group, String> create = Command1(
    (name) => _guarded(
      () => _repository.create(organizationId, name.trim()),
      onDone: (group) =>
          _emit(_state.copyWith(groups: [..._state.groups, group])),
    ),
    blocked: () => isWorking,
  );

  /// Renames a group, then reads the groups again.
  late final Command1<void, ({String groupId, String name})> rename = Command1(
    (change) => _changeAndReload(
      () => _repository.rename(
        organizationId,
        change.groupId,
        change.name.trim(),
      ),
    ),
    blocked: () => isWorking,
  );

  /// Who loses access to the organization if the group given is deleted,
  /// and who stays in it through another group.
  late final Command1<({List<String> loses, List<String> stays}), String>
  deletionImpact = Command1(
    (groupId) => _guarded(
      () => _repository.deletionImpact(organizationId, groupId),
      onDone: (impact) =>
          _lastImpact = (groupId: groupId, loses: impact.loses.length),
    ),
    blocked: () => isWorking,
  );

  /// The group whose [deletionImpact] was read last and how many it loses.
  ({String groupId, int loses})? _lastImpact;

  /// Deletes the group given, takes it off the list and keeps it in
  /// [GroupsState.deleted] (with the count its [deletionImpact] read).
  late final Command1<void, String> delete = Command1((groupId) {
    final name = byId(groupId)?.name ?? '';
    final impact = _lastImpact;
    return _guarded(
      () => _repository.delete(organizationId, groupId),
      onDone: (_) => _emit(
        _state.copyWith(
          groups: [
            for (final g in _state.groups)
              if (g.id != groupId) g,
          ],
          deleted: DeletedGroup(
            id: groupId,
            name: name,
            loses: impact?.groupId == groupId ? impact!.loses : 0,
          ),
        ),
      ),
    );
  }, blocked: () => isWorking);

  /// Sets a person's roles in a group, never none (see
  /// [rolesChoiceProblem]), then reads the groups again.
  late final Command1<
    void,
    ({String groupId, String email, Set<GroupRole> roles})
  >
  setRoles = Command1(_setRoles, blocked: () => isWorking);

  /// Removes a person from a group, then reads the groups again.
  late final Command1<void, ({String groupId, String email})> remove = Command1(
    (person) => _changeAndReload(
      () => _repository.remove(organizationId, person.groupId, person.email),
    ),
    blocked: () => isWorking,
  );

  /// The operations, which never overlap.
  List<Command<Object?>> get _operations => [
    create,
    rename,
    deletionImpact,
    delete,
    setRoles,
    remove,
  ];

  /// Whether an operation (create, rename, deletion impact, delete, roles,
  /// remove) runs.
  bool get isWorking => _operations.any((command) => command.running);

  Future<Result<void>> _load() async {
    _emit(_state.copyWith(failure: null));
    final listed = await _repository.list(organizationId);
    switch (listed) {
      case Ok(value: final groups):
        _emit(_state.copyWith(groups: groups));
      case Err(:final failure):
        _emit(_state.copyWith(failure: failure));
    }
    return listed;
  }

  /// Runs [operation], keeping its failure in [GroupsState.failure],
  /// then [onDone] with its value.
  Future<Result<T>> _guarded<T>(
    Future<Result<T>> Function() operation, {
    void Function(T value)? onDone,
  }) async {
    _emit(_state.copyWith(failure: null));
    final result = await operation();
    switch (result) {
      case Ok(:final value):
        onDone?.call(value);
      case Err(:final failure):
        _emit(_state.copyWith(failure: failure));
    }
    return result;
  }

  /// Runs [operation] and reads the groups again after it worked (a failed
  /// reload shows in [GroupsState.failure] but does not fail it).
  Future<Result<void>> _changeAndReload(
    Future<Result<void>> Function() operation,
  ) async {
    final result = await _guarded(operation);
    if (result is Ok) await load.execute();
    return result;
  }

  Future<Result<void>> _setRoles(
    ({String groupId, String email, Set<GroupRole> roles}) change,
  ) async {
    final problem = rolesProblem(change.roles);
    if (problem != null) {
      _emit(_state.copyWith(failure: problem));
      return Err(problem);
    }
    return _changeAndReload(
      () => _repository.setRoles(
        organizationId,
        change.groupId,
        change.email,
        change.roles,
      ),
    );
  }
}
