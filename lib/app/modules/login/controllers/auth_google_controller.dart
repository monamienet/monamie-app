import 'dart:async';

import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/partner/central_partner_directory.dart';
import 'package:monamie_app/app/data/partner/partner_binding.dart';
import 'package:monamie_app/app/data/partner/partner_branding_loader.dart';
import 'package:monamie_app/app/data/partner/hive_partner_local_data.dart';
import 'package:monamie_app/app/data/partner/partner_directory.dart';
import 'package:monamie_app/app/data/partner/partner_local_data.dart';
import 'package:monamie_app/app/data/partner/partner_membership.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/data/repository/user_data_repository.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/data/services/flutter_background_service_tracking_stopper.dart';
import 'package:monamie_app/app/data/services/monamie_claims_service.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/app_theme.dart';

/// Signs the user in and binds their partner.
///
/// After Google sign-in (central project), the user's partners come from
/// their groups: none shows the "not linked" screen, one is entered
/// directly, several open the partner picker. Entering a partner binds its
/// Firebase project, root group and branding together, then signs in to the
/// partner project and syncs the claims there.
class AuthGoogleController extends GetxController {
  AuthGoogleController({
    AuthGoogleService? authGoogleService,
    UserGoogleRepository? userRepository,
    BackgroundTrackingStopper? trackingStopper,
    PartnerDirectory? partnerDirectory,
    PartnerBrandingLoader? brandingLoader,
    PartnerSession? partnerSession,
    PartnerLocalData? partnerLocalData,
    void Function()? refreshTheme,
  }) : _partnerLocalData = partnerLocalData ?? const HivePartnerLocalData(),
       _injectedAuthGoogle = authGoogleService,
       _injectedUserRepository = userRepository,
       _injectedTrackingStopper = trackingStopper,
       _injectedPartnerDirectory = partnerDirectory,
       _brandingLoader = brandingLoader ?? const PartnerBrandingLoader(),
       _injectedPartnerSession = partnerSession,
       _refreshTheme =
           refreshTheme ?? (() => Get.changeTheme(AppTheme.lightTheme));

  final AuthGoogleService? _injectedAuthGoogle;
  final UserGoogleRepository? _injectedUserRepository;
  final BackgroundTrackingStopper? _injectedTrackingStopper;
  final PartnerDirectory? _injectedPartnerDirectory;
  final PartnerBrandingLoader _brandingLoader;
  final PartnerSession? _injectedPartnerSession;
  final PartnerLocalData _partnerLocalData;

  /// Rebuilds the theme from the bound partner (or MonAmie when none).
  final void Function() _refreshTheme;

  late final PartnerDirectory _partnerDirectory =
      _injectedPartnerDirectory ?? CentralPartnerDirectory();
  late final PartnerSession _partnerSession =
      _injectedPartnerSession ?? PartnerSession();

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

  /// Name of the partner being entered, for the "Entrando em ..." message.
  final RxnString enteringPartnerName = RxnString();

  /// Partners offered by the picker when the user belongs to several.
  final RxList<PartnerBinding> partnerChoices = <PartnerBinding>[].obs;

  /// Google ID token kept while the user picks a partner.
  String? _pendingIdToken;

  @override
  void onInit() {
    super.onInit();
    _webSignInSub = _authGoogle.onWebSignIn.listen(_onWebGoogleSignIn);

    _authGoogle
        .ensureInitialized()
        .then((_) {
          googleReady.value = true;
        })
        .catchError((_) {
          googleReady.value = true;
        });
  }

