import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/organization/organization.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/organization_firebase.dart';
import 'package:monamie_app/app/data/groups/organization_membership_check.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';
import 'package:monamie_app/app/data/organization/organization_binding_store.dart';
import 'package:monamie_app/app/data/organization/organization_branding_loader.dart';
import 'package:monamie_app/app/data/organization/organization_directory.dart';
import 'package:monamie_app/app/data/organization/organization_local_data.dart';
import 'package:monamie_app/app/data/organization/organization_session.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';
import 'package:monamie_app/app/modules/invites/invite.dart';
import 'package:monamie_app/app/modules/invites/invites_backend.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import '../../../../support/test_organization.dart';

const String _kHomeRoute = '/home-test';

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
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuthGoogleServiceSignIn implements AuthGoogleService {
  _FakeAuthGoogleServiceSignIn(
    this.log, {
    this.idToken = _kIdToken,
    this.refreshedToken = _kIdToken,
    this.signInError,
    this.logoutError,
    this.chooser,
  });

  final List<String> log;
  final String? idToken;
  final String? refreshedToken;
  final Object? signInError;
  final Object? logoutError;

  /// Holds the fake at Google's account chooser until the test completes it
  /// (with an error to mimic a cancelled chooser). Null: the choice is instant.
  final Completer<void>? chooser;

  int signInCalls = 0;
  int logoutCalls = 0;
  int signOutOfOrganizationCalls = 0;

  @override
  Future<String?> signInGoogle({void Function()? onAccountChosen}) async {
    signInCalls++;
    log.add('signInGoogle');
    await chooser?.future;
    onAccountChosen?.call();
    final failure = signInError;
    if (failure != null) throw failure;
    return idToken;
  }

  @override
  Future<String?> refreshGoogleIdToken() async {
    log.add('refreshGoogleIdToken');
    return refreshedToken;
  }

  @override
  Future<String?> centralEmail() async => _kCentralEmail;

  @override
  Future<void> signInToOrganization(String idToken) async {
    log.add('signInToOrganization');
  }

  @override
  Future<void> signOutOfOrganization() async {
    signOutOfOrganizationCalls++;
    log.add('signOutOfOrganization');
  }

  @override
  Future<void> logoutGoogle() async {
    logoutCalls++;
    log.add('logoutGoogle');
    final failure = logoutError;
    if (failure != null) throw failure;
  }

  @override
  Future<UserGoogleModel?> saveOrganizationProfile() async =>
      UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kCentralEmail);

  @override
  Stream<String?> get onWebSignIn => const Stream<String?>.empty();

  @override
  Future<void> ensureInitialized() async {}

  @override
  void dispose() {}
}

class _FakeOrganizationDirectory implements OrganizationDirectory {
  _FakeOrganizationDirectory({
    this.organizations = const [],
    this.error,
    this.log,
  });

  final List<OrganizationCandidate> organizations;
  final Object? error;
  final List<String>? log;
  int calls = 0;

  @override
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser() async {
    calls++;
    log?.add('directory');
    final failure = error;
    if (failure != null) throw failure;
    return organizations;
  }
}

class _FakeBrandingLoaderSignIn implements OrganizationBrandingLoader {
  @override
  Future<OrganizationBinding> load(OrganizationCandidate candidate) async =>
      OrganizationBinding(
        organization: OrganizationConfig(id: candidate.id, name: _kRotaSulName),
        options: candidate.options,
      );

  @override
  Future<OrganizationConfig> readBranding(OrganizationBinding binding) =>
      throw UnimplementedError('readBranding is not used by the sign-in');
}

class _MemoryBindingStore implements OrganizationBindingStore {
  OrganizationBinding? binding;

  @override
  Future<OrganizationBinding?> read() async => binding;

  @override
  Future<void> write(OrganizationBinding value) async => binding = value;

  @override
  Future<void> clear() async => binding = null;
}

/// [OrganizationSession] that binds without creating a real [FirebaseApp]: it
/// sets [Organization.current] and a fake [OrganizationFirebase].
class _FakeOrganizationSessionSignIn extends OrganizationSession {
  _FakeOrganizationSessionSignIn(this.log)
    : super(store: _MemoryBindingStore());

  final List<String> log;
  int forgetCalls = 0;

  @override
  Future<void> bind(OrganizationBinding binding, {bool remember = true}) async {
    log.add('bind');
    Organization.bind(binding.organization);
    CurrentOrganizationFirebase.set(_FakeOrganizationFirebase());
  }

  @override
  Future<void> forget() async {
    forgetCalls++;
    log.add('forget');
    await super.forget();
  }
}

class _FakeOrganizationFirebase implements OrganizationFirebase {
  @override
  FirebaseAuth get auth => throw UnimplementedError();

  @override
  FirebaseFunctions get functions => throw UnimplementedError();

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  FirebaseStorage get storage => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get organizationData =>
      throw UnimplementedError();
}

/// Answers [member] for every organization: `true` belongs, `false` was
/// removed, `null` could not be read.
class _FakeMembershipCheck implements OrganizationMembershipCheck {
  _FakeMembershipCheck(this.member);

  final bool? member;

  @override
  Future<bool?> isMemberOf(String organizationId) async => member;
}

class _FakeTrackingStopperSignIn implements BackgroundTrackingStopper {
  _FakeTrackingStopperSignIn(this.log);

  final List<String> log;

  @override
  Future<bool> stop({String? email}) async {
    log.add('stop');
    return true;
  }
}

class _FakeOrganizationLocalData implements OrganizationLocalData {
  @override
  Future<void> clear() async {}
}

class _FakeUserGoogleRepositorySignIn implements UserGoogleRepository {
  @override
  Future<UserGoogleModel?> getUserGoogleModel() async => null;

