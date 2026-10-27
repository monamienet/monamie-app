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
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';
import 'package:monamie_app/app/data/firebase/partner_firebase.dart';
import 'package:monamie_app/app/data/models/gd_groups_google_model.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/partner/partner_binding.dart';
import 'package:monamie_app/app/data/partner/partner_binding_store.dart';
import 'package:monamie_app/app/data/partner/partner_branding_loader.dart';
import 'package:monamie_app/app/data/partner/partner_directory.dart';
import 'package:monamie_app/app/data/partner/partner_local_data.dart';
import 'package:monamie_app/app/data/partner/partner_session.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/routes/app_pages.dart';

import '../../support/test_partner.dart';

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

const _kRotaSul = PartnerCandidate(id: 'rotasul', options: _kOptions);
const _kRotaSulName = 'Rota Sul';

/// Claims `syncClaims` returns for a person with no capability left.
const Map<String, Object?> _kNoClaims = {
  'share': <String>[],
  'watch': <String>[],
  'owns': <String>[],
};

/// Claims of a person who shares their location in one team.
const Map<String, Object?> _kShareClaims = {
  'share': ['rotasul01'],
  'watch': <String>[],
  'owns': <String>[],
};

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
  int signOutOfPartnerCalls = 0;

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
  Future<void> signInToPartner(String idToken) async {
    log.add('signInToPartner');
  }

  @override
  Future<void> signOutOfPartner() async {
    signOutOfPartnerCalls++;
    log.add('signOutOfPartner');
  }

  @override
  Future<void> logoutGoogle() async {
    logoutCalls++;
    log.add('logoutGoogle');
    final failure = logoutError;
    if (failure != null) throw failure;
  }

  @override
  Future<UserGoogleModel?> savePartnerProfile() async =>
      UserGoogleModel(id: 'uid-123', name: 'Ana Souza', email: _kCentralEmail);

  @override
  Future<String?> getFirebaseIdToken() async => null;

  @override
  Stream<String?> get onWebSignIn => const Stream<String?>.empty();

  @override
  Future<void> ensureInitialized() async {}

  @override
  void dispose() {}
}

class _FakePartnerDirectory implements PartnerDirectory {
  _FakePartnerDirectory({this.partners = const [], this.error, this.log});

  final List<PartnerCandidate> partners;
  final Object? error;
  final List<String>? log;
  int calls = 0;

  @override
  Future<List<PartnerCandidate>> partnersOfSignedInUser({
    bool fresh = false,
  }) async {
    calls++;
    log?.add('directory');
    final failure = error;
    if (failure != null) throw failure;
    return partners;
  }
}

class _FakeBrandingLoader implements PartnerBrandingLoader {
  @override
  Future<PartnerBinding> load(PartnerCandidate candidate) async =>
      PartnerBinding(
        partner: PartnerConfig(id: candidate.id, name: _kRotaSulName),
        options: candidate.options,
      );

  @override
  Future<PartnerConfig> readBranding(PartnerBinding binding) =>
      throw UnimplementedError('readBranding is not used by the sign-in');
}

class _MemoryBindingStore implements PartnerBindingStore {
  PartnerBinding? binding;

  @override
  Future<PartnerBinding?> read() async => binding;

  @override
  Future<void> write(PartnerBinding value) async => binding = value;

  @override
  Future<void> clear() async => binding = null;
}

/// [PartnerSession] that binds without creating a real [FirebaseApp]: it
/// sets [Partner.current] and a fake [PartnerFirebase] whose `syncClaims`
/// returns [claims] (or fails when [syncError] is set).
class _FakePartnerSession extends PartnerSession {
  _FakePartnerSession(this.log, {this.claims, this.syncError})
    : super(store: _MemoryBindingStore());

  final List<String> log;
  final Map<String, Object?>? claims;
  final Object? syncError;
  int forgetCalls = 0;

