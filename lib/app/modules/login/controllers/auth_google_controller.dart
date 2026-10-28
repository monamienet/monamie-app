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
import 'package:monamie_app/app/data/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/app/modules/account/account_deletion.dart';
import 'package:monamie_app/app/modules/account/account_deletion_backend.dart';
import 'package:monamie_app/app/modules/account/firebase_account_deletion_backend.dart';
import 'package:monamie_app/app/modules/creation/create_organization_controller.dart';
import 'package:monamie_app/app/modules/creation/create_organization_view.dart';
import 'package:monamie_app/app/modules/creation/firebase_creation_backend.dart';
import 'package:monamie_app/app/modules/invites/firebase_invites_backend.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/invites/invites_backend.dart';
import 'package:monamie_app/app/data/services/monamie_claims_service.dart';
import 'package:monamie_app/app/modules/login/id_token_expiry.dart';
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
    InvitesBackend? invitesBackend,
    AccountDeletionBackend? deletionBackend,
    void Function()? refreshTheme,
  }) : _invitesBackend = invitesBackend ?? const FirebaseInvitesBackend(),
       _deletionBackend =
           deletionBackend ?? const FirebaseAccountDeletionBackend(),
       _partnerLocalData = partnerLocalData ?? const HivePartnerLocalData(),
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
  final InvitesBackend _invitesBackend;
  final AccountDeletionBackend _deletionBackend;

  /// The signed-in account's pending deletion, shown on *Em exclusão*.
  final Rxn<AccountDeletion> accountDeletion = Rxn<AccountDeletion>();
  final RxBool cancellingDeletion = false.obs;

  /// The deletion was cancelled: *Em exclusão* says everything is back.
  final RxBool deletionRestored = false.obs;
  final RxString deletionError = ''.obs;

  /// Invites waiting for the signed-in account, shown on *Sem organização*.
  final RxList<Invite> pendingInvites = <Invite>[].obs;

  /// The invite being accepted (its button shows the pending state).
  final RxnString acceptingInvite = RxnString();

  /// Error of the last accept, shown on the invite card.
  final RxString inviteError = ''.obs;

  static const _acceptRetries = 6;
  static const _acceptRetryDelay = Duration(seconds: 4);

  /// The invite just accepted: *Boas-vindas* is shown once, after entering.
  final Rxn<Invite> welcome = Rxn<Invite>();

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

  /// The busy operation is a change of organization, not a sign-out: both set
  /// [isLoggingOut] (the lock and the overlay), and this decides the overlay's
  /// message.
  final RxBool isSwitchingOrganization = false.obs;

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
      await _continueWithPartners(idToken, alwaysPick: true);
    } catch (e) {
      _showLoginError("Ocorreu um erro ao carregar seus dados: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Finds the user's partners and offers a choice. [alwaysPick] (a sign-in
  /// the person just made) shows the choice even for a single partner, so
  /// they see where they are entering; otherwise the only partner is entered
  /// directly (an invite just accepted).
  ///
  /// With no partner the user lands on *Sem organização* still signed in to
  /// MonAmie, so they can check again (after accepting an invite) or create
  /// their organization without signing in twice.
  Future<void> _continueWithPartners(
    String idToken, {
    bool fresh = false,
    bool alwaysPick = false,
  }) async {
    _pendingIdToken = idToken;
    signedInEmail.value = await _authGoogle.centralEmail();
    if (!deletionRestored.value) {
      final deletion = await _pendingDeletion();
      if (deletion != null) {
        accountDeletion.value = deletion;
        Get.offAllNamed(Routes.DELETION_PENDING);
        return;
      }
    }
    deletionRestored.value = false;
    accountDeletion.value = null;
    final candidates = await _partnerDirectory.partnersOfSignedInUser(
      fresh: fresh,
    );
    if (candidates.isEmpty) {
      await _loadInvites();
      Get.offAllNamed(Routes.NO_ORGANIZATION);
      return;
    }
    final bindings = await Future.wait(candidates.map(_brandingLoader.load));
    if (bindings.length == 1 && !alwaysPick) {
      await _enterPartner(bindings.single, idToken);
      return;
    }
    partnerChoices.assignAll(bindings);
    Get.toNamed(Routes.PARTNER_PICKER);
  }

  /// A failing check must not keep anyone out: the account is then
  /// treated as not being deleted.
  Future<AccountDeletion?> _pendingDeletion() async {
    try {
      return await _deletionBackend.pending();
    } catch (e) {
      debugPrint('[Account] Could not read the deletion: $e');
      return null;
    }
  }

  /// *Minha conta* scheduled the deletion: signs out of everything and
  /// shows *Em exclusão*.
  Future<void> accountDeleted(AccountDeletion deletion) async {
    // Registry entries made before in-app creation have no name: the bound
    // partner's display name stands in.
    final partner = Partner.current;
    accountDeletion.value =
        partner != null &&
            deletion.ownedPartners.contains(partner.id) &&
            !deletion.ownedNames.containsKey(partner.id)
        ? AccountDeletion(
            deleteAt: deletion.deleteAt,
            ownedPartners: deletion.ownedPartners,
            ownedNames: {...deletion.ownedNames, partner.id: partner.name},
          )
        : deletion;
    deletionRestored.value = false;
    deletionError.value = '';
    await _signOut(destination: Routes.DELETION_PENDING);
  }

  /// "Cancelar exclusão": signs in again if needed (the deletion signed the
  /// account out), then cancels it.
  Future<void> cancelAccountDeletion() async {
    if (cancellingDeletion.value || isLoading.value) return;
    cancellingDeletion.value = true;
    deletionError.value = '';
    try {
      _pendingIdToken ??= await _authGoogle.signInGoogle();
      if (_pendingIdToken == null) return;
      await _deletionBackend.cancel();
      deletionRestored.value = true;
    } on AccountDeletionException catch (e) {
      deletionError.value = e.message;
    } catch (e) {
      debugPrint('[Account] Cancel failed: $e');
      deletionError.value =
          'Não foi possível cancelar agora. Verifique a conexão e tente de novo.';
    } finally {
      cancellingDeletion.value = false;
    }
  }

  Future<void> _loadInvites() async {
    try {
      pendingInvites.assignAll(await _invitesBackend.mine());
    } catch (e) {
      debugPrint('[Invites] Could not read the invites: $e');
      pendingInvites.clear();
    }
  }

  /// Enters [partnerId] once the central directory lists it. Google's group
  /// directory takes a few seconds to show a new membership (an accepted
  /// invite, a newly created root group), so it asks again without the
  /// server's cache before going on with the sign-in.
  Future<void> _enterWhenListed(String partnerId) async {
    final idToken = _pendingIdToken ?? await _authGoogle.signInGoogle();
    if (idToken == null) return;
    for (var attempt = 0; attempt < _acceptRetries; attempt++) {
      final candidates = await _partnerDirectory.partnersOfSignedInUser(
        fresh: true,
      );
      if (candidates.any((c) => c.id == partnerId)) break;
      await Future<void>.delayed(_acceptRetryDelay);
    }
    await _continueWithPartners(idToken, fresh: true);
  }

  /// "A <nome> está pronta · Entrar": enters the organization just created.
  Future<void> enterCreatedOrganization(String partnerId) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _enterWhenListed(partnerId);
    } catch (e) {
      _showLoginError("Não foi possível entrar agora: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// "Aceitar e entrar": joins the invite's team, then enters its partner
  /// (looked up without the server's cache) and shows *Boas-vindas*.
  Future<void> acceptInvite(Invite invite) async {
    if (acceptingInvite.value != null || isLoading.value) return;
    acceptingInvite.value = invite.id;
    inviteError.value = '';
    try {
      await _invitesBackend.accept(invite);
      welcome.value = invite;
      await _enterWhenListed(invite.partnerId);
    } on InvitesException catch (e) {
      inviteError.value = e.message;
    } catch (e) {
      debugPrint('[Invites] Accept failed: $e');
      inviteError.value =
          'Não foi possível aceitar agora. Verifique a conexão e tente de novo.';
    } finally {
      acceptingInvite.value = null;
    }
  }

  /// "Já me convidaram · verificar de novo": asks again which partners the
  /// user belongs to, reusing this sign-in when there is one.
  Future<void> recheckPartners() async {
    if (isLoading.value) return;
    isLoading.value = true;
    noAccessReason.value = null;
    try {
      final idToken = _pendingIdToken ?? await _authGoogle.signInGoogle();
      if (idToken != null) {
        await _continueWithPartners(idToken, alwaysPick: true);
      }
    } catch (e) {
      _showLoginError("Não foi possível verificar agora: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// "Criar minha organização": the creation flow; a Community organization
  /// is entered as soon as it is ready.
  void startCreatingOrganization() {
    // Registered with GetX so its lifecycle runs (onInit loads the themes);
    // a fresh one each time the flow opens.
    Get.delete<CreateOrganizationController>(force: true);
    final controller = Get.put(
      CreateOrganizationController(
        backend: const FirebaseCreationBackend(),
        themes: const FirestoreThemeCatalog(),
      ),
    );
    Get.to(
      () => CreateOrganizationView(
        controller: controller,
        ownerEmail: signedInEmail.value ?? '',
        onReady: () => enterCreatedOrganization(controller.id.value),
      ),
    );
  }

  /// "Trocar de organização": leaves the bound organization and opens the
  /// organization picker, still signed in with the same Google account.
  ///
  /// The person's organizations are looked up first, so a failing lookup
  /// leaves them where they are instead of unbound. Then the tracking stops
  /// (the service outlives the screen), the organization is forgotten and the
  /// picker, or *Sem organização* when nothing is left, replaces the stack.
  Future<void> switchOrganization() async {
    if (isLoggingOut.value || isLoading.value) return;
    // The token kept since sign-in is used while it is good; only then does
    // Google need to be asked again (which may show its account chooser).
    final kept = _pendingIdToken;
    final idToken = idTokenIsFresh(kept, DateTime.now())
        ? kept
        : await _authGoogle.refreshGoogleIdToken();
    if (idToken == null) {
      // Nothing was changed: the person stays where they are.
      Get.snackbar(
        'Trocar de organização',
        'Não foi possível renovar o acesso com o Google. Tente de novo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        duration: const Duration(seconds: 5),
      );
      return;
    }

    isLoggingOut.value = true;
    isSwitchingOrganization.value = true;
    try {
      final candidates = await _partnerDirectory.partnersOfSignedInUser();
      final bindings = await Future.wait(candidates.map(_brandingLoader.load));

      await _stopTracking();
      await _authGoogle.signOutOfPartner();
      await _userRepository.deleteUserGoogleModel();
      await _partnerSession.forget();
      await _partnerLocalData.clear();
      _refreshTheme();
      _pendingIdToken = idToken;

      if (bindings.isEmpty) {
        await _loadInvites();
        Get.offAllNamed(Routes.NO_ORGANIZATION);
        return;
      }
      partnerChoices.assignAll(bindings);
      Get.offAllNamed(Routes.PARTNER_PICKER);
    } catch (e) {
      debugPrint('Erro ao trocar de organização: $e');
      Get.snackbar(
        'Trocar de organização',
        'Não foi possível trocar agora. Verifique a conexão e tente de novo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoggingOut.value = false;
      isSwitchingOrganization.value = false;
    }
  }

  /// Stops the background tracking and warns when it could not be confirmed.
  /// It must run while the partner is still signed in: after that the rules
  /// refuse the write of `isTracked = false`.
  Future<void> _stopTracking() async {
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

      // The token stays (in memory, until sign-out) so that switching
      // organization does not need Google again while it is still good.
      partnerChoices.clear();
      // Right after accepting an invite to this partner: welcome first.
      final invite = welcome.value;
      if (invite != null && invite.partnerId == binding.partner.id) {
        Get.offAllNamed(Routes.WELCOME);
      } else {
        welcome.value = null;
        Get.offAllNamed(Routes.MONAMIE);
      }
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
      if (idToken != null) {
        await _continueWithPartners(idToken, alwaysPick: true);
      }
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
      await _stopTracking();

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
