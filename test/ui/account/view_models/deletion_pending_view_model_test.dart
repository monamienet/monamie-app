import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/account/view_models/deletion_pending_view_model.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../support/session_double.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<EnterOrganization>(),
  MockSpec<SignOut>(),
])
import 'deletion_pending_view_model_test.mocks.dart';

final _kDeletion = AccountDeletion(deleteAt: DateTime.utc(2026, 12, 2));

/// A [DeletionPendingViewModel] on *Em exclusão* over a session double
/// whose `keptOrSignIn` answers [token] (or fails with [signInError]) and
/// mocks: the cancel answers [cancel], the entry [entry] after
/// [pendingEntry].
class _Harness {
  _Harness({
    String? token = 'google-id-token',
    Object? signInError,
    Result<void> cancel = const Ok(null),
    Completer<void>? pendingCancel,
    Result<void> entry = const Ok(null),
    Completer<void>? pendingEntry,
  }) : session = SessionDouble(initial: SessionState.deletionPending(_kDeletion)) {
    when(session.repository.keptOrSignIn()).thenAnswer((_) async {
      if (signInError != null) throw signInError;
      return token;
    });
    when(repository.cancel()).thenAnswer((_) async {
      await pendingCancel?.future;
      return cancel;
    });
    when(
      enterOrganization.withKeptSignIn(
        enter: anyNamed('enter'),
        welcome: anyNamed('welcome'),
        checkDeletion: anyNamed('checkDeletion'),
        onEntering: anyNamed('onEntering'),
      ),
    ).thenAnswer((_) async {
      await pendingEntry?.future;
      return entry;
    });
    when(signOut.call()).thenAnswer((_) async => const Ok(true));
    controller = DeletionPendingViewModel(
      session: session.repository,
      enterOrganization: enterOrganization,
      signOut: signOut,
      repository: repository,
    );
  }

  final SessionDouble session;
  final repository = MockAccountDeletionRepository();
  final enterOrganization = MockEnterOrganization();
  final signOut = MockSignOut();
  late final DeletionPendingViewModel controller;

  /// The `checkDeletion` of every entry, verifying there was at least one.
  List<Object?> checkDeletions() => verify(
    enterOrganization.withKeptSignIn(
      enter: anyNamed('enter'),
      welcome: anyNamed('welcome'),
      checkDeletion: captureAnyNamed('checkDeletion'),
      onEntering: anyNamed('onEntering'),
    ),
  ).captured;
}

