import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'account_deletion.dart';
import 'account_deletion_backend.dart';

/// State of *Minha conta*: deleting the account. An owner deletes their
/// organization with it and confirms by typing its id.
class MyAccountController extends GetxController {
  MyAccountController({
    required AccountDeletionBackend backend,
    required this.partnerId,
    required this.isOwner,
    required Future<void> Function(AccountDeletion) onDeleted,
  }) : _backend = backend,
       _onDeleted = onDeleted;

  final AccountDeletionBackend _backend;
  final Future<void> Function(AccountDeletion) _onDeleted;

  /// The bound organization.
  final String partnerId;
  final bool isOwner;

  final RxString confirmation = ''.obs;
  final RxBool isDeleting = false.obs;
  final RxString errorMessage = ''.obs;

  /// A member deletes at once; an owner once the id is typed.
  bool get canDelete =>
      !isDeleting.value &&
      (!isOwner || confirmsId(confirmation.value, partnerId));

  /// "Excluir conta" / "Excluir conta e organização".
  Future<void> deleteAccount() async {
    if (!canDelete) return;
    isDeleting.value = true;
    errorMessage.value = '';
    try {
      final deletion = await _backend.request(
        confirmIds: isOwner ? [partnerId] : const [],
      );
      await _onDeleted(deletion);
    } on AccountDeletionException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      debugPrint('[Account] Deletion failed: $e');
      errorMessage.value =
          'Não foi possível excluir agora. Verifique a conexão e tente de novo.';
    } finally {
      isDeleting.value = false;
    }
  }
}
