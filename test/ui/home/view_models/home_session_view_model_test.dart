import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/home/view_models/home_session_view_model.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../support/session_double.dart';

@GenerateNiceMocks([MockSpec<OrganizationDirectory>(), MockSpec<SignOut>()])
import 'home_session_view_model_test.mocks.dart';

const _kOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-rotasul',
  messagingSenderId: '111',
);

/// What the directory answers: the user owns `rotasul`, not `verdemar`.
const _kOrganizations = [
  OrganizationCandidate(id: 'rotasul', options: _kOptions, owner: true),
  OrganizationCandidate(id: 'verdemar', options: _kOptions),
];

/// A [HomeSessionViewModel] on the map over a session double and mocks.
class _Harness {
  _Harness() : session = SessionDouble(initial: const SessionState.bound()) {
    when(
      directory.organizationsOfSignedInUser(),
    ).thenAnswer((_) async => _kOrganizations);
    when(signOut.call()).thenAnswer((_) async => const Ok(true));
    when(signOut.switchOrganization()).thenAnswer((_) async => const Ok(null));
    controller = HomeSessionViewModel(
      session: session.repository,
      signOut: signOut,
      directory: directory,
    );
  }

  final SessionDouble session;
  final directory = MockOrganizationDirectory();
  final signOut = MockSignOut();
  late final HomeSessionViewModel controller;
}

void main() {
  provideDummy<Result<void>>(const Ok(null));
  provideDummy<Result<bool>>(const Ok(true));

  group('HomeSessionViewModel leaving - Unit Test Suite', () {
    test('Happy Path: a sign-out running locks the screen, with the '
        'sign-out message', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.session.leaving.value = SessionExit.signOut;

      // 3. Assert
      expect(harness.controller.state.isLoggingOut, isTrue);
      expect(harness.controller.state.isSwitchingOrganization, isFalse);
    });

    test('Happy Path: a switch of organization running locks the screen, '
        'with the switch message', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.session.leaving.value = SessionExit.switchOrganization;

      // 3. Assert
      expect(harness.controller.state.isLoggingOut, isTrue);
      expect(harness.controller.state.isSwitchingOrganization, isTrue);
    });

    test('Edge Case: starts unlocked, and unlocks once the leaving ends', () {
      // 1. Arrange
      final harness = _Harness();
      expect(harness.controller.state.isLoggingOut, isFalse);
      harness.session.leaving.value = SessionExit.signOut;

      // 2. Act
      harness.session.leaving.value = null;

      // 3. Assert
      expect(harness.controller.state.isLoggingOut, isFalse);
    });

    test('Sad Path: a disposed view model stops following the leaving', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.dispose();

      // 2. Act
      harness.session.leaving.value = SessionExit.signOut;

      // 3. Assert
      expect(harness.controller.state.isLoggingOut, isFalse);
    });
  });

  group('HomeSessionViewModel menu actions - Unit Test Suite', () {
    test('Happy Path: "Sair" signs out and returns its result', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final result = await harness.controller.logout.execute();

      // 3. Assert
      expect(result, isA<Ok<bool>>());
      verify(harness.signOut.call()).called(1);
    });

    test('Happy Path: "Trocar de organização" switches and returns its '
        'result', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final result = await harness.controller.switchOrganization.execute();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(harness.signOut.switchOrganization()).called(1);
    });

    test('Sad Path: a failing switch returns its Err', () async {
      // 1. Arrange
      final harness = _Harness();
      when(harness.signOut.switchOrganization()).thenAnswer(
        (_) async => const Err('Sem rede.', title: 'Trocar de organização'),
      );

      // 2. Act
      final result = await harness.controller.switchOrganization.execute();

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.title,
          'title',
          'Trocar de organização',
        ),
      );
    });
  });

  group('HomeSessionViewModel.loadOwnership - Unit Test Suite', () {
    test(
      'Happy Path: the owner of the organization is recorded as such',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.controller.loadOwnership.execute('rotasul');

        // 3. Assert
        expect(harness.controller.state.ownership, {'rotasul': true});
      },
    );

    test('Happy Path: a member who does not own it is recorded as not the '
        'owner', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.controller.loadOwnership.execute('verdemar');

      // 3. Assert
      expect(harness.controller.state.ownership, {'verdemar': false});
    });

    test('Edge Case: an organization already read is not read again, nor '
        'notified', () async {
      // 1. Arrange
      final harness = _Harness();
      await harness.controller.loadOwnership.execute('rotasul');
      var notifications = 0;
      harness.controller.addListener(() => notifications++);

      // 2. Act
      await harness.controller.loadOwnership.execute('rotasul');

      // 3. Assert
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
      expect(notifications, 0);
    });

    test('Edge Case: another organization is read on its own', () async {
      // 1. Arrange
      final harness = _Harness();
      await harness.controller.loadOwnership.execute('rotasul');

      // 2. Act
      await harness.controller.loadOwnership.execute('verdemar');

      // 3. Assert
      verify(harness.directory.organizationsOfSignedInUser()).called(2);
      expect(harness.controller.state.ownership, {
        'rotasul': true,
        'verdemar': false,
      });
    });

    test('Edge Case: a call while one is reading reads nothing', () async {
      // 1. Arrange
      final harness = _Harness();
      final gate = Completer<void>();
      when(harness.directory.organizationsOfSignedInUser()).thenAnswer((
        _,
      ) async {
        await gate.future;
        return _kOrganizations;
      });
      final first = harness.controller.loadOwnership.execute('rotasul');

      // 2. Act
      final second = await harness.controller.loadOwnership.execute('rotasul');

      // 3. Assert
      expect(second, isNull);
      expect(harness.controller.loadOwnership.argument, 'rotasul');
      verify(harness.directory.organizationsOfSignedInUser()).called(1);
      gate.complete();
      await first;
      expect(harness.controller.loadOwnership.argument, isNull);
    });

    test(
      'Edge Case: reading the ownership does not move the session',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.controller.loadOwnership.execute('rotasul');

        // 3. Assert
        expect(harness.session.moves, isEmpty);
      },
    );

    test('Sad Path: a failed read leaves the ownership unknown (hidden) and '
        'notifies nobody', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => throw StateError('offline'));
      var notifications = 0;
      harness.controller.addListener(() => notifications++);

      // 2. Act
      await harness.controller.loadOwnership.execute('rotasul');

      // 3. Assert
      expect(
        harness.controller.state.ownership.containsKey('rotasul'),
        isFalse,
      );
      expect(notifications, 0);
    });

    test('Sad Path: after a failed read the next call tries again', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => throw StateError('offline'));
      await harness.controller.loadOwnership.execute('rotasul');
      when(
        harness.directory.organizationsOfSignedInUser(),
      ).thenAnswer((_) async => _kOrganizations);

      // 2. Act
      await harness.controller.loadOwnership.execute('rotasul');

      // 3. Assert
      verify(harness.directory.organizationsOfSignedInUser()).called(2);
      expect(harness.controller.state.ownership, {'rotasul': true});
    });
  });
}
