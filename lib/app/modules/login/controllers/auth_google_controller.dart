import 'dart:async';

import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/repository/user_data_repository.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/harpia_claims_service.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthGoogleController extends GetxController {
  AuthGoogleController();

  late final AuthGoogleService _authGoogle = AuthGoogleService();
  late final UserGoogleRepository _userRepository = UserGoogleRepository();
  late final UserDataRepository _userDataRepository = UserDataRepository();
  StreamSubscription? _webSignInSub;

  // indica se o GoogleSignIn já terminou de inicializar
  final RxBool googleReady = false.obs;

  // indica se uma operação de login está em andamento
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _webSignInSub = _authGoogle.onWebSignIn.listen(_handleLoginResult);

    _authGoogle.ensureInitialized().then((_) {
      googleReady.value = true;
    }).catchError((_) {
      googleReady.value = true;
    });
  }

  Future<void> _handleLoginResult(dynamic user) async {
    if (user != null) {
      try {
        String? token = await _authGoogle.getFirebaseIdToken();
        await _userRepository.saveUserGoogleModel(user);
        //await Get.find<UserController>().loadCurrentUser();
        await _getGdiGroupsGoogle(token ?? '', user.email);

        // Sincronizar Custom Claims ANTES de navegar.
        // A criação do doc em `usuarios` exige claims de observável.
        await _syncHarpiaClaims();

        Get.offNamed(Routes.MONITORA_UFF);
      } catch (e) {
        Get.snackbar(
          "Erro ao finalizar login",
          "Ocorreu um erro ao carregar seus dados: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          duration: const Duration(seconds: 5),
        );
      }
    } else {
      Get.snackbar(
        "Erro de Login",
        "Falha ao autenticar o usuário. Verifique sua conta Google e tente novamente.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _getGdiGroupsGoogle(String token, String email) async {
    try {
      GdiGroupsGoogle gdiGroups = await _userRepository.getGdiGroupsGoogle(
        token,
        email,
      );
      // TODO: o comando abaixo retorna a promessa de uma String s,
      // mas nada é feito com s. Por isso, talvez eu possa remover o await.
      await _userDataRepository.updateGdiGroupsGoogle(gdiGroups);
    } catch (e) {
      debugPrint("Erro ao obter grupos GDI Google: $e");
      Get.snackbar(
        "Aviso",
        "Não foi possível carregar seus grupos. Algumas funcionalidades podem ficar limitadas.\nErro: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        duration: const Duration(seconds: 5),
      );
    }
  }

  //Future<void> _getGoogleGroupMembers(String token, String groupEmail) async {
  //  try {
  //    GdiGroupsGoogle gdiGroups = await _userRepository.getGdiGroupsGoogle(
  //      token,
  //      groupEmail,
  //    );
  //    
  //    // TODO: o comando abaixo retorna a promessa de uma String s,
  //    // mas nada é feito com s. Por isso, talvez eu possa remover o await.
  //    await _userDataRepository.updateGdiGroupsGoogle(gdiGroups);
  //  } catch (e) {
  //    debugPrint("Erro ao obter grupos GDI Google: $e");
  //  }
  //}
  
  void loginGoogle() async {
    isLoading.value = true;
    try {
      final user = await _authGoogle.signInGoogle();
      if (user != null) {
        await _handleLoginResult(user);
      }
      // Na web o login retorna null propositalmente (o resultado chega via stream),
      // portanto não exibimos erro quando user é null.
    } catch (e) {
      Get.snackbar(
        "Erro de Login",
        "Ocorreu um erro inesperado: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> tryLogin() async {
    isLoading.value = true;
    try {
      var hasLogged = await _authGoogle.trySignInGoogle();
      if (hasLogged != null) {
        //await Get.find<UserController>().loadCurrentUser();
        String? token = await _authGoogle.getFirebaseIdToken();
        await _getGdiGroupsGoogle(token ?? '', hasLogged.email);

        // Sincronizar Custom Claims ANTES de navegar.
        await _syncHarpiaClaims();

        Get.offNamed(Routes.MONITORA_UFF);
      } else {
        Get.offNamed(Routes.LOGIN);
      }
    } catch (e) {
      debugPrint("Erro ao tentar login automático: $e");
      Get.offNamed(Routes.LOGIN);
    } finally {
      isLoading.value = false;
    }
  }

  /// Chama a Cloud Function `syncHarpiaClaims` para sincronizar os
  /// Custom Claims do Firebase Auth com os papéis do usuário nos
  /// grupos do Harpia. Após a chamada, força refresh do token.
  Future<void> _syncHarpiaClaims() async {
    await HarpiaClaimsService.syncClaims();
  }

  Future<void> logout() async {
    await _authGoogle.logoutGoogle();
    await _userRepository.deleteUserGoogleModel();
    Get.offAllNamed(Routes.LOGIN);
  }

  @override
  void onClose() {
    _webSignInSub?.cancel();
    _authGoogle.dispose();
    super.onClose();
  }
}
