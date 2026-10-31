import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

import 'group.dart';
import 'groups_backend.dart';

/// [GroupsBackend] over the central project's group functions, called with
/// the MonAmie (central) session.
class FirebaseGroupsBackend implements GroupsBackend {
  const FirebaseGroupsBackend();

  Future<Object?> _call(String name, Map<String, Object?> data) async {
    try {
      final result = await CentralFirebase.functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw GroupsException(switch (e.code) {
        'invalid-argument' ||
        'failed-precondition' ||
        'permission-denied' => e.message ?? 'Não foi possível concluir.',
        _ =>
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
      });
    }
  }

  @override
  Future<List<Group>> list(String organizationId) async {
    final data = await _call('listGroups', {'organizationId': organizationId});
    final groups = data is Map ? data['groups'] : null;
    return [
      for (final entry in groups is List ? groups : const [])
        ?Group.fromJson(entry),
    ];
  }

  @override
  Future<Group> create(String organizationId, String name) async {
    final data = await _call('createGroup', {
      'organizationId': organizationId,
      'name': name,
    });
    return Group.fromJson({...?(data as Map?), 'people': const []}) ??
        (throw const GroupsException('Resposta inesperada ao criar o grupo.'));
  }

  @override
  Future<void> rename(String organizationId, String groupId, String name) =>
      _call('renameGroup', {
        'organizationId': organizationId,
        'groupId': groupId,
        'name': name,
      });

  @override
  Future<({List<String> loses, List<String> stays})> deletionImpact(
    String organizationId,
    String groupId,
  ) async {
    final data = await _call('groupDeletionImpact', {
      'organizationId': organizationId,
      'groupId': groupId,
    });
    List<String> list(String key) => [
      for (final e in (data is Map ? data[key] : null) as List? ?? const [])
        if (e is String) e,
    ];
    return (loses: list('loses'), stays: list('stays'));
  }

  @override
  Future<void> delete(String organizationId, String groupId) => _call(
    'deleteGroup',
    {'organizationId': organizationId, 'groupId': groupId},
  );

  @override
  Future<void> setRoles(
    String organizationId,
    String groupId,
    String email,
    Set<GroupRole> roles,
  ) => _call('setMemberRoles', {
    'organizationId': organizationId,
    'groupId': groupId,
    'email': email,
    'roles': [for (final r in roles) r.id],
  });

  @override
  Future<void> remove(String organizationId, String groupId, String email) =>
      _call('removeMember', {
        'organizationId': organizationId,
        'groupId': groupId,
        'email': email,
      });
}