  @override
  Future<String> deleteUserGoogleModel() async => 'ok';

  @override
  Future<String> saveUserGoogleModel(UserGoogleModel user) async => 'ok';

  @override
  Future<UserGoogleModel> saveGoogleProfile(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) => throw UnimplementedError();

  @override
  Future<String> clearAllUserGoogle() => throw UnimplementedError();

  @override
  Future<bool> hasUserGoogle() => throw UnimplementedError();
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
  }) {
    authService = _FakeAuthGoogleServiceSignIn(
      log,
      idToken: idToken,
      refreshedToken: refreshedToken,
      signInError: signInError,
      logoutError: logoutError,
      chooser: chooser,
    );
    directory = _FakeOrganizationDirectory(
      organizations: organizations,
      error: directoryError,
      log: log,
    );
    session = _FakeOrganizationSessionSignIn(log);
    membershipCheck = _FakeMembershipCheck(member);
    controller = AuthGoogleController(
      authGoogleService: authService,
      userRepository: _FakeUserGoogleRepositorySignIn(),
      trackingStopper: _FakeTrackingStopperSignIn(log),
      organizationDirectory: directory,
      brandingLoader: _FakeBrandingLoaderSignIn(),
      organizationSession: session,
      organizationLocalData: _FakeOrganizationLocalData(),
      membershipCheck: membershipCheck,
      refreshTheme: () => log.add('refreshTheme'),
    );
  }

  final List<String> log = <String>[];
  late final _FakeMembershipCheck membershipCheck;
  late final _FakeAuthGoogleServiceSignIn authService;
  late final _FakeOrganizationDirectory directory;
  late final _FakeOrganizationSessionSignIn session;
  late final AuthGoogleController controller;
}

