import 'package:cloud_functions/cloud_functions.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

import 'account_deletion.dart';
import 'account_deletion_backend.dart';

/// [AccountDeletionBackend] over the central project's functions.
class FirebaseAccountDeletionBackend implements AccountDeletionBackend {
  const FirebaseAccountDeletionBackend();

  Future<Object?> _call(
    String name, [
    Map<String, Object?> data = const {},
  ]) async {
    try {
      final result = await CentralFirebase.functions
          .httpsCallable(
            name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
          )
          .call(data);
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      throw AccountDeletionException(switch (e.code) {
        'failed-precondition' => e.message ?? 'Não foi possível agora.',
        _ =>
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
      });
    }
  }

  @override
  Future<AccountDeletion> request({List<String> confirmIds = const []}) async {
    final deletion = AccountDeletion.fromJson(
      await _call('requestAccountDeletion', {'confirmIds': confirmIds}),
    );
    if (deletion == null) {
      throw const AccountDeletionException('Resposta inesperada do servidor.');
    }
    return deletion;
  }

  @override
  Future<void> cancel() => _call('cancelAccountDeletion');

  @override
  Future<AccountDeletion?> pending() async {
    final data = await _call('myAccountDeletion');
    return AccountDeletion.fromJson(data is Map ? data['deletion'] : null);
  }
}