  @override
  Future<void> bind(PartnerBinding binding, {bool remember = true}) async {
    log.add('bind');
    Partner.bind(binding.partner);
    CurrentPartnerFirebase.set(
      _FakePartnerFirebase(claims: claims ?? const {}, error: syncError),
    );
  }

  @override
  Future<void> forget() async {
    forgetCalls++;
    log.add('forget');
    await super.forget();
  }
}

class _FakePartnerFirebase implements PartnerFirebase {
  _FakePartnerFirebase({required this.claims, this.error});

  final Map<String, Object?> claims;
  final Object? error;

  @override
  FirebaseAuth get auth => _FakeFirebaseAuth();

  @override
  FirebaseFunctions get functions => _FakeFunctions(claims, error);

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  FirebaseStorage get storage => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get partnerData =>
      throw UnimplementedError();
}

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => _FakeUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'partner-id-token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFunctions implements FirebaseFunctions {
  _FakeFunctions(this.claims, this.error);

  final Map<String, Object?> claims;
  final Object? error;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _FakeCallable(claims, error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCallable implements HttpsCallable {
  _FakeCallable(this.claims, this.error);

  final Map<String, Object?> claims;
  final Object? error;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    final failure = error;
    if (failure != null) throw failure;
    return _FakeCallableResult<T>(claims as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCallableResult<T> implements HttpsCallableResult<T> {
  _FakeCallableResult(this.data);

  @override
  final T data;
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

class _FakePartnerLocalData implements PartnerLocalData {
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
  Future<GdiGroupsGoogle> getGdiGroupsGoogle(String token, String email) =>
      throw StateError('groups gateway unavailable in tests');

  @override
  Future<UserGoogleModel> createUserDoc(
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
    List<PartnerCandidate> partners = const [],
    Object? directoryError,
    Map<String, Object?>? claims,
    Object? syncError,
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
    directory = _FakePartnerDirectory(
      partners: partners,
      error: directoryError,
      log: log,
    );
    session = _FakePartnerSession(log, claims: claims, syncError: syncError);
    controller = AuthGoogleController(
      authGoogleService: authService,
      userRepository: _FakeUserGoogleRepository(),
      trackingStopper: _FakeTrackingStopper(log),
      partnerDirectory: directory,
      brandingLoader: _FakeBrandingLoader(),
      partnerSession: session,
      partnerLocalData: _FakePartnerLocalData(),
      refreshTheme: () => log.add('refreshTheme'),
    );
  }

  final List<String> log = <String>[];
  late final _FakeAuthGoogleService authService;
  late final _FakePartnerDirectory directory;
  late final _FakePartnerSession session;
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
        page(Routes.PARTNER_PICKER),
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

/// Entries of [log] before the partner is forgotten or signed out of.
Iterable<String> _beforeNoAccessDecision(List<String> log) =>
    log.takeWhile((e) => e != 'forget' && e != 'signOutOfPartner');

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
    Partner.bind(testPartner);
    CurrentPartnerFirebase.debugReset();
  });

  group(
    'AuthGoogleController.loginGoogle (sem parceiro) - Suíte de Testes Unitários',
    () {
      testWidgets(
        'Happy Path: Deve navegar para Routes.NO_ORGANIZATION quando o usuário não tiver parceiro',
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
        'Edge Case: Não deve sair do Google/central quando o usuário não tiver parceiro',
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
        'Sad Path: Deve exibir erro de login e voltar isLoading a false quando a busca de parceiros lançar',
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
    'AuthGoogleController.loginGoogle (parceiro sem acesso) - Suíte de Testes Unitários',
    () {
      testWidgets(
        'Happy Path: Deve explicar em noAccessReason que a conta não tem mais acesso ao parceiro',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(partners: [_kRotaSul], claims: _kNoClaims);
          await _pumpApp(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(
            harness.controller.noAccessReason.value,
            'Sua conta não tem mais acesso à Rota Sul.',
          );
        },
      );

      testWidgets(
        'Happy Path: Deve navegar para Routes.NO_ORGANIZATION quando as claims não derem acesso',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(partners: [_kRotaSul], claims: _kNoClaims);
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
        'Happy Path: Deve esquecer o parceiro quando as claims não derem acesso',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(partners: [_kRotaSul], claims: _kNoClaims);
          await _pumpApp(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(harness.session.forgetCalls, greaterThanOrEqualTo(1));
          expect(Partner.current, isNull);
        },
      );

      testWidgets(
        'Happy Path: Deve sair apenas do projeto do parceiro quando as claims não derem acesso',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(partners: [_kRotaSul], claims: _kNoClaims);
          await _pumpApp(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(harness.authService.signOutOfPartnerCalls, 1);
        },
      );

      testWidgets(
        'Edge Case: Não deve exibir snackbar de erro de login quando as claims não derem acesso',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(partners: [_kRotaSul], claims: _kNoClaims);
          await _pumpApp(tester);

          // 2. Act
          final titles = await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(titles, isNot(contains(_kLoginErrorTitle)));
        },
      );

      testWidgets(
        'Edge Case: Não deve aplicar o tema do parceiro antes de decidir que a conta não tem acesso',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(partners: [_kRotaSul], claims: _kNoClaims);
          await _pumpApp(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(
            _beforeNoAccessDecision(harness.log),
            isNot(contains('refreshTheme')),
          );
        },
      );

      testWidgets(
        'Edge Case: Não deve definir noAccessReason nem ir para Sem organização quando as claims derem acesso',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(
            partners: [_kRotaSul],
            claims: _kShareClaims,
          );
          await _pumpApp(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(harness.controller.noAccessReason.value, isNull);
          expect(Get.currentRoute, isNot(Routes.NO_ORGANIZATION));
        },
      );

      testWidgets(
        'Sad Path: Não deve tratar uma falha do syncClaims como perda de acesso',
        (WidgetTester tester) async {
          // 1. Arrange
          final harness = _Harness(
            partners: [_kRotaSul],
            syncError: Exception('functions indisponível'),
          );
          await _pumpApp(tester);

          // 2. Act
          await _run(
            tester,
            harness.controller,
            harness.controller.loginGoogle,
          );

          // 3. Assert
          expect(harness.controller.noAccessReason.value, isNull);
          expect(harness.authService.signOutOfPartnerCalls, 0);
        },
      );
    },
  );

  group('AuthGoogleController.recheckPartners - Suíte de Testes Unitários', () {
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
          harness.controller.recheckPartners,
        );

        // 3. Assert
        expect(harness.authService.signInCalls, 1);
      },
    );

    testWidgets('Happy Path: Deve buscar de novo os parceiros do usuário', (
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
        harness.controller.recheckPartners,
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
        harness.controller.recheckPartners,
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
          harness.controller.recheckPartners,
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
        await harness.controller.recheckPartners();

        // 3. Assert
        expect(harness.authService.signInCalls, 0);
        expect(harness.directory.calls, 0);
      },
    );

    testWidgets(
      'Sad Path: Deve voltar isLoading a false quando a busca de parceiros lançar',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(directoryError: Exception('sem rede'));
        await _pumpApp(tester);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.recheckPartners,
        );

        // 3. Assert
        expect(harness.controller.isLoading.value, isFalse);
      },
    );
  });

  group('AuthGoogleController.forgetRemovedPartner - Suíte de Testes Unitários', () {
    testWidgets(
      'Happy Path: Deve explicar em noAccessReason que o usuário não faz mais parte do parceiro',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness();
        await _pumpApp(tester);
        Partner.bind(const PartnerConfig(id: 'rotasul', name: _kRotaSulName));

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.forgetRemovedPartner,
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
          harness.controller.forgetRemovedPartner,
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
          harness.controller.forgetRemovedPartner,
        );

        // 3. Assert
        expect(harness.log.where((e) => e == 'stop' || e == 'logoutGoogle'), [
          'stop',
          'logoutGoogle',
        ]);
      },
    );

    testWidgets(
      'Edge Case: Deve usar "desta organização" quando não houver parceiro vinculado',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness();
        await _pumpApp(tester);
        Partner.unbind();

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.forgetRemovedPartner,
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
          harness.controller.forgetRemovedPartner,
        );

        // 3. Assert
        expect(Get.currentRoute, _kHomeRoute);
      },
    );
  });

  group('AuthGoogleController.switchOrganization - Suíte de Testes Unitários', () {
    testWidgets(
      'Happy Path: Deve abrir o seletor de organizações com as organizações da pessoa',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(partners: [_kRotaSul]);
        await _pumpApp(tester);

        // 2. Act
        await _run(
          tester,
          harness.controller,
          harness.controller.switchOrganization,
        );

        // 3. Assert
        expect(Get.currentRoute, Routes.PARTNER_PICKER);
        expect(harness.controller.partnerChoices.map((b) => b.partner.id), [
          'rotasul',
        ]);
      },
    );

    testWidgets(
      'Happy Path: Deve buscar as organizações antes de parar o rastreamento e esquecer o parceiro',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(partners: [_kRotaSul]);
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
                e == 'signOutOfPartner' ||
                e == 'forget',
          ),
          ['directory', 'stop', 'signOutOfPartner', 'forget'],
        );
      },
    );

    testWidgets(
      'Happy Path: Não deve sair do Google nem abrir o seletor de contas',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(partners: [_kRotaSul]);
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
      'Happy Path: Deve atualizar o tema depois de esquecer o parceiro',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(partners: [_kRotaSul]);
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
          partners: [_kRotaSul],
          claims: _kShareClaims,
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
        expect(harness.log, contains('signOutOfPartner'));
        expect(Get.currentRoute, Routes.PARTNER_PICKER);
      },
    );

    testWidgets(
      'Edge Case: Deve pedir um token novo quando o token guardado não for um JWT válido',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(partners: [_kRotaSul], claims: _kShareClaims);
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
        expect(harness.log, contains('signOutOfPartner'));
      },
    );

    testWidgets(
      'Edge Case: Deve pedir um token novo quando o token guardado estiver vencido',
      (WidgetTester tester) async {
        // 1. Arrange
        final harness = _Harness(
          partners: [_kRotaSul],
          claims: _kShareClaims,
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
        expect(harness.log, contains('signOutOfPartner'));
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
        expect(harness.controller.partnerChoices, isEmpty);
        expect(harness.authService.logoutCalls, 0);
      },
    );

    test(
      'Edge Case: Não deve fazer nada quando chamado com isLoggingOut true (reentrância)',
      () async {
        // 1. Arrange
        final harness = _Harness(partners: [_kRotaSul]);
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
        final harness = _Harness(partners: [_kRotaSul]);
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
        final harness = _Harness(partners: [_kRotaSul], refreshedToken: null);
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
        final harness = _Harness(partners: [_kRotaSul], refreshedToken: null);
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
        final harness = _Harness(partners: [_kRotaSul], refreshedToken: null);
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
      'Sad Path: Não deve parar o rastreamento nem esquecer o parceiro quando a busca de organizações lançar',
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
            (e) => e == 'stop' || e == 'signOutOfPartner' || e == 'forget',
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
        final harness = _Harness(partners: [_kRotaSul]);
        await _pumpApp(tester);
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
        final harness = _Harness(directoryError: Exception('sem rede'));
        await _pumpApp(tester);
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
        final harness = _Harness();
        await _pumpApp(tester);
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
        final harness = _Harness(partners: [_kRotaSul]);
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
        final harness = _Harness(partners: [_kRotaSul], refreshedToken: null);
        await _pumpApp(tester);
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
}
