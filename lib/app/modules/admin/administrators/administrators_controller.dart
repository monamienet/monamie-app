import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'administrators.dart';
import 'administrators_backend.dart';

/// State of *Administradores*, the owner's screen: who administers the
/// organization, appointing a member and turning an administrator back
/// into a member. One change at a time: [workingEmail] guards reentrancy
/// and marks the row in flight; it always resets in `finally`.
class AdministratorsController extends GetxController {
  AdministratorsController({
    required this.organizationId,
    required this.backend,
  });

  final String organizationId;

  /// The central functions (a fake in tests).
  final AdministratorsBackend backend;

  final Rx<OrganizationAdministrators> people =
      const OrganizationAdministrators().obs;
  final RxBool isLoading = false.obs;

  /// The e-mail whose role is being changed, or `null`.
  final RxnString workingEmail = RxnString();
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      people.value = await backend.list(organizationId);
    } on AdministratorsException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      debugPrint('[Administrators] Could not load: $e');
      errorMessage.value = 'Não foi possível carregar os administradores.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Makes [email] an administrator ([admin] true) or a member again;
  /// returns whether it changed (the message is in [errorMessage] when not).
  Future<bool> setAdministrator(String email, {required bool admin}) async {
    if (workingEmail.value != null || isLoading.value) return false;
    workingEmail.value = email;
    errorMessage.value = '';
    try {
      await backend.setAdministrator(organizationId, email, admin: admin);
      people.value = await backend.list(organizationId);
      return true;
    } on AdministratorsException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      debugPrint('[Administrators] Change failed: $e');
      errorMessage.value =
          'Não foi possível concluir agora. Verifique a conexão e tente de novo.';
      return false;
    } finally {
      workingEmail.value = null;
    }
  }
}
