import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/sign_in_actions.dart';
import 'package:monamie_app/app/modules/login/services/google_bond_check.dart';
import 'package:monamie_app/app/routes/app_pages.dart';

@GenerateNiceMocks([MockSpec<GoogleBondCheck>(), MockSpec<SignInActions>()])
import 'login_controller_test.mocks.dart';

/// Rota fictícia de login usada como rota inicial nos testes de navegação.
const String _kLoginRoute = '/login-test';
const String _kLoginPlaceholder = 'login-placeholder';
const String _kMonamiePlaceholder = 'monamie-placeholder';

/// A [MockGoogleBondCheck] whose `hasActiveBond` answers [hasBond], throws
/// [error] or waits for [pending].
MockGoogleBondCheck _bondCheck({
  bool hasBond = false,
  Object? error,
  Completer<bool>? pending,
}) {
  final check = MockGoogleBondCheck();
  when(check.hasActiveBond()).thenAnswer((_) {
    if (pending != null) return pending.future;
    if (error != null) return Future.error(error);
    return Future.value(hasBond);
  });
  return check;
}

/// A [LoginController] over [bondCheck] and a [MockSignInActions].
LoginController _controller(MockGoogleBondCheck bondCheck) =>
    LoginController(signIn: MockSignInActions(), bondCheck: bondCheck);

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

  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginController - Restauração de Sessão no Cold Start', () {
    test(
      'Edge Case: Deve iniciar isRestoringSession como true logo após a construção',
      () {
        // 1. Arrange
        const hasBond = true;

        // 2. Act
        final controller = _controller(_bondCheck(hasBond: hasBond));

        // 3. Assert
        expect(controller.isRestoringSession.value, isTrue);
      },
    );

    testWidgets(
      'Happy Path: Deve navegar para Routes.MONAMIE quando houver sessão Google ativa',
      (WidgetTester tester) async {
        // 1. Arrange
        await tester.pumpWidget(_buildTestApp());
        final controller = _controller(_bondCheck(hasBond: true));

        // 2. Act
        Get.put<LoginController>(controller);
        await tester.pumpAndSettle();

        // 3. Assert
        expect(Get.currentRoute, Routes.MONAMIE);
        expect(find.text(_kMonamiePlaceholder), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: Deve finalizar isRestoringSession como false após restaurar a sessão',
      (WidgetTester tester) async {
        // 1. Arrange
        await tester.pumpWidget(_buildTestApp());
        final controller = _controller(_bondCheck(hasBond: true));

        // 2. Act
        Get.put<LoginController>(controller);
        await tester.pumpAndSettle();

        // 3. Assert
        expect(controller.isRestoringSession.value, isFalse);
      },
    );

    testWidgets(
      'Happy Path: Deve consultar hasActiveGoogleBond exatamente uma vez no onReady',
      (WidgetTester tester) async {
        // 1. Arrange
        await tester.pumpWidget(_buildTestApp());
        final bondCheck = _bondCheck(hasBond: true);
        final controller = _controller(bondCheck);

        // 2. Act
        Get.put<LoginController>(controller);
        await tester.pumpAndSettle();

        // 3. Assert
        verify(bondCheck.hasActiveBond()).called(1);
      },
    );

    testWidgets(
      'Edge Case: Deve manter isRestoringSession true e permanecer no login enquanto a verificação estiver pendente',
      (WidgetTester tester) async {
        // 1. Arrange
        await tester.pumpWidget(_buildTestApp());
        final pending = Completer<bool>();
        final controller = _controller(_bondCheck(pending: pending));

        // 2. Act
        Get.put<LoginController>(controller);
        await tester.pump();

        // 3. Assert
        expect(controller.isRestoringSession.value, isTrue);
        expect(Get.currentRoute, _kLoginRoute);
      },
    );

    testWidgets(
      'Sad Path: Deve permanecer na rota de login quando não houver sessão ativa',
      (WidgetTester tester) async {
        // 1. Arrange
        await tester.pumpWidget(_buildTestApp());
        final controller = _controller(_bondCheck(hasBond: false));

        // 2. Act
        Get.put<LoginController>(controller);
        await tester.pumpAndSettle();

        // 3. Assert
        expect(Get.currentRoute, _kLoginRoute);
        expect(find.text(_kLoginPlaceholder), findsOneWidget);
        expect(find.text(_kMonamiePlaceholder), findsNothing);
      },
    );

    testWidgets(
      'Sad Path: Deve finalizar isRestoringSession como false quando não houver sessão ativa',
      (WidgetTester tester) async {
        // 1. Arrange
        await tester.pumpWidget(_buildTestApp());
        final controller = _controller(_bondCheck(hasBond: false));

        // 2. Act
        Get.put<LoginController>(controller);
        await tester.pumpAndSettle();

        // 3. Assert
        expect(controller.isRestoringSession.value, isFalse);
      },
    );

    testWidgets(
      'Sad Path: Deve permanecer no login e finalizar isRestoringSession como false quando hasActiveGoogleBond lançar exceção',
      (WidgetTester tester) async {
        // 1. Arrange
        await tester.pumpWidget(_buildTestApp());
        final failure = StateError('falha simulada ao verificar sessão');
        final controller = _controller(_bondCheck(error: failure));
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
      },
    );
  });
}
