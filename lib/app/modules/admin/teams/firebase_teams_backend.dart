import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

import 'team.dart';
import 'teams_backend.dart';

/// [TeamsBackend] over the central project's team functions, called with
/// the MonAmie (central) session.
class FirebaseTeamsBackend implements TeamsBackend {
  const FirebaseTeamsBackend();

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
      throw TeamsException(switch (e.code) {
        'invalid-argument' ||
        'failed-precondition' ||
        'permission-denied' => e.message ?? 'Não foi possível concluir.',
        _ =>
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
      });
    }
  }

  @override
  Future<List<Team>> list(String organizationId) async {
    final data = await _call('listTeams', {'organizationId': organizationId});
    final teams = data is Map ? data['teams'] : null;
    return [
      for (final entry in teams is List ? teams : const [])
        ?Team.fromJson(entry),
    ];
  }

  @override
  Future<Team> create(String organizationId, String name) async {
    final data = await _call('createTeam', {
      'organizationId': organizationId,
      'name': name,
    });
    return Team.fromJson({...?(data as Map?), 'people': const []}) ??
        (throw const TeamsException('Resposta inesperada ao criar a equipe.'));
  }

  @override
  Future<void> rename(String organizationId, String team, String name) => _call(
    'renameTeam',
    {'organizationId': organizationId, 'team': team, 'name': name},
  );

  @override
  Future<({List<String> loses, List<String> stays})> deletionImpact(
    String organizationId,
    String team,
  ) async {
    final data = await _call('teamDeletionImpact', {
      'organizationId': organizationId,
      'team': team,
    });
    List<String> list(String key) => [
      for (final e in (data is Map ? data[key] : null) as List? ?? const [])
        if (e is String) e,
    ];
    return (loses: list('loses'), stays: list('stays'));
  }

  @override
  Future<void> delete(String organizationId, String team) =>
      _call('deleteTeam', {'organizationId': organizationId, 'team': team});

  @override
  Future<void> setRoles(
    String organizationId,
    String team,
    String email,
    Set<TeamRole> roles,
  ) => _call('setMemberRoles', {
    'organizationId': organizationId,
    'team': team,
    'email': email,
    'roles': [for (final r in roles) r.name],
  });

  @override
  Future<void> remove(String organizationId, String team, String email) =>
      _call('removeMember', {
        'organizationId': organizationId,
        'team': team,
        'email': email,
      });
}
