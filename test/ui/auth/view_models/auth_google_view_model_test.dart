import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';
import 'package:monamie_app/data/services/firebase/organization_firebase.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/repositories/organization/organization_binder.dart';
import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/repositories/organization/organization_binding_store.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/ui/auth/view_models/auth_google_view_model.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/routing/session_redirect.dart';
import 'package:monamie_app/ui/core/ui/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';
import '../../../support/test_organization.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<AuthGoogleService>(),
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<InvitesRepository>(),
  MockSpec<NoticePresenter>(),
  MockSpec<OrganizationBinder>(),
  MockSpec<OrganizationBindingStore>(),
  MockSpec<OrganizationBrandingLoader>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<OrganizationFirebase>(),
  MockSpec<OrganizationLocalData>(),
  MockSpec<MembershipService>(),
  MockSpec<UserGoogleRepository>(),
])
import 'auth_google_view_model_test.mocks.dart';

/// Where a test starts: whatever screen the person is on before the
/// controller moves the session.
const String _kHomeRoute = '/home-test';

/// The screen of each session the controller moved to since
/// [_followRoutes], in order: what the router would open.
final List<String> _visited = [];

/// The screen the router shows now: the last session's, or [_kHomeRoute]
/// while the session has not moved (what `_currentRoute` read when the
/// controller navigated itself).
String get _currentRoute => _visited.isEmpty ? _kHomeRoute : _visited.last;

/// Records in [_visited] (and as `push:<route>` in [log]) the screen of
/// each session [controller] moves to, starting empty.
void _followRoutes(AuthGoogleViewModel controller, [List<String>? log]) {
  _visited.clear();
  controller.session.addListener(() {
    final route = sessionLocation(controller.session.value);
    _visited.add(route);
    log?.add('push:$route');
  });
}

/// Calls [onChange] with [select]'s value each time it changes (as the GetX
/// `ever` worker these tests used did); returns the function that stops it.
void Function() _onChange<T>(
  AuthGoogleViewModel controller,
  T Function(AuthGoogleState state) select,
  void Function(T value) onChange,
) {
  var last = select(controller.state);
  void listener() {
    final value = select(controller.state);
    if (value == last) return;
    last = value;
    onChange(value);
  }

  controller.addListener(listener);
  return () => controller.removeListener(listener);
}

const String _kIdToken = 'google-id-token';

const String _kCentralEmail = 'ana.souza@monamie.net';

const String _kLoginErrorTitle = 'Erro de Login';

const _kOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

const _kRotaSul = OrganizationCandidate(id: 'rotasul', options: _kOptions);

const _kRotaSulName = 'Rota Sul';

const _kVerdeMarSignIn = OrganizationCandidate(
  id: 'verdemar',
  options: FirebaseOptions(
    apiKey: 'api-key',
    appId: '1:222:android:def',
    projectId: 'monamienet-verdemar',
    messagingSenderId: '222',
  ),
);

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

/// The `onAccountChosen` callback passed to `signInGoogle`.
void Function()? _onAccountChosen(Invocation invocation) =>
    invocation.namedArguments[#onAccountChosen] as void Function()?;

/// A [MockAuthGoogleService] for the sign-in: each call is written to [log];
/// `signInGoogle` waits on [chooser] (Google's account chooser; completing it
/// with an error mimics a cancelled chooser), then answers [idToken] or fails
/// with [signInError]; `logoutGoogle` fails with [logoutError].
MockAuthGoogleService _authServiceSignIn(
  List<String> log, {
  String? idToken = _kIdToken,
  String? refreshedToken = _kIdToken,
  Object? signInError,
  Object? logoutError,
  Completer<void>? chooser,
}) {
  final service = MockAuthGoogleService();
  when(
    service.signInGoogle(onAccountChosen: anyNamed('onAccountChosen')),
  ).thenAnswer((invocation) async {
    log.add('signInGoogle');
    await chooser?.future;
    _onAccountChosen(invocation)?.call();
    if (signInError != null) throw signInError;
    return idToken;
  });
  when(service.refreshGoogleIdToken()).thenAnswer((_) async {
    log.add('refreshGoogleIdToken');
    return refreshedToken;
  });
  when(service.centralEmail()).thenAnswer((_) async => _kCentralEmail);
  when(service.signInToOrganization(any)).thenAnswer((_) async {
    log.add('signInToOrganization');
  });
  when(service.signOutOfOrganization()).thenAnswer((_) async {
    log.add('signOutOfOrganization');
  });
  when(service.logoutGoogle()).thenAnswer((_) async {
    log.add('logoutGoogle');
    if (logoutError != null) throw logoutError;
  });
  when(service.saveOrganizationProfile()).thenAnswer(
    (_) async => UserGoogleModel(
      id: 'uid-123',
      name: 'Ana Souza',
      email: _kCentralEmail,
    ),
  );
  when(service.onWebSignIn).thenAnswer((_) => const Stream<String?>.empty());
  return service;
}

/// A [MockOrganizationDirectory] that writes `directory` to [log] and
/// answers [organizations] or fails with [error].
MockOrganizationDirectory _directorySignIn(
  List<String> log, {
  List<OrganizationCandidate> organizations = const [],
  Object? error,
}) {
  final directory = MockOrganizationDirectory();
  when(directory.organizationsOfSignedInUser()).thenAnswer((_) async {
    log.add('directory');
    if (error != null) throw error;
    return organizations;
  });
  return directory;
}

/// A [MockOrganizationBrandingLoader] whose `load` names each organization
/// with [nameOf].
MockOrganizationBrandingLoader _brandingLoader(
  String Function(OrganizationCandidate candidate) nameOf,
) {
  final loader = MockOrganizationBrandingLoader();
  when(loader.load(any)).thenAnswer((invocation) async {
    final candidate =
        invocation.positionalArguments.single as OrganizationCandidate;
    return OrganizationBinding(
      organization: OrganizationConfig(
        id: candidate.id,
        name: nameOf(candidate),
      ),
      options: candidate.options,
    );
  });
  return loader;
}

/// A [MockMembershipService] that answers [member] for every
/// organization: `true` belongs, `false` was removed, `null` could not be
/// read.
MockMembershipService _membershipCheck(bool? member) {
  final check = MockMembershipService();
  when(check.isMemberOf(any)).thenAnswer((_) async => member);
  return check;
}

/// A [MockBackgroundTrackingStopper] that writes [entry] to [log] and
/// answers [result], or waits on [pending] when given.
MockBackgroundTrackingStopper _trackingStopper(
  List<String> log, {
  String entry = 'stop',
  bool result = true,
  Completer<bool>? pending,
}) {
  final stopper = MockBackgroundTrackingStopper();
  when(stopper.stop(email: anyNamed('email'))).thenAnswer((_) {
    log.add(entry);
    return pending?.future ?? Future<bool>.value(result);
  });
  return stopper;
}

/// A [MockUserGoogleRepository] with no saved user, whose writes succeed.
MockUserGoogleRepository _userRepository() {
  final repository = MockUserGoogleRepository();
  when(repository.getUserGoogleModel()).thenAnswer((_) async => null);
  when(repository.deleteUserGoogleModel()).thenAnswer((_) async => 'ok');
  when(repository.saveUserGoogleModel(any)).thenAnswer((_) async => 'ok');
  return repository;
}

/// A [MockOrganizationBinder] that binds without creating a real
/// [FirebaseApp]: `bind` logs, records the organization id in [boundIds] and
/// sets [Organization.current] and a mock [OrganizationFirebase]; `forget`
/// logs and clears both, as `OrganizationSession.forget` does.
MockOrganizationBinder _organizationBinder(
  List<String> log, [
  List<String>? boundIds,
]) {
  final binder = MockOrganizationBinder();
  when(binder.bind(any, remember: anyNamed('remember'))).thenAnswer((
    invocation,
  ) async {
    final binding =
        invocation.positionalArguments.single as OrganizationBinding;
    log.add('bind');
    boundIds?.add(binding.organization.id);
    Organization.bind(binding.organization);
    CurrentOrganizationFirebase.set(MockOrganizationFirebase());
  });
  when(binder.forget()).thenAnswer((_) async {
    log.add('forget');
    Organization.unbind();
    CurrentOrganizationFirebase.clear();
  });
  return binder;
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _HarnessSignIn {
  _HarnessSignIn({
    List<OrganizationCandidate> organizations = const [],
    Object? directoryError,
    bool? member = false,
    String? idToken = _kIdToken,
    String? refreshedToken = _kIdToken,
    Object? signInError,
    Object? logoutError,
    Completer<void>? chooser,
    Completer<bool>? pendingStop,
    AccountDeletionRepository? deletionRepository,
  }) {
    authService = _authServiceSignIn(
      log,
      idToken: idToken,
      refreshedToken: refreshedToken,
      signInError: signInError,
      logoutError: logoutError,
      chooser: chooser,
    );
    directory = _directorySignIn(
      log,
      organizations: organizations,
      error: directoryError,
    );
    session = _organizationBinder(log);
    membershipCheck = _membershipCheck(member);
    controller = AuthGoogleViewModel(
      notices: notices,
      authGoogle: authService,
      userRepository: _userRepository(),
      trackingStopper: _trackingStopper(log, pending: pendingStop),
      organizationDirectory: directory,
      brandingLoader: _brandingLoader((_) => _kRotaSulName),
      organizationSession: session,
      organizationLocalData: MockOrganizationLocalData(),
      invitesRepository: MockInvitesRepository(),
      deletionRepository: deletionRepository ?? MockAccountDeletionRepository(),
      membershipCheck: membershipCheck,
      refreshTheme: () => log.add('refreshTheme'),
    );
    _followRoutes(controller);
  }

  final List<String> log = <String>[];
  final notices = MockNoticePresenter();
  late final MockMembershipService membershipCheck;
  late final MockAuthGoogleService authService;
  late final MockOrganizationDirectory directory;
  late final MockOrganizationBinder session;
  late final AuthGoogleViewModel controller;
}

/// A plain app around the flow: the controller no longer navigates, the
/// screen it leads to is read from its session ([_currentRoute]).
Future<void> _pumpAppSignIn(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: Text(_kHomeRoute))),
  );
  await tester.pumpAndSettle();
}

/// Runs [act] (which may start un-awaited work such as `loginGoogle()`),
/// waits until the controller is idle and returns what [act] completed with
/// (the [Result] of the controller's method, when it returns one).
Future<Object?> _run(
  WidgetTester tester,
  AuthGoogleViewModel controller,
  FutureOr<Object?> Function() act,
) async {
  final outcome = await act();
  for (
    var i = 0;
    i < 50 && (controller.state.isLoading || controller.state.isLoggingOut);
    i++
  ) {
    await tester.pump();
  }
  await tester.pumpAndSettle();
  return outcome;
}

/// An [Err] titled [title].
Matcher _errTitled(String title) =>
    isA<Err<Object?>>().having((err) => err.title, 'title', title);

/// A [UserNotice] titled [title].
Matcher _noticeTitled(String title) =>
    isA<UserNotice>().having((notice) => notice.title, 'title', title);

