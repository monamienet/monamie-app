import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

import 'administrators.dart';
import 'administrators_backend.dart';

/// [AdministratorsBackend] over the central project's functions, called
/// with the MonAmie (central) session.
class FirebaseAdministratorsBackend implements AdministratorsBackend {
  const FirebaseAdministratorsBackend();

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
      throw AdministratorsException(
        administratorsErrorMessage(e.code, e.message),
      );
    }
  }

  @override
  Future<OrganizationAdministrators> list(String organizationId) async =>
      OrganizationAdministrators.fromJson(
        await _call('listAdministrators', {'organizationId': organizationId}),
      );

  @override
  Future<void> setAdministrator(
    String organizationId,
    String email, {
    required bool admin,
  }) => _call('setAdministrator', {
    'organizationId': organizationId,
    'email': email,
    'admin': admin,
  });
}

/// The owner's message for a failed call with error [code]: the server's
/// own message when it explains the refusal, else a connection hint.
String administratorsErrorMessage(String code, String? message) =>
    switch (code) {
      'invalid-argument' ||
      'failed-precondition' ||
      'permission-denied' => message ?? 'Não foi possível concluir.',
      _ =>
        'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
    };
