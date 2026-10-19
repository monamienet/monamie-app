import 'dart:async';

import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/repository/user_data_repository.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/data/services/flutter_background_service_tracking_stopper.dart';
import 'package:monamie_app/app/data/services/monamie_claims_service.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:get/get.dart';

class AuthGoogleController extends GetxController {
  AuthGoogleController({
    AuthGoogleService? authGoogleService,
    UserGoogleRepository? userRepository,
    BackgroundTrackingStopper? trackingStopper,
  }) : _injectedAuthGoogle = authGoogleService,
       _injectedUserRepository = userRepository,
       _injectedTrackingStopper = trackingStopper;

  final AuthGoogleService? _injectedAuthGoogle;
  final UserGoogleRepository? _injectedUserRepository;
  final BackgroundTrackingStopper? _injectedTrackingStopper;

  late final AuthGoogleService _authGoogle =
      _injectedAuthGoogle ?? AuthGoogleService();
  late final UserGoogleRepository _userRepository =
      _injectedUserRepository ?? UserGoogleRepository();
  late final UserDataRepository _userDataRepository = UserDataRepository();
  late final BackgroundTrackingStopper _trackingStopper =
      _injectedTrackingStopper ?? FlutterBackgroundServiceTrackingStopper();
  StreamSubscription? _webSignInSub;

  // indica se o GoogleSignIn já terminou de inicializar
  final RxBool googleReady = false.obs;

  // indica se uma operação de login está em andamento
  final RxBool isLoading = false.obs;

  // indica se o logout (parada do rastreamento + saída) está em andamento
  final RxBool isLoggingOut = false.obs;

  @override
  void onInit() {
    super.onInit();
    _webSignInSub = _authGoogle.onWebSignIn.listen(_handleLoginResult);

    _authGoogle
        .ensureInitialized()
        .then((_) {
          googleReady.value = true;
        })
        .catchError((_) {
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
        await _syncClaims();

        Get.offNamed(Routes.MONAMIE);
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
        await _syncClaims();

        Get.offNamed(Routes.MONAMIE);
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

  /// Chama a Cloud Function `syncClaims` para sincronizar os
  /// Custom Claims do Firebase Auth com os papéis do usuário nos
  /// grupos do MonAmie. Após a chamada, força refresh do token.
  Future<void> _syncClaims() async {
    await MonAmieClaimsService.syncClaims();
  }

  Future<void> logout() async {
    if (isLoggingOut.value) return;

    isLoggingOut.value = true;
    try {
      // O rastreamento precisa parar ANTES do signOut: o serviço sobrevive ao
      // fechamento da tela, e depois do logout as regras do Firestore recusam
      // a escrita de `isTracked = false`.
      final stopped = await _trackingStopper.stop(email: await _currentEmail());
      if (!stopped) {
        Get.snackbar(
          "Rastreamento",
          "Não foi possível confirmar o encerramento do rastreamento. "
              "Ele será encerrado automaticamente em instantes.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          duration: const Duration(seconds: 5),
        );
      }

      await _authGoogle.logoutGoogle();
      await _userRepository.deleteUserGoogleModel();
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      debugPrint("Erro ao sair: $e");
      Get.snackbar(
        "Erro ao sair",
        "Não foi possível encerrar a sessão. Tente novamente.\nErro: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  /// E-mail do usuário salvo no Hive, a mesma fonte usada pelo
  /// `UserController` para o id do documento em `usuarios`. Uma falha na
  /// leitura não deve impedir o logout.
  Future<String?> _currentEmail() async {
    try {
      return (await _userRepository.getUserGoogleModel())?.email;
    } catch (e) {
      debugPrint("Erro ao ler o usuário salvo antes do logout: $e");
      return null;
    }
  }

  @override
  void onClose() {
    _webSignInSub?.cancel();
    _authGoogle.dispose();
    super.onClose();
  }
}
