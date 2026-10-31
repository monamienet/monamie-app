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
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';

import '../../support/test_organization.dart';

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

const _kVerdeMar = OrganizationCandidate(
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

class _FakeAuthGoogleService implements AuthGoogleService {
  _FakeAuthGoogleService(
    this.log, {
    this.idToken = _kIdToken,
    this.refreshedToken = _kIdToken,
    this.signInError,
    this.logoutError,
  });

  final List<String> log;
  final String? idToken;
  final String? refreshedToken;
  final Object? signInError;
  final Object? logoutError;

  int signInCalls = 0;
  int logoutCalls = 0;
  int signOutOfOrganizationCalls = 0;

  @override
  Future<String?> signInGoogle() async {
    signInCalls++;
    log.add('signInGoogle');
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

class _FakeBrandingLoader implements OrganizationBrandingLoader {
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
class _FakeOrganizationSession extends OrganizationSession {
  _FakeOrganizationSession(this.log) : super(store: _MemoryBindingStore());

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

class _FakeTrackingStopper implements BackgroundTrackingStopper {
  _FakeTrackingStopper(this.log);

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

class _FakeUserGoogleRepository implements UserGoogleRepository {
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

class _Harness {
  _Harness({
    List<OrganizationCandidate> organizations = const [],
    Object? directoryError,
    bool? member = false,
    String? idToken = _kIdToken,
    String? refreshedToken = _kIdToken,
    Object? signInError,
    Object? logoutError,
  }) {
    authService = _FakeAuthGoogleService(
      log,
      idToken: idToken,
      refreshedToken: refreshedToken,
      signInError: signInError,
      logoutError: logoutError,
    );
    directory = _FakeOrganizationDirectory(
      organizations: organizations,
      error: directoryError,
      log: log,
    );
    session = _FakeOrganizationSession(log);
    membershipCheck = _FakeMembershipCheck(member);
    controller = AuthGoogleController(
      authGoogleService: authService,
      userRepository: _FakeUserGoogleRepository(),
      trackingStopper: _FakeTrackingStopper(log),
      organizationDirectory: directory,
      brandingLoader: _FakeBrandingLoader(),
      organizationSession: session,
      organizationLocalData: _FakeOrganizationLocalData(),
      membershipCheck: membershipCheck,
      refreshTheme: () => log.add('refreshTheme'),
    );
  }

  final List<String> log = <String>[];
  late final _FakeMembershipCheck membershipCheck;
  late final _FakeAuthGoogleService authService;
  late final _FakeOrganizationDirectory directory;
  late final _FakeOrganizationSession session;
  late final AuthGoogleController controller;
}

Future<void> _pumpApp(WidgetTester tester) async {
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

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Organization.bind(testOrganization);
    CurrentOrganizationFirebase.debugReset();
  });

  group(
    'AuthGoogleController.loginGoogle (sem organização) - Suíte de Testes Unitários',
    () {
      testWidgets(
        'Happy Path: Deve navegar para Routes.NO_ORGANIZATION quando o usuário não tiver organização',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness();
          await _pumpApp(tester);

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
          final harness = _Harness();
          await _pumpApp(tester);

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
          final harness = _Harness();
          await _pumpApp(tester);

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
          final harness = _Harness(directoryError: Exception('sem rede'));
          await _pumpApp(tester);

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
          final harness = _Harness(organizations: [_kRotaSul], member: true);
          await _pumpApp(tester);

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
          final harness = _Harness(
            organizations: [_kRotaSul, _kVerdeMar],
            member: true,
          );
          await _pumpApp(tester);

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
          final harness = _Harness(organizations: [_kRotaSul], member: true);
          await _pumpApp(tester);

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
          final harness = _Harness(organizations: [_kRotaSul], member: true);
          await _pumpApp(tester);

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
          final harness = _Harness(organizations: [_kRotaSul], idToken: null);
          await _pumpApp(tester);

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
          final harness = _Harness(organizations: [_kRotaSul], member: false);
          await _pumpApp(tester);
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
          final harness = _Harness(organizations: [_kRotaSul], member: false);
          await _pumpApp(tester);
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
          final harness = _Harness(organizations: [_kRotaSul], member: false);
          await _pumpApp(tester);
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
          final harness = _Harness(organizations: [_kRotaSul], member: false);
          await _pumpApp(tester);
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
          final harness = _Harness(organizations: [_kRotaSul], member: false);
          await _pumpApp(tester);
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
          final harness = _Harness(organizations: [_kRotaSul], member: false);
          await _pumpApp(tester);
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
          final harness = _Harness(organizations: [_kRotaSul], member: true);
          await _pumpApp(tester);
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
          final harness = _Harness(organizations: [_kRotaSul], member: null);
          await _pumpApp(tester);
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
        final harness = _Harness();
        await _pumpApp(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);

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

    testWidgets('Happy Path: Deve buscar de novo as organizações do usuário', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final harness = _Harness();
      await _pumpApp(tester);
      await _run(tester, harness.controller, harness.controller.loginGoogle);

      // 2. Act
      await _run(
        tester,
        harness.controller,
        harness.controller.recheckOrganizations,
      );

      // 3. Assert
      expect(harness.directory.calls, 2);
    });

    testWidgets('Happy Path: Deve limpar noAccessReason', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final harness = _Harness();
      await _pumpApp(tester);
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
        final harness = _Harness();
        await _pumpApp(tester);

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
        final harness = _Harness();
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
        final harness = _Harness(directoryError: Exception('sem rede'));
        await _pumpApp(tester);

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
          final harness = _Harness();
          await _pumpApp(tester);
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
          final harness = _Harness();
          await _pumpApp(tester);

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
          final harness = _Harness();
          await _pumpApp(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.forgetRemovedOrganization,
          );

          // 3. Assert
          expect(harness.log.where((e) => e == 'stop' || e == 'logoutGoogle'), [
            'stop',
            'logoutGoogle',
          ]);
        },
      );

      testWidgets(
        'Edge Case: Deve usar "desta organização" quando não houver organização vinculada',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness();
          await _pumpApp(tester);
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
          final harness = _Harness(logoutError: Exception('falha de rede'));
          await _pumpApp(tester);

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
        final harness = _Harness(organizations: [_kRotaSul]);
        await _pumpApp(tester);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.switchOrganization,
        );

        // 3. Assert
        expect(Get.currentRoute, Routes.ORGANIZATION_PICKER);
        expect(
          harness.controller.organizationChoices.map((b) => b.organization.id),
          ['rotasul'],
        );
      },
    );

    testWidgets(
      'Happy Path: Deve buscar as organizações antes de parar o rastreamento e esquecer a organização',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(organizations: [_kRotaSul]);
        await _pumpApp(tester);

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
        final harness = _Harness(organizations: [_kRotaSul]);
        await _pumpApp(tester);

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
        final harness = _Harness(organizations: [_kRotaSul]);
        await _pumpApp(tester);

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
        final harness = _Harness(
          organizations: [_kRotaSul],
          member: true,
          idToken: _jwtExpiringIn(const Duration(hours: 1)),
          refreshedToken: null,
        );
        await _pumpApp(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);
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
        final harness = _Harness(organizations: [_kRotaSul], member: true);
        await _pumpApp(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);
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
        final harness = _Harness(
          organizations: [_kRotaSul],
          member: true,
          idToken: _jwtExpiringIn(const Duration(hours: -1)),
        );
        await _pumpApp(tester);
        await _run(tester, harness.controller, harness.controller.loginGoogle);
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
        final harness = _Harness();
        await _pumpApp(tester);

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
        final harness = _Harness(organizations: [_kRotaSul]);
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
        final harness = _Harness(organizations: [_kRotaSul]);
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
        final harness = _Harness(
          organizations: [_kRotaSul],
          refreshedToken: null,
        );
        await _pumpApp(tester);

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
        final harness = _Harness(
          organizations: [_kRotaSul],
          refreshedToken: null,
        );
        await _pumpApp(tester);

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
        final harness = _Harness(
          organizations: [_kRotaSul],
          refreshedToken: null,
        );
        await _pumpApp(tester);

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
        final harness = _Harness(directoryError: Exception('sem rede'));
        await _pumpApp(tester);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.switchOrganization,
        );

        // 3. Assert
        expect(
          harness.log.where(
            (e) => e == 'stop' || e == 'signOutOfOrganization' || e == 'forget',
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
        final harness = _Harness(directoryError: Exception('sem rede'));
        await _pumpApp(tester);

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
        final harness = _Harness(directoryError: Exception('sem rede'));
        await _pumpApp(tester);

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
        final harness = _Harness(organizations: [_kRotaSul]);
        await _pumpApp(tester);
        final seen = <bool>[];
        final sub = harness.controller.isSwitchingOrganization.listen(seen.add);

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
        final harness = _Harness(directoryError: Exception('sem rede'));
        await _pumpApp(tester);
        final seen = <bool>[];
        final sub = harness.controller.isSwitchingOrganization.listen(seen.add);

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
        final harness = _Harness();
        await _pumpApp(tester);
        final seen = <bool>[];
        final sub = harness.controller.isSwitchingOrganization.listen(seen.add);

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
        final harness = _Harness(organizations: [_kRotaSul]);
        harness.controller.isLoggingOut.value = true;
        final seen = <bool>[];
        final sub = harness.controller.isSwitchingOrganization.listen(seen.add);

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
        final harness = _Harness(
          organizations: [_kRotaSul],
          refreshedToken: null,
        );
        await _pumpApp(tester);
        final seen = <bool>[];
        final sub = harness.controller.isSwitchingOrganization.listen(seen.add);

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
        final harness = _Harness(
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
        final harness = _Harness(organizations: [_kRotaSul, _kVerdeMar]);

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
        final harness = _Harness(
          organizations: [
            _kRotaSul,
            OrganizationCandidate(
              id: _kVerdeMar.id,
              options: _kVerdeMar.options,
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
        final harness = _Harness(organizations: [_kVerdeMar]);

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
        final harness = _Harness(directoryError: StateError('offline'));

        // 2. Act
        final owns = harness.controller.ownsOrganization('rotasul');

        // 3. Assert
        await expectLater(owns, throwsStateError);
      },
    );
  });
}
