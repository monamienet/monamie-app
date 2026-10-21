import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';

class LoginController extends GetxController {
  late final AuthGoogleController _loginGoogleController;

  UserGoogleRepository userGoogleRepository = UserGoogleRepository();

  /// `true` enquanto verifica se há uma sessão válida para restaurar.
  final isRestoringSession = true.obs;

  //UserData _user = UserData();

  @override
  Future<void> onInit() async {
    _loginGoogleController = Get.find<AuthGoogleController>();

    super.onInit();
  }

  /// Restaura a sessão quando o app é recriado do zero — por exemplo, depois
  /// que o Android encerra o processo enquanto o usuário está nas
  /// configurações do sistema. Sem isso o usuário precisaria logar de novo.
  @override
  Future<void> onReady() async {
    super.onReady();
    try {
      if (await hasActiveGoogleBond()) {
        Get.offNamed(Routes.MONAMIE);
      }
    } finally {
      isRestoringSession.value = false;
    }
  }

  Future<bool> hasActiveGoogleBond() async {
    try {
      // No bound partner: the user must sign in and pick one first.
      if (!CurrentPartnerFirebase.isSet) return false;
      final currentUser = CurrentPartnerFirebase.instance.auth.currentUser;
      final storedUser = await userGoogleRepository.getUserGoogleModel();
      final hasStoredUser = storedUser != null && storedUser.email.isNotEmpty;
      return currentUser != null && hasStoredUser;
    } catch (e) {
      debugPrint("Error checking Google bond: $e");
      return false;
    }
  }

  void loginGoogle() {
    _loginGoogleController.loginGoogle();
  }

  //void loginAnonimous() {
  //  Get.offAllNamed(Routes.HOME);
  //}

  void logoutGoogle() {
    _loginGoogleController.logout();
  }
}
