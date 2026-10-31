import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'group.dart';
import 'groups_backend.dart';

/// State of the group screens (*Grupos*, *Criar grupo*, *Grupo*) for an
/// administrator, who manages every group, or a group's maintainer
/// (*Gestor do grupo*), who sees only the groups they maintain and manages
/// their people, invites and name. The server checks the same; [isAdmin]
/// only hides what the person may not do. One operation at a time:
/// [isWorking] guards reentrancy and drives the pending states; it always
/// resets in `finally`.
///
/// The map under these screens needs no notice: it follows the groups in
/// Firestore by itself.
class GroupsController extends GetxController {
  GroupsController({
    required this.organizationId,
    required GroupsBackend backend,
    this.isAdmin = false,
  }) : _backend = backend;

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

  final RxList<Group> groups = <Group>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isWorking = false.obs;
  final RxString errorMessage = ''.obs;

  /// The most groups an organization may have (the server refuses more).
  static const maxGroups = 99;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// "12 de 99".
  String get countLabel => '${groups.length} de $maxGroups';

  Group? byId(String groupId) =>
      groups.firstWhereOrNull((g) => g.id == groupId);

  /// Why [name] cannot be a new group (or the new name of group [renaming]).
  String? nameProblem(String name, {String? renaming}) => groupNameProblem(
    name,
    groups.where((g) => g.id != renaming).map((g) => g.name),
  );

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      groups.assignAll(await _backend.list(organizationId));
    } on GroupsException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      debugPrint('[Groups] Could not load: $e');
      errorMessage.value = 'Não foi possível carregar os grupos.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Runs [operation] guarded; returns its result, or `null` when it did
  /// not run or failed (the message is in [errorMessage]).
  Future<T?> _guarded<T>(Future<T> Function() operation) async {
    if (isWorking.value) return null;
    isWorking.value = true;
    errorMessage.value = '';
    try {
      return await operation();
    } on GroupsException catch (e) {
      errorMessage.value = e.message;
      return null;
    } catch (e) {
      debugPrint('[Groups] Operation failed: $e');
      errorMessage.value =
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.';
      return null;
    } finally {
      isWorking.value = false;
    }
  }

  /// Creates a group; returns it, or `null` on failure.
  Future<Group?> create(String name) => _guarded(() async {
    final group = await _backend.create(organizationId, name.trim());
    groups.add(group);
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
        groups.removeWhere((g) => g.id == groupId);
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
      errorMessage.value = problem;
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