/// A JWT-shaped token whose `exp` is [fromNow] from the real clock (the
/// controller reads `DateTime.now()`); the signature is not checked.
String _jwtExpiringIn(Duration fromNow) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(fromNow).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'none'})}.${part({'exp': exp})}.sig';
}

/// Entries of [log] before the organization is forgotten or signed out of.
Iterable<String> _beforeNoAccessDecision(List<String> log) =>
    log.takeWhile((e) => e != 'forget' && e != 'signOutOfOrganization');

const _kVerdeMarInvites = OrganizationCandidate(
  id: 'verdemar',
  options: _kOptions,
);

const _kAzulCeu = OrganizationCandidate(id: 'azulceu', options: _kOptions);

/// Display name of each organization the fake branding loader knows.
const Map<String, String> _kOrganizationNames = {
  'rotasul': _kRotaSulName,
  'verdemar': 'Verde Mar',
  'azulceu': 'Azul Céu',
};

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

/// A [MockOrganizationDirectory] that answers the n-th call with
/// `answers[n]` (the last answer repeats).
MockOrganizationDirectory _sequencedDirectory(
  List<List<OrganizationCandidate>> answers,
) {
  final directory = MockOrganizationDirectory();
  var calls = 0;
  when(directory.organizationsOfSignedInUser()).thenAnswer((_) async {
    final index = calls++;
    return answers[index < answers.length ? index : answers.length - 1];
  });
  return directory;
}

/// A [MockInvitesRepository] whose `accept` returns the invite and `mine`
/// answers no invite.
MockInvitesRepository _invitesRepository() {
  final repository = MockInvitesRepository();
  when(repository.accept(any)).thenAnswer(
    (invocation) async => Ok(invocation.positionalArguments.single as Invite),
  );
  when(repository.mine()).thenAnswer((_) async => const Ok([]));
  return repository;
}

final _kOtherInvite = Invite(
  id: 'inv2',
  organizationId: 'verdemar',
  organizationName: 'Verde Mar',
  groupId: '02',
  groupName: 'Equipe Sul',
  email: _kCentralEmail,
  roles: const {GroupRole.subscriber},
  inviterName: 'Caio Prado',
  expiresAt: DateTime.utc(2026, 11, 10, 12),
);

final _kInvite = Invite(
  id: 'inv1',
  organizationId: 'rotasul',
  organizationName: _kRotaSulName,
  groupId: '01',
  groupName: 'Equipe Norte',
  email: _kCentralEmail,
  roles: const {GroupRole.publisher},
  inviterName: 'Rita Lima',
  expiresAt: DateTime.utc(2026, 11, 9, 12),
);

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _HarnessInvites {
  _HarnessInvites({
    List<List<OrganizationCandidate>> answers = const [
      [_kRotaSul],
    ],
  }) {
    directory = _sequencedDirectory(answers);
    session = _organizationBinder(log, boundIds);
    controller = AuthGoogleViewModel(
      notices: MockNoticePresenter(),
      authGoogle: _authServiceSignIn(log, refreshedToken: null),
      userRepository: _userRepository(),
      trackingStopper: _trackingStopper(log),
      organizationDirectory: directory,
      brandingLoader: _brandingLoader(
        (candidate) => _kOrganizationNames[candidate.id] ?? candidate.id,
      ),
      organizationSession: session,
      organizationLocalData: MockOrganizationLocalData(),
      invitesRepository: invites,
      deletionRepository: MockAccountDeletionRepository(),
      membershipCheck: _membershipCheck(true),
      refreshTheme: () => log.add('refreshTheme'),
    );
    _followRoutes(controller);
  }

  final List<String> log = <String>[];
  final invites = _invitesRepository();
  late final MockOrganizationDirectory directory;
  late final MockOrganizationBinder session;

  /// Id of every organization bound, in order.
  final boundIds = <String>[];
  late final AuthGoogleViewModel controller;
}

/// See [_pumpAppSignIn].
Future<void> _pumpAppInvites(WidgetTester tester) => _pumpAppSignIn(tester);

/// Starts accepting [_kInvite] and advances the fake clock until it is over.
Future<void> _accept(WidgetTester tester, AuthGoogleViewModel controller) =>
    _drive(tester, controller, () => controller.acceptInvite(_kInvite));

/// Starts [act] and advances the fake clock one second at a time until the
/// controller is no longer busy.
Future<void> _drive(
  WidgetTester tester,
  AuthGoogleViewModel controller,
  Future<void> Function() act,
) async {
  final done = act();
  for (
    var i = 0;
    i < 60 &&
        (controller.state.acceptingInvite != null ||
            controller.state.isLoading);
    i++
  ) {
    await tester.pump(const Duration(seconds: 1));
  }
  await done;
  await tester.pumpAndSettle();
}

/// What the ownership tests' directory answers.
const _kOwnershipOrganizations = [
  OrganizationCandidate(id: 'rotasul', options: _kOptions, owner: true),
  OrganizationCandidate(id: 'verdemar', options: _kOptions),
];

/// Makes [directory] answer [_kOwnershipOrganizations].
void _directoryAnswers() {
  when(
    directory.organizationsOfSignedInUser(),
  ).thenAnswer((_) async => _kOwnershipOrganizations);
}

late MockOrganizationDirectory directory;

/// Built without calling `start`, so Google Sign-In is never initialized.
AuthGoogleViewModel newController() => AuthGoogleViewModel(
  notices: MockNoticePresenter(),
  authGoogle: MockAuthGoogleService(),
  userRepository: MockUserGoogleRepository(),
  trackingStopper: MockBackgroundTrackingStopper(),
  organizationDirectory: directory,
  brandingLoader: MockOrganizationBrandingLoader(),
  organizationSession: MockOrganizationBinder(),
  organizationLocalData: MockOrganizationLocalData(),
  invitesRepository: MockInvitesRepository(),
  deletionRepository: MockAccountDeletionRepository(),
  membershipCheck: MockMembershipService(),
  refreshTheme: () {},
);

const String _kHomePlaceholder = 'home-placeholder';

const String _kLoginPlaceholder = 'login-placeholder';

const String _kStoredEmail = 'ana.souza@monamie.net';

// Entradas do registro compartilhado de chamadas, usado para verificar a
// ordem das operações do logout.
const String _kLogStop = 'stop';

const String _kLogSignOut = 'logoutGoogle';

const String _kLogDeleteUser = 'deleteUserGoogleModel';

const String _kLogNavigateLogin = 'push:${Routes.login}';

/// Mock do AuthGoogleService: o logout do Google registra [_kLogSignOut]
/// no log e falha com [logoutError].
MockAuthGoogleService _authServiceLogout(
  List<String> log, {
  Object? logoutError,
}) {
  final service = MockAuthGoogleService();
  when(service.logoutGoogle()).thenAnswer((_) async {
    log.add(_kLogSignOut);
    if (logoutError != null) throw logoutError;
  });
  when(
    service.signInGoogle(onAccountChosen: anyNamed('onAccountChosen')),
  ).thenAnswer((invocation) async {
    _onAccountChosen(invocation)?.call();
    return null;
  });
  when(service.onWebSignIn).thenAnswer((_) => const Stream<String?>.empty());
  return service;
}

/// Mock do UserGoogleRepository: devolve [storedUser] (ou falha com
/// [getUserError]) e a exclusão registra [_kLogDeleteUser] no log (ou falha
/// com [deleteError]).
MockUserGoogleRepository _userRepositoryLogout(
  List<String> log, {
  UserGoogleModel? storedUser,
  Object? getUserError,
  Object? deleteError,
}) {
  final repository = MockUserGoogleRepository();
  when(repository.getUserGoogleModel()).thenAnswer((_) async {
    if (getUserError != null) throw getUserError;
    return storedUser;
  });
  when(repository.deleteUserGoogleModel()).thenAnswer((_) async {
    log.add(_kLogDeleteUser);
    if (deleteError != null) throw deleteError;
    return 'ok';
  });
  return repository;
}

/// E-mails passados a `stop` desde a última verificação.
List<Object?> _stoppedEmails(MockBackgroundTrackingStopper stopper) =>
    verify(stopper.stop(email: captureAnyNamed('email'))).captured;

/// Conjunto de dependências falsas de um cenário de logout.
class _HarnessLogout {
  _HarnessLogout({
    UserGoogleModel? storedUser,
    Object? getUserError,
    Object? deleteError,
    bool stopResult = true,
    Completer<bool>? pendingStop,
    Object? logoutError,
  }) {
    stopper = _trackingStopper(
      log,
      entry: _kLogStop,
      result: stopResult,
      pending: pendingStop,
    );
    authService = _authServiceLogout(log, logoutError: logoutError);
    userRepository = _userRepositoryLogout(
      log,
      storedUser: storedUser,
      getUserError: getUserError,
      deleteError: deleteError,
    );
    // O controller nunca recebe `start`, de modo que o Google Sign-In nunca
    // é inicializado.
    controller = AuthGoogleViewModel(
      notices: notices,
      organizationSession: OrganizationSession(
        store: MockOrganizationBindingStore(),
      ),
      organizationLocalData: MockOrganizationLocalData(),
      refreshTheme: () {},
      authGoogle: authService,
      userRepository: userRepository,
      trackingStopper: stopper,
      organizationDirectory: MockOrganizationDirectory(),
      brandingLoader: MockOrganizationBrandingLoader(),
      invitesRepository: MockInvitesRepository(),
      deletionRepository: MockAccountDeletionRepository(),
      membershipCheck: MockMembershipService(),
    );
    _followRoutes(controller, log);
  }

  final List<String> log = <String>[];
  final notices = MockNoticePresenter();
  late final MockBackgroundTrackingStopper stopper;
  late final MockAuthGoogleService authService;
  late final MockUserGoogleRepository userRepository;
  late final AuthGoogleViewModel controller;
}

/// Resultado observável de uma execução completa de `logout()`.
class _LogoutRun {
  _LogoutRun({required this.error, required this.result});

  /// Exceção que escapou de `logout()`, se houver.
  final Object? error;

  /// O [Result] devolvido por `logout()` (nulo quando ele lançou).
  final Result<bool>? result;
}

UserGoogleModel _storedUser() =>
    UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kStoredEmail);

