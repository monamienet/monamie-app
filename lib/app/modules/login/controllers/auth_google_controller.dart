import 'dart:async';

import 'package:flutter/material.dart';
import 'package:monamie_app/app/data/groups/firestore_organization_membership_check.dart';
import 'package:monamie_app/app/data/groups/organization_membership_check.dart';
import 'package:monamie_app/app/data/organization/central_organization_directory.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/data/organization/organization_branding_loader.dart';
import 'package:monamie_app/app/data/organization/hive_organization_local_data.dart';
import 'package:monamie_app/app/data/organization/organization_directory.dart';
import 'package:monamie_app/app/data/organization/organization_local_data.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/data/services/flutter_background_service_tracking_stopper.dart';
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
import 'package:monamie_app/app/modules/login/id_token_expiry.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/utils/app_theme.dart';

/// Signs the user in and binds their organization.
///
/// After Google sign-in (central project), the user's organizations come from
/// the central `resolveOrganizations`: none shows the "not linked" screen,
/// one is entered directly, several open the organization picker. Entering
/// an organization binds its Firebase project and branding together, signs
/// in to the organization project and checks there that the person still
/// has a membership.
class AuthGoogleController extends GetxController {
  AuthGoogleController({
    AuthGoogleService? authGoogleService,
    UserGoogleRepository? userRepository,
    BackgroundTrackingStopper? trackingStopper,
    OrganizationDirectory? organizationDirectory,
    OrganizationBrandingLoader? brandingLoader,
    OrganizationSession? organizationSession,
    OrganizationLocalData? organizationLocalData,
    InvitesBackend? invitesBackend,
    AccountDeletionBackend? deletionBackend,
    OrganizationMembershipCheck? membershipCheck,
    void Function()? refreshTheme,
  }) : _membershipCheck =
           membershipCheck ?? const FirestoreOrganizationMembershipCheck(),
       _invitesBackend = invitesBackend ?? const FirebaseInvitesBackend(),
       _deletionBackend =
           deletionBackend ?? const FirebaseAccountDeletionBackend(),
       _organizationLocalData =
           organizationLocalData ?? const HiveOrganizationLocalData(),
       _injectedAuthGoogle = authGoogleService,
       _injectedUserRepository = userRepository,
       _injectedTrackingStopper = trackingStopper,
       _injectedOrganizationDirectory = organizationDirectory,
       _brandingLoader = brandingLoader ?? OrganizationBrandingLoader(),
       _injectedOrganizationSession = organizationSession,
       _refreshTheme =
           refreshTheme ?? (() => Get.changeTheme(AppTheme.lightTheme));

  final AuthGoogleService? _injectedAuthGoogle;
  final UserGoogleRepository? _injectedUserRepository;
  final BackgroundTrackingStopper? _injectedTrackingStopper;
  final OrganizationDirectory? _injectedOrganizationDirectory;
  final OrganizationBrandingLoader _brandingLoader;
  final OrganizationSession? _injectedOrganizationSession;
  final OrganizationLocalData _organizationLocalData;
  final InvitesBackend _invitesBackend;
  final AccountDeletionBackend _deletionBackend;
  final OrganizationMembershipCheck _membershipCheck;

  /// The signed-in account's pending deletion, shown on *Em exclusão*.
  final Rxn<AccountDeletion> accountDeletion = Rxn<AccountDeletion>();
  final RxBool cancellingDeletion = false.obs;

  /// The deletion was cancelled: *Em exclusão* says everything is back.
  final RxBool deletionRestored = false.obs;
  final RxString deletionError = ''.obs;

  /// Invites waiting for the signed-in account, shown on *Sem organização*
  /// and *Escolher organização*.
  final RxList<Invite> pendingInvites = <Invite>[].obs;

  /// The invite being accepted (its button shows the pending state).
  final RxnString acceptingInvite = RxnString();

  /// Error of the last accept, shown on the invite card.
  final RxString inviteError = ''.obs;