Future<void> _pumpAppSignIn(WidgetTester tester) async {
  GetPage<dynamic> page(String name) => GetPage(
    name: name,
    page: () => Scaffold(body: Text(name)),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: _kHomeRoute,
      getPages: [
        page(_kHomeRoute),
        page(Routes.LOGIN),
        page(Routes.NO_ORGANIZATION),
        page(Routes.ORGANIZATION_PICKER),
        page(Routes.MONAMIE),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

String _snackbarTitle(GetSnackBar snackBar) {
  final titleWidget = snackBar.titleText;
  if (titleWidget is Text) return titleWidget.data ?? '';
  return snackBar.title ?? '';
}

/// Runs [act] (which may start un-awaited work such as `loginGoogle()`),
/// waits until the controller is idle, records the snackbars shown and lets
/// them close (GetX timers cannot be left pending).
Future<List<String>> _run(
  WidgetTester tester,
  AuthGoogleController controller,
  FutureOr<void> Function() act,
) async {
  await act();
  for (
    var i = 0;
    i < 50 && (controller.isLoading.value || controller.isLoggingOut.value);
    i++
  ) {
    await tester.pump();
  }
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  final titles = tester
      .widgetList<GetSnackBar>(find.byType(GetSnackBar))
      .map(_snackbarTitle)
      .toList();
  for (var i = 0; i < 30 && Get.isSnackbarOpen; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
  return titles;
}

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
// Fakes
// ---------------------------------------------------------------------------

class _FakeAuthGoogleServiceInvites implements AuthGoogleService {
  _FakeAuthGoogleServiceInvites(this.log);

  final List<String> log;
  final String? idToken = _kIdToken;
  final Object? signInError = null;
  final Object? logoutError = null;

  int signInCalls = 0;
  int logoutCalls = 0;
  int signOutOfOrganizationCalls = 0;

  @override
  Future<String?> signInGoogle({void Function()? onAccountChosen}) async {
    signInCalls++;
    log.add('signInGoogle');
    onAccountChosen?.call();
    final failure = signInError;
    if (failure != null) throw failure;
    return idToken;
  }

  @override
  Future<String?> refreshGoogleIdToken() async => null;

  @override
  Future<String?> centralEmail() async => _kCentralEmail;

  @override
  Future<void> signInToOrganization(String idToken) async {
    log.add('signInToOrganization');
  }

  @override
  Future<void> signOutOfOrganization() async {
    signOutOfOrganizationCalls++;
    log.add('signOutOfOrganization');
  }

  @override
  Future<void> logoutGoogle() async {
    logoutCalls++;
    log.add('logoutGoogle');
    final failure = logoutError;
    if (failure != null) throw failure;
  }

  @override
  Future<UserGoogleModel?> saveOrganizationProfile() async =>
      UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kCentralEmail);

  @override
  Stream<String?> get onWebSignIn => const Stream<String?>.empty();

  @override
  Future<void> ensureInitialized() async {}

  @override
  void dispose() {}
}

class _FakeBrandingLoaderInvites implements OrganizationBrandingLoader {
  @override
  Future<OrganizationBinding> load(OrganizationCandidate candidate) async =>
      OrganizationBinding(
        organization: OrganizationConfig(
          id: candidate.id,
          name: _kOrganizationNames[candidate.id] ?? candidate.id,
        ),
        options: candidate.options,
      );

  @override
  Future<OrganizationConfig> readBranding(OrganizationBinding binding) =>
      throw UnimplementedError('readBranding is not used by the sign-in');
}

/// [OrganizationSession] that binds without creating a real [FirebaseApp]: it
/// sets [Organization.current] and a fake [OrganizationFirebase].
class _FakeOrganizationSessionInvites extends OrganizationSession {
  _FakeOrganizationSessionInvites(this.log)
    : super(store: _MemoryBindingStore());

  final List<String> log;
  int forgetCalls = 0;

  /// Id of every organization bound, in order.
  final boundIds = <String>[];

  @override
  Future<void> bind(OrganizationBinding binding, {bool remember = true}) async {
    log.add('bind');
    boundIds.add(binding.organization.id);
    Organization.bind(binding.organization);
    CurrentOrganizationFirebase.set(_FakeOrganizationFirebase());
  }

  @override
  Future<void> forget() async {
    forgetCalls++;
    log.add('forget');
    await super.forget();
  }
}

/// The person still belongs to every organization entered.
class _MemberEverywhere implements OrganizationMembershipCheck {
  @override
  Future<bool?> isMemberOf(String organizationId) async => true;
}

class _FakeTrackingStopperInvites implements BackgroundTrackingStopper {
  _FakeTrackingStopperInvites(this.log);

  final List<String> log;

  @override
  Future<bool> stop({String? email}) async {
    log.add('stop');
    return true;
  }
}

class _FakeUserGoogleRepositoryInvites implements UserGoogleRepository {
  @override
  Future<UserGoogleModel?> getUserGoogleModel() async => null;

  @override
  Future<String> deleteUserGoogleModel() async => 'ok';

  @override
  Future<String> saveUserGoogleModel(UserGoogleModel user) async => 'ok';

  @override
  Future<UserGoogleModel> saveGoogleProfile(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) => throw UnimplementedError();

  @override
  Future<String> clearAllUserGoogle() => throw UnimplementedError();

  @override
  Future<bool> hasUserGoogle() => throw UnimplementedError();
}

/// [OrganizationDirectory] that answers the n-th call with `answers[n]` (the last
/// answer repeats) and counts the calls.
class _SequencedOrganizationDirectory implements OrganizationDirectory {
  _SequencedOrganizationDirectory(this.answers);

  final List<List<OrganizationCandidate>> answers;
  int calls = 0;

  @override
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser() async {
    final index = calls++;
    return answers[index < answers.length ? index : answers.length - 1];
  }
}

/// [InvitesBackend] whose `accept` records the invite, optionally waits on
/// [gate] and fails with [failure]; `mine` answers [mineResult] or fails
/// with [mineFailure].
class _FakeInvitesBackend implements InvitesBackend {
  final accepted = <String>[];
  Completer<void>? gate;
  Object? failure;
  List<Invite> mineResult = const [];
  Object? mineFailure;

  @override
  Future<Invite> accept(Invite invite) async {
    accepted.add(invite.id);
    await gate?.future;
    if (failure case final failure?) throw failure;
    return invite;
  }

  @override
  Future<List<Invite>> mine() async {
    if (mineFailure case final failure?) throw failure;
    return mineResult;
  }

  @override
  Future<InviteSendResult> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  }) => throw UnimplementedError();

  @override
  Future<List<Invite>> listForGroup(String organizationId, String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> resend(String organizationId, String inviteId) =>
      throw UnimplementedError();

  @override
  Future<void> cancel(String organizationId, String inviteId) =>
      throw UnimplementedError();
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
    directory = _SequencedOrganizationDirectory(answers);
    session = _FakeOrganizationSessionInvites(log);
    controller = AuthGoogleController(
      authGoogleService: _FakeAuthGoogleServiceInvites(log),
      userRepository: _FakeUserGoogleRepositoryInvites(),
      trackingStopper: _FakeTrackingStopperInvites(log),
      organizationDirectory: directory,
      brandingLoader: _FakeBrandingLoaderInvites(),
      organizationSession: session,
      organizationLocalData: _FakeOrganizationLocalData(),
      invitesBackend: backend,
      membershipCheck: _MemberEverywhere(),
      refreshTheme: () => log.add('refreshTheme'),
    );
  }

  final List<String> log = <String>[];
  final backend = _FakeInvitesBackend();
  late final _SequencedOrganizationDirectory directory;
  late final _FakeOrganizationSessionInvites session;
  late final AuthGoogleController controller;
}

Future<void> _pumpAppInvites(WidgetTester tester) async {
  GetPage<dynamic> page(String name) => GetPage(
    name: name,
    page: () => Scaffold(body: Text(name)),
  );
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: _kHomeRoute,
      getPages: [
        page(_kHomeRoute),
        page(Routes.NO_ORGANIZATION),
        page(Routes.ORGANIZATION_PICKER),
        page(Routes.MONAMIE),
        page(Routes.WELCOME),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// Starts accepting [_kInvite] and advances the fake clock until it is over.
Future<void> _accept(WidgetTester tester, AuthGoogleController controller) =>
    _drive(tester, controller, () => controller.acceptInvite(_kInvite));

/// Starts [act] and advances the fake clock one second at a time (the
/// snackbars wait on timers) until the controller is no longer busy.
Future<void> _drive(
  WidgetTester tester,
  AuthGoogleController controller,
  Future<void> Function() act,
) async {
  final done = act();
  for (
    var i = 0;
    i < 60 &&
        (controller.acceptingInvite.value != null ||
            controller.isLoading.value);
    i++
  ) {
    await tester.pump(const Duration(seconds: 1));
  }
  await done;
  // Let any snackbar (the central functions are unavailable in tests) close:
  // GetX timers cannot be left pending.
  for (var i = 0; i < 30 && Get.isSnackbarOpen; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

/// [OrganizationDirectory] that counts its reads, returns [organizations],
/// optionally waits on [gate] and fails with [failure].
class FakeOrganizationDirectory implements OrganizationDirectory {
  int reads = 0;
  List<OrganizationCandidate> organizations = const [
    OrganizationCandidate(id: 'rotasul', options: _kOptions, owner: true),
    OrganizationCandidate(id: 'verdemar', options: _kOptions),
  ];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser() async {
    reads++;
    await gate?.future;
    if (failure case final failure?) throw failure;
    return organizations;
  }
}

late FakeOrganizationDirectory directory;

/// Built without `Get.put`, so the real `onInit` (Google Sign-In) never runs.
AuthGoogleController newController() =>
    AuthGoogleController(organizationDirectory: directory, refreshTheme: () {});

const String _kHomePlaceholder = 'home-placeholder';

const String _kLoginPlaceholder = 'login-placeholder';

const String _kStoredEmail = 'ana.souza@monamie.net';

// Entradas do registro compartilhado de chamadas, usado para verificar a
// ordem das operações do logout.
const String _kLogStop = 'stop';

const String _kLogSignOut = 'logoutGoogle';

const String _kLogDeleteUser = 'deleteUserGoogleModel';

const String _kLogNavigateLogin = 'push:${Routes.LOGIN}';

/// Fake do contrato de parada do rastreamento.
class _FakeTrackingStopperLogout implements BackgroundTrackingStopper {
  _FakeTrackingStopperLogout(this.log, {this.result = true, this.pending});

  final List<String> log;
  final bool result;

  /// Quando informado, `stop` só conclui quando este completer completar.
  final Completer<bool>? pending;

  final List<String?> emails = <String?>[];

  int get calls => emails.length;

  @override
  Future<bool> stop({String? email}) {
    emails.add(email);
    log.add(_kLogStop);
    final waiting = pending;
    if (waiting != null) return waiting.future;
    return Future<bool>.value(result);
  }
}

/// Fake do AuthGoogleService. Usa `implements` para não executar o construtor
/// real (que acessa GoogleSignIn e Firebase).
class _FakeAuthGoogleServiceLogout implements AuthGoogleService {
  _FakeAuthGoogleServiceLogout(this.log, {this.logoutError});

  final List<String> log;
  final Object? logoutError;
  int logoutCalls = 0;

  @override
  Future<void> logoutGoogle() async {
    logoutCalls++;
    log.add(_kLogSignOut);
    final failure = logoutError;
    if (failure != null) throw failure;
  }

  @override
  Stream<String?> get onWebSignIn => const Stream<String?>.empty();

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<String?> signInGoogle({void Function()? onAccountChosen}) async {
    onAccountChosen?.call();
    return null;
  }

  @override
  Future<void> signInToOrganization(String idToken) async {}

  @override
  Future<UserGoogleModel?> saveOrganizationProfile() async => null;

  @override
  Future<String?> refreshGoogleIdToken() async => null;

  @override
  Future<String?> centralEmail() async => null;

  @override
  Future<void> signOutOfOrganization() async {}

  @override
  void dispose() {}
}

/// Fake do UserGoogleRepository. Usa `implements` para não instanciar os
/// providers reais (Hive/Firebase).
class _FakeUserGoogleRepositoryLogout implements UserGoogleRepository {
  _FakeUserGoogleRepositoryLogout(
    this.log, {
    this.storedUser,
    this.getUserError,
    this.deleteError,
  });

  final List<String> log;
  final UserGoogleModel? storedUser;
  final Object? getUserError;
  final Object? deleteError;
  int deleteCalls = 0;

  @override
  Future<UserGoogleModel?> getUserGoogleModel() async {
    final failure = getUserError;
    if (failure != null) throw failure;
    return storedUser;
  }

  @override
  Future<String> deleteUserGoogleModel() async {
    deleteCalls++;
    log.add(_kLogDeleteUser);
    final failure = deleteError;
    if (failure != null) throw failure;
    return 'ok';
  }

  @override
  Future<UserGoogleModel> saveGoogleProfile(
    String email,
    String name,
    String uid,
    String urlImage, {
    String? avatarBase64,
  }) => throw UnimplementedError('saveGoogleProfile não é usado no logout');

  @override
  Future<String> saveUserGoogleModel(UserGoogleModel user) =>
      throw UnimplementedError('saveUserGoogleModel não é usado no logout');

  @override
  Future<String> clearAllUserGoogle() =>
      throw UnimplementedError('clearAllUserGoogle não é usado no logout');

  @override
  Future<bool> hasUserGoogle() =>
      throw UnimplementedError('hasUserGoogle não é usado no logout');
}

/// Registra no log compartilhado as rotas empilhadas pelo Navigator.
class _LoggingNavigatorObserver extends NavigatorObserver {
  _LoggingNavigatorObserver(this.log);

  final List<String> log;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.add('push:${route.settings.name}');
  }
}

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
    stopper = _FakeTrackingStopperLogout(
      log,
      result: stopResult,
      pending: pendingStop,
    );
    authService = _FakeAuthGoogleServiceLogout(log, logoutError: logoutError);
    userRepository = _FakeUserGoogleRepositoryLogout(
      log,
      storedUser: storedUser,
      getUserError: getUserError,
      deleteError: deleteError,
    );
    // O controller é construído sem `Get.put`, de modo que o `onInit` real
    // (que acessa o Google Sign-In) nunca é executado.
    controller = AuthGoogleController(
      organizationSession: OrganizationSession(store: _MemoryBindingStore()),
      organizationLocalData: _FakeOrganizationLocalData(),
      refreshTheme: () {},
      authGoogleService: authService,
      userRepository: userRepository,
      trackingStopper: stopper,
    );
  }

  final List<String> log = <String>[];
  late final _FakeTrackingStopperLogout stopper;
  late final _FakeAuthGoogleServiceLogout authService;
  late final _FakeUserGoogleRepositoryLogout userRepository;
  late final AuthGoogleController controller;
}

/// Resultado observável de uma execução completa de `logout()`.
class _LogoutRun {
  _LogoutRun({required this.error, required this.snackbarTitles});

  /// Exceção que escapou de `logout()`, se houver.
  final Object? error;

  /// Títulos dos snackbars exibidos durante o logout.
  final List<String> snackbarTitles;
}

UserGoogleModel _storedUser() =>
    UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kStoredEmail);

/// Monta o app com a rota inicial fictícia e um stub de `Routes.LOGIN`, e
/// limpa do log os pushes feitos durante a montagem.
Future<void> _pumpAppLogout(WidgetTester tester, _HarnessLogout harness) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: _kHomeRoute,
      navigatorObservers: [_LoggingNavigatorObserver(harness.log)],
      getPages: [
        GetPage(
          name: _kHomeRoute,
          page: () => const Scaffold(body: Text(_kHomePlaceholder)),
        ),
        GetPage(
          name: Routes.LOGIN,
          page: () => const Scaffold(body: Text(_kLoginPlaceholder)),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  harness.log.clear();
}

/// Executa `logout()` até o fim: captura uma eventual exceção, registra os
/// snackbars exibidos e deixa todos eles fecharem (os timers de 5 s do
/// GetX não podem ficar pendentes ao final do teste).
Future<_LogoutRun> _runLogout(
  WidgetTester tester,
  AuthGoogleController controller,
) async {
  Object? error;
  try {
    await controller.logout();
  } catch (e) {
    error = e;
  }

  // Exibe o snackbar (se houver) e conclui a animação de entrada.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  final titles = tester
      .widgetList<GetSnackBar>(find.byType(GetSnackBar))
      .map(_snackbarTitle)
      .toList();

  // Aguarda o fechamento de todos os snackbars enfileirados.
  for (var i = 0; i < 30 && Get.isSnackbarOpen; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();

  return _LogoutRun(error: error, snackbarTitles: titles);
}

void main() {
  group('sign in', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
      Organization.bind(testOrganization);
      CurrentOrganizationFirebase.debugReset();
    });

    group(
      'AuthGoogleController.loginGoogle (seletor de contas do Google) - Suíte de Testes Unitários',
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
            final worker = ever<bool>(controller.isLoading, loadingHistory.add);
            controller.loginGoogle();
            await tester.pump();
            final loadingWhileChooserOpen = controller.isLoading.value;
            final guardedWhileChooserOpen = controller.isChoosingAccount.value;
            final historyWhileChooserOpen = List<bool>.of(loadingHistory);

            // 2. Act
            chooser.complete();
            await _run(tester, controller, () {});
            worker.dispose();

            // 3. Assert
            expect(loadingWhileChooserOpen, isFalse);
            expect(guardedWhileChooserOpen, isTrue);
            expect(historyWhileChooserOpen, isEmpty);
            expect(loadingHistory, [true, false]);
            expect(controller.isChoosingAccount.value, isFalse);
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
            expect(harness.authService.signInCalls, 1);

            // Cleanup: finishes the pending sign-in so no timers stay open.
            chooser.complete();
            await _run(tester, harness.controller, () {});
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
            final worker = ever<bool>(
              controller.isLoading,
              (value) => loadingEverTrue = loadingEverTrue || value,
            );
            controller.loginGoogle();
            await tester.pump();

            // 2. Act
            chooser.completeError(Exception('cancelled'));
            await _run(tester, controller, () {});
            worker.dispose();

            // 3. Assert
            expect(loadingEverTrue, isFalse);
            expect(controller.isLoading.value, isFalse);
            expect(controller.isChoosingAccount.value, isFalse);
            expect(harness.authService.signInCalls, 1);
          },
        );
      },
    );

    group(
      'AuthGoogleController.loginGoogle (sem organização) - Suíte de Testes Unitários',
      () {
        testWidgets(
          'Happy Path: Deve navegar para Routes.NO_ORGANIZATION quando o usuário não tiver organização',
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
            expect(Get.currentRoute, Routes.NO_ORGANIZATION);
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
            expect(harness.controller.signedInEmail.value, _kCentralEmail);
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
            expect(harness.authService.logoutCalls, 0);
          },
        );

        testWidgets(
          'Sad Path: Deve exibir erro de login e voltar isLoading a false quando a busca de organizações lançar',
          (WidgetTester tester) async {
            // 1. Arrange
            final harness = _HarnessSignIn(
              directoryError: Exception('sem rede'),
            );
            await _pumpAppSignIn(tester);

            // 2. Act
            final titles = await _run(
              tester,
              harness.controller,
              harness.controller.loginGoogle,
            );

            // 3. Assert
            expect(titles, [_kLoginErrorTitle]);
            expect(harness.controller.isLoading.value, isFalse);
          },
        );
      },
    );

    group(
      'AuthGoogleController.loginGoogle (seletor de organizações) - Suíte de Testes Unitários',
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
            expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
            expect(
              harness.controller.organizationChoices.map(
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
            expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
            expect(
              harness.controller.organizationChoices.map(
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
            expect(harness.session.forgetCalls, 0);
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
            expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
            expect(
              harness.controller.organizationChoices.map(
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
            expect(Get.currentRoute, _kHomeRoute);
            expect(harness.controller.organizationChoices, isEmpty);
            expect(harness.directory.calls, 0);
          },
        );
      },
    );

    group(
      'AuthGoogleController.chooseOrganization (organização sem acesso) - Suíte de Testes Unitários',
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
                harness.controller.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(
              harness.controller.noAccessReason.value,
              'Sua conta não tem mais acesso à Rota Sul.',
            );
          },
        );

        testWidgets(
          'Happy Path: Deve navegar para Routes.NO_ORGANIZATION quando a pessoa não tiver mais matrícula',
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
                harness.controller.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(Get.currentRoute, Routes.NO_ORGANIZATION);
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
                harness.controller.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(harness.session.forgetCalls, greaterThanOrEqualTo(1));
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
                harness.controller.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(harness.authService.signOutOfOrganizationCalls, 1);
          },
        );

        testWidgets(
          'Edge Case: Não deve exibir snackbar de erro de login quando a pessoa não tiver mais matrícula',
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
            final titles = await _run(
              tester,
              harness.controller,
              () => harness.controller.chooseOrganization(
                harness.controller.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(titles, isNot(contains(_kLoginErrorTitle)));
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
                harness.controller.organizationChoices.single,
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
                harness.controller.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(harness.controller.noAccessReason.value, isNull);
            expect(Get.currentRoute, isNot(Routes.NO_ORGANIZATION));
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
                harness.controller.organizationChoices.single,
              ),
            );

            // 3. Assert
            expect(harness.controller.noAccessReason.value, isNull);
            expect(harness.authService.signOutOfOrganizationCalls, 0);
          },
        );
      },
    );

    group('AuthGoogleController.recheckOrganizations - Suíte de Testes Unitários', () {
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
          expect(harness.authService.signInCalls, 1);
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
          expect(harness.directory.calls, 2);
        },
      );

      testWidgets('Happy Path: Deve limpar noAccessReason', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessSignIn();
        await _pumpAppSignIn(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);
        harness.controller.noAccessReason.value =
            'Sua conta não tem mais acesso à Rota Sul.';

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.recheckOrganizations,
        );

        // 3. Assert
        expect(harness.controller.noAccessReason.value, isNull);
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
          expect(harness.authService.signInCalls, 1);
        },
      );

      test(
        'Edge Case: Não deve fazer nada quando chamado com isLoading true (reentrância)',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          harness.controller.isLoading.value = true;

          // 2. Act
          await harness.controller.recheckOrganizations();

          // 3. Assert
          expect(harness.authService.signInCalls, 0);
          expect(harness.directory.calls, 0);
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
          expect(harness.controller.isLoading.value, isFalse);
        },
      );
    });

    group(
      'AuthGoogleController.forgetRemovedOrganization - Suíte de Testes Unitários',
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
              harness.controller.noAccessReason.value,
              'Você não faz mais parte da Rota Sul.',
            );
          },
        );

        testWidgets(
          'Happy Path: Deve navegar para Routes.NO_ORGANIZATION em vez de Routes.LOGIN',
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
            expect(Get.currentRoute, Routes.NO_ORGANIZATION);
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
              harness.controller.noAccessReason.value,
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
            expect(Get.currentRoute, _kHomeRoute);
          },
        );
      },
    );

    group('AuthGoogleController.switchOrganization - Suíte de Testes Unitários', () {
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
          expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
          expect(
            harness.controller.organizationChoices.map(
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
          expect(harness.directory.calls, 1);
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
          expect(harness.authService.logoutCalls, 0);
          expect(harness.authService.signInCalls, 0);
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
          expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
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
        'Edge Case: Deve navegar para Routes.NO_ORGANIZATION quando a pessoa não tiver organização',
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
          expect(Get.currentRoute, Routes.NO_ORGANIZATION);
          expect(harness.controller.organizationChoices, isEmpty);
          expect(harness.authService.logoutCalls, 0);
        },
      );

      test(
        'Edge Case: Não deve fazer nada quando chamado com isLoggingOut true (reentrância)',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          harness.controller.isLoggingOut.value = true;

          // 2. Act
          await harness.controller.switchOrganization();

          // 3. Assert
          expect(harness.log, isEmpty);
          expect(harness.directory.calls, 0);
        },
      );

      test(
        'Edge Case: Não deve fazer nada quando chamado com isLoading true (reentrância)',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          harness.controller.isLoading.value = true;

          // 2. Act
          await harness.controller.switchOrganization();

          // 3. Assert
          expect(harness.log, isEmpty);
          expect(harness.directory.calls, 0);
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
          expect(harness.directory.calls, 0);
          expect(harness.authService.logoutCalls, 0);
          expect(harness.authService.signInCalls, 0);
          expect(Get.currentRoute, _kHomeRoute);
        },
      );

      testWidgets(
        'Sad Path: Deve exibir snackbar quando não houver token válido nem renovação',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(
            organizations: [_kRotaSul],
            refreshedToken: null,
          );
          await _pumpAppSignIn(tester);

          // 2. Act
          final titles = await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(titles, ['Trocar de organização']);
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
          expect(harness.controller.isLoggingOut.value, isFalse);
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
          expect(Get.currentRoute, _kHomeRoute);
        },
      );

      testWidgets(
        'Sad Path: Deve exibir snackbar de erro quando a busca de organizações lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('sem rede'));
          await _pumpAppSignIn(tester);

          // 2. Act
          final titles = await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          expect(titles, ['Trocar de organização']);
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
          expect(harness.controller.isLoggingOut.value, isFalse);
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
          final sub = harness.controller.isSwitchingOrganization.listen(
            seen.add,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          await sub.cancel();
          expect(seen, [true, false]);
          expect(harness.controller.isSwitchingOrganization.value, isFalse);
        },
      );

      testWidgets(
        'Sad Path: Deve emitir isSwitchingOrganization true e depois false quando a busca de organizações lançar',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn(directoryError: Exception('sem rede'));
          await _pumpAppSignIn(tester);
          final seen = <bool>[];
          final sub = harness.controller.isSwitchingOrganization.listen(
            seen.add,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          await sub.cancel();
          expect(seen, [true, false]);
          expect(harness.controller.isSwitchingOrganization.value, isFalse);
        },
      );

      testWidgets(
        'Edge Case: Não deve marcar isSwitchingOrganization durante um logout comum',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessSignIn();
          await _pumpAppSignIn(tester);
          final seen = <bool>[];
          final sub = harness.controller.isSwitchingOrganization.listen(
            seen.add,
          );

          // 2. Act
          await _run(tester, harness.controller, harness.controller.logout);

          // 3. Assert
          await sub.cancel();
          expect(seen, isEmpty);
          expect(harness.controller.isSwitchingOrganization.value, isFalse);
        },
      );

      test(
        'Edge Case: Não deve marcar isSwitchingOrganization quando chamado com isLoggingOut true (reentrância)',
        () async {
          // 1. Arrange
          final harness = _HarnessSignIn(organizations: [_kRotaSul]);
          harness.controller.isLoggingOut.value = true;
          final seen = <bool>[];
          final sub = harness.controller.isSwitchingOrganization.listen(
            seen.add,
          );

          // 2. Act
          await harness.controller.switchOrganization();

          // 3. Assert
          await sub.cancel();
          expect(seen, isEmpty);
          expect(harness.controller.isSwitchingOrganization.value, isFalse);
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
          final sub = harness.controller.isSwitchingOrganization.listen(
            seen.add,
          );

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.switchOrganization,
          );

          // 3. Assert
          await sub.cancel();
          expect(seen, isEmpty);
          expect(harness.controller.isSwitchingOrganization.value, isFalse);
        },
      );
    });

    group('AuthGoogleController.ownsOrganization - Suíte de Testes Unitários', () {
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
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
      Organization.bind(testOrganization);
      CurrentOrganizationFirebase.debugReset();
    });

    group('AuthGoogleController.acceptInvite - Unit Test Suite', () {
      testWidgets('Happy Path: accepts the invite through the backend', (
        WidgetTester tester,
      ) async {
        // 1. Arrange
        final harness = _HarnessInvites();
        await _pumpAppInvites(tester);

        // 2. Act
        await _accept(tester, harness.controller);

        // 3. Assert
        expect(harness.backend.accepted, ['inv1']);
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
        expect(harness.controller.welcome.value, same(_kInvite));
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
          expect(harness.directory.calls, 1);
          expect(
            harness.log,
            containsAllInOrder(['bind', 'signInToOrganization']),
          );
          expect(harness.controller.acceptingInvite.value, isNull);
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
          expect(harness.directory.calls, 1);
          expect(harness.log, isNot(contains('bind')));
          expect(Get.currentRoute, Routes.NO_ORGANIZATION);
        },
      );

      test(
        'Edge Case: a second accept while one is in flight does nothing',
        () async {
          // 1. Arrange
          final harness = _HarnessInvites();
          harness.backend.gate = Completer<void>();
          unawaited(harness.controller.acceptInvite(_kInvite));

          // 2. Act
          await harness.controller.acceptInvite(_kInvite);

          // 3. Assert
          expect(harness.backend.accepted, ['inv1']);
          expect(harness.controller.acceptingInvite.value, 'inv1');
        },
      );

      test(
        'Sad Path: an InvitesException sets inviteError and clears acceptingInvite',
        () async {
          // 1. Arrange
          final harness = _HarnessInvites();
          harness.backend.failure = const InvitesException(
            'Este convite expirou. Peça um novo a quem convidou você.',
          );

          // 2. Act
          await harness.controller.acceptInvite(_kInvite);

          // 3. Assert
          expect(
            harness.controller.inviteError.value,
            'Este convite expirou. Peça um novo a quem convidou você.',
          );
          expect(harness.controller.acceptingInvite.value, isNull);
          expect(harness.directory.calls, 0);
        },
      );
    });

    group('AuthGoogleController pending invites on the picker - Unit Test Suite', () {
      testWidgets(
        'Happy Path: recheckOrganizations with one organization loads the pending invites',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites();
          harness.backend.mineResult = [_kInvite];
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          expect(harness.controller.pendingInvites, [_kInvite]);
          expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
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
          harness.backend.mineResult = [_kInvite, _kOtherInvite];
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          expect(harness.controller.pendingInvites, [_kInvite, _kOtherInvite]);
          expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
          expect(harness.log, isNot(contains('bind')));
        },
      );

      testWidgets(
        'Sad Path: a failing invite read leaves pendingInvites empty and still opens the picker',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessInvites();
          harness.controller.pendingInvites.add(_kOtherInvite);
          harness.backend.mineFailure = Exception('sem rede');
          await _pumpAppInvites(tester);

          // 2. Act
          await _drive(
            tester,
            harness.controller,
            harness.controller.recheckOrganizations,
          );

          // 3. Assert
          expect(harness.controller.pendingInvites, isEmpty);
          expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
        },
      );
    });

    group(
      'AuthGoogleController.acceptInvite (several organizations) - Unit Test Suite',
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
            expect(harness.session.boundIds, ['rotasul']);
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
          expect(Get.currentRoute, Routes.WELCOME);
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
            expect(harness.directory.calls, 1);
            expect(harness.session.boundIds, isEmpty);
            expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
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
            expect(harness.session.boundIds, isEmpty);
            expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
          },
        );
      },
    );

    group('AuthGoogleController.enterCreatedOrganization - Unit Test Suite', () {
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
          expect(harness.session.boundIds, ['verdemar']);
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
        expect(Get.currentRoute, Routes.MONAMIE);
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
          expect(harness.directory.calls, 1);
          expect(harness.session.boundIds, isEmpty);
          expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
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
          expect(harness.session.boundIds, isEmpty);
          expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
        },
      );
    });
  });

  group('ownership', () {
    setUp(() {
      Get.testMode = true;
      directory = FakeOrganizationDirectory();
    });

    group('AuthGoogleController.loadOwnership - Unit Test Suite', () {
      test(
        'Happy Path: the owner of the organization is recorded as such',
        () async {
          // 1. Arrange
          final controller = newController();

          // 2. Act
          await controller.loadOwnership('rotasul');

          // 3. Assert
          expect(controller.ownership, {'rotasul': true});
        },
      );

      test('Happy Path: a member who does not own it is recorded as not the '
          'owner', () async {
        // 1. Arrange
        final controller = newController();

        // 2. Act
        await controller.loadOwnership('verdemar');

        // 3. Assert
        expect(controller.ownership, {'verdemar': false});
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
          expect(directory.reads, 1);
        },
      );

      test('Edge Case: another organization is read on its own', () async {
        // 1. Arrange
        final controller = newController();
        await controller.loadOwnership('rotasul');

        // 2. Act
        await controller.loadOwnership('verdemar');

        // 3. Assert
        expect(directory.reads, 2);
        expect(controller.ownership, {'rotasul': true, 'verdemar': false});
      });

      test('Edge Case: a call while one is reading reads nothing', () async {
        // 1. Arrange
        final controller = newController();
        directory.gate = Completer<void>();
        final first = controller.loadOwnership('rotasul');

        // 2. Act
        await controller.loadOwnership('rotasul');

        // 3. Assert
        expect(directory.reads, 1);
        directory.gate!.complete();
        await first;
      });

      test(
        'Sad Path: a failed read leaves the ownership unknown (hidden)',
        () async {
          // 1. Arrange
          final controller = newController();
          directory.failure = StateError('offline');

          // 2. Act
          await controller.loadOwnership('rotasul');

          // 3. Assert
          expect(controller.ownership.containsKey('rotasul'), isFalse);
        },
      );

      test('Sad Path: after a failed read the next call tries again', () async {
        // 1. Arrange
        final controller = newController();
        directory.failure = StateError('offline');
        await controller.loadOwnership('rotasul');
        directory.failure = null;

        // 2. Act
        await controller.loadOwnership('rotasul');

        // 3. Assert
        expect(directory.reads, 2);
        expect(controller.ownership, {'rotasul': true});
      });
    });
  });

  group('logout', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    group('AuthGoogleController.logout - Suíte de Testes Unitários', () {
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
          expect(harness.stopper.emails, [_kStoredEmail]);
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
        'Happy Path: Deve navegar para Routes.LOGIN ao concluir o logout',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(Get.currentRoute, Routes.LOGIN);
          expect(find.text(_kLoginPlaceholder), findsOneWidget);
          expect(find.text(_kHomePlaceholder), findsNothing);
        },
      );

      testWidgets(
        'Happy Path: Deve concluir sem exceção e sem snackbar quando o rastreamento parar normalmente',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);

          // 2. Act
          final run = await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(run.error, isNull);
          expect(run.snackbarTitles, isEmpty);
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
          expect(harness.controller.isLoggingOut.value, isFalse);
        },
      );

      testWidgets(
        'Happy Path: Deve limpar signedInEmail ao concluir o logout',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);
          harness.controller.signedInEmail.value = _kStoredEmail;

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.controller.signedInEmail.value, isNull);
        },
      );

      testWidgets(
        'Happy Path: Deve esquecer a titularidade lida ao concluir o logout',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(storedUser: _storedUser());
          await _pumpAppLogout(tester, harness);
          harness.controller.ownership['rotasul'] = true;

          // 2. Act
          await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(harness.controller.ownership, isEmpty);
        },
      );

      // ---------------------------------------------------------------------
      // Edge Case
      // ---------------------------------------------------------------------
      test('Edge Case: Deve iniciar com isLoggingOut false', () {
        // 1. Arrange
        final log = <String>[];

        // 2. Act
        final controller = AuthGoogleController(
          organizationSession: OrganizationSession(
            store: _MemoryBindingStore(),
          ),
          organizationLocalData: _FakeOrganizationLocalData(),
          refreshTheme: () {},
          authGoogleService: _FakeAuthGoogleServiceLogout(log),
          userRepository: _FakeUserGoogleRepositoryLogout(log),
          trackingStopper: _FakeTrackingStopperLogout(log),
        );

        // 3. Assert
        expect(controller.isLoggingOut.value, isFalse);
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
          expect(harness.stopper.emails, [null]);
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
          expect(harness.controller.isLoggingOut.value, isTrue);
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
          expect(harness.authService.logoutCalls, 0);
          expect(harness.userRepository.deleteCalls, 0);
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
          expect(harness.stopper.calls, 1);
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
          expect(harness.stopper.calls, 1);
          expect(harness.authService.logoutCalls, 1);
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
          expect(harness.stopper.emails, [null]);
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
          expect(Get.currentRoute, Routes.LOGIN);
        },
      );

      testWidgets(
        'Sad Path: Deve exibir um snackbar de aviso quando stop não confirmar a parada',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _HarnessLogout(
            storedUser: _storedUser(),
            stopResult: false,
          );
          await _pumpAppLogout(tester, harness);

          // 2. Act
          final run = await _runLogout(tester, harness.controller);

          // 3. Assert
          expect(run.snackbarTitles, ['Rastreamento']);
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
          expect(harness.userRepository.deleteCalls, 0);
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
          expect(harness.controller.isLoggingOut.value, isFalse);
        },
      );

      testWidgets(
        'Sad Path: Deve exibir um snackbar de erro quando logoutGoogle lançar',
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
          expect(run.snackbarTitles, ['Erro ao sair']);
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
          expect(Get.currentRoute, _kHomeRoute);
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
          expect(harness.controller.isLoggingOut.value, isFalse);
        },
      );
    });
  });
}
