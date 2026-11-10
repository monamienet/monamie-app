import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/repositories/sharing_resume/sharing_resume_repository.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_view_model.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([
  MockSpec<PermissionsRepository>(),
  MockSpec<SharingResumeRepository>(),
])
import 'resume_on_restart_view_model_test.mocks.dart';

const _kTexts = SharingResumeTexts(
  notificationTitle: 'Sua localização está sendo compartilhada',
  notificationContent: 'O compartilhamento está ligado.',
  waitingForGps: 'Aguardando o GPS',
  failureChannel: 'Compartilhamento',
  failureTitle: 'Não foi possível retomar o compartilhamento',
  failures: {ResumeFailure.noGroup: 'Você não compartilha em nenhum grupo'},
);

/// The view model's collaborators as mocks whose values are plain
/// [ValueNotifier]s the tests change: the option off, location allowed all
/// the time and the battery not restricted, unless told otherwise.
class _Harness {
  _Harness({
    bool available = true,
    bool enabled = false,
    bool always = true,
    bool restricted = false,
  }) : resumeOnRestart = ValueNotifier(enabled),
       hasAlways = ValueNotifier(always),
       isRestricted = ValueNotifier(restricted) {
    when(repository.resumeOnRestart).thenReturn(resumeOnRestart);
    when(permissions.hasAlwaysLocationPermission).thenReturn(hasAlways);
    when(permissions.isBackgroundRestricted).thenReturn(isRestricted);
    when(repository.setResumeOnRestart(any)).thenAnswer((invocation) async {
      resumeOnRestart.value = invocation.positionalArguments.single as bool;
      return const Ok(null);
    });
    viewModel = ResumeOnRestartViewModel(
      repository: repository,
      permissions: permissions,
      available: available,
    );
  }

  final repository = MockSharingResumeRepository();
  final permissions = MockPermissionsRepository();
  final ValueNotifier<bool> resumeOnRestart;
  final ValueNotifier<bool> hasAlways;
  final ValueNotifier<bool> isRestricted;
  late final ResumeOnRestartViewModel viewModel;

  /// How many times the view model notified from now on.
  int Function() countNotifications() {
    var count = 0;
    viewModel.addListener(() => count++);
    return () => count;
  }
}

