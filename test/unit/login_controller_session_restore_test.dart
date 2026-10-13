import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
// O pacote de interface de plataforma é dependência transitiva de
// firebase_core e expõe os mocks oficiais do Firebase Core para testes.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:monamie_app/app/routes/app_pages.dart';

/// Rota fictícia de login usada como rota inicial nos testes de navegação.
const String _kLoginRoute = '/login-test';
const String _kLoginPlaceholder = 'login-placeholder';
const String _kMonamiePlaceholder = 'monamie-placeholder';

/// Fake do AuthGoogleController: sobrescreve `onInit` para NÃO assinar o
/// stream de login web nem inicializar o GoogleSignIn. Como os serviços do
/// controller real são `late final`, eles nunca chegam a ser instanciados.
class _FakeAuthGoogleController extends AuthGoogleController {
  @override
  // ignore: must_call_super
  void onInit() {
    // Intencionalmente vazio: evita chamadas a Google Sign-In/Firebase.
  }
}

/// Subclasse de teste do LoginController que substitui a verificação real
/// (FirebaseAuth + Hive) por uma resposta determinística.
class _FakeLoginController extends LoginController {
  _FakeLoginController({this.hasBond = false, this.error, this.pending});

  final bool hasBond;
  final Object? error;
  final Completer<bool>? pending;
  int hasActiveGoogleBondCalls = 0;

  @override
  Future<bool> hasActiveGoogleBond() async {
    hasActiveGoogleBondCalls++;
    final pendingCheck = pending;
    if (pendingCheck != null) return pendingCheck.future;
    final failure = error;
    if (failure != null) throw failure;
    return hasBond;
  }
}

Widget _buildTestApp() {
  return GetMaterialApp(
    initialRoute: _kLoginRoute,
    getPages: [
      GetPage(
        name: _kLoginRoute,
        page: () => const Scaffold(body: Text(_kLoginPlaceholder)),
      ),
      GetPage(
        name: Routes.MONAMIE,
        page: () => const Scaffold(body: Text(_kMonamiePlaceholder)),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // O construtor do LoginController instancia UserGoogleRepository, que
    // chama `Firebase.app()`. Os mocks oficiais evitam canais nativos.
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    Get.testMode = true;
    Get.put<AuthGoogleController>(_FakeAuthGoogleController());
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginController - Restauração de Sessão no Cold Start', () {
    test('Edge Case: Deve iniciar isRestoringSession como true logo após a construção',
        () {
      // 1. Arrange
      const hasBond = true;

      // 2. Act
      final controller = _FakeLoginController(hasBond: hasBond);

      // 3. Assert
      expect(controller.isRestoringSession.value, isTrue);
    });

    testWidgets(
        'Happy Path: Deve navegar para Routes.MONAMIE quando houver sessão Google ativa',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final controller = _FakeLoginController(hasBond: true);

      // 2. Act
      Get.put<LoginController>(controller);
      await tester.pumpAndSettle();

      // 3. Assert
      expect(Get.currentRoute, Routes.MONAMIE);
      expect(find.text(_kMonamiePlaceholder), findsOneWidget);
    });

    testWidgets(
        'Happy Path: Deve finalizar isRestoringSession como false após restaurar a sessão',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final controller = _FakeLoginController(hasBond: true);

      // 2. Act
      Get.put<LoginController>(controller);
      await tester.pumpAndSettle();

      // 3. Assert
      expect(controller.isRestoringSession.value, isFalse);
    });

    testWidgets(
        'Happy Path: Deve consultar hasActiveGoogleBond exatamente uma vez no onReady',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final controller = _FakeLoginController(hasBond: true);

      // 2. Act
      Get.put<LoginController>(controller);
      await tester.pumpAndSettle();

      // 3. Assert
      expect(controller.hasActiveGoogleBondCalls, 1);
    });

    testWidgets(
        'Edge Case: Deve manter isRestoringSession true e permanecer no login enquanto a verificação estiver pendente',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final pending = Completer<bool>();
      final controller = _FakeLoginController(pending: pending);

      // 2. Act
      Get.put<LoginController>(controller);
      await tester.pump();

      // 3. Assert
      expect(controller.isRestoringSession.value, isTrue);
      expect(Get.currentRoute, _kLoginRoute);
    });

    testWidgets(
        'Sad Path: Deve permanecer na rota de login quando não houver sessão ativa',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final controller = _FakeLoginController(hasBond: false);

      // 2. Act
      Get.put<LoginController>(controller);
      await tester.pumpAndSettle();

      // 3. Assert
      expect(Get.currentRoute, _kLoginRoute);
      expect(find.text(_kLoginPlaceholder), findsOneWidget);
      expect(find.text(_kMonamiePlaceholder), findsNothing);
    });

    testWidgets(
        'Sad Path: Deve finalizar isRestoringSession como false quando não houver sessão ativa',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final controller = _FakeLoginController(hasBond: false);

      // 2. Act
      Get.put<LoginController>(controller);
      await tester.pumpAndSettle();

      // 3. Assert
      expect(controller.isRestoringSession.value, isFalse);
    });

    testWidgets(
        'Sad Path: Deve permanecer no login e finalizar isRestoringSession como false quando hasActiveGoogleBond lançar exceção',
        (WidgetTester tester) async {
      // 1. Arrange
      await tester.pumpWidget(_buildTestApp());
      final failure = StateError('falha simulada ao verificar sessão');
      final controller = _FakeLoginController(error: failure);
      final uncaughtErrors = <Object>[];

      // 2. Act
      // O onReady usa apenas try/finally (sem catch) e é disparado pelo GetX
      // via post-frame callback sem await. A exceção escapa como erro
      // assíncrono não tratado; a zona guardada a captura para inspeção.
      await runZonedGuarded(() async {
        Get.put<LoginController>(controller);
        await tester.pumpAndSettle();
      }, (error, _) => uncaughtErrors.add(error));

      // 3. Assert
      expect(uncaughtErrors, [same(failure)]);
      expect(controller.isRestoringSession.value, isFalse);
      expect(Get.currentRoute, _kLoginRoute);
    });
  });
}