  /// The invite just accepted: *Boas-vindas* is shown once, after entering.
  final Rxn<Invite> welcome = Rxn<Invite>();

  /// Rebuilds the theme from the bound organization (or MonAmie when none).
  final void Function() _refreshTheme;

  late final OrganizationDirectory _organizationDirectory =
      _injectedOrganizationDirectory ?? CentralOrganizationDirectory();
  late final OrganizationSession _organizationSession =
      _injectedOrganizationSession ?? OrganizationSession();

  late final AuthGoogleService _authGoogle =
      _injectedAuthGoogle ?? AuthGoogleService();
  late final UserGoogleRepository _userRepository =
      _injectedUserRepository ?? UserGoogleRepository();
  late final BackgroundTrackingStopper _trackingStopper =
      _injectedTrackingStopper ?? FlutterBackgroundServiceTrackingStopper();
  StreamSubscription? _webSignInSub;

  // indica se o GoogleSignIn já terminou de inicializar
  final RxBool googleReady = false.obs;

  // indica se uma operação de login está em andamento
  final RxBool isLoading = false.obs;

  /// The login button was tapped and the sign-in has not finished: Google's
  /// account chooser may be open. Guards against a second tap without showing
  /// [isLoading]'s "Procurando sua organização…", which only makes sense once an
  /// account is chosen.
  final RxBool isChoosingAccount = false.obs;

  // indica se o logout (parada do rastreamento + saída) está em andamento
  final RxBool isLoggingOut = false.obs;

  /// The busy operation is a change of organization, not a sign-out: both set
  /// [isLoggingOut] (the lock and the overlay), and this decides the overlay's
  /// message.
  final RxBool isSwitchingOrganization = false.obs;

  /// Name of the organization being entered, for the "Entrando em ..." message.
  final RxnString enteringOrganizationName = RxnString();

  /// Organizations offered by the picker when the user belongs to several.
  final RxList<OrganizationBinding> organizationChoices =
      <OrganizationBinding>[].obs;

  /// Google ID token of this sign-in, kept to enter an organization after the
  /// picker or after "verificar de novo" on *Sem organização*.
  String? _pendingIdToken;

  /// E-mail of the Google account signed in to MonAmie (central project),
  /// shown on MonAmie's own screens with "Trocar".
  final RxnString signedInEmail = RxnString();

