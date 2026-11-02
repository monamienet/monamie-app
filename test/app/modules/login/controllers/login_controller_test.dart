import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/sign_in_actions.dart';
import 'package:monamie_app/app/modules/login/services/google_bond_check.dart';

@GenerateNiceMocks([MockSpec<GoogleBondCheck>(), MockSpec<SignInActions>()])
import 'login_controller_test.mocks.dart';

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

/// The sign-in the controller under test reports to; the router opens the
/// map exactly when it hears `sessionRestored` (the session becomes bound),
/// so "goes to the map" is that call and "stays on *Login*" its absence.
late MockSignInActions _signIn;

/// A [LoginController] over [bondCheck] and [_signIn].
LoginController _controller(MockGoogleBondCheck bondCheck) =>
    LoginController(signIn: _signIn, bondCheck: bondCheck);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _signIn = MockSignInActions();
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
        expect(controller.state.isRestoringSession, isTrue);
      },
    );

    testWidgets(
      'Happy Path: Deve levar ao mapa (sessão restaurada) quando houver sessão Google ativa',
      (WidgetTester tester) async {
        // 1. Arrange
        final controller = _controller(_bondCheck(hasBond: true));

        // 2. Act
        controller.restoreSession();
        await tester.pumpAndSettle();

        // 3. Assert
        verify(_signIn.sessionRestored()).called(1);
      },
    );

    testWidgets(
      'Happy Path: Deve finalizar isRestoringSession como false após restaurar a sessão',
      (WidgetTester tester) async {
        // 1. Arrange
        final controller = _controller(_bondCheck(hasBond: true));

        // 2. Act
        controller.restoreSession();
        await tester.pumpAndSettle();

        // 3. Assert
        expect(controller.state.isRestoringSession, isFalse);
      },
    );

    testWidgets(
      'Happy Path: Deve consultar hasActiveGoogleBond exatamente uma vez no onReady',
      (WidgetTester tester) async {
        // 1. Arrange
        final bondCheck = _bondCheck(hasBond: true);
        final controller = _controller(bondCheck);

        // 2. Act
        controller.restoreSession();
        await tester.pumpAndSettle();

        // 3. Assert
        verify(bondCheck.hasActiveBond()).called(1);
      },
    );

    testWidgets(
      'Edge Case: Deve manter isRestoringSession true e permanecer no login enquanto a verificação estiver pendente',
      (WidgetTester tester) async {
        // 1. Arrange
        final pending = Completer<bool>();
        final controller = _controller(_bondCheck(pending: pending));

        // 2. Act
        controller.restoreSession();
        await tester.pump();

        // 3. Assert
        expect(controller.state.isRestoringSession, isTrue);
        verifyNever(_signIn.sessionRestored());
      },
    );

    testWidgets(
      'Sad Path: Deve permanecer na rota de login quando não houver sessão ativa',
      (WidgetTester tester) async {
        // 1. Arrange
        final controller = _controller(_bondCheck(hasBond: false));

        // 2. Act
        controller.restoreSession();
        await tester.pumpAndSettle();

        // 3. Assert
        verifyNever(_signIn.sessionRestored());
      },
    );

    testWidgets(
      'Sad Path: Deve finalizar isRestoringSession como false quando não houver sessão ativa',
      (WidgetTester tester) async {
        // 1. Arrange
        final controller = _controller(_bondCheck(hasBond: false));

        // 2. Act
        controller.restoreSession();
        await tester.pumpAndSettle();

        // 3. Assert
        expect(controller.state.isRestoringSession, isFalse);
      },
    );

    testWidgets(
      'Sad Path: Deve permanecer no login e finalizar isRestoringSession como false quando hasActiveGoogleBond lançar exceção',
      (WidgetTester tester) async {
        // 1. Arrange
        final failure = StateError('falha simulada ao verificar sessão');
        final controller = _controller(_bondCheck(error: failure));
        final uncaughtErrors = <Object>[];

        // 2. Act
        // O restoreSession usa apenas try/finally (sem catch) e é disparado
        // pela tela via post-frame callback sem await. A exceção escapa como erro
        // assíncrono não tratado; a zona guardada a captura para inspeção.
        await runZonedGuarded(() async {
          controller.restoreSession();
          await tester.pumpAndSettle();
        }, (error, _) => uncaughtErrors.add(error));

        // 3. Assert
        expect(uncaughtErrors, [same(failure)]);
        expect(controller.state.isRestoringSession, isFalse);
        verifyNever(_signIn.sessionRestored());
      },
    );
  });

  group('LoginController.restoreSession - SignInActions', () {
    testWidgets(
      'Happy Path: a remembered session tells the sign-in it was restored',
      (WidgetTester tester) async {
        // 1. Arrange
        final signIn = MockSignInActions();
        final controller = LoginController(
          signIn: signIn,
          bondCheck: _bondCheck(hasBond: true),
        );

        // 2. Act
        await controller.restoreSession();
        await tester.pumpAndSettle();

        // 3. Assert
        verify(signIn.sessionRestored()).called(1);
      },
    );

    testWidgets(
      'Edge Case: a second call checks nothing and notifies nothing',
      (WidgetTester tester) async {
        // 1. Arrange
        final bondCheck = _bondCheck(hasBond: true);
        final signIn = MockSignInActions();
        final controller = LoginController(
          signIn: signIn,
          bondCheck: bondCheck,
        );
        await controller.restoreSession();
        await tester.pumpAndSettle();
        var notifications = 0;
        controller.addListener(() => notifications++);

        // 2. Act
        await controller.restoreSession();

        // 3. Assert
        verify(bondCheck.hasActiveBond()).called(1);
        verify(signIn.sessionRestored()).called(1);
        expect(notifications, 0);
      },
    );

    test(
      'Sad Path: no remembered session never says it was restored',
      () async {
        // 1. Arrange
        final signIn = MockSignInActions();
        final controller = LoginController(
          signIn: signIn,
          bondCheck: _bondCheck(hasBond: false),
        );
        var notifications = 0;
        controller.addListener(() => notifications++);

        // 2. Act
        await controller.restoreSession();

        // 3. Assert
        verifyNever(signIn.sessionRestored());
        expect(notifications, 1);
      },
    );
  });
}
