import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

import 'creation_backend.dart';

/// [CreationBackend] over the central project's creation functions.
class FirebaseCreationBackend implements CreationBackend {
  const FirebaseCreationBackend();

  Future<Object?> _call(String name, Map<String, Object?> data) async {
    try {
      final result = await CentralFirebase.functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
          )
          .call(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw CreationException(switch (e.code) {
        'invalid-argument' ||
        'failed-precondition' => e.message ?? 'Não foi possível criar.',
        _ =>
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
      });
    }
  }

  @override
  Future<String?> idProblem(String id) async {
    final data = await _call('checkOrganizationId', {'id': id});
    if (data is Map && data['available'] == true) return null;
    return data is Map && data['problem'] is String
        ? data['problem'] as String
        : 'Esse identificador não pode ser usado.';
  }

  @override
  Future<String> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  }) async {
    final data = await _call('createOrganization', {
      'id': id,
      'name': name,
      'themeId': themeId,
      'plan': plan,
    });
    return data is Map && data['status'] is String
        ? data['status'] as String
        : 'failed';
  }

  @override
  Future<List<Creation>> mine() async {
    final data = await _call('myCreations', {});
    return [
      for (final entry
          in (data is Map ? data['creations'] : null) as List? ?? const [])
        ?Creation.fromJson(entry),
    ];
  }
}
