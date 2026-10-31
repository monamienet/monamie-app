import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'account_deletion.dart';
import 'account_deletion_backend.dart';

/// State of *Minha conta*: deleting the account. The owner (*titular*)
/// deletes their organization with it and confirms by typing its id.
class MyAccountController extends GetxController {
  MyAccountController({
    required AccountDeletionBackend backend,
    required this.organizationId,
    required Future<bool> Function() checkOwner,
    required Future<void> Function(AccountDeletion) onDeleted,
  }) : _backend = backend,
       _checkOwner = checkOwner,
       _onDeleted = onDeleted;

  final AccountDeletionBackend _backend;
  final Future<bool> Function() _checkOwner;
  final Future<void> Function(AccountDeletion) _onDeleted;

  /// The bound organization.
  final String organizationId;

  /// Whether the person owns [organizationId]; `null` while it is being read or
  /// when it could not be read, and then nothing can be deleted.
  final RxnBool isOwner = RxnBool();
  final RxBool isCheckingOwner = false.obs;

  final RxString confirmation = ''.obs;
  final RxBool isDeleting = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadOwnership();
  }

  /// Asks the server whether the person owns the organization, so the
  /// screen says what the deletion takes with it before it is confirmed.
  Future<void> loadOwnership() async {
    if (isCheckingOwner.value) return;
    isCheckingOwner.value = true;
    errorMessage.value = '';
    try {
      isOwner.value = await _checkOwner();
    } catch (e) {
      debugPrint('[Account] Could not read the ownership: $e');
      errorMessage.value =
          'Não foi possível carregar sua conta. Verifique a conexão e tente '
          'de novo.';
    } finally {
      isCheckingOwner.value = false;
    }
  }

  /// A member deletes at once; the owner once the id is typed. Nothing
  /// while the ownership is unknown.
  bool get canDelete => switch (isOwner.value) {
    null => false,
    final owner =>
      !isDeleting.value &&
          (!owner || confirmsId(confirmation.value, organizationId)),
  };

  /// "Excluir conta" / "Excluir conta e organização".
  Future<void> deleteAccount() async {
    if (!canDelete) return;
    isDeleting.value = true;
    errorMessage.value = '';
    try {
      final deletion = await _backend.request(
        confirmIds: isOwner.value == true ? [organizationId] : const [],
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