void main() {
  provideDummy<Result<void>>(const Ok(null));

  group('ResumeOnRestartViewModel.state - Unit Test Suite', () {
    test('Happy Path: starts with the option the repository holds', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(enabled: true);

      // 3. Assert
      expect(
        harness.viewModel.state,
        const ResumeOnRestartState(available: true, enabled: true),
      );
      harness.viewModel.dispose();
    });

    test('Edge Case: an unavailable device (web, iOS) says so', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(available: false);

      // 3. Assert
      expect(harness.viewModel.state.available, isFalse);
      harness.viewModel.dispose();
    });

    test('Happy Path: with the option on and location not allowed all the '
        'time, the blocker is the location', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(enabled: true, always: false);

      // 3. Assert
      expect(harness.viewModel.state.blocker, ResumeBlocker.alwaysLocation);
      harness.viewModel.dispose();
    });

    test('Happy Path: with the option on and the battery restricted, the '
        'blocker is the battery', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(enabled: true, restricted: true);

      // 3. Assert
      expect(harness.viewModel.state.blocker, ResumeBlocker.batteryRestricted);
      harness.viewModel.dispose();
    });

    test('Edge Case: location is named before the battery when both '
        'block', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(enabled: true, always: false, restricted: true);

      // 3. Assert
      expect(harness.viewModel.state.blocker, ResumeBlocker.alwaysLocation);
      harness.viewModel.dispose();
    });

    test('Edge Case: nothing blocks while the option is off', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(always: false, restricted: true);

      // 3. Assert
      expect(harness.viewModel.state.blocker, isNull);
      harness.viewModel.dispose();
    });

    test('Edge Case: nothing blocks on a device that cannot resume, even '
        'with the option stored on', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(
        available: false,
        enabled: true,
        always: false,
        restricted: true,
      );

      // 3. Assert
      expect(harness.viewModel.state.blocker, isNull);
      harness.viewModel.dispose();
    });

    test('Edge Case: nothing blocks with the option on and everything '
        'allowed', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(enabled: true);

      // 3. Assert
      expect(harness.viewModel.state.blocker, isNull);
      harness.viewModel.dispose();
    });

    test('Happy Path: follows the permissions: granting location all the '
        'time removes the blocker and notifies', () {
      // 1. Arrange
      final harness = _Harness(enabled: true, always: false);
      final notifications = harness.countNotifications();

      // 2. Act
      harness.hasAlways.value = true;

      // 3. Assert
      expect(harness.viewModel.state.blocker, isNull);
      expect(notifications(), 1);
      harness.viewModel.dispose();
    });

    test('Happy Path: follows the battery: a restriction appearing shows '
        'the blocker', () {
      // 1. Arrange
      final harness = _Harness(enabled: true);

      // 2. Act
      harness.isRestricted.value = true;

      // 3. Assert
      expect(harness.viewModel.state.blocker, ResumeBlocker.batteryRestricted);
      harness.viewModel.dispose();
    });

    test('Edge Case: a permission change while the option is off does not '
        'notify', () {
      // 1. Arrange
      final harness = _Harness(always: false);
      final notifications = harness.countNotifications();

      // 2. Act
      harness.hasAlways.value = true;
      harness.isRestricted.value = true;

      // 3. Assert
      expect(notifications(), 0);
      harness.viewModel.dispose();
    });

    test('Edge Case: the battery changing behind a location blocker does '
        'not notify', () {
      // 1. Arrange
      final harness = _Harness(enabled: true, always: false);
      final notifications = harness.countNotifications();

      // 2. Act
      harness.isRestricted.value = true;

      // 3. Assert
      expect(harness.viewModel.state.blocker, ResumeBlocker.alwaysLocation);
      expect(notifications(), 0);
      harness.viewModel.dispose();
    });
  });

  group('ResumeOnRestartViewModel.load - Unit Test Suite', () {
    test('Happy Path: reads the stored option', () async {
      // 1. Arrange
      final harness = _Harness();
      when(harness.repository.restore()).thenAnswer((_) async {
        harness.resumeOnRestart.value = true;
      });

      // 2. Act
      final result = await harness.viewModel.load.execute();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(harness.repository.restore()).called(1);
      expect(harness.viewModel.state.enabled, isTrue);
      harness.viewModel.dispose();
    });

    test('Edge Case: reads nothing on a device that cannot resume', () async {
      // 1. Arrange
      final harness = _Harness(available: false);

      // 2. Act
      await harness.viewModel.load.execute();

      // 3. Assert
      verifyNever(harness.repository.restore());
      harness.viewModel.dispose();
    });
  });

  group('ResumeOnRestartViewModel.setEnabled - Unit Test Suite', () {
    test('Happy Path: stores the choice and shows it on', () async {
      // 1. Arrange
      final harness = _Harness();
      final notifications = harness.countNotifications();

      // 2. Act
      final result = await harness.viewModel.setEnabled.execute(true);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(harness.repository.setResumeOnRestart(true)).called(1);
      expect(harness.viewModel.state.enabled, isTrue);
      expect(notifications(), 1);
      harness.viewModel.dispose();
    });

    test('Happy Path: turning it on with location not allowed all the time '
        'keeps it on and shows the blocker', () async {
      // 1. Arrange
      final harness = _Harness(always: false);

      // 2. Act
      await harness.viewModel.setEnabled.execute(true);

      // 3. Assert
      expect(
        harness.viewModel.state,
        const ResumeOnRestartState(
          available: true,
          enabled: true,
          blocker: ResumeBlocker.alwaysLocation,
        ),
      );
      verifyNever(harness.permissions.requestAlwaysPermission());
      harness.viewModel.dispose();
    });

    test('Happy Path: turning it off removes the blocker', () async {
      // 1. Arrange
      final harness = _Harness(enabled: true, restricted: true);

      // 2. Act
      await harness.viewModel.setEnabled.execute(false);

      // 3. Assert
      expect(
        harness.viewModel.state,
        const ResumeOnRestartState(available: true, enabled: false),
      );
      harness.viewModel.dispose();
    });

    test('Edge Case: running while the choice is stored, and a second tap '
        'meanwhile is ignored', () async {
      // 1. Arrange
      final harness = _Harness();
      final stored = Completer<Result<void>>();
      when(
        harness.repository.setResumeOnRestart(any),
      ).thenAnswer((_) => stored.future);
      final first = harness.viewModel.setEnabled.execute(true);

      // 2. Act
      final second = await harness.viewModel.setEnabled.execute(false);

      // 3. Assert
      expect(harness.viewModel.setEnabled.running, isTrue);
      expect(second, isNull);
      verify(harness.repository.setResumeOnRestart(true)).called(1);
      stored.complete(const Ok(null));
      await first;
      expect(harness.viewModel.setEnabled.running, isFalse);
      harness.viewModel.dispose();
    });

    test('Sad Path: a failing store returns its Err and keeps the choice as '
        'it was, without notifying', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.repository.setResumeOnRestart(any),
      ).thenAnswer((_) async => const Err(Failure.resumeOptionNotSaved()));
      final notifications = harness.countNotifications();

      // 2. Act
      final result = await harness.viewModel.setEnabled.execute(true);

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.failure,
          'failure',
          const Failure.resumeOptionNotSaved(),
        ),
      );
      expect(harness.viewModel.state.enabled, isFalse);
      expect(notifications(), 0);
      harness.viewModel.dispose();
    });

    test('Edge Case: changing the option starts or stops nothing: only the '
        'repository is asked to store it', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.viewModel.setEnabled.execute(true);

      // 3. Assert
      verifyNever(harness.repository.saveIntent(any));
      verifyNever(harness.repository.clearIntent());
      harness.viewModel.dispose();
    });
  });

  group('ResumeOnRestartViewModel.resolveBlocker - Unit Test Suite', () {
    test('Happy Path: asks for location all the time when that is the '
        'blocker', () async {
      // 1. Arrange
      final harness = _Harness(enabled: true, always: false, restricted: true);

      // 2. Act
      final result = await harness.viewModel.resolveBlocker.execute();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(harness.permissions.requestAlwaysPermission()).called(1);
      verifyNever(harness.permissions.openBackgroundUsageSettings());
      harness.viewModel.dispose();
    });

    test("Happy Path: opens the app's battery settings when the battery is "
        'the blocker', () async {
      // 1. Arrange
      final harness = _Harness(enabled: true, restricted: true);

      // 2. Act
      await harness.viewModel.resolveBlocker.execute();

      // 3. Assert
      verify(harness.permissions.openBackgroundUsageSettings()).called(1);
      verifyNever(harness.permissions.requestAlwaysPermission());
      harness.viewModel.dispose();
    });

    test('Edge Case: does nothing when nothing blocks', () async {
      // 1. Arrange
      final harness = _Harness(enabled: true);

      // 2. Act
      final result = await harness.viewModel.resolveBlocker.execute();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyNever(harness.permissions.requestAlwaysPermission());
      verifyNever(harness.permissions.openBackgroundUsageSettings());
      harness.viewModel.dispose();
    });

    test('Edge Case: does nothing while the option is off, whatever the '
        'permissions', () async {
      // 1. Arrange
      final harness = _Harness(always: false, restricted: true);

      // 2. Act
      await harness.viewModel.resolveBlocker.execute();

      // 3. Assert
      verifyNever(harness.permissions.requestAlwaysPermission());
      verifyNever(harness.permissions.openBackgroundUsageSettings());
      harness.viewModel.dispose();
    });
  });

  group('ResumeOnRestartViewModel.storeTexts - Unit Test Suite', () {
    test('Happy Path: stores the texts', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.viewModel.storeTexts(_kTexts);

      // 3. Assert
      verify(harness.repository.saveTexts(_kTexts)).called(1);
      harness.viewModel.dispose();
    });

    test('Happy Path: stores them whether the option is on or off', () async {
      // 1. Arrange
      final harness = _Harness(enabled: false);

      // 2. Act
      await harness.viewModel.storeTexts(_kTexts);

      // 3. Assert
      verify(harness.repository.saveTexts(_kTexts)).called(1);
      harness.viewModel.dispose();
    });

    test('Edge Case: stores nothing on a device that cannot resume', () async {
      // 1. Arrange
      final harness = _Harness(available: false);

      // 2. Act
      await harness.viewModel.storeTexts(_kTexts);

      // 3. Assert
      verifyNever(harness.repository.saveTexts(any));
      harness.viewModel.dispose();
    });

    test('Sad Path: a failing store is only logged', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.repository.saveTexts(any),
      ).thenThrow(StateError('SharedPreferences indisponível'));

      // 2. Act and 3. Assert: it completes without throwing.
      await expectLater(harness.viewModel.storeTexts(_kTexts), completes);
      harness.viewModel.dispose();
    });

    test('Edge Case: texts of a second language change made while the first '
        'ones are being stored are stored too', () async {
      // 1. Arrange
      final harness = _Harness();
      final firstStored = Completer<void>();
      when(
        harness.repository.saveTexts(_kTexts),
      ).thenAnswer((_) => firstStored.future);
      const english = SharingResumeTexts(
        notificationTitle: 'Your location is being shared',
        notificationContent: 'Sharing is on.',
        waitingForGps: 'Waiting for GPS',
        failureChannel: 'Sharing',
        failureTitle: 'Sharing could not resume',
        failures: {ResumeFailure.noGroup: 'You share in no group'},
      );
      final first = harness.viewModel.storeTexts(_kTexts);

      // 2. Act
      final second = harness.viewModel.storeTexts(english);
      firstStored.complete();
      await first;
      await second;
      await pumpEventQueue();

      // 3. Assert
      verify(harness.repository.saveTexts(english)).called(1);
      harness.viewModel.dispose();
    });
  });

  group('ResumeOnRestartViewModel.dispose - Unit Test Suite', () {
    test('Happy Path: stops following the repository and the '
        'permissions', () {
      // 1. Arrange
      final harness = _Harness(always: false);
      final before = harness.viewModel.state;

      // 2. Act
      harness.viewModel.dispose();
      harness.resumeOnRestart.value = true;
      harness.hasAlways.value = true;
      harness.isRestricted.value = true;

      // 3. Assert
      expect(harness.viewModel.state, before);
    });

    test('Edge Case: a second dispose does nothing', () {
      // 1. Arrange
      final harness = _Harness();
      harness.viewModel.dispose();

      // 2. Act / 3. Assert
      expect(harness.viewModel.dispose, returnsNormally);
    });
  });
}