  /// Why the user is on *Sem organização* after trying to enter an
  /// organization (no membership there any more); `null` otherwise.
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
      await _continueWithOrganizations(idToken, alwaysPick: true);
    } catch (e) {
      _showLoginError("Ocorreu um erro ao carregar seus dados: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Finds the user's organizations and offers a choice. [alwaysPick] (a sign-in
  /// the person just made) shows the choice even for a single organization, so
  /// they see where they are entering; otherwise the only organization is entered
  /// directly. [enter] (an invite just accepted, an organization just
  /// created) is entered directly whenever it is listed.
  ///
  /// With no organization the user lands on *Sem organização* still signed in to
  /// MonAmie, so they can check again (after accepting an invite) or create
  /// their organization without signing in twice. Both screens show the
  /// pending invites: someone already in an organization can be invited to
  /// another one, or to another group.
  Future<void> _continueWithOrganizations(
    String idToken, {
    bool alwaysPick = false,
    String? enter,
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
    final candidates = await _organizationDirectory
        .organizationsOfSignedInUser();
    if (candidates.isEmpty) {
      await _loadInvites();
      Get.offAllNamed(Routes.NO_ORGANIZATION);
      return;
    }
    final bindings = await Future.wait(candidates.map(_brandingLoader.load));
    final target =
        bindings.firstWhereOrNull((b) => b.organization.id == enter) ??
        (bindings.length == 1 && !alwaysPick ? bindings.single : null);
    if (target != null) {
      await _enterOrganization(target, idToken);
      return;
    }
    await _loadInvites();
    organizationChoices.assignAll(bindings);
    Get.toNamed(Routes.ORGANIZATION_PICKER);
  }

  /// Whether the signed-in user owns each organization read so far (by id),
  /// as [loadOwnership] last read it; cleared on sign-out. The owner-only
  /// menu entries (*Administradores*) follow it.
  final RxMap<String, bool> ownership = <String, bool>{}.obs;
  bool _readingOwnership = false;

  /// Reads once whether the signed-in user owns [organizationId] into
  /// [ownership]. A failure leaves it unknown, so owner-only entries stay
  /// hidden (the server refuses anyone else anyway) and the next call
  /// retries.
  Future<void> loadOwnership(String organizationId) async {
    if (_readingOwnership || ownership.containsKey(organizationId)) return;
    _readingOwnership = true;
    try {
      ownership[organizationId] = await ownsOrganization(organizationId);
    } catch (e) {
      debugPrint('[Account] Could not read the ownership: $e');
    } finally {
      _readingOwnership = false;
    }
  }

  /// Whether the signed-in user owns organization [organizationId] (*titular*), as
  /// the server says now. Throws when it cannot be read.
  Future<bool> ownsOrganization(String organizationId) async {
    final candidates = await _organizationDirectory
        .organizationsOfSignedInUser();
    return candidates.any((c) => c.id == organizationId && c.owner);
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
    // organization's display name stands in.
    final organization = Organization.current;
    accountDeletion.value =
        organization != null &&
            deletion.ownedOrganizationIds.contains(organization.id) &&
            !deletion.ownedOrganizationNames.containsKey(organization.id)
        ? AccountDeletion(
            deleteAt: deletion.deleteAt,
            ownedOrganizationIds: deletion.ownedOrganizationIds,
            ownedOrganizationNames: {
              ...deletion.ownedOrganizationNames,
              organization.id: organization.name,
            },
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

  /// Enters [organizationId], which just became the person's (an invite
  /// accepted, an organization created), without the picker in between. The
  /// memberships live in Firestore, so the central directory lists it at
  /// once; if it does not, the picker shows, never another organization
  /// silently.
  Future<void> _enterNew(String organizationId) async {
    final idToken = _pendingIdToken ?? await _authGoogle.signInGoogle();
    if (idToken == null) return;
    await _continueWithOrganizations(
      idToken,
      alwaysPick: true,
      enter: organizationId,
    );
  }

  /// "A <nome> está pronta · Entrar": enters the organization just created.
  Future<void> enterCreatedOrganization(String organizationId) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _enterNew(organizationId);
    } catch (e) {
      _showLoginError("Não foi possível entrar agora: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// "Aceitar e entrar": joins the invite's group, then enters its
  /// organization and shows *Boas-vindas*.
  Future<void> acceptInvite(Invite invite) async {
    if (acceptingInvite.value != null || isLoading.value) return;
    acceptingInvite.value = invite.id;
    inviteError.value = '';
    try {
      await _invitesBackend.accept(invite);
      welcome.value = invite;
      await _enterNew(invite.organizationId);
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

  /// "Já me convidaram · verificar de novo": asks again which organizations the
  /// user belongs to, reusing this sign-in when there is one.
  Future<void> recheckOrganizations() async {
    if (isLoading.value) return;
    isLoading.value = true;
    noAccessReason.value = null;
    try {
      final idToken = _pendingIdToken ?? await _authGoogle.signInGoogle();
      if (idToken != null) {
        await _continueWithOrganizations(idToken, alwaysPick: true);
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
      final candidates = await _organizationDirectory
          .organizationsOfSignedInUser();
      final bindings = await Future.wait(candidates.map(_brandingLoader.load));

      await _stopTracking();
      await _authGoogle.signOutOfOrganization();
      await _userRepository.deleteUserGoogleModel();
      await _organizationSession.forget();
      await _organizationLocalData.clear();
      _refreshTheme();
      _pendingIdToken = idToken;

      await _loadInvites();
      if (bindings.isEmpty) {
        Get.offAllNamed(Routes.NO_ORGANIZATION);
        return;
      }
      organizationChoices.assignAll(bindings);
      Get.offAllNamed(Routes.ORGANIZATION_PICKER);
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
  /// It must run while the organization is still signed in: after that the rules
  /// refuse the write of `isPublishing = false`.
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

  /// Enters the organization the user picked in the organization picker.
  Future<void> chooseOrganization(OrganizationBinding binding) async {
    final idToken = _pendingIdToken;
    if (idToken == null || isLoading.value) return;
    isLoading.value = true;
    try {
      await _enterOrganization(binding, idToken);
    } catch (e) {
      _showLoginError(
        "Não foi possível entrar em ${binding.organization.name}: $e",
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _enterOrganization(
    OrganizationBinding binding,
    String idToken,
  ) async {
    try {
      await _organizationSession.bind(binding);
      // The screen stays in MonAmie's colors until the user is known to
      // belong to the organization: a removed user never sees its brand (#78).
      enteringOrganizationName.value = binding.organization.name;
      await _authGoogle.signInToOrganization(idToken);

      // The person's membership first: the rules only let the
      // organization's members read the map or write their own position.
      // A failed read (null) is not evidence of removal.
      final member = await _membershipCheck.isMemberOf(binding.organization.id);
      if (member == false) {
        // Listed by the central directory (`accounts` may lag behind the
        // organization) but no membership here: same outcome as no
        // organization.
        await _authGoogle.signOutOfOrganization();
        await _organizationSession.forget();
        noAccessReason.value =
            'Sua conta não tem mais acesso à ${binding.organization.name}.';
        Get.offAllNamed(Routes.NO_ORGANIZATION);
        return;
      }
      _refreshTheme();

      final user = await _authGoogle.saveOrganizationProfile();
      if (user == null) {
        throw StateError(
          'No user after signing in to ${binding.organization.id}.',
        );
      }
      await _userRepository.saveUserGoogleModel(user);

      // The token stays (in memory, until sign-out) so that switching
      // organization does not need Google again while it is still good.
      organizationChoices.clear();
      // Right after accepting an invite to this organization: welcome first.
      final invite = welcome.value;
      if (invite != null && invite.organizationId == binding.organization.id) {
        Get.offAllNamed(Routes.WELCOME);
      } else {
        welcome.value = null;
        Get.offAllNamed(Routes.MONAMIE);
      }
    } catch (_) {
      // Never stay bound to an organization the user could not enter.
      await _organizationSession.forget();
      _refreshTheme();
      rethrow;
    } finally {
      enteringOrganizationName.value = null;
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

  void loginGoogle() async {
    if (isLoading.value || isChoosingAccount.value) return;
    isChoosingAccount.value = true;
    try {
      // The spinner waits for an account: while Google's chooser is open there
      // is no organization to look for yet.
      final idToken = await _authGoogle.signInGoogle(
        onAccountChosen: () => isLoading.value = true,
      );
      // Na web o login retorna null propositalmente (o resultado chega via
      // stream), portanto não exibimos erro quando idToken é null.
      if (idToken != null) {
        await _continueWithOrganizations(idToken, alwaysPick: true);
      }
    } catch (e) {
      _showLoginError("Ocorreu um erro inesperado: $e");
    } finally {
      isLoading.value = false;
      isChoosingAccount.value = false;
    }
  }

  Future<void> logout() => _signOut();

  /// Forgets the organization after the user's membership was removed:
  /// the same steps as [logout], then *Sem organização* saying why.
  Future<void> forgetRemovedOrganization() async {
    final name = Organization.current?.name;
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
      // a escrita de `isPublishing = false`.
      await _stopTracking();

      await _authGoogle.logoutGoogle();
      await _userRepository.deleteUserGoogleModel();
      await _organizationSession.forget();
      await _organizationLocalData.clear();
      _refreshTheme();
      _pendingIdToken = null;
      signedInEmail.value = null;
      ownership.clear();
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
  /// `UserController` para o id do documento em `positions`. Uma falha na
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
