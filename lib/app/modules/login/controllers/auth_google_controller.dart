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
import 'package:monamie_app/app/data/services/capabilities.dart';
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
       _brandingLoader = brandingLoader ?? PartnerBrandingLoader(),
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

  /// Google ID token of this sign-in, kept to enter a partner after the
  /// picker or after "verificar de novo" on *Sem organização*.
  String? _pendingIdToken;

  /// E-mail of the Google account signed in to MonAmie (central project),
  /// shown on MonAmie's own screens with "Trocar".
  final RxnString signedInEmail = RxnString();

  /// Why the user is on *Sem organização* after trying to enter a partner
  /// (removed from its groups, or no capability there); `null` otherwise.
  final RxnString noAccessReason = RxnString();

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
  ///
  /// With no partner the user lands on *Sem organização* still signed in to
  /// MonAmie, so they can check again (after accepting an invite) or create
  /// their organization without signing in twice.
  Future<void> _continueWithPartners(String idToken) async {
    _pendingIdToken = idToken;
    signedInEmail.value = await _authGoogle.centralEmail();
    final candidates = await _partnerDirectory.partnersOfSignedInUser();
    if (candidates.isEmpty) {
      Get.offAllNamed(Routes.NO_ORGANIZATION);
      return;
    }
    final bindings = await Future.wait(candidates.map(_brandingLoader.load));
    if (bindings.length == 1) {
      await _enterPartner(bindings.single, idToken);
      return;
    }
    partnerChoices.assignAll(bindings);
    Get.toNamed(Routes.PARTNER_PICKER);
  }

  /// "Já me convidaram · verificar de novo": asks again which partners the
  /// user belongs to, reusing this sign-in when there is one.
  Future<void> recheckPartners() async {
    if (isLoading.value) return;
    isLoading.value = true;
    noAccessReason.value = null;
    try {
      final idToken = _pendingIdToken ?? await _authGoogle.signInGoogle();
      if (idToken != null) await _continueWithPartners(idToken);
    } catch (e) {
      _showLoginError("Não foi possível verificar agora: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// "Criar minha organização". The in-app creation flow (#93) replaces this
  /// notice.
  void startCreatingOrganization() {
    Get.snackbar(
      'Criar organização',
      'A criação de organizações pelo app chega em breve.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// "Trocar de organização": signs out of everything and opens the Google
  /// account chooser again, which leads to the organization picker.
  Future<void> switchOrganization() async {
    // Only ask for an account once the old session is really gone.
    if (await _signOut()) loginGoogle();
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
      // The screen stays in MonAmie's colors until the user is known to
      // belong to the partner: a removed user never sees its brand (#78).
      enteringPartnerName.value = binding.partner.name;
      await _authGoogle.signInToPartner(idToken);

      // Sync the claims first: the rules only let the partner's members
      // write their profile, read the map or write their own position.
      final capabilities = await _syncClaims();
      if (claimsShowNoAccess(capabilities)) {
        // Listed by the central directory (its group cache may still have
        // the user) but no capability here: same outcome as no partner.
        await _authGoogle.signOutOfPartner();
        await _partnerSession.forget();
        noAccessReason.value =
            'Sua conta não tem mais acesso à ${binding.partner.name}.';
        Get.offAllNamed(Routes.NO_ORGANIZATION);
        return;
      }
      _refreshTheme();

      final user = await _authGoogle.savePartnerProfile();
      if (user == null) {
        throw StateError('No user after signing in to ${binding.partner.id}.');
      }
      await _userRepository.saveUserGoogleModel(user);
      final token = await _authGoogle.getFirebaseIdToken();
      await _getGdiGroupsGoogle(token ?? '', user.email);

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

  /// Recomputes the person's capabilities in the partner (`syncClaims`).
  Future<Capabilities?> _syncClaims() => MonAmieClaimsService.syncClaims();

  Future<void> logout() => _signOut();

  /// Forgets the partner after the user was removed from all its groups:
  /// the same steps as [logout], then *Sem organização* saying why.
  Future<void> forgetRemovedPartner() async {
    final name = Partner.current?.name;
    noAccessReason.value = name == null
        ? 'Você não faz mais parte desta organização.'
        : 'Você não faz mais parte da $name.';
    await _signOut(destination: Routes.NO_ORGANIZATION);
  }

  /// Returns whether the sign-out finished.
  Future<bool> _signOut({
    String? reason,
    String destination = Routes.LOGIN,
  }) async {
    if (isLoggingOut.value) return false;

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
      _pendingIdToken = null;
      signedInEmail.value = null;
      Get.offAllNamed(destination);
      if (reason != null) {
        Get.snackbar(
          "Acesso encerrado",
          reason,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          duration: const Duration(seconds: 6),
        );
      }
      return true;
    } catch (e) {
      debugPrint("Erro ao sair: $e");
      Get.snackbar(
        "Erro ao sair",
        "Não foi possível encerrar a sessão. Tente novamente.\nErro: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        duration: const Duration(seconds: 5),
      );
      return false;
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