/// Monta o app com a pessoa no mapa (sessão restaurada) e um roteador que
/// segue a sessão do controller como o do app (`sessionRedirect`), com
/// stubs do mapa e de `Routes.login`; limpa do log e de [_visited] o que a
/// montagem registrou.
Future<void> _pumpAppLogout(WidgetTester tester, _HarnessLogout harness) async {
  final controller = harness.controller..sessionRestored();
  final router = GoRouter(
    initialLocation: Routes.monamie,
    refreshListenable: controller.session,
    redirect: (_, state) =>
        sessionRedirect(controller.session.value, state.uri.path),
    routes: [
      GoRoute(
        path: Routes.monamie,
        builder: (_, _) => const Scaffold(body: Text(_kHomePlaceholder)),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const Scaffold(body: Text(_kLoginPlaceholder)),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  harness.log.clear();
  _visited.clear();
}

/// Executa `logout()` até o fim e captura o [Result] devolvido ou uma
/// eventual exceção.
Future<_LogoutRun> _runLogout(
  WidgetTester tester,
  AuthGoogleViewModel controller,
) async {
  Object? error;
  Result<bool>? result;
  try {
    result = await controller.logout();
  } catch (e) {
    error = e;
  }
  await tester.pumpAndSettle();

  return _LogoutRun(error: error, result: result);
}

void main() {
  provideDummy<Result<List<Invite>>>(const Ok([]));
  provideDummy<Result<Invite>>(Ok(_kInvite));
  provideDummy<Result<AccountDeletion?>>(const Ok(null));
  provideDummy<Result<void>>(const Ok(null));

  group('sign in', () {
    tearDown(() {
      Organization.bind(testOrganization);
      CurrentOrganizationFirebase.debugReset();
    });

    group(
      'AuthGoogleViewModel.loginGoogle (seletor de contas do Google) - Suíte de Testes Unitários',
      () {
        testWidgets(
          'Happy Path: Deve manter isLoading falso enquanto o seletor de contas está aberto e ligá-lo só depois da escolha',
          (WidgetTester tester) async {
            // 1. Arrange
            final chooser = Completer<void>();
            final harness = _HarnessSignIn(chooser: chooser);
            await _pumpAppSignIn(tester);
            final controller = harness.controller;
            final loadingHistory = <bool>[];
            final worker = _onChange(
              controller,
              (state) => state.isLoading,
              loadingHistory.add,
            );
            controller.loginGoogle();
            await tester.pump();
            final loadingWhileChooserOpen = controller.state.isLoading;
            final guardedWhileChooserOpen = controller.state.isChoosingAccount;
            final historyWhileChooserOpen = List<bool>.of(loadingHistory);

            // 2. Act
            chooser.complete();
            await _run(tester, controller, () => null);
            worker();

            // 3. Assert
            expect(loadingWhileChooserOpen, isFalse);
            expect(guardedWhileChooserOpen, isTrue);
            expect(historyWhileChooserOpen, isEmpty);
            expect(loadingHistory, [true, false]);
            expect(controller.state.isChoosingAccount, isFalse);
          },
        );

        testWidgets(
          'Edge Case: Não deve chamar signInGoogle de novo quando há um segundo toque com o seletor aberto',
          (WidgetTester tester) async {
            // 1. Arrange
            final chooser = Completer<void>();
            final harness = _HarnessSignIn(chooser: chooser);
            await _pumpAppSignIn(tester);
            harness.controller.loginGoogle();
            await tester.pump();

            // 2. Act
            harness.controller.loginGoogle();
            await tester.pump();

            // 3. Assert
            verify(
              harness.authService.signInGoogle(
                onAccountChosen: anyNamed('onAccountChosen'),
              ),
            ).called(1);

            // Cleanup: finishes the pending sign-in so no timers stay open.
            chooser.complete();
            await _run(tester, harness.controller, () => null);
          },
        );

        testWidgets(
          'Sad Path: Não deve ligar isLoading quando o seletor é cancelado e deve liberar um novo toque',
          (WidgetTester tester) async {
            // 1. Arrange
            final chooser = Completer<void>();
            final harness = _HarnessSignIn(chooser: chooser);
            await _pumpAppSignIn(tester);
            final controller = harness.controller;
            var loadingEverTrue = false;
            final worker = _onChange(
              controller,
              (state) => state.isLoading,
              (value) => loadingEverTrue = loadingEverTrue || value,
            );
            controller.loginGoogle();
            await tester.pump();

            // 2. Act
            chooser.completeError(Exception('cancelled'));
            await _run(tester, controller, () => null);
            worker();

            // 3. Assert
            expect(loadingEverTrue, isFalse);
            expect(controller.state.isLoading, isFalse);
            expect(controller.state.isChoosingAccount, isFalse);
            verify(
              harness.authService.signInGoogle(
                onAccountChosen: anyNamed('onAccountChosen'),
              ),
            ).called(1);
          },
        );
      },
    );

    group(
      'AuthGoogleViewModel.loginGoogle (sem organização) - Suíte de Testes Unitários',
      () {
        testWidgets(
          'Happy Path: Deve navegar para Routes.noOrganization quando o usuário não tiver organização',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn();
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(_currentRoute, Routes.noOrganization);
          },
        );

        testWidgets(
          'Happy Path: Deve guardar em signedInEmail o e-mail da conta central',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn();
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(harness.controller.state.signedInEmail, _kCentralEmail);
          },
        );

        testWidgets(
          'Edge Case: Não deve sair do Google/central quando o usuário não tiver organização',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn();
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            verifyNever(harness.authService.logoutGoogle());
          },
        );

        testWidgets(
          'Sad Path: Deve devolver erro de login e voltar isLoading a false quando a busca de organizações lançar',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              directoryError: Exception('sem rede'),
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            final result = await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(result, _errTitled(_kLoginErrorTitle));
            expect(harness.controller.state.isLoading, isFalse);
          },
        );
      },
    );

    group(
      'AuthGoogleViewModel.loginGoogle (seletor de organizações) - Suíte de Testes Unitários',
      () {
        testWidgets(
          'Happy Path: Deve abrir o seletor com a única organização da pessoa',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: true,
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(_currentRoute, Routes.organizationPicker);
            expect(
              harness.controller.state.organizationChoices.map(
                (b) => b.organization.id,
              ),
              ['rotasul'],
            );
          },
        );

        testWidgets(
          'Happy Path: Deve abrir o seletor com as duas organizações da pessoa',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul, _kVerdeMarSignIn],
              member: true,
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(_currentRoute, Routes.organizationPicker);
            expect(
              harness.controller.state.organizationChoices.map(
                (b) => b.organization.id,
              ),
              ['rotasul', 'verdemar'],
            );
          },
        );

        testWidgets(
          'Edge Case: Não deve vincular nem entrar na única organização antes da escolha',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: true,
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(harness.log, isNot(contains('bind')));
            expect(harness.log, isNot(contains('signInToOrganization')));
            verifyNever(harness.session.forget());
          },
        );

        testWidgets(
          'Edge Case: Deve abrir o seletor com a única organização ao verificar de novo em Sem organização',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: true,
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.recheckOrganizations,
            );

            // 3. Assert
            expect(_currentRoute, Routes.organizationPicker);
            expect(
              harness.controller.state.organizationChoices.map(
                (b) => b.organization.id,
              ),
              ['rotasul'],
            );
            expect(harness.log, isNot(contains('bind')));
          },
        );

        testWidgets(
          'Sad Path: Não deve abrir o seletor quando o login do Google não devolver token',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              idToken: null,
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(_currentRoute, _kHomeRoute);
            expect(harness.controller.state.organizationChoices, isEmpty);
            verifyNever(harness.directory.organizationsOfSignedInUser());
          },
        );
      },
    );

    group(
      'AuthGoogleViewModel.chooseOrganization (organização sem acesso) - Suíte de Testes Unitários',
      () {
        testWidgets(
          'Happy Path: Deve explicar em noAccessReason que a conta não tem mais acesso à organização',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: false,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(
              harness.controller.state.noAccessReason,
              'Sua conta não tem mais acesso à Rota Sul.',
            );
          },
        );

        testWidgets(
          'Happy Path: Deve navegar para Routes.noOrganization quando a pessoa não tiver mais matrícula',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: false,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(_currentRoute, Routes.noOrganization);
          },
        );

        testWidgets(
          'Happy Path: Deve esquecer a organização quando a pessoa não tiver mais matrícula',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: false,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            verify(harness.session.forget());
            expect(Organization.current, isNull);
          },
        );

        testWidgets(
          'Happy Path: Deve sair apenas do projeto da organização quando a pessoa não tiver mais matrícula',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: false,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            verify(harness.authService.signOutOfOrganization()).called(1);
          },
        );

        testWidgets(
          'Edge Case: Não deve devolver erro de login quando a pessoa não tiver mais matrícula',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: false,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            final result = await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(result, isA<Ok<void>>());
          },
        );

        testWidgets(
          'Edge Case: Não deve aplicar o tema da organização antes de decidir que a conta não tem acesso',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: false,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(
              _beforeNoAccessDecision(harness.log),
              isNot(contains('refreshTheme')),
            );
          },
        );

        testWidgets(
          'Edge Case: Não deve definir noAccessReason nem ir para Sem organização quando a pessoa tiver matrícula',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: true,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(harness.controller.state.noAccessReason, isNull);
            expect(_currentRoute, isNot(Routes.noOrganization));
          },
        );

        testWidgets(
          'Sad Path: Não deve tratar uma falha na leitura da matrícula como perda de acesso',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              organizations: [_kRotaSul],
              member: null,
            );
            await _pumpAppSignIn(tester);
            await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.state.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(harness.controller.state.noAccessReason, isNull);
            verifyNever(harness.authService.signOutOfOrganization());
          },
        );
      },
    );

    group('AuthGoogleViewModel.recheckOrganizations - Suíte de Testes Unitários', () {
      testWidgets(
        'Happy Path: Deve reutilizar o ID token do login anterior sem chamar signInGoogle de novo',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          verify(
            harness.authService.signInGoogle(
              onAccountChosen: anyNamed('onAccountChosen'),
            ),
          ).called(1);
        },
      );

      testWidgets(
        'Happy Path: Deve buscar de novo as organizações do usuário',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          verify(harness.directory.organizationsOfSignedInUser()).called(2);
        },
      );

      testWidgets('Happy Path: Deve limpar noAccessReason', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        // Entering an organization without a membership there sets the
        // reason (and lands on Sem organização).
        final harness = _HarnessSignIn(
          organizations: [_kRotaSul],
          member: false,
        );
        await _pumpAppSignIn(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);
        await _run(
          tester,
          harness.controller,
          () => harness.controller.chooseOrganization(
            harness.controller.state.organizationChoices.single,
          ),
        );
        expect(harness.controller.state.noAccessReason, isNotNull);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.recheckOrganizations,
        );

        // 3. Assert
        expect(harness.controller.state.noAccessReason, isNull);
      });

      testWidgets(
        'Edge Case: Deve chamar signInGoogle quando não houver login anterior',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          verify(
            harness.authService.signInGoogle(
              onAccountChosen: anyNamed('onAccountChosen'),
            ),
          ).called(1);
        },
      );

      testWidgets(
        'Edge Case: Não deve fazer nada quando chamado com isLoading true (reentrância)',
        (WidgetTester tester) async {
          // 1. Arrange
          // A first check held open at the directory keeps isLoading true.
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);
          final lookup = Completer<List<OrganizationCandidate>>();
          when(
            harness.directory.organizationsOfSignedInUser(),
          ).thenAnswer((_) => lookup.future);
          final first = harness.controller.recheckOrganizations();
          await tester.pump();
          expect(harness.controller.state.isLoading, isTrue);

          // 2. Act
          final second = await harness.controller.recheckOrganizations();

          // 3. Assert
          expect(second, isA<Ok<void>>());
          verify(
            harness.authService.signInGoogle(
              onAccountChosen: anyNamed('onAccountChosen'),
            ),
          ).called(1);
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
          lookup.complete(const []);
          await _run(tester, harness.controller, () => first);
        },
      );

      testWidgets(
        'Sad Path: Deve voltar isLoading a false quando a busca de organizações lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('sem rede'));
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          expect(harness.controller.state.isLoading, isFalse);
        },
      );
    });

    group(
      'AuthGoogleViewModel.forgetRemovedOrganization - Suíte de Testes Unitários',
      () {
        testWidgets(
          'Happy Path: Deve explicar em noAccessReason que o usuário não faz mais parte da organização',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn();
            await _pumpAppSignIn(tester);
            Organization.bind(
              const OrganizationConfig(id: 'rotasul', name: _kRotaSulName),
            );

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.forgetRemovedOrganization,
            );

            // 3. Assert
            expect(
              harness.controller.state.noAccessReason,
              'Você não faz mais parte da Rota Sul.',
            );
          },
        );

        testWidgets(
          'Happy Path: Deve navegar para Routes.noOrganization em vez de Routes.login',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn();
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.forgetRemovedOrganization,
            );

            // 3. Assert
            expect(_currentRoute, Routes.noOrganization);
          },
        );

        testWidgets(
          'Happy Path: Deve parar o rastreamento antes de sair, como no logout',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn();
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.forgetRemovedOrganization,
            );

            // 3. Assert
            expect(
              harness.log.where((e) => e == 'stop' || e == 'logoutGoogle'),
              ['stop', 'logoutGoogle'],
            );
          },
        );

        testWidgets(
          'Edge Case: Deve usar "desta organização" quando não houver organização vinculada',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn();
            await _pumpAppSignIn(tester);
            Organization.unbind();

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.forgetRemovedOrganization,
            );

            // 3. Assert
            expect(
              harness.controller.state.noAccessReason,
              'Você não faz mais parte desta organização.',
            );
          },
        );

        testWidgets(
          'Sad Path: Deve permanecer na tela atual quando logoutGoogle lançar',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              logoutError: Exception('falha de rede'),
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await _run(
              tester,
              harness.controller,
              harness.controller.forgetRemovedOrganization,
            );

            // 3. Assert
            expect(_currentRoute, _kHomeRoute);
          },
        );
      },
    );

    group('AuthGoogleViewModel.switchOrganization - Suíte de Testes Unitários', () {
      testWidgets(
        'Happy Path: Deve abrir o seletor de organizações com as organizações da pessoa',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(_currentRoute, Routes.organizationPicker);
          expect(
            harness.controller.state.organizationChoices.map(
              (b) => b.organization.id,
            ),
            ['rotasul'],
          );
        },
      );

      testWidgets(
        'Happy Path: Deve buscar as organizações antes de parar o rastreamento e esquecer a organização',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
          expect(
            harness.log.where(
              (e) =>
                  e == 'directory' ||
                  e == 'stop' ||
                  e == 'signOutOfOrganization' ||
                  e == 'forget',
            ),
            ['directory', 'stop', 'signOutOfOrganization', 'forget'],
          );
        },
      );

      testWidgets(
        'Happy Path: Não deve sair do Google nem abrir o seletor de contas',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          verifyNever(harness.authService.logoutGoogle());
          verifyNever(
            harness.authService.signInGoogle(
              onAccountChosen: anyNamed('onAccountChosen'),
            ),
          );
        },
      );

      testWidgets(
        'Happy Path: Deve atualizar o tema depois de esquecer a organização',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(
            harness.log.indexOf('refreshTheme'),
            greaterThan(harness.log.indexOf('forget')),
          );
          expect(harness.log, contains('refreshTheme'));
        },
      );

      testWidgets(
        'Happy Path: Deve usar o token guardado do login, sem pedir ao Google, enquanto ele for válido',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: true,
            idToken: _jwtExpiringIn(const Duration(hours: 1)),
            refreshedToken: null,
          );
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );
          harness.log.clear();

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(harness.log, isNot(contains('refreshGoogleIdToken')));
          expect(harness.log, contains('signOutOfOrganization'));
          expect(_currentRoute, Routes.organizationPicker);
        },
      );

      testWidgets(
        'Edge Case: Deve pedir um token novo quando o token guardado não for um JWT válido',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: true,
          );
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );
          harness.log.clear();

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(harness.log, contains('refreshGoogleIdToken'));
          expect(harness.log, contains('signOutOfOrganization'));
        },
      );

      testWidgets(
        'Edge Case: Deve pedir um token novo quando o token guardado estiver vencido',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: true,
            idToken: _jwtExpiringIn(const Duration(hours: -1)),
          );
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );
          harness.log.clear();

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(harness.log, contains('refreshGoogleIdToken'));
          expect(harness.log, contains('signOutOfOrganization'));
        },
      );

      testWidgets(
        'Edge Case: Deve navegar para Routes.noOrganization quando a pessoa não tiver organização',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(_currentRoute, Routes.noOrganization);
          expect(harness.controller.state.organizationChoices, isEmpty);
          verifyNever(harness.authService.logoutGoogle());
        },
      );

      testWidgets(
        'Edge Case: Não deve fazer nada quando chamado com isLoggingOut true (reentrância)',
        (WidgetTester tester) async {
          // 1. Arrange
          // A logout held open at the tracking stop keeps isLoggingOut true.
          final pendingStop = Completer<bool>();
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            pendingStop: pendingStop,
          );
          await _pumpAppSignIn(tester);
          final logout = harness.controller.logout();
          await tester.pump();
          expect(harness.controller.state.isLoggingOut, isTrue);
          harness.log.clear();

          // 2. Act
          final result = await harness.controller.switchOrganization();

          // 3. Assert
          expect(result, isA<Ok<void>>());
          expect(harness.log, isEmpty);
          verifyNever(harness.authService.refreshGoogleIdToken());
          verifyNever(harness.directory.organizationsOfSignedInUser());
          pendingStop.complete(true);
          await _run(tester, harness.controller, () => logout);
        },
      );

      testWidgets(
        'Edge Case: Não deve fazer nada quando chamado com isLoading true (reentrância)',
        (WidgetTester tester) async {
          // 1. Arrange
          // A sign-in held open at the directory (after the account was
          // chosen) keeps isLoading true.
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          await _pumpAppSignIn(tester);
          final lookup = Completer<List<OrganizationCandidate>>();
          when(
            harness.directory.organizationsOfSignedInUser(),
          ).thenAnswer((_) => lookup.future);
          final login = harness.controller.loginGoogle();
          await tester.pump();
          expect(harness.controller.state.isLoading, isTrue);
          harness.log.clear();

          // 2. Act
          final result = await harness.controller.switchOrganization();

          // 3. Assert
          expect(result, isA<Ok<void>>());
          expect(harness.log, isEmpty);
          verifyNever(harness.authService.refreshGoogleIdToken());
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
          lookup.complete(const []);
          await _run(tester, harness.controller, () => login);
        },
      );

      testWidgets(
        'Sad Path: Não deve mudar nada quando não houver token válido nem renovação',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            refreshedToken: null,
          );
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(harness.log, ['refreshGoogleIdToken']);
          verifyNever(harness.directory.organizationsOfSignedInUser());
          verifyNever(harness.authService.logoutGoogle());
          verifyNever(
            harness.authService.signInGoogle(
              onAccountChosen: anyNamed('onAccountChosen'),
            ),
          );
          expect(_currentRoute, _kHomeRoute);
        },
      );

      testWidgets(
        'Sad Path: Deve devolver Err "Trocar de organização" quando não houver token válido nem renovação',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            refreshedToken: null,
          );
          await _pumpAppSignIn(tester);

          // 2. Act
          final result = await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(result, _errTitled('Trocar de organização'));
        },
      );

      testWidgets(
        'Sad Path: Deve manter isLoggingOut false quando não houver token válido nem renovação',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            refreshedToken: null,
          );
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(harness.controller.state.isLoggingOut, isFalse);
        },
      );

      testWidgets(
        'Sad Path: Não deve parar o rastreamento nem esquecer a organização quando a busca de organizações lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('sem rede'));
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(
            harness.log.where(
              (e) =>
                  e == 'stop' || e == 'signOutOfOrganization' || e == 'forget',
            ),
            isEmpty,
          );
          expect(_currentRoute, _kHomeRoute);
        },
      );

      testWidgets(
        'Sad Path: Deve devolver Err "Trocar de organização" quando a busca de organizações lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('sem rede'));
          await _pumpAppSignIn(tester);

          // 2. Act
          final result = await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(result, _errTitled('Trocar de organização'));
        },
      );

      testWidgets(
        'Sad Path: Deve voltar isLoggingOut a false quando a busca de organizações lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('sem rede'));
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(harness.controller.state.isLoggingOut, isFalse);
        },
      );

      // isSwitchingOrganization: the harness has no seam to pause the run, so
      // the in-flight value is observed through the values the Rx emits.
      testWidgets(
        'Happy Path: Deve emitir isSwitchingOrganization true e depois false ao trocar de organização',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          await _pumpAppSignIn(tester);
          final seen = <bool>[];
          final sub = _onChange(
            harness.controller,
            (state) => state.isSwitchingOrganization,
            seen.add,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          sub();
          expect(seen, [true, false]);
          expect(harness.controller.state.isSwitchingOrganization, isFalse);
        },
      );

      testWidgets(
        'Sad Path: Deve emitir isSwitchingOrganization true e depois false quando a busca de organizações lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('sem rede'));
          await _pumpAppSignIn(tester);
          final seen = <bool>[];
          final sub = _onChange(
            harness.controller,
            (state) => state.isSwitchingOrganization,
            seen.add,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          sub();
          expect(seen, [true, false]);
          expect(harness.controller.state.isSwitchingOrganization, isFalse);
        },
      );

      testWidgets(
        'Edge Case: Não deve marcar isSwitchingOrganization durante um logout comum',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);
          final seen = <bool>[];
          final sub = _onChange(
            harness.controller,
            (state) => state.isSwitchingOrganization,
            seen.add,
          );

          // 2. Act
          await _run(tester, harness.controller, harness.controller.logout);

          // 3. Assert
          sub();
          expect(seen, isEmpty);
          expect(harness.controller.state.isSwitchingOrganization, isFalse);
        },
      );

      testWidgets(
        'Edge Case: Não deve marcar isSwitchingOrganization quando chamado com isLoggingOut true (reentrância)',
        (WidgetTester tester) async {
          // 1. Arrange
          // A logout held open at the tracking stop keeps isLoggingOut true.
          final pendingStop = Completer<bool>();
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            pendingStop: pendingStop,
          );
          await _pumpAppSignIn(tester);
          final logout = harness.controller.logout();
          await tester.pump();
          expect(harness.controller.state.isLoggingOut, isTrue);
          final seen = <bool>[];
          final sub = _onChange(
            harness.controller,
            (state) => state.isSwitchingOrganization,
            seen.add,
          );

          // 2. Act
          await harness.controller.switchOrganization();

          // 3. Assert
          sub();
          expect(seen, isEmpty);
          expect(harness.controller.state.isSwitchingOrganization, isFalse);
          pendingStop.complete(true);
          await _run(tester, harness.controller, () => logout);
        },
      );

      testWidgets(
        'Sad Path: Não deve marcar isSwitchingOrganization quando não houver token válido nem renovação',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            refreshedToken: null,
          );
          await _pumpAppSignIn(tester);
          final seen = <bool>[];
          final sub = _onChange(
            harness.controller,
            (state) => state.isSwitchingOrganization,
            seen.add,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          sub();
          expect(seen, isEmpty);
          expect(harness.controller.state.isSwitchingOrganization, isFalse);
        },
      );
    });

    group('AuthGoogleViewModel.ownsOrganization - Suíte de Testes Unitários', () {
      test(
        'Happy Path: Deve ser true quando o diretório marca a organização como do usuário',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [
              const OrganizationCandidate(
                id: 'rotasul',
                options: _kOptions,
                owner: true,
              ),
            ],
          );

          // 2. Act
          final owns = await harness.controller.ownsOrganization('rotasul');

          // 3. Assert
          expect(owns, isTrue);
        },
      );

      test(
        'Edge Case: Deve ser false quando o usuário é só membro da organização',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul, _kVerdeMarSignIn],
          );

          // 2. Act
          final owns = await harness.controller.ownsOrganization('rotasul');

          // 3. Assert
          expect(owns, isFalse);
        },
      );

      test(
        'Edge Case: Deve ser false quando o usuário é titular de outra organização',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [
              _kRotaSul,
              OrganizationCandidate(
                id: _kVerdeMarSignIn.id,
                options: _kVerdeMarSignIn.options,
                owner: true,
              ),
            ],
          );

          // 2. Act
          final owns = await harness.controller.ownsOrganization('rotasul');

          // 3. Assert
          expect(owns, isFalse);
        },
      );

      test(
        'Sad Path: Deve ser false quando a organização não está na lista',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kVerdeMarSignIn]);

          // 2. Act
          final owns = await harness.controller.ownsOrganization('rotasul');

          // 3. Assert
          expect(owns, isFalse);
        },
      );

      test(
        'Sad Path: Deve propagar a falha do diretório em vez de responder false',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: StateError('offline'));

          // 2. Act
          final owns = harness.controller.ownsOrganization('rotasul');

          // 3. Assert
          await expectLater(owns, throwsStateError);
        },
      );
    });
  });

  group('invites', () {
    tearDown(() {
      Organization.bind(testOrganization);
      CurrentOrganizationFirebase.debugReset();
    });

    group('AuthGoogleViewModel.acceptInvite - Unit Test Suite', () {
      testWidgets('Happy Path: accepts the invite through the repository', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessInvites();
        await _pumpAppInvites(tester);

        // 2. Act
        await _accept(tester, harness.controller);

        // 3. Assert
        verify(harness.invites.accept(_kInvite)).called(1);
      });

      testWidgets('Happy Path: sets welcome to the accepted invite', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessInvites();
        await _pumpAppInvites(tester);

        // 2. Act
        await _accept(tester, harness.controller);

        // 3. Assert
        expect(harness.controller.state.welcome, same(_kInvite));
      });

      testWidgets(
        'Happy Path: with the organization listed, asks once and continues into the organization',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites();
          await _pumpAppInvites(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
          expect(
            harness.log,
            containsAllInOrder(['bind', 'signInToOrganization']),
          );
          expect(harness.controller.state.acceptingInvite, isNull);
        },
      );

      testWidgets(
        'Edge Case: an organization not listed is not waited for: Sem organização after one ask',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites(answers: const [[]]);
          await _pumpAppInvites(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
          expect(harness.log, isNot(contains('bind')));
          expect(_currentRoute, Routes.noOrganization);
        },
      );

      test(
        'Edge Case: a second accept while one is in flight does nothing',
        () async {
          // 1. Arrange
          final harness = _HarnessInvites();
          final gate = Completer<void>();
          when(harness.invites.accept(any)).thenAnswer((_) async {
            await gate.future;
            return Ok(_kInvite);
          });
          unawaited(harness.controller.acceptInvite(_kInvite));

          // 2. Act
          await harness.controller.acceptInvite(_kInvite);

          // 3. Assert
          verify(harness.invites.accept(_kInvite)).called(1);
          expect(harness.controller.state.acceptingInvite, 'inv1');
        },
      );

      test(
        'Sad Path: an Err sets inviteError and clears acceptingInvite',
        () async {
          // 1. Arrange
          final harness = _HarnessInvites();
          when(harness.invites.accept(any)).thenAnswer(
            (_) async => const Err(
              'Este convite expirou. Peça um novo a quem convidou você.',
            ),
          );

          // 2. Act
          await harness.controller.acceptInvite(_kInvite);

          // 3. Assert
          expect(
            harness.controller.state.inviteError,
            'Este convite expirou. Peça um novo a quem convidou você.',
          );
          expect(harness.controller.state.acceptingInvite, isNull);
          verifyNever(harness.directory.organizationsOfSignedInUser());
        },
      );
    });

    group('AuthGoogleViewModel pending invites on the picker - Unit Test Suite', () {
      testWidgets(
        'Happy Path: recheckOrganizations with one organization loads the pending invites',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites();
          when(harness.invites.mine()).thenAnswer((_) async => Ok([_kInvite]));
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          expect(harness.controller.state.pendingInvites, [_kInvite]);
          expect(_currentRoute, Routes.organizationPicker);
        },
      );

      testWidgets(
        'Edge Case: recheckOrganizations with several organizations loads every pending invite',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites(
            answers: const [
              [_kRotaSul, _kVerdeMarInvites],
            ],
          );
          when(
            harness.invites.mine(),
          ).thenAnswer((_) async => Ok([_kInvite, _kOtherInvite]));
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          expect(harness.controller.state.pendingInvites, [
            _kInvite,
            _kOtherInvite,
          ]);
          expect(_currentRoute, Routes.organizationPicker);
          expect(harness.log, isNot(contains('bind')));
        },
      );

      testWidgets(
        'Sad Path: a failing invite read leaves pendingInvites empty and still opens the picker',
        (WidgetTester tester) async {
          // 1. Arrange
          // A first check loads one invite; the second read fails.
          final harness = _HarnessInvites();
          var reads = 0;
          when(harness.invites.mine()).thenAnswer((_) async {
            if (reads++ == 0) return Ok([_kOtherInvite]);
            return Err(
              'Não foi possível carregar os convites.',
              error: Exception('sem rede'),
            );
          });
          await _pumpAppInvites(tester);
          await _drive(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );
          expect(harness.controller.state.pendingInvites, [_kOtherInvite]);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          expect(harness.controller.state.pendingInvites, isEmpty);
          expect(harness.controller.state.session, isA<SessionPicking>());
        },
      );
    });

    group(
      'AuthGoogleViewModel.acceptInvite (several organizations) - Unit Test Suite',
      () {
        testWidgets(
          "Happy Path: binds the invite's organization even when another one is listed first",
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessInvites(
              answers: const [
                [_kVerdeMarInvites, _kRotaSul],
              ],
            );
            await _pumpAppInvites(tester);

            // 2. Act
            await _accept(tester, harness.controller);

            // 3. Assert
            expect(harness.boundIds, ['rotasul']);
          },
        );

        testWidgets('Happy Path: ends on the welcome screen, not the picker', (
          WidgetTester tester,
        ) async {
          // 1. Arrange
          final harness = _HarnessInvites(
            answers: const [
              [_kVerdeMarInvites, _kRotaSul],
            ],
          );
          await _pumpAppInvites(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(_currentRoute, Routes.welcome);
        });

        testWidgets(
          "Sad Path: opens the picker when the invite's organization never shows up among several others",
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessInvites(
              answers: const [
                [_kVerdeMarInvites, _kAzulCeu],
              ],
            );
            await _pumpAppInvites(tester);

            // 2. Act
            await _accept(tester, harness.controller);

            // 3. Assert
            verify(harness.directory.organizationsOfSignedInUser()).called(1);
            expect(harness.boundIds, isEmpty);
            expect(_currentRoute, Routes.organizationPicker);
          },
        );

        testWidgets(
          "Sad Path: opens the picker when the invite's organization never shows up and one other is listed",
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessInvites(
              answers: const [
                [_kVerdeMarInvites],
              ],
            );
            await _pumpAppInvites(tester);

            // 2. Act
            await _accept(tester, harness.controller);

            // 3. Assert
            expect(harness.boundIds, isEmpty);
            expect(_currentRoute, Routes.organizationPicker);
          },
        );
      },
    );

    group('AuthGoogleViewModel.enterCreatedOrganization - Unit Test Suite', () {
      testWidgets(
        'Happy Path: binds the created organization when several are listed',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites(
            answers: const [
              [_kRotaSul, _kVerdeMarInvites],
            ],
          );
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            () => harness.controller.enterCreatedOrganization('verdemar'),
          );

          // 3. Assert
          expect(harness.boundIds, ['verdemar']);
        },
      );

      testWidgets('Happy Path: ends on MonAmie, not the picker', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessInvites(
          answers: const [
            [_kRotaSul, _kVerdeMarInvites],
          ],
        );
        await _pumpAppInvites(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          () => harness.controller.enterCreatedOrganization('verdemar'),
        );

        // 3. Assert
        expect(_currentRoute, Routes.monamie);
      });

      testWidgets(
        'Sad Path: opens the picker when the created organization never shows up among several others',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites(
            answers: const [
              [_kRotaSul, _kAzulCeu],
            ],
          );
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            () => harness.controller.enterCreatedOrganization('verdemar'),
          );

          // 3. Assert
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
          expect(harness.boundIds, isEmpty);
          expect(_currentRoute, Routes.organizationPicker);
        },
      );

      testWidgets(
        'Sad Path: opens the picker when the created organization never shows up and one other is listed',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites();
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            () => harness.controller.enterCreatedOrganization('verdemar'),
          );

          // 3. Assert
          expect(harness.boundIds, isEmpty);
          expect(_currentRoute, Routes.organizationPicker);
        },
      );
    });
  });

  group('ownership', () {
    setUp(() {
      directory = MockOrganizationDirectory();
      _directoryAnswers();
    });

    group('AuthGoogleViewModel.loadOwnership - Unit Test Suite', () {
      test(
        'Happy Path: the owner of the organization is recorded as such',
        () async {
          // 1. Arrange
          final controller = newController();

          // 2. Act
          await controller.loadOwnership('rotasul');

          // 3. Assert
          expect(controller.state.ownership, {'rotasul': true});
        },
      );

      test('Happy Path: a member who does not own it is recorded as not the '
          'owner', () async {
        // 1. Arrange
        final controller = newController();

        // 2. Act
        await controller.loadOwnership('verdemar');

        // 3. Assert
        expect(controller.state.ownership, {'verdemar': false});
      });

      test(
        'Edge Case: an organization already read is not read again',
        () async {
          // 1. Arrange
          final controller = newController();
          await controller.loadOwnership('rotasul');

          // 2. Act
          await controller.loadOwnership('rotasul');

          // 3. Assert
          verify(directory.organizationsOfSignedInUser()).called(1);
        },
      );

      test('Edge Case: another organization is read on its own', () async {
        // 1. Arrange
        final controller = newController();
        await controller.loadOwnership('rotasul');

        // 2. Act
        await controller.loadOwnership('verdemar');

        // 3. Assert
        verify(directory.organizationsOfSignedInUser()).called(2);
        expect(controller.state.ownership, {
          'rotasul': true,
          'verdemar': false,
        });
      });

      test('Edge Case: a call while one is reading reads nothing', () async {
        // 1. Arrange
        final controller = newController();
        final gate = Completer<void>();
        when(directory.organizationsOfSignedInUser()).thenAnswer((_) async {
          await gate.future;
          return _kOwnershipOrganizations;
        });
        final first = controller.loadOwnership('rotasul');

        // 2. Act
        await controller.loadOwnership('rotasul');

        // 3. Assert
        verify(directory.organizationsOfSignedInUser()).called(1);
        gate.complete();
        await first;
      });

      test(
        'Sad Path: a failed read leaves the ownership unknown (hidden)',
        () async {
          // 1. Arrange
          final controller = newController();
          when(
            directory.organizationsOfSignedInUser(),
          ).thenAnswer((_) async => throw StateError('offline'));

          // 2. Act
          await controller.loadOwnership('rotasul');

          // 3. Assert
          expect(controller.state.ownership.containsKey('rotasul'), isFalse);
        },
      );

      test('Sad Path: after a failed read the next call tries again', () async {
        // 1. Arrange
        final controller = newController();
        when(
          directory.organizationsOfSignedInUser(),
        ).thenAnswer((_) async => throw StateError('offline'));
        await controller.loadOwnership('rotasul');
        _directoryAnswers();

        // 2. Act
        await controller.loadOwnership('rotasul');

        // 3. Assert
        verify(directory.organizationsOfSignedInUser()).called(2);
        expect(controller.state.ownership, {'rotasul': true});
      });
    });
  });

  group('logout', () {
    group('AuthGoogleViewModel.logout - Suíte de Testes Unitários', () {
      // ---------------------------------------------------------------------
      // Happy Path
      // ---------------------------------------------------------------------
      testWidgets(
        'Happy Path: Deve parar o rastreamento informando o e-mail do usuário salvo',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(_stoppedEmails(harness.stopper), [_kStoredEmail]);
        },
      );

      testWidgets(
        'Happy Path: Deve parar o rastreamento antes do signOut, depois limpar o usuário salvo e então navegar para o login',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.log, [
            _kLogStop,
            _kLogSignOut,
            _kLogDeleteUser,
            _kLogNavigateLogin,
          ]);
        },
      );

      testWidgets(
        'Happy Path: Deve navegar para Routes.login ao concluir o logout',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(_currentRoute, Routes.login);
          expect(find.text(_kLoginPlaceholder), findsOneWidget);
          expect(find.text(_kHomePlaceholder), findsNothing);
        },
      );

      testWidgets(
        'Happy Path: Deve concluir com Ok(true) e sem aviso quando o rastreamento parar normalmente',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          final run = await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(run.error, isNull);
          expect(
            run.result,
            isA<Ok<bool>>().having((ok) => ok.value, 'value', isTrue),
          );
          verifyNever(harness.notices.show(any));
        },
      );

      testWidgets(
        'Happy Path: Deve finalizar isLoggingOut como false após o logout',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.controller.state.isLoggingOut, isFalse);
        },
      );

      testWidgets(
        'Happy Path: Deve limpar signedInEmail ao concluir o logout',
        (WidgetTester tester) async {
          // 1. Arrange
          // A sign-in (with no organization) records the central e-mail.
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );
          expect(harness.controller.state.signedInEmail, _kCentralEmail);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.controller.state.signedInEmail, isNull);
        },
      );

      testWidgets(
        'Happy Path: Deve esquecer a titularidade lida ao concluir o logout',
        (WidgetTester tester) async {
          // 1. Arrange
          // The owner's organization is read first.
          final harness = _HarnessSignIn(
            organizations: const [
              OrganizationCandidate(
                id: 'rotasul',
                options: _kOptions,
                owner: true,
              ),
            ],
          );
          await _pumpAppSignIn(tester);
          await harness.controller.loadOwnership('rotasul');
          expect(harness.controller.state.ownership, {'rotasul': true});

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.controller.state.ownership, isEmpty);
        },
      );

      // ---------------------------------------------------------------------
      // Edge Case
      // ---------------------------------------------------------------------
      test('Edge Case: Deve iniciar com isLoggingOut false', () {
        // 1. Arrange
        final log = <String>[];

        // 2. Act
        final controller = AuthGoogleViewModel(
          notices: MockNoticePresenter(),
          organizationSession: OrganizationSession(
            store: MockOrganizationBindingStore(),
          ),
          organizationLocalData: MockOrganizationLocalData(),
          refreshTheme: () {},
          authGoogle: _authServiceLogout(log),
          userRepository: _userRepositoryLogout(log),
          trackingStopper: _trackingStopper(log, entry: _kLogStop),
          organizationDirectory: MockOrganizationDirectory(),
          brandingLoader: MockOrganizationBrandingLoader(),
          invitesRepository: MockInvitesRepository(),
          deletionRepository: MockAccountDeletionRepository(),
          membershipCheck: MockMembershipService(),
        );

        // 3. Assert
        expect(controller.state.isLoggingOut, isFalse);
      });

      testWidgets(
        'Edge Case: Deve chamar stop com e-mail nulo quando não houver usuário salvo',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: null);
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(_stoppedEmails(harness.stopper), [null]);
        },
      );

      testWidgets(
        'Edge Case: Deve prosseguir com signOut, limpeza e navegação quando não houver usuário salvo',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: null);
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.log, [
            _kLogStop,
            _kLogSignOut,
            _kLogDeleteUser,
            _kLogNavigateLogin,
          ]);
        },
      );

      testWidgets(
        'Edge Case: Deve manter isLoggingOut true enquanto a parada do rastreamento estiver em andamento',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            pendingStop: Completer<bool>(),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          unawaited(harness.controller.logout());
          await tester.pump();

          // 3. Assert
          expect(harness.controller.state.isLoggingOut, isTrue);
        },
      );

      testWidgets(
        'Edge Case: Não deve fazer signOut nem limpar o usuário enquanto a parada do rastreamento não concluir',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            pendingStop: Completer<bool>(),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          unawaited(harness.controller.logout());
          await tester.pump();

          // 3. Assert
          verifyNever(harness.authService.logoutGoogle());
          verifyNever(harness.userRepository.deleteUserGoogleModel());
        },
      );

      testWidgets(
        'Edge Case: Deve ignorar um segundo logout enquanto o primeiro estiver em andamento',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            pendingStop: Completer<bool>(),
          );
          await _pumpAppLogout(tester, harness);
          unawaited(harness.controller.logout());
          await tester.pump();

          // 2. Act
          await harness.controller.logout();

          // 3. Assert
          verify(harness.stopper.stop(email: anyNamed('email'))).called(1);
        },
      );

      testWidgets(
        'Edge Case: Deve executar stop e logoutGoogle uma única vez quando logout for chamado duas vezes em sequência',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await Future.wait([
            harness.controller.logout(),
            harness.controller.logout(),
          ]);
          await tester.pumpAndSettle();

          // 3. Assert
          verify(harness.stopper.stop(email: anyNamed('email'))).called(1);
          verify(harness.authService.logoutGoogle()).called(1);
        },
      );

      // ---------------------------------------------------------------------
      // Sad Path
      // ---------------------------------------------------------------------
      testWidgets(
        'Sad Path: Deve chamar stop com e-mail nulo quando a leitura do usuário salvo lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            getUserError: StateError('box do Hive indisponível'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(_stoppedEmails(harness.stopper), [null]);
        },
      );

      testWidgets(
        'Sad Path: Deve prosseguir com signOut, limpeza e navegação quando a leitura do usuário salvo lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            getUserError: StateError('box do Hive indisponível'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.log, [
            _kLogStop,
            _kLogSignOut,
            _kLogDeleteUser,
            _kLogNavigateLogin,
          ]);
        },
      );

      testWidgets(
        'Sad Path: Deve fazer signOut, limpar o usuário e navegar mesmo quando stop não confirmar a parada',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            stopResult: false,
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.log, [
            _kLogStop,
            _kLogSignOut,
            _kLogDeleteUser,
            _kLogNavigateLogin,
          ]);
          expect(_currentRoute, Routes.login);
        },
      );

      testWidgets(
        'Sad Path: Deve mostrar o aviso "Rastreamento" quando stop não confirmar a parada',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            stopResult: false,
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          verify(
            harness.notices.show(argThat(_noticeTitled('Rastreamento'))),
          ).called(1);
        },
      );

      testWidgets(
        'Sad Path: Não deve apagar o usuário salvo quando logoutGoogle lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            logoutError: Exception('falha de rede no signOut'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          verifyNever(harness.userRepository.deleteUserGoogleModel());
        },
      );

      testWidgets(
        'Sad Path: Não deve propagar exceção para fora de logout quando logoutGoogle lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            logoutError: Exception('falha de rede no signOut'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          final run = await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(run.error, isNull);
        },
      );

      testWidgets(
        'Sad Path: Deve finalizar isLoggingOut como false quando logoutGoogle lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            logoutError: Exception('falha de rede no signOut'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.controller.state.isLoggingOut, isFalse);
        },
      );

      testWidgets(
        'Sad Path: Deve devolver Err "Erro ao sair" quando logoutGoogle lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            logoutError: Exception('falha de rede no signOut'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          final run = await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(run.result, _errTitled('Erro ao sair'));
        },
      );

      testWidgets(
        'Sad Path: Deve permanecer na tela atual (sem navegar para o login) quando logoutGoogle lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            logoutError: Exception('falha de rede no signOut'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(_currentRoute, _kHomeRoute);
          expect(find.text(_kHomePlaceholder), findsOneWidget);
        },
      );

      testWidgets(
        'Sad Path: Deve finalizar isLoggingOut como false e não propagar exceção quando a limpeza do usuário salvo lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            deleteError: StateError('falha ao apagar o box do Hive'),
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          final run = await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(run.error, isNull);
          expect(harness.controller.state.isLoggingOut, isFalse);
        },
      );
    });
  });

  // The session state each navigation decision leaves the controller in. The
  // router's redirect will read it alone, so these tests never look at the
  // current route.
  group('session state', () {
    tearDown(() {
      Organization.bind(testOrganization);
      CurrentOrganizationFirebase.debugReset();
    });

    /// Rota Sul as the branding loader of [_HarnessSignIn] names it.
    final rotaSul = OrganizationBinding(
      organization: const OrganizationConfig(
        id: 'rotasul',
        name: _kRotaSulName,
      ),
      options: _kRotaSul.options,
    );

    /// Signs in and picks Rota Sul, ending bound to it (the person has a
    /// membership there).
    Future<void> bindRotaSul(
      WidgetTester tester,
      _HarnessSignIn harness,
    ) async {
      await _run(tester, harness.controller, harness.controller.loginGoogle);
      await _run(
        tester,
        harness.controller,
        () => harness.controller.chooseOrganization(
          harness.controller.state.organizationChoices.single,
        ),
      );
      expect(harness.controller.state.session, const SessionState.bound());
    }

    group('AuthGoogleViewModel.loginGoogle - Unit Test Suite', () {
      testWidgets(
        'Happy Path: several organizations end in picking with their choices',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul, _kVerdeMarSignIn],
          );
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(
            harness.controller.state.session,
            SessionState.picking([
              rotaSul,
              OrganizationBinding(
                organization: const OrganizationConfig(
                  id: 'verdemar',
                  name: _kRotaSulName,
                ),
                options: _kVerdeMarSignIn.options,
              ),
            ]),
          );
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
        },
      );

      testWidgets(
        'Happy Path: a single organization still ends in picking (a sign-in just made)',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(
            harness.controller.state.session,
            SessionState.picking([rotaSul]),
          );
        },
      );

      testWidgets('Edge Case: no organization ends in noOrganization', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn();
        await _pumpAppSignIn(tester);

        // 2. Act
        await _run(tester, harness.controller, harness.controller.loginGoogle);

        // 3. Assert
        expect(
          harness.controller.state.session,
          const SessionState.noOrganization(),
        );
      });

      testWidgets(
        'Edge Case: a pending deletion ends in deletionPending without looking up organizations',
        (WidgetTester tester) async {
          // 1. Arrange
          final deletion = AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2));
          final deletionRepository = MockAccountDeletionRepository();
          when(
            deletionRepository.pending(),
          ).thenAnswer((_) async => Ok(deletion));
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            deletionRepository: deletionRepository,
          );
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.deletionPending(),
          );
          expect(harness.controller.state.accountDeletion, deletion);
          verify(deletionRepository.pending()).called(1);
          verifyNever(harness.directory.organizationsOfSignedInUser());
        },
      );

      testWidgets(
        'Sad Path: an unreadable pending deletion does not keep the person '
        'out: the organizations are looked up as usual',
        (WidgetTester tester) async {
          // 1. Arrange
          final deletionRepository = MockAccountDeletionRepository();
          when(deletionRepository.pending()).thenAnswer(
            (_) async => Err(
              'Não foi possível ler a exclusão da conta.',
              error: Exception('offline'),
            ),
          );
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            deletionRepository: deletionRepository,
          );
          await _pumpAppSignIn(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(
            harness.controller.state.session,
            isNot(const SessionState.deletionPending()),
          );
          expect(harness.controller.state.accountDeletion, isNull);
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
        },
      );

      group('AuthGoogleViewModel.cancelAccountDeletion - Unit Test Suite', () {
        testWidgets(
          'Happy Path: signs in again, cancels the deletion and marks it '
          'restored',
          (WidgetTester tester) async {
            // 1. Arrange
            final deletionRepository = MockAccountDeletionRepository();
            when(
              deletionRepository.cancel(),
            ).thenAnswer((_) async => const Ok(null));
            final harness = _HarnessSignIn(
              deletionRepository: deletionRepository,
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await harness.controller.cancelAccountDeletion();
            await tester.pumpAndSettle();

            // 3. Assert
            verify(deletionRepository.cancel()).called(1);
            expect(harness.log, contains('signInGoogle'));
            expect(harness.controller.state.deletionRestored, isTrue);
            expect(harness.controller.state.deletionError, isEmpty);
            expect(harness.controller.state.cancellingDeletion, isFalse);
          },
        );

        testWidgets(
          'Sad Path: an Err from the cancel shows its message and restores '
          'nothing',
          (WidgetTester tester) async {
            // 1. Arrange
            final deletionRepository = MockAccountDeletionRepository();
            when(
              deletionRepository.cancel(),
            ).thenAnswer((_) async => const Err('Prazo encerrado.'));
            final harness = _HarnessSignIn(
              deletionRepository: deletionRepository,
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await harness.controller.cancelAccountDeletion();
            await tester.pumpAndSettle();

            // 3. Assert
            expect(harness.controller.state.deletionError, 'Prazo encerrado.');
            expect(harness.controller.state.deletionRestored, isFalse);
            expect(harness.controller.state.cancellingDeletion, isFalse);
          },
        );

        testWidgets(
          'Sad Path: a failed Google sign-in shows a generic message and '
          'cancels nothing',
          (WidgetTester tester) async {
            // 1. Arrange
            final deletionRepository = MockAccountDeletionRepository();
            final harness = _HarnessSignIn(
              deletionRepository: deletionRepository,
              signInError: Exception('offline'),
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            await harness.controller.cancelAccountDeletion();
            await tester.pumpAndSettle();

            // 3. Assert
            verifyNever(deletionRepository.cancel());
            expect(
              harness.controller.state.deletionError,
              'Não foi possível cancelar agora. Verifique a conexão e tente '
              'de novo.',
            );
            expect(harness.controller.state.deletionRestored, isFalse);
          },
        );
      });

      testWidgets(
        'Sad Path: a failing organization lookup leaves the session signedOut',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('offline'));
          await _pumpAppSignIn(tester);

          // 2. Act
          final result = await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(result, _errTitled(_kLoginErrorTitle));
          expect(
            harness.controller.state.session,
            const SessionState.signedOut(),
          );
        },
      );
    });

    group('AuthGoogleViewModel web sign-in - Unit Test Suite', () {
      testWidgets(
        'Happy Path: a web sign-in token with no organization ends in noOrganization',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          final webSignIns = StreamController<String?>();
          when(
            harness.authService.onWebSignIn,
          ).thenAnswer((_) => webSignIns.stream);
          when(
            harness.authService.ensureInitialized(),
          ).thenAnswer((_) async {});
          await _pumpAppSignIn(tester);
          harness.controller.start();

          // 2. Act
          webSignIns.add(_kIdToken);
          await tester.pump();
          await _run(tester, harness.controller, () => null);

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.noOrganization(),
          );
          verify(harness.directory.organizationsOfSignedInUser()).called(1);
          await webSignIns.close();
        },
      );

      testWidgets(
        'Sad Path: a failed web sign-in (null token) keeps signedOut and shows the login error',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          final webSignIns = StreamController<String?>();
          when(
            harness.authService.onWebSignIn,
          ).thenAnswer((_) => webSignIns.stream);
          when(
            harness.authService.ensureInitialized(),
          ).thenAnswer((_) async {});
          await _pumpAppSignIn(tester);
          harness.controller.start();

          // 2. Act
          webSignIns.add(null);
          await tester.pump();

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.signedOut(),
          );
          verify(
            harness.notices.show(argThat(_noticeTitled(_kLoginErrorTitle))),
          ).called(1);
          verifyNever(harness.directory.organizationsOfSignedInUser());
          await webSignIns.close();
        },
      );
    });

    group('AuthGoogleViewModel.chooseOrganization - Unit Test Suite', () {
      testWidgets('Happy Path: a member ends bound', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: [_kRotaSul],
          member: true,
        );
        await _pumpAppSignIn(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          () => harness.controller.chooseOrganization(rotaSul),
        );

        // 3. Assert
        expect(harness.controller.state.session, const SessionState.bound());
        verify(harness.session.bind(rotaSul)).called(1);
      });

      testWidgets(
        'Edge Case: an unreadable membership (null) still ends bound',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: null,
          );
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            () => harness.controller.chooseOrganization(rotaSul),
          );

          // 3. Assert
          expect(harness.controller.state.session, const SessionState.bound());
        },
      );

      testWidgets('Edge Case: a membership gone ends in noOrganization', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: [_kRotaSul],
          member: false,
        );
        await _pumpAppSignIn(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          () => harness.controller.chooseOrganization(rotaSul),
        );

        // 3. Assert
        expect(
          harness.controller.state.session,
          const SessionState.noOrganization(),
        );
        verify(harness.session.forget()).called(1);
      });

      testWidgets(
        'Sad Path: an entry that fails after binding keeps picking with the same choices',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: true,
          );
          when(
            harness.authService.saveOrganizationProfile(),
          ).thenAnswer((_) async => null);
          await _pumpAppSignIn(tester);
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 2. Act
          final result = await _run(
            tester,
            harness.controller,
            () => harness.controller.chooseOrganization(rotaSul),
          );

          // 3. Assert
          expect(result, _errTitled(_kLoginErrorTitle));
          expect(
            harness.controller.state.session,
            SessionState.picking([rotaSul]),
          );
          verify(harness.session.forget()).called(1);
        },
      );
    });

    group('AuthGoogleViewModel.switchOrganization - Unit Test Suite', () {
      testWidgets(
        'Happy Path: organizations left end in picking with their choices',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: true,
          );
          await _pumpAppSignIn(tester);
          await bindRotaSul(tester, harness);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(
            harness.controller.state.session,
            SessionState.picking([rotaSul]),
          );
        },
      );

      testWidgets('Edge Case: nothing left ends in noOrganization', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: [_kRotaSul],
          member: true,
        );
        await _pumpAppSignIn(tester);
        await bindRotaSul(tester, harness);
        when(
          harness.directory.organizationsOfSignedInUser(),
        ).thenAnswer((_) async => const []);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.switchOrganization,
        );

        // 3. Assert
        expect(
          harness.controller.state.session,
          const SessionState.noOrganization(),
        );
      });

      testWidgets('Sad Path: a failing lookup keeps the session bound', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: [_kRotaSul],
          member: true,
        );
        await _pumpAppSignIn(tester);
        await bindRotaSul(tester, harness);
        when(
          harness.directory.organizationsOfSignedInUser(),
        ).thenAnswer((_) async => throw Exception('offline'));

        // 2. Act
        final result = await _run(
          tester,
          harness.controller,
          harness.controller.switchOrganization,
        );

        // 3. Assert
        expect(result, _errTitled('Trocar de organização'));
        expect(harness.controller.state.session, const SessionState.bound());
      });
    });

    group('AuthGoogleViewModel sign-outs - Unit Test Suite', () {
      testWidgets('Happy Path: logout from bound ends signedOut', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: [_kRotaSul],
          member: true,
        );
        await _pumpAppSignIn(tester);
        await bindRotaSul(tester, harness);

        // 2. Act
        final result = await _run(
          tester,
          harness.controller,
          harness.controller.logout,
        );

        // 3. Assert
        expect(result, isA<Ok<bool>>().having((ok) => ok.value, 'value', true));
        expect(
          harness.controller.state.session,
          const SessionState.signedOut(),
        );
      });

      testWidgets(
        'Happy Path: accountDeleted from bound ends deletionPending with the deletion',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: true,
          );
          await _pumpAppSignIn(tester);
          await bindRotaSul(tester, harness);
          final deletion = AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2));

          // 2. Act
          await _run(
            tester,
            harness.controller,
            () => harness.controller.accountDeleted(deletion),
          );

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.deletionPending(),
          );
          expect(harness.controller.state.accountDeletion, deletion);
          verify(harness.authService.logoutGoogle()).called(1);
        },
      );

      testWidgets(
        'Happy Path: forgetRemovedOrganization from bound ends in noOrganization',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            member: true,
          );
          await _pumpAppSignIn(tester);
          await bindRotaSul(tester, harness);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.forgetRemovedOrganization,
          );

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.noOrganization(),
          );
          expect(
            harness.controller.state.noAccessReason,
            'Você não faz mais parte da $_kRotaSulName.',
          );
        },
      );

      testWidgets('Sad Path: a failing logout keeps the session bound', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: [_kRotaSul],
          member: true,
          logoutError: Exception('offline'),
        );
        await _pumpAppSignIn(tester);
        await bindRotaSul(tester, harness);

        // 2. Act
        final result = await _run(
          tester,
          harness.controller,
          harness.controller.logout,
        );

        // 3. Assert
        expect(result, _errTitled('Erro ao sair'));
        expect(harness.controller.state.session, const SessionState.bound());
      });
    });

    group('AuthGoogleViewModel.sessionRestored - Unit Test Suite', () {
      test('Happy Path: a restored session ends bound', () {
        // 1. Arrange
        final harness = _HarnessSignIn();

        // 2. Act
        harness.controller.sessionRestored();

        // 3. Assert
        expect(harness.controller.state.session, const SessionState.bound());
      });

      test('Edge Case: a second call does not notify again', () {
        // 1. Arrange
        final harness = _HarnessSignIn();
        harness.controller.sessionRestored();
        var notifications = 0;
        harness.controller.addListener(() => notifications++);

        // 2. Act
        harness.controller.sessionRestored();

        // 3. Assert
        expect(notifications, 0);
        expect(harness.controller.state.session, const SessionState.bound());
      });

      test('Sad Path: a disposed controller is not notified', () {
        // 1. Arrange
        final harness = _HarnessSignIn();
        harness.controller.dispose();

        // 2. Act
        final act = harness.controller.sessionRestored;

        // 3. Assert
        expect(act, returnsNormally);
      });
    });
  });

  group('session state after invites', () {
    tearDown(() {
      Organization.bind(testOrganization);
      CurrentOrganizationFirebase.debugReset();
    });

    group('AuthGoogleViewModel.acceptInvite - Unit Test Suite', () {
      testWidgets(
        "Happy Path: entering the invite's organization ends in welcome",
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites();
          await _pumpAppInvites(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.welcome(),
          );
          expect(harness.controller.state.welcome, _kInvite);
        },
      );

      testWidgets(
        "Edge Case: the invite's organization not listed ends in noOrganization",
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites(answers: const [[]]);
          await _pumpAppInvites(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.noOrganization(),
          );
        },
      );

      testWidgets(
        'Sad Path: a refused invite leaves the session where it was',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites();
          when(
            harness.invites.accept(any),
          ).thenAnswer((_) async => const Err('Este convite expirou.'));
          await _pumpAppInvites(tester);

          // 2. Act
          await _accept(tester, harness.controller);

          // 3. Assert
          expect(
            harness.controller.state.session,
            const SessionState.signedOut(),
          );
          expect(harness.controller.state.welcome, isNull);
        },
      );
    });

    group('AuthGoogleViewModel.finishWelcome - Unit Test Suite', () {
      testWidgets('Happy Path: closing the welcome ends bound', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessInvites();
        await _pumpAppInvites(tester);
        await _accept(tester, harness.controller);

        // 2. Act
        harness.controller.finishWelcome();

        // 3. Assert
        expect(harness.controller.state.session, const SessionState.bound());
      });

      testWidgets('Edge Case: closing the welcome forgets the invite', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessInvites();
        await _pumpAppInvites(tester);
        await _accept(tester, harness.controller);

        // 2. Act
        harness.controller.finishWelcome();

        // 3. Assert
        expect(harness.controller.state.welcome, isNull);
      });

      test('Sad Path: with no welcome pending it still ends bound', () {
        // 1. Arrange
        final harness = _HarnessInvites();

        // 2. Act
        harness.controller.finishWelcome();

        // 3. Assert
        expect(harness.controller.state.session, const SessionState.bound());
      });
    });

    group('AuthGoogleViewModel.enterCreatedOrganization - Unit Test Suite', () {
      testWidgets('Happy Path: the organization just created ends bound', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessInvites(
          answers: const [
            [_kVerdeMarInvites, _kRotaSul],
          ],
        );
        await _pumpAppInvites(tester);

        // 2. Act
        await _drive(
          tester,
          harness.controller,
          () => harness.controller.enterCreatedOrganization('rotasul'),
        );

        // 3. Assert
        expect(harness.controller.state.session, const SessionState.bound());
      });
    });
  });

  group('lifecycle', () {
    group('AuthGoogleViewModel.start - Unit Test Suite', () {
      test(
        'Happy Path: start initializes Google and then marks it ready',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          when(
            harness.authService.ensureInitialized(),
          ).thenAnswer((_) async {});

          // 2. Act
          harness.controller.start();
          await pumpEventQueue();

          // 3. Assert
          expect(harness.controller.state.googleReady, isTrue);
          verify(harness.authService.ensureInitialized()).called(1);
        },
      );

      test('Edge Case: a second start does nothing', () async {
        // 1. Arrange
        final harness = _HarnessSignIn();
        when(harness.authService.ensureInitialized()).thenAnswer((_) async {});
        harness.controller.start();

        // 2. Act
        harness.controller.start();
        await pumpEventQueue();

        // 3. Assert
        verify(harness.authService.onWebSignIn).called(1);
        verify(harness.authService.ensureInitialized()).called(1);
      });

      test(
        'Sad Path: a failing initialization still marks Google ready',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          when(
            harness.authService.ensureInitialized(),
          ).thenAnswer((_) async => throw StateError('no Play services'));

          // 2. Act
          harness.controller.start();
          await pumpEventQueue();

          // 3. Assert
          expect(harness.controller.state.googleReady, isTrue);
        },
      );
    });

    group('AuthGoogleViewModel.dispose - Unit Test Suite', () {
      test(
        'Happy Path: dispose stops listening to the web sign-in and disposes the service',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          final webSignIns = StreamController<String?>();
          when(
            harness.authService.onWebSignIn,
          ).thenAnswer((_) => webSignIns.stream);
          when(
            harness.authService.ensureInitialized(),
          ).thenAnswer((_) async {});
          harness.controller.start();
          await pumpEventQueue();
          expect(webSignIns.hasListener, isTrue);

          // 2. Act
          harness.controller.dispose();

          // 3. Assert
          expect(webSignIns.hasListener, isFalse);
          verify(harness.authService.dispose()).called(1);
          await webSignIns.close();
        },
      );

      test(
        'Edge Case: dispose without start never touches the Google service',
        () {
          // 1. Arrange
          final harness = _HarnessSignIn();

          // 2. Act
          harness.controller.dispose();

          // 3. Assert
          verifyZeroInteractions(harness.authService);
        },
      );

      test(
        'Sad Path: an initialization finishing after dispose does not notify',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          final init = Completer<void>();
          when(
            harness.authService.ensureInitialized(),
          ).thenAnswer((_) => init.future);
          harness.controller.start();
          harness.controller.dispose();

          // 2. Act
          init.complete();
          await pumpEventQueue();

          // 3. Assert
          // A ChangeNotifier notified after dispose throws; reaching here
          // without an error is the check.
          expect(harness.controller.state.googleReady, isTrue);
        },
      );
    });

    group('AuthGoogleViewModel notifications - Unit Test Suite', () {
      test('Happy Path: a state change notifies the listeners once', () {
        // 1. Arrange
        final harness = _HarnessSignIn();
        var notifications = 0;
        harness.controller.addListener(() => notifications++);

        // 2. Act
        harness.controller.finishWelcome();

        // 3. Assert
        expect(notifications, 1);
      });

      test('Edge Case: an ownership already read does not notify', () async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: const [
            OrganizationCandidate(
              id: 'rotasul',
              options: _kOptions,
              owner: true,
            ),
          ],
        );
        await harness.controller.loadOwnership('rotasul');
        var notifications = 0;
        harness.controller.addListener(() => notifications++);

        // 2. Act
        await harness.controller.loadOwnership('rotasul');

        // 3. Assert
        expect(notifications, 0);
      });

      test(
        'Sad Path: a failed ownership read changes nothing and does not notify',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: StateError('offline'));
          var notifications = 0;
          harness.controller.addListener(() => notifications++);

          // 2. Act
          await harness.controller.loadOwnership('rotasul');

          // 3. Assert
          expect(notifications, 0);
          expect(harness.controller.state, const AuthGoogleState());
        },
      );
    });
  });

  group('session notifications', () {
    group('AuthGoogleViewModel.session - Unit Test Suite', () {
      test('Happy Path: a new session notifies the session listeners once', () {
        // 1. Arrange
        final harness = _HarnessSignIn();
        var notifications = 0;
        harness.controller.session.addListener(() => notifications++);

        // 2. Act
        harness.controller.sessionRestored();

        // 3. Assert
        expect(notifications, 1);
        expect(harness.controller.session.value, const SessionState.bound());
      });

      test('Edge Case: the same session again does not notify', () {
        // 1. Arrange
        final harness = _HarnessSignIn();
        harness.controller.sessionRestored();
        var notifications = 0;
        harness.controller.session.addListener(() => notifications++);

        // 2. Act
        harness.controller.sessionRestored();

        // 3. Assert
        expect(notifications, 0);
      });

      test('Edge Case: a state change that keeps the session notifies the '
          'controller but not the session', () async {
        // 1. Arrange
        final harness = _HarnessSignIn(
          organizations: const [
            OrganizationCandidate(
              id: 'rotasul',
              options: _kOptions,
              owner: true,
            ),
          ],
        );
        var stateNotifications = 0;
        var sessionNotifications = 0;
        harness.controller.addListener(() => stateNotifications++);
        harness.controller.session.addListener(() => sessionNotifications++);

        // 2. Act
        await harness.controller.loadOwnership('rotasul');

        // 3. Assert
        expect(stateNotifications, greaterThan(0));
        expect(sessionNotifications, 0);
        expect(
          harness.controller.session.value,
          const SessionState.signedOut(),
        );
      });

      test(
        'Sad Path: a failed sign-out keeps the session and does not notify it',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(logoutError: StateError('offline'));
          harness.controller.sessionRestored();
          var notifications = 0;
          harness.controller.session.addListener(() => notifications++);

          // 2. Act
          final result = await harness.controller.logout();

          // 3. Assert
          expect(result, isA<Err<bool>>());
          expect(notifications, 0);
          expect(harness.controller.session.value, const SessionState.bound());
        },
      );
    });
  });
}
