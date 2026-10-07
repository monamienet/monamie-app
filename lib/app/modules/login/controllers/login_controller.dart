import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  late final AuthGoogleController _loginGoogleController;

  UserGoogleRepository userGoogleRepository = UserGoogleRepository();

  //UserData _user = UserData();

  @override
  Future<void> onInit() async {
    _loginGoogleController = Get.find<AuthGoogleController>();

    super.onInit();
  }

  Future<bool> hasActiveGoogleBond() async {
    try{
    final currentUser = fb.FirebaseAuth.instanceFor(
      //app: Firebase.app('uffmobileplus)
      app: Firebase.app(),
    ).currentUser;
    final storedUser = await userGoogleRepository.getUserGoogleModel();
    final hasStoredUser = storedUser != null && storedUser.email.isNotEmpty;
    return currentUser != null && hasStoredUser;
    }
    catch(e){
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
