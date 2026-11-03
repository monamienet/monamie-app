import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/ui/auth/view_models/login_view_model.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

import '../../../support/session_double.dart';

@GenerateNiceMocks([
  MockSpec<EnterOrganization>(),
  MockSpec<GoogleBondCheck>(),
  MockSpec<NoticePresenter>(),
])
import 'login_view_model_test.mocks.dart';

const _kIdToken = 'google-id-token';

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

/// The sign-in's [Err] ("Ocorreu um erro inesperado", titled "Erro de
/// Login" on screen).
final Matcher _loginErr = isA<Err<Object?>>().having(
  (err) => err.failure,
  'failure',
  isA<EntryFailure>().having((f) => f.stage, 'stage', EntryStage.unexpected),
);

/// A [UserNotice] of [failure].
Matcher _failureNotice(Object failure) =>
    isA<FailureNotice>().having((notice) => notice.failure, 'failure', failure);

/// The `onEntering` callback passed to the entry.
void Function(String)? _onEntering(Invocation invocation) =>
    invocation.namedArguments[#onEntering] as void Function(String)?;

/// A [LoginViewModel] over a session double (the router opens the map
/// exactly when the session becomes bound, so "goes to the map" is that
/// move and "stays on *Login*" its absence) and mocks.
class _Harness {
  _Harness({
    MockGoogleBondCheck? bondCheck,
    String? idToken = _kIdToken,
    Completer<void>? chooser,
    Object? signInError,
    Result<void> entry = const Ok(null),
    Completer<void>? pendingEntry,
    bool googleReady = false,
  }) : session = SessionDouble(googleReady: googleReady) {
    when(session.repository.webSignIns).thenAnswer((_) => webSignIns.stream);
    when(
      session.repository.signInGoogle(
        onAccountChosen: anyNamed('onAccountChosen'),
      ),
    ).thenAnswer((invocation) async {
      await chooser?.future;
      (invocation.namedArguments[#onAccountChosen] as void Function()?)?.call();
      if (signInError != null) throw signInError;
      return idToken;
    });
    when(
      enterOrganization.afterSignIn(
        any,
        checkDeletion: anyNamed('checkDeletion'),
        onEntering: anyNamed('onEntering'),
      ),
    ).thenAnswer((invocation) async {
      _onEntering(invocation)?.call('Rota Sul');
      enteringSeen = controller.state.enteringOrganizationName;
      await pendingEntry?.future;
      return entry;
    });
    controller = LoginViewModel(
      session: session.repository,
      enterOrganization: enterOrganization,
      bondCheck: bondCheck ?? _bondCheck(),
      notices: notices,
    );
  }

  final SessionDouble session;
  final webSignIns = StreamController<String?>.broadcast();
  final enterOrganization = MockEnterOrganization();
  final notices = MockNoticePresenter();
  late final LoginViewModel controller;

  /// The organization name the state showed while the entry ran.
  String? enteringSeen;

  /// Whether the session moved to the map.
  bool get wentToMap => session.moves.contains(const SessionState.bound());
}

void main() {
  provideDummy<Result<void>>(const Ok(null));

  group('LoginViewModel - Restauração de Sessão no Cold Start', () {
    test(
      'Edge Case: Deve iniciar isRestoringSession como true logo após a construção',
      () {
        // 1. Arrange
        const hasBond = true;

        // 2. Act
        final harness = _Harness(bondCheck: _bondCheck(hasBond: hasBond));

        // 3. Assert
        expect(harness.controller.state.isRestoringSession, isTrue);
      },
    );

    test(
      'Happy Path: Deve levar ao mapa (sessão restaurada) quando houver sessão Google ativa',
      () async {
        // 1. Arrange
        final harness = _Harness(bondCheck: _bondCheck(hasBond: true));

        // 2. Act
        await harness.controller.restoreSession.execute();

        // 3. Assert
        expect(harness.session.moves, [const SessionState.bound()]);
      },
    );

    test(
      'Happy Path: Deve finalizar isRestoringSession como false após restaurar a sessão',
      () async {
        // 1. Arrange
        final harness = _Harness(bondCheck: _bondCheck(hasBond: true));

        // 2. Act
        await harness.controller.restoreSession.execute();

        // 3. Assert
        expect(harness.controller.state.isRestoringSession, isFalse);
      },
    );

    test(
      'Happy Path: Deve consultar hasActiveGoogleBond exatamente uma vez',
      () async {
        // 1. Arrange
        final bondCheck = _bondCheck(hasBond: true);
        final harness = _Harness(bondCheck: bondCheck);

        // 2. Act
        await harness.controller.restoreSession.execute();

        // 3. Assert
        verify(bondCheck.hasActiveBond()).called(1);
      },
    );

    test(
      'Edge Case: Deve manter isRestoringSession true e permanecer no login enquanto a verificação estiver pendente',
      () async {
        // 1. Arrange
        final pending = Completer<bool>();
        final harness = _Harness(bondCheck: _bondCheck(pending: pending));

        // 2. Act
        unawaited(harness.controller.restoreSession.execute());
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.state.isRestoringSession, isTrue);
        expect(harness.wentToMap, isFalse);
        pending.complete(false);
      },
    );

    test(
      'Edge Case: a second call checks nothing and notifies nothing',
      () async {
        // 1. Arrange
        final bondCheck = _bondCheck(hasBond: true);
        final harness = _Harness(bondCheck: bondCheck);
        await harness.controller.restoreSession.execute();
        var notifications = 0;
        harness.controller.addListener(() => notifications++);

        // 2. Act
        await harness.controller.restoreSession.execute();

        // 3. Assert
        verify(bondCheck.hasActiveBond()).called(1);
        expect(harness.session.moves, [const SessionState.bound()]);
        expect(notifications, 0);
      },
    );

    test(
      'Sad Path: Deve permanecer no login e finalizar isRestoringSession como false quando não houver sessão ativa',
      () async {
        // 1. Arrange
        final harness = _Harness(bondCheck: _bondCheck(hasBond: false));
        var notifications = 0;
        harness.controller.addListener(() => notifications++);

        // 2. Act
        await harness.controller.restoreSession.execute();

        // 3. Assert
        expect(harness.wentToMap, isFalse);
        expect(harness.controller.state.isRestoringSession, isFalse);
        expect(notifications, 1);
      },
    );

    test(
      'Sad Path: Deve permanecer no login e finalizar isRestoringSession como false quando hasActiveGoogleBond lançar exceção',
      () async {
        // 1. Arrange
        final failure = StateError('falha simulada ao verificar sessão');
        final harness = _Harness(bondCheck: _bondCheck(error: failure));

        // 2. Act
        // restoreSession has only try/finally (no catch) and the screen
        // starts it without await: the error escapes to the caller.
        final restore = harness.controller.restoreSession.execute();

        // 3. Assert
        await expectLater(restore, throwsA(same(failure)));
        expect(harness.controller.restoreSession.running, isFalse);
        expect(harness.controller.state.isRestoringSession, isFalse);
        expect(harness.wentToMap, isFalse);
      },
    );
  });

  group('LoginViewModel.googleReady - Unit Test Suite', () {
    test('Happy Path: follows the session when Google becomes ready', () {
      // 1. Arrange
      final harness = _Harness();
      var notifications = 0;
      harness.controller.addListener(() => notifications++);

      // 2. Act
      harness.session.googleReady.value = true;

      // 3. Assert
      expect(harness.controller.state.googleReady, isTrue);
      expect(notifications, 1);
    });

    test('Edge Case: starts with what the session says', () {
      // 1. Arrange
      // 2. Act
      final harness = _Harness(googleReady: true);

      // 3. Assert
      expect(harness.controller.state.googleReady, isTrue);
    });

    test('Sad Path: a disposed view model stops following the session', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.dispose();

      // 2. Act
      harness.session.googleReady.value = true;

      // 3. Assert
      expect(harness.controller.state.googleReady, isFalse);
    });
  });

  group(
    'LoginViewModel.loginGoogle (seletor de contas do Google) - Suíte de Testes Unitários',
    () {
      test(
        'Happy Path: Deve manter isLoading falso enquanto o seletor de contas está aberto e ligá-lo só depois da escolha',
        () async {
          // 1. Arrange
          final chooser = Completer<void>();
          final harness = _Harness(chooser: chooser);
          final controller = harness.controller;
          final loadingHistory = <bool>[];
          var last = controller.state.isLoading;
          controller.addListener(() {
            if (controller.state.isLoading == last) return;
            last = controller.state.isLoading;
            loadingHistory.add(last);
          });
          final login = controller.loginGoogle.execute();
          await pumpEventQueue();
          final loadingWhileChooserOpen = controller.state.isLoading;
          final guardedWhileChooserOpen = controller.loginGoogle.running;
          final historyWhileChooserOpen = List<bool>.of(loadingHistory);

          // 2. Act
          chooser.complete();
          await login;

          // 3. Assert
          expect(loadingWhileChooserOpen, isFalse);
          expect(guardedWhileChooserOpen, isTrue);
          expect(historyWhileChooserOpen, isEmpty);
          expect(loadingHistory, [true, false]);
          expect(controller.loginGoogle.running, isFalse);
        },
      );

      test(
        'Edge Case: Não deve chamar signInGoogle de novo quando há um segundo toque com o seletor aberto',
        () async {
          // 1. Arrange
          final chooser = Completer<void>();
          final harness = _Harness(chooser: chooser);
          final first = harness.controller.loginGoogle.execute();
          await pumpEventQueue();

          // 2. Act
          final second = await harness.controller.loginGoogle.execute();

          // 3. Assert
          expect(second, isNull);
          verify(
            harness.session.repository.signInGoogle(
              onAccountChosen: anyNamed('onAccountChosen'),
            ),
          ).called(1);
          chooser.complete();
          await first;
        },
      );

      test(
        'Sad Path: Não deve ligar isLoading quando o seletor é cancelado e deve liberar um novo toque',
        () async {
          // 1. Arrange
          final chooser = Completer<void>();
          final harness = _Harness(chooser: chooser);
          final controller = harness.controller;
          var loadingEverTrue = false;
          controller.addListener(
            () =>
                loadingEverTrue = loadingEverTrue || controller.state.isLoading,
          );
          final login = controller.loginGoogle.execute();
          await pumpEventQueue();

          // 2. Act
          chooser.completeError(Exception('cancelled'));
          final result = await login;

          // 3. Assert
          expect(result, _loginErr);
          expect(loadingEverTrue, isFalse);
          expect(controller.state.isLoading, isFalse);
          expect(controller.loginGoogle.running, isFalse);
          verifyNever(
            harness.enterOrganization.afterSignIn(
              any,
              checkDeletion: anyNamed('checkDeletion'),
              onEntering: anyNamed('onEntering'),
            ),
          );
        },
      );
    },
  );

  group('LoginViewModel.loginGoogle (entrada) - Unit Test Suite', () {
    test('Happy Path: the Google token goes on to the entry', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final result = await harness.controller.loginGoogle.execute();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(
        harness.enterOrganization.afterSignIn(
          _kIdToken,
          checkDeletion: anyNamed('checkDeletion'),
          onEntering: anyNamed('onEntering'),
        ),
      ).called(1);
    });

    test('Happy Path: shows the organization being entered while the entry '
        'runs, then clears it', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.controller.loginGoogle.execute();

      // 3. Assert
      expect(harness.enteringSeen, 'Rota Sul');
      expect(harness.controller.state.enteringOrganizationName, isNull);
      expect(harness.controller.state.isLoading, isFalse);
    });

    test('Edge Case: no token (the web, where it arrives as an event) is no '
        'error and enters nothing', () async {
      // 1. Arrange
      final harness = _Harness(idToken: null);

      // 2. Act
      final result = await harness.controller.loginGoogle.execute();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(harness.session.moves, isEmpty);
      verifyNever(
        harness.enterOrganization.afterSignIn(
          any,
          checkDeletion: anyNamed('checkDeletion'),
          onEntering: anyNamed('onEntering'),
        ),
      );
    });

    test('Edge Case: a tap while the entry runs does nothing', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      final first = harness.controller.loginGoogle.execute();
      await pumpEventQueue();
      expect(harness.controller.state.isLoading, isTrue);

      // 2. Act
      final second = await harness.controller.loginGoogle.execute();

      // 3. Assert
      expect(second, isNull);
      verify(
        harness.session.repository.signInGoogle(
          onAccountChosen: anyNamed('onAccountChosen'),
        ),
      ).called(1);
      pendingEntry.complete();
      await first;
    });

    test('Sad Path: a failed entry returns the login error and turns '
        'isLoading off', () async {
      // 1. Arrange
      final harness = _Harness(
        entry: Err(
          const Failure.entry(EntryStage.enter, 'Exception: sem rede'),
          error: Exception('sem rede'),
        ),
      );

      // 2. Act
      final result = await harness.controller.loginGoogle.execute();

      // 3. Assert
      expect(result, _loginErr);
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.failure,
          'failure',
          const Failure.entry(EntryStage.unexpected, 'Exception: sem rede'),
        ),
      );
      expect(harness.controller.state.isLoading, isFalse);
    });
  });

  group('LoginViewModel web sign-in - Unit Test Suite', () {
    test('Happy Path: a web sign-in token goes on to the entry', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.webSignIns.add(_kIdToken);
      await pumpEventQueue();

      // 3. Assert
      verify(
        harness.enterOrganization.afterSignIn(
          _kIdToken,
          checkDeletion: anyNamed('checkDeletion'),
          onEntering: anyNamed('onEntering'),
        ),
      ).called(1);
      expect(harness.controller.state.isLoading, isFalse);
      verifyNever(harness.notices.show(any));
    });

    test('Edge Case: isLoading is on while the web entry runs', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);

      // 2. Act
      harness.webSignIns.add(_kIdToken);
      await pumpEventQueue();

      // 3. Assert
      expect(harness.controller.state.isLoading, isTrue);
      pendingEntry.complete();
      await pumpEventQueue();
      expect(harness.controller.state.isLoading, isFalse);
    });

    test('Edge Case: a tap on the button while the web entry runs is '
        'ignored (null)', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      harness.webSignIns.add(_kIdToken);
      await pumpEventQueue();

      // 2. Act
      final tap = await harness.controller.loginGoogle.execute();

      // 3. Assert
      expect(tap, isNull);
      expect(harness.controller.loginGoogle.running, isFalse);
      verifyNever(
        harness.session.repository.signInGoogle(
          onAccountChosen: anyNamed('onAccountChosen'),
        ),
      );
      pendingEntry.complete();
      await pumpEventQueue();
    });

    test('Edge Case: a web sign-in while an entry runs is ignored', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      harness.webSignIns.add(_kIdToken);
      await pumpEventQueue();

      // 2. Act
      harness.webSignIns.add('another-token');
      await pumpEventQueue();

      // 3. Assert
      verify(
        harness.enterOrganization.afterSignIn(
          any,
          checkDeletion: anyNamed('checkDeletion'),
          onEntering: anyNamed('onEntering'),
        ),
      ).called(1);
      pendingEntry.complete();
      await pumpEventQueue();
    });

    test('Sad Path: a failed web sign-in (null token) stays on Login and '
        'shows the login error', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.webSignIns.add(null);
      await pumpEventQueue();

      // 3. Assert
      expect(harness.session.moves, isEmpty);
      verify(
        harness.notices.show(
          argThat(_failureNotice(const Failure.googleAuth())),
        ),
      ).called(1);
      verifyNever(
        harness.enterOrganization.afterSignIn(
          any,
          checkDeletion: anyNamed('checkDeletion'),
          onEntering: anyNamed('onEntering'),
        ),
      );
    });

    test('Sad Path: a failed web entry shows the login error', () async {
      // 1. Arrange
      final harness = _Harness(
        entry: Err(
          const Failure.entry(EntryStage.enter, 'Exception: x'),
          error: Exception('x'),
        ),
      );

      // 2. Act
      harness.webSignIns.add(_kIdToken);
      await pumpEventQueue();

      // 3. Assert
      verify(
        harness.notices.show(
          argThat(
            _failureNotice(
              const Failure.entry(EntryStage.loadData, 'Exception: x'),
            ),
          ),
        ),
      ).called(1);
    });

    test('Sad Path: once disposed (Login closed) the web sign-ins are no '
        'longer heard', () async {
      // 1. Arrange
      final harness = _Harness();
      expect(harness.webSignIns.hasListener, isTrue);

      // 2. Act
      harness.controller.dispose();

      // 3. Assert
      expect(harness.webSignIns.hasListener, isFalse);
    });
  });
}
