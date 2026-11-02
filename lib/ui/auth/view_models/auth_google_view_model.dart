import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/membership/organization_membership_check.dart';
import 'package:monamie_app/domain/models/organization/organization_binding.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_binder.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_backend.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/data/repositories/invites/invites_backend.dart';
import 'package:monamie_app/ui/auth/view_models/sign_in_actions.dart';
import 'package:monamie_app/ui/auth/view_models/auth_google_state.dart';
import 'package:monamie_app/ui/auth/view_models/session_flow.dart';
import 'package:monamie_app/ui/auth/view_models/session_state.dart';
import 'package:monamie_app/data/services/auth/id_token_expiry.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/ui/core/ui/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

export 'auth_google_state.dart';
export 'session_flow.dart';
export 'session_state.dart';

/// Signs the user in and binds their organization.
///
/// After Google sign-in (central project), the user's organizations come from
/// the central `resolveOrganizations`: none shows the "not linked" screen,
/// one is entered directly, several open the organization picker. Entering
/// an organization binds its Firebase project and branding together, signs
/// in to the organization project and checks there that the person still
/// has a membership.
///
/// [AuthGoogleState.session] (also [session]) says where the flow stands;
/// the controller never navigates: the router redirects to the session's
/// screen whenever it changes. The app scope that creates the controller
/// calls [start] once; [dispose] stops listening to the web sign-in.
class AuthGoogleViewModel extends ChangeNotifier
    implements SignInActions, SessionFlow {
  /// [notices] shows the messages no screen is waiting for: those of the web
  /// sign-in (a stream), of a sign-out started by a controller (removal from
  /// the organization, account deletion) and the tracking warning, which
  /// shows after the screen that started the sign-out is gone.
  /// [refreshTheme] rebuilds the app's theme from the bound organization (or
  /// MonAmie's when none).
  AuthGoogleViewModel({
    required this._notices,
    required this._refreshTheme,
    required this._authGoogle,
    required this._userRepository,
    required this._trackingStopper,
    required this._organizationDirectory,
    required this._brandingLoader,
    required this._organizationSession,
    required this._organizationLocalData,
    required this._invitesBackend,
    required this._deletionBackend,
    required this._membershipCheck,
  });

  final NoticePresenter _notices;
  final AuthGoogleService _authGoogle;
  final UserGoogleRepository _userRepository;
  final BackgroundTrackingStopper _trackingStopper;
  final OrganizationDirectory _organizationDirectory;
  final OrganizationBrandingLoader _brandingLoader;
  final OrganizationBinder _organizationSession;
  final OrganizationLocalData _organizationLocalData;
  final InvitesBackend _invitesBackend;
  final AccountDeletionBackend _deletionBackend;
  final OrganizationMembershipCheck _membershipCheck;

  /// Rebuilds the theme from the bound organization (or MonAmie when none).
  final void Function() _refreshTheme;
  StreamSubscription<String?>? _webSignInSub;
  bool _started = false;
  bool _disposed = false;

  AuthGoogleState _state = const AuthGoogleState();

  /// What the entry screens show; replaced whole, never changed in place.
  @override
  AuthGoogleState get state => _state;

  final ValueNotifier<SessionState> _session = ValueNotifier(
    const SessionState.signedOut(),
  );

  @override
  ValueListenable<SessionState> get session => _session;

  /// Replaces the state, notifying only when it differs; [session] follows
  /// its `session` (and notifies only when that changes).
  void _emit(AuthGoogleState next) {
    final changed = next != _state;
    _state = next;
    if (_disposed) return;
    if (changed) notifyListeners();
    _session.value = next.session;
  }

  /// Sets where the flow stands; the router takes the person there.
  void _moveTo(SessionState session) =>
      _emit(_state.copyWith(session: session));

  /// Google ID token of this sign-in, kept to enter an organization after the
  /// picker or after "verificar de novo" on *Sem organização*.
  String? _pendingIdToken;

  /// Listens to the web sign-in and initializes Google Sign-In; runs once,
  /// called by whoever creates the controller.
  void start() {
    if (_started) return;
    _started = true;
    _webSignInSub = _authGoogle.onWebSignIn.listen(_onWebGoogleSignIn);

    _authGoogle
        .ensureInitialized()
        .then((_) {
          _emit(_state.copyWith(googleReady: true));
        })
        .catchError((_) {
          _emit(_state.copyWith(googleReady: true));
        });
  }

  /// The invite just accepted was welcomed (*Boas-vindas* closed): the
  /// person goes on to the map.
  @override
  void finishWelcome() {
    _emit(_state.copyWith(welcome: null, session: const SessionState.bound()));
  }

  /// A session remembered from a previous run was restored by *Login*:
  /// the person goes straight to the map.
  @override
  void sessionRestored() {
    _emit(_state.copyWith(session: const SessionState.bound()));
  }

  Future<void> _onWebGoogleSignIn(String? idToken) async {
    if (idToken == null) {
      _notices.show(
        const UserNotice(
          "Falha ao autenticar o usuário. Verifique sua conta Google e tente novamente.",
          title: _loginErrorTitle,
        ),
      );
      return;
    }
    if (_state.isLoading) return;
    _emit(_state.copyWith(isLoading: true));
    try {
      await _continueWithOrganizations(idToken, alwaysPick: true);
    } catch (e) {
      _notices.show(
        UserNotice(
          "Ocorreu um erro ao carregar seus dados: $e",
          title: _loginErrorTitle,
        ),
      );
    } finally {
      _emit(_state.copyWith(isLoading: false));
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
    final email = await _authGoogle.centralEmail();
    _emit(_state.copyWith(signedInEmail: email));
    if (!_state.deletionRestored) {
      final deletion = await _pendingDeletion();
      if (deletion != null) {
        _emit(_state.copyWith(accountDeletion: deletion));
        _moveTo(const SessionState.deletionPending());
        return;
      }
    }
    _emit(_state.copyWith(deletionRestored: false, accountDeletion: null));
    final candidates = await _organizationDirectory
        .organizationsOfSignedInUser();
    if (candidates.isEmpty) {
      await _loadInvites();
      _moveTo(const SessionState.noOrganization());
      return;
    }
    final bindings = await Future.wait(candidates.map(_brandingLoader.load));
    final target =
        bindings.where((b) => b.organization.id == enter).firstOrNull ??
        (bindings.length == 1 && !alwaysPick ? bindings.single : null);
    if (target != null) {
      await _enterOrganization(target, idToken);
      return;
    }
    await _loadInvites();
    _moveTo(SessionState.picking(bindings));
  }

  bool _readingOwnership = false;

  /// Reads once whether the signed-in user owns [organizationId] into
  /// [AuthGoogleState.ownership]. A failure leaves it unknown, so owner-only entries stay
  /// hidden (the server refuses anyone else anyway) and the next call
  /// retries.
  @override
  Future<void> loadOwnership(String organizationId) async {
    if (_readingOwnership || _state.ownership.containsKey(organizationId)) {
      return;
    }
    _readingOwnership = true;
    try {
      final owns = await ownsOrganization(organizationId);
      _emit(
        _state.copyWith(ownership: {..._state.ownership, organizationId: owns}),
      );
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
    final shown =
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
    _emit(
      _state.copyWith(
        accountDeletion: shown,
        deletionRestored: false,
        deletionError: '',
      ),
    );
    _showFailure(
      await _signOut(destination: const SessionState.deletionPending()),
    );
  }

  /// "Cancelar exclusão": signs in again if needed (the deletion signed the
  /// account out), then cancels it.
  @override
  Future<void> cancelAccountDeletion() async {
    if (_state.cancellingDeletion || _state.isLoading) return;
    _emit(_state.copyWith(cancellingDeletion: true, deletionError: ''));
    try {
      _pendingIdToken ??= await _authGoogle.signInGoogle();
      if (_pendingIdToken == null) return;
      await _deletionBackend.cancel();
      _emit(_state.copyWith(deletionRestored: true));
    } on AccountDeletionException catch (e) {
      _emit(_state.copyWith(deletionError: e.message));
    } catch (e) {
      debugPrint('[Account] Cancel failed: $e');
      _emit(
        _state.copyWith(
          deletionError:
              'Não foi possível cancelar agora. Verifique a conexão e tente '
              'de novo.',
        ),
      );
    } finally {
      _emit(_state.copyWith(cancellingDeletion: false));
    }
  }

  Future<void> _loadInvites() async {
    try {
      final invites = await _invitesBackend.mine();
      _emit(_state.copyWith(pendingInvites: invites));
    } catch (e) {
      debugPrint('[Invites] Could not read the invites: $e');
      _emit(_state.copyWith(pendingInvites: const []));
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

  /// "A `<nome>` está pronta · Entrar": enters the organization just created.
  /// [Err] says why it could not; [Ok] also while another entry runs.
  Future<Result<void>> enterCreatedOrganization(String organizationId) async {
    if (_state.isLoading) return const Ok(null);
    _emit(_state.copyWith(isLoading: true));
    try {
      await _enterNew(organizationId);
      return const Ok(null);
    } catch (e, stackTrace) {
      return _loginError("Não foi possível entrar agora: $e", e, stackTrace);
    } finally {
      _emit(_state.copyWith(isLoading: false));
    }
  }

  /// "Aceitar e entrar": joins the invite's group, then enters its
  /// organization and shows *Boas-vindas*.
  @override
  Future<void> acceptInvite(Invite invite) async {
    if (_state.acceptingInvite != null || _state.isLoading) return;
    _emit(_state.copyWith(acceptingInvite: invite.id, inviteError: ''));
    try {
      await _invitesBackend.accept(invite);
      _emit(_state.copyWith(welcome: invite));
      await _enterNew(invite.organizationId);
    } on InvitesException catch (e) {
      _emit(_state.copyWith(inviteError: e.message));
    } catch (e) {
      debugPrint('[Invites] Accept failed: $e');
      _emit(
        _state.copyWith(
          inviteError:
              'Não foi possível aceitar agora. Verifique a conexão e tente '
              'de novo.',
        ),
      );
    } finally {
      _emit(_state.copyWith(acceptingInvite: null));
    }
  }

  /// "Já me convidaram · verificar de novo": asks again which organizations the
  /// user belongs to, reusing this sign-in when there is one. [Err] says why
  /// it could not; [Ok] also while another operation runs.
  @override
  Future<Result<void>> recheckOrganizations() async {
    if (_state.isLoading) return const Ok(null);
    _emit(_state.copyWith(isLoading: true, noAccessReason: null));
    try {
      final idToken = _pendingIdToken ?? await _authGoogle.signInGoogle();
      if (idToken != null) {
        await _continueWithOrganizations(idToken, alwaysPick: true);
      }
      return const Ok(null);
    } catch (e, stackTrace) {
      return _loginError("Não foi possível verificar agora: $e", e, stackTrace);
    } finally {
      _emit(_state.copyWith(isLoading: false));
    }
  }

  /// "Trocar de organização": leaves the bound organization and opens the
  /// organization picker, still signed in with the same Google account.
  ///
  /// The person's organizations are looked up first, so a failing lookup
  /// leaves them where they are instead of unbound. Then the tracking stops
  /// (the service outlives the screen), the organization is forgotten and the
  /// picker, or *Sem organização* when nothing is left, replaces the stack.
  /// [Err] says why nothing changed; [Ok] also while another operation runs.
  @override
  Future<Result<void>> switchOrganization() async {
    if (_state.isLoggingOut || _state.isLoading) return const Ok(null);
    // The token kept since sign-in is used while it is good; only then does
    // Google need to be asked again (which may show its account chooser).
    final kept = _pendingIdToken;
    final idToken = idTokenIsFresh(kept, DateTime.now())
        ? kept
        : await _authGoogle.refreshGoogleIdToken();
    if (idToken == null) {
      // Nothing was changed: the person stays where they are.
      return const Err(
        'Não foi possível renovar o acesso com o Google. Tente de novo.',
        title: _switchTitle,
      );
    }

    _emit(_state.copyWith(isLoggingOut: true, isSwitchingOrganization: true));
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
        _moveTo(const SessionState.noOrganization());
        return const Ok(null);
      }
      _moveTo(SessionState.picking(bindings));
      return const Ok(null);
    } catch (e, stackTrace) {
      debugPrint('Erro ao trocar de organização: $e');
      return Err(
        'Não foi possível trocar agora. Verifique a conexão e tente de novo.',
        title: _switchTitle,
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _emit(
        _state.copyWith(isLoggingOut: false, isSwitchingOrganization: false),
      );
    }
  }

  /// Stops the background tracking and warns when it could not be confirmed.
  /// It must run while the organization is still signed in: after that the rules
  /// refuse the write of `isPublishing = false`.
  ///
  /// The warning goes through [_notices]: the operation goes on, and the
  /// screen that started it is usually replaced by then.
  Future<void> _stopTracking() async {
    final stopped = await _trackingStopper.stop(email: await _currentEmail());
    if (!stopped) {
      _notices.show(
        const UserNotice(
          "Não foi possível confirmar o encerramento do rastreamento. "
          "Ele será encerrado automaticamente em instantes.",
          title: "Rastreamento",
        ),
      );
    }
  }

  /// Enters the organization the user picked in the organization picker.
  /// [Err] says why it could not; [Ok] also when there is nothing to do.
  @override
  Future<Result<void>> chooseOrganization(OrganizationBinding binding) async {
    final idToken = _pendingIdToken;
    if (idToken == null || _state.isLoading) return const Ok(null);
    _emit(_state.copyWith(isLoading: true));
    try {
      await _enterOrganization(binding, idToken);
      return const Ok(null);
    } catch (e, stackTrace) {
      return _loginError(
        "Não foi possível entrar em ${binding.organization.name}: $e",
        e,
        stackTrace,
      );
    } finally {
      _emit(_state.copyWith(isLoading: false));
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
      _emit(
        _state.copyWith(enteringOrganizationName: binding.organization.name),
      );
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
        _emit(
          _state.copyWith(
            noAccessReason:
                'Sua conta não tem mais acesso à '
                '${binding.organization.name}.',
          ),
        );
        _moveTo(const SessionState.noOrganization());
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
      // Leaving the picker drops its choices (they live in the session).
      // Right after accepting an invite to this organization: welcome first.
      final invite = _state.welcome;
      if (invite != null && invite.organizationId == binding.organization.id) {
        _moveTo(const SessionState.welcome());
      } else {
        _emit(_state.copyWith(welcome: null));
        _moveTo(const SessionState.bound());
      }
    } catch (_) {
      // Never stay bound to an organization the user could not enter.
      await _organizationSession.forget();
      _refreshTheme();
      rethrow;
    } finally {
      _emit(_state.copyWith(enteringOrganizationName: null));
    }
  }

  static const _loginErrorTitle = "Erro de Login";
  static const _switchTitle = 'Trocar de organização';

  Err<void> _loginError(String message, Object error, StackTrace stackTrace) =>
      Err(
        message,
        title: _loginErrorTitle,
        error: error,
        stackTrace: stackTrace,
      );

  /// "Entrar com o Google". [Err] says why the sign-in failed; [Ok] also
  /// while another sign-in runs.
  @override
  Future<Result<void>> loginGoogle() async {
    if (_state.isLoading || _state.isChoosingAccount) return const Ok(null);
    _emit(_state.copyWith(isChoosingAccount: true));
    try {
      // The spinner waits for an account: while Google's chooser is open there
      // is no organization to look for yet.
      final idToken = await _authGoogle.signInGoogle(
        onAccountChosen: () => _emit(_state.copyWith(isLoading: true)),
      );
      // Na web o login retorna null propositalmente (o resultado chega via
      // stream), portanto não exibimos erro quando idToken é null.
      if (idToken != null) {
        await _continueWithOrganizations(idToken, alwaysPick: true);
      }
      return const Ok(null);
    } catch (e, stackTrace) {
      return _loginError("Ocorreu um erro inesperado: $e", e, stackTrace);
    } finally {
      _emit(_state.copyWith(isLoading: false, isChoosingAccount: false));
    }
  }

  /// "Sair". [Ok] holds whether the sign-out finished (`false` while another
  /// one runs); [Err] says why it failed.
  @override
  Future<Result<bool>> logout() => _signOut();

  /// Forgets the organization after the user's membership was removed:
  /// the same steps as [logout], then *Sem organização* saying why.
  Future<void> forgetRemovedOrganization() async {
    final name = Organization.current?.name;
    _emit(
      _state.copyWith(
        noAccessReason: name == null
            ? 'Você não faz mais parte desta organização.'
            : 'Você não faz mais parte da $name.',
      ),
    );
    _showFailure(
      await _signOut(destination: const SessionState.noOrganization()),
    );
  }

  /// Shows [result]'s message through [_notices] when it failed: for the
  /// sign-outs no screen waits for.
  void _showFailure(Result<Object?> result) {
    if (result case Err(:final message, :final title)) {
      _notices.show(UserNotice(message, title: title));
    }
  }

  /// [Ok] holds whether the sign-out finished (`false` while another one
  /// runs); [Err] says why it failed.
  Future<Result<bool>> _signOut({
    SessionState destination = const SessionState.signedOut(),
  }) async {
    if (_state.isLoggingOut) return const Ok(false);

    _emit(_state.copyWith(isLoggingOut: true));
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
      _emit(_state.copyWith(signedInEmail: null, ownership: const {}));
      _moveTo(destination);
      return const Ok(true);
    } catch (e, stackTrace) {
      debugPrint("Erro ao sair: $e");
      return Err(
        "Não foi possível encerrar a sessão. Tente novamente.\nErro: $e",
        title: "Erro ao sair",
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _emit(_state.copyWith(isLoggingOut: false));
    }
  }

  /// E-mail do usuário salvo no Hive, a mesma fonte usada pelo
  /// `UserViewModel` para o id do documento em `positions`. Uma falha na
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
  void dispose() {
    _disposed = true;
    _session.dispose();
    if (_started) {
      _webSignInSub?.cancel();
      _authGoogle.dispose();
    }
    super.dispose();
  }
}