void main() {
  provideDummy<Result<void>>(const Ok(null));
  provideDummy<Result<bool>>(const Ok(true));

  group('DeletionPendingViewModel session - Unit Test Suite', () {
    test('Happy Path: opens with the deletion of the session', () {
      // 1. Arrange
      // 2. Act
      final harness = _Harness();

      // 3. Assert
      expect(harness.controller.state.accountDeletion, _kDeletion);
    });

    test('Edge Case: a sign-out running shows isLoggingOut', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.session.leaving.value = SessionExit.signOut;

      // 3. Assert
      expect(harness.controller.state.isLoggingOut, isTrue);
    });

    test('Sad Path: leaving the screen (another session) keeps the '
        'deletion shown', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.session.session.value = const SessionState.signedOut();

      // 3. Assert
      expect(harness.controller.state.accountDeletion, _kDeletion);
    });
  });

  group('DeletionPendingViewModel.cancelAccountDeletion - Unit Test Suite', () {
    test('Happy Path: signs in again, cancels the deletion and marks it '
        'restored', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.controller.cancelAccountDeletion();

      // 3. Assert
      verify(harness.session.repository.keptOrSignIn()).called(1);
      verify(harness.repository.cancel()).called(1);
      expect(harness.controller.state.deletionRestored, isTrue);
      expect(harness.controller.state.deletionError, isEmpty);
      expect(harness.controller.state.cancellingDeletion, isFalse);
    });

    test('Edge Case: a second tap while the cancel runs does nothing', () async {
      // 1. Arrange
      final pendingCancel = Completer<void>();
      final harness = _Harness(pendingCancel: pendingCancel);
      final first = harness.controller.cancelAccountDeletion();
      await pumpEventQueue();
      expect(harness.controller.state.cancellingDeletion, isTrue);

      // 2. Act
      await harness.controller.cancelAccountDeletion();

      // 3. Assert
      verify(harness.repository.cancel()).called(1);
      pendingCancel.complete();
      await first;
    });

    test('Edge Case: no token (the chooser closed) cancels nothing', () async {
      // 1. Arrange
      final harness = _Harness(token: null);

      // 2. Act
      await harness.controller.cancelAccountDeletion();

      // 3. Assert
      verifyNever(harness.repository.cancel());
      expect(harness.controller.state.cancellingDeletion, isFalse);
      expect(harness.controller.state.deletionRestored, isFalse);
    });

    test('Sad Path: an Err from the cancel shows its message and restores '
        'nothing', () async {
      // 1. Arrange
      final harness = _Harness(cancel: const Err('Prazo encerrado.'));

      // 2. Act
      await harness.controller.cancelAccountDeletion();

      // 3. Assert
      expect(harness.controller.state.deletionError, 'Prazo encerrado.');
      expect(harness.controller.state.deletionRestored, isFalse);
      expect(harness.controller.state.cancellingDeletion, isFalse);
    });

    test('Sad Path: a failed Google sign-in shows a generic message and '
        'cancels nothing', () async {
      // 1. Arrange
      final harness = _Harness(signInError: Exception('offline'));

      // 2. Act
      await harness.controller.cancelAccountDeletion();

      // 3. Assert
      verifyNever(harness.repository.cancel());
      expect(
        harness.controller.state.deletionError,
        'Não foi possível cancelar agora. Verifique a conexão e tente '
        'de novo.',
      );
      expect(harness.controller.state.deletionRestored, isFalse);
    });
  });

  group('DeletionPendingViewModel.enter - Unit Test Suite', () {
    test('Happy Path: after the cancel, enters without the deletion check', () async {
      // 1. Arrange
      final harness = _Harness();
      await harness.controller.cancelAccountDeletion();

      // 2. Act
      final result = await harness.controller.enter();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(harness.checkDeletions(), [false]);
      expect(harness.controller.state.isLoading, isFalse);
    });

    test('Edge Case: before any cancel the deletion is checked again', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.controller.enter();

      // 3. Assert
      expect(harness.checkDeletions(), [true]);
    });

    test('Edge Case: a second tap while entering does nothing', () async {
      // 1. Arrange
      final pendingEntry = Completer<void>();
      final harness = _Harness(pendingEntry: pendingEntry);
      final first = harness.controller.enter();
      expect(harness.controller.state.isLoading, isTrue);

      // 2. Act
      final second = await harness.controller.enter();

      // 3. Assert
      expect(second, isA<Ok<void>>());
      expect(harness.checkDeletions(), hasLength(1));
      pendingEntry.complete();
      await first;
    });

    test('Sad Path: a failing entry returns why, titled "Erro de Login"', () async {
      // 1. Arrange
      final harness = _Harness(
        entry: Err('Não foi possível entrar agora', error: Exception('x')),
      );

      // 2. Act
      final result = await harness.controller.enter();

      // 3. Assert
      expect(
        result,
        isA<Err<void>>()
            .having((err) => err.title, 'title', 'Erro de Login')
            .having(
              (err) => err.message,
              'message',
              startsWith('Não foi possível verificar agora'),
            ),
      );
      expect(harness.controller.state.isLoading, isFalse);
    });
  });

  group('DeletionPendingViewModel.logout - Unit Test Suite', () {
    test('Happy Path: "Sair" signs out and returns its result', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final result = await harness.controller.logout();

      // 3. Assert
      expect(result, isA<Ok<bool>>());
      verify(harness.signOut.call()).called(1);
    });
  });
}