  Future<void> _onWebGoogleSignIn(String? idToken) async {
    if (idToken == null) {
      _showLoginError(
        "Falha ao autenticar o usuário. Verifique sua conta Google e tente novamente.",
      );
      return;
    }
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _continueWithPartners(idToken);
    } catch (e) {
      _showLoginError("Ocorreu um erro ao carregar seus dados: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Finds the user's partners and enters the only one, or offers a choice.
  Future<void> _continueWithPartners(String idToken) async {
    final candidates = await _partnerDirectory.partnersOfSignedInUser();
    if (candidates.isEmpty) {
      await _authGoogle.logoutGoogle();
      Get.offAllNamed(Routes.NOT_LINKED);
      return;
    }
    final bindings = await Future.wait(candidates.map(_brandingLoader.load));
    if (bindings.length == 1) {
      await _enterPartner(bindings.single, idToken);
      return;
    }
    _pendingIdToken = idToken;
    partnerChoices.assignAll(bindings);
    Get.toNamed(Routes.PARTNER_PICKER);
  }

  /// Enters the partner the user picked in the partner picker.
  Future<void> choosePartner(PartnerBinding binding) async {
    final idToken = _pendingIdToken;
    if (idToken == null || isLoading.value) return;
    isLoading.value = true;
    try {
      await _enterPartner(binding, idToken);
    } catch (e) {
      _showLoginError("Não foi possível entrar em ${binding.partner.name}: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _enterPartner(PartnerBinding binding, String idToken) async {
    try {
      await _partnerSession.bind(binding);
      _refreshTheme();
      // Set after binding, so the screen rebuilds in the partner's brand.
      enteringPartnerName.value = binding.partner.name;
      final user = await _authGoogle.signInToPartner(idToken);
      if (user == null) {
        throw StateError('No user after signing in to ${binding.partner.id}.');
      }
      await _userRepository.saveUserGoogleModel(user);
      final token = await _authGoogle.getFirebaseIdToken();
      await _getGdiGroupsGoogle(token ?? '', user.email);

      // Sincronizar Custom Claims ANTES de navegar.
      // A criação do doc em `usuarios` exige claims de observável.
      final roles = await _syncClaims();
      if (claimsShowNoAccess(roles)) {
        // A group is named after the partner but is not under its root.
        throw StateError(
          'sua conta não tem papel em nenhum grupo de ${binding.partner.name}',
        );
      }

      _pendingIdToken = null;
      partnerChoices.clear();
      Get.offAllNamed(Routes.MONAMIE);
    } catch (_) {
      // Never stay bound to a partner the user could not enter.
      await _partnerSession.forget();
      _refreshTheme();
      rethrow;
    } finally {
      enteringPartnerName.value = null;
    }
  }

  void _showLoginError(String message) {
    Get.snackbar(
      "Erro de Login",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      duration: const Duration(seconds: 5),
    );
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
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final idToken = await _authGoogle.signInGoogle();
      // Na web o login retorna null propositalmente (o resultado chega via
      // stream), portanto não exibimos erro quando idToken é null.
      if (idToken != null) await _continueWithPartners(idToken);
    } catch (e) {
      _showLoginError("Ocorreu um erro inesperado: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Chama a Cloud Function `syncClaims` para sincronizar os
  /// Custom Claims do Firebase Auth com os papéis do usuário nos
  /// grupos do MonAmie. Após a chamada, força refresh do token.
  Future<Map<String, dynamic>?> _syncClaims() =>
      MonAmieClaimsService.syncClaims();

  Future<void> logout() => _signOut();

  /// Forgets the partner after the user was removed from all its groups:
  /// the same steps as [logout], then a message saying why.
  Future<void> forgetRemovedPartner() async {
    final name = Partner.current?.name;
    await _signOut(
      reason: name == null
          ? 'Você não faz mais parte desta organização.'
          : 'Você não faz mais parte da $name.',
    );
  }

  Future<void> _signOut({String? reason}) async {
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
      await _partnerSession.forget();
      await _partnerLocalData.clear();
      _refreshTheme();
      Get.offAllNamed(Routes.LOGIN);
      if (reason != null) {
        Get.snackbar(
          "Acesso encerrado",
          reason,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          duration: const Duration(seconds: 6),
        );
      }
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
