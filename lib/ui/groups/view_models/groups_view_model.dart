import 'package:flutter/foundation.dart';

import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/data/repositories/groups/groups_backend.dart';
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
    required this._backend,
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
  final GroupsBackend _backend;

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
      final groups = await _backend.list(organizationId);
      _emit(_state.copyWith(groups: groups));
    } on GroupsException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
    } catch (e) {
      debugPrint('[Groups] Could not load: $e');
      _emit(
        _state.copyWith(errorMessage: 'Não foi possível carregar os grupos.'),
      );
    } finally {
      _emit(_state.copyWith(isLoading: false));
    }
  }

  /// Runs [operation] guarded; returns its result, or `null` when it did
  /// not run or failed (the message is in [GroupsState.errorMessage]).
  Future<T?> _guarded<T>(Future<T> Function() operation) async {
    if (_state.isWorking) return null;
    _emit(_state.copyWith(isWorking: true, errorMessage: ''));
    try {
      return await operation();
    } on GroupsException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
      return null;
    } catch (e) {
      debugPrint('[Groups] Operation failed: $e');
      _emit(
        _state.copyWith(
          errorMessage:
              'Não foi possível concluir agora. Verifique a conexão e tente '
              'de novo.',
        ),
      );
      return null;
    } finally {
      _emit(_state.copyWith(isWorking: false));
    }
  }

  /// Creates a group; returns it, or `null` on failure.
  Future<Group?> create(String name) => _guarded(() async {
    final group = await _backend.create(organizationId, name.trim());
    _emit(_state.copyWith(groups: [..._state.groups, group]));
    return group;
  });

  Future<bool> rename(String groupId, String name) async =>
      await _guarded(() async {
        await _backend.rename(organizationId, groupId, name.trim());
        await load();
        return true;
      }) ??
      false;

  Future<({List<String> loses, List<String> stays})?> deletionImpact(
    String groupId,
  ) => _guarded(() => _backend.deletionImpact(organizationId, groupId));

  Future<bool> delete(String groupId) async =>
      await _guarded(() async {
        await _backend.delete(organizationId, groupId);
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
    return await _guarded(() async {
          await _backend.setRoles(organizationId, groupId, email, roles);
          await load();
          return true;
        }) ??
        false;
  }

  Future<bool> remove(String groupId, String email) async =>
      await _guarded(() async {
        await _backend.remove(organizationId, groupId, email);
        await load();
        return true;
      }) ??
      false;
}
