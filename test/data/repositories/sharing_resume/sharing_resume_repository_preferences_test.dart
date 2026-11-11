import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/repositories/sharing_resume/sharing_resume_repository_preferences.dart';
import 'package:monamie_app/data/services/sharing_resume_preferences_service.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform interface is a transitive dependency of shared_preferences
// and provides its official in-memory backend for tests.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';

const _kIntent = SharingIntent(email: 'ana@example.com', name: 'Ana Souza');

const _kTexts = SharingResumeTexts(
  notificationTitle: 'Sua localização está sendo compartilhada',
  notificationContent: 'O compartilhamento está ligado.',
  failureChannel: 'Compartilhamento',
  failureTitle: 'Não foi possível retomar o compartilhamento',
  failures: {
    ResumeFailure.backgroundLocation: 'Precisa da localização o tempo todo',
    ResumeFailure.batteryRestricted: 'A bateria do app está em Restrito',
    ResumeFailure.locationOff: 'A localização do aparelho está desligada',
    ResumeFailure.signedOut: 'Você saiu da conta',
    ResumeFailure.noGroup: 'Você não compartilha em nenhum grupo',
  },
);

/// An in-memory storage whose reads and writes fail, as a broken device
/// storage would.
final class _BrokenPreferences extends InMemorySharedPreferencesAsync {
  _BrokenPreferences() : super.empty();

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) async => throw StateError('disk full');

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async =>
      throw StateError('unreadable');

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async => throw StateError('disk full');

  @override
  Future<bool> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async => throw StateError('disk full');
}

/// A repository over the real service, as `appDependencies` builds it.
SharingResumeRepositoryPreferences _repository() =>
    SharingResumeRepositoryPreferences(
      service: SharingResumePreferencesService(),
    );

/// What is stored under [key], as the native side reads it.
Future<Object?> _stored(String key) async =>
    (await SharedPreferencesAsync().getAll(allowList: {key}))[key];

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('SharingResumeRepositoryPreferences.restore - Unit Test Suite', () {
    test('Happy Path: the option is off before restore', () {
      // 1. Arrange / 2. Act
      final repository = _repository();

      // 3. Assert
      expect(repository.resumeOnRestart.value, isFalse);
    });

    test('Happy Path: restore reads the stored option', () async {
      // 1. Arrange
      await _repository().setResumeOnRestart(true);
      final relaunched = _repository();

      // 2. Act
      await relaunched.restore();

      // 3. Assert
      expect(relaunched.resumeOnRestart.value, isTrue);
    });

    test('Edge Case: nothing stored leaves the option off', () async {
      // 1. Arrange
      final repository = _repository();

      // 2. Act
      await repository.restore();

      // 3. Assert
      expect(repository.resumeOnRestart.value, isFalse);
    });

    test('Sad Path: an unreadable storage leaves the option off without '
        'throwing', () async {
      // 1. Arrange
      SharedPreferencesAsyncPlatform.instance = _BrokenPreferences();
      final repository = _repository();

      // 2. Act
      await repository.restore();

      // 3. Assert
      expect(repository.resumeOnRestart.value, isFalse);
    });
  });

  group(
    'SharingResumeRepositoryPreferences.setResumeOnRestart - Unit Test Suite',
    () {
      test('Happy Path: uses and stores the option under the native '
          'key', () async {
        // 1. Arrange
        final repository = _repository();

        // 2. Act
        final result = await repository.setResumeOnRestart(true);

        // 3. Assert
        expect(result, isA<Ok<void>>());
        expect(repository.resumeOnRestart.value, isTrue);
        expect(await _stored(sharingResumeOptionKey), isTrue);
      });

      test('Happy Path: turning it off stores false', () async {
        // 1. Arrange
        final repository = _repository();
        await repository.setResumeOnRestart(true);

        // 2. Act
        await repository.setResumeOnRestart(false);

        // 3. Assert
        expect(repository.resumeOnRestart.value, isFalse);
        expect(await _stored(sharingResumeOptionKey), isFalse);
      });

      test('Edge Case: storing the same value notifies once', () async {
        // 1. Arrange
        final repository = _repository();
        var notifications = 0;
        repository.resumeOnRestart.addListener(() => notifications++);

        // 2. Act
        await repository.setResumeOnRestart(true);
        await repository.setResumeOnRestart(true);

        // 3. Assert
        expect(notifications, 1);
      });

      test('Sad Path: a failing write returns resumeOptionNotSaved and keeps '
          'the option as it was', () async {
        // 1. Arrange
        SharedPreferencesAsyncPlatform.instance = _BrokenPreferences();
        final repository = _repository();
        var notifications = 0;
        repository.resumeOnRestart.addListener(() => notifications++);

        // 2. Act
        final result = await repository.setResumeOnRestart(true);

        // 3. Assert
        expect(
          result,
          isA<Err<void>>()
              .having(
                (err) => err.failure,
                'failure',
                const Failure.resumeOptionNotSaved(),
              )
              .having((err) => err.error, 'error', isA<StateError>()),
        );
        expect(repository.resumeOnRestart.value, isFalse);
        expect(notifications, 0);
      });
    },
  );

  group('SharingResumeRepositoryPreferences - intent - Unit Test Suite', () {
    test('Happy Path: saveIntent stores {email, name} as JSON under the '
        'native key', () async {
      // 1. Arrange
      final repository = _repository();

      // 2. Act
      await repository.saveIntent(_kIntent);

      // 3. Assert
      final raw = await _stored(sharingResumeIntentKey);
      expect(jsonDecode(raw! as String), {
        'email': 'ana@example.com',
        'name': 'Ana Souza',
      });
      expect(await SharingResumePreferencesService().readIntent(), (
        email: 'ana@example.com',
        name: 'Ana Souza',
      ));
    });

    test('Happy Path: clearIntent removes the intent', () async {
      // 1. Arrange
      final repository = _repository();
      await repository.saveIntent(_kIntent);

      // 2. Act
      await repository.clearIntent();

      // 3. Assert
      expect(await _stored(sharingResumeIntentKey), isNull);
      expect(await SharingResumePreferencesService().readIntent(), isNull);
    });

    test('Edge Case: clearing the intent keeps the option', () async {
      // 1. Arrange
      final repository = _repository();
      await repository.setResumeOnRestart(true);
      await repository.saveIntent(_kIntent);

      // 2. Act
      await repository.clearIntent();

      // 3. Assert
      expect(await _stored(sharingResumeOptionKey), isTrue);
    });

    test('Edge Case: names with quotes and accents survive the JSON', () async {
      // 1. Arrange
      final repository = _repository();
      const intent = SharingIntent(
        email: 'joao@example.com',
        name: 'João "Jota" d\'Ávila',
      );

      // 2. Act
      await repository.saveIntent(intent);

      // 3. Assert
      expect(await SharingResumePreferencesService().readIntent(), (
        email: intent.email,
        name: intent.name,
      ));
    });

    test('Sad Path: saveIntent throws when the storage fails', () async {
      // 1. Arrange
      SharedPreferencesAsyncPlatform.instance = _BrokenPreferences();
      final repository = _repository();

      // 2. Act
      final saving = repository.saveIntent(_kIntent);

      // 3. Assert
      await expectLater(saving, throwsStateError);
    });
  });

  group('SharingResumeRepositoryPreferences.saveTexts - Unit Test Suite', () {
    test('Happy Path: stores every text as JSON, the failures by their '
        'ResumeFailure name', () async {
      // 1. Arrange
      final repository = _repository();

      // 2. Act
      await repository.saveTexts(_kTexts);

      // 3. Assert
      final raw = await _stored(sharingResumeTextsKey);
      expect(jsonDecode(raw! as String), {
        'notificationTitle': 'Sua localização está sendo compartilhada',
        'notificationContent': 'O compartilhamento está ligado.',
        'failureChannel': 'Compartilhamento',
        'failureTitle': 'Não foi possível retomar o compartilhamento',
        'failures': {
          'backgroundLocation': 'Precisa da localização o tempo todo',
          'batteryRestricted': 'A bateria do app está em Restrito',
          'locationOff': 'A localização do aparelho está desligada',
          'signedOut': 'Você saiu da conta',
          'noGroup': 'Você não compartilha em nenhum grupo',
        },
      });
    });

    test('Happy Path: the failure names are the ones the native side '
        'knows', () async {
      // 1. Arrange
      final repository = _repository();

      // 2. Act
      await repository.saveTexts(_kTexts);

      // 3. Assert
      final texts = await SharingResumePreferencesService().readTexts();
      final failures = texts!['failures']! as Map<String, Object?>;
      // `ResumeDecision.BACKGROUND_LOCATION`, `BATTERY_RESTRICTED` and
      // `LOCATION_OFF` in ResumeDecision.kt.
      expect(
        failures.keys,
        containsAll(['backgroundLocation', 'batteryRestricted', 'locationOff']),
      );
    });

    test('Happy Path: stores the location-off text and no text for '
        'waiting for the GPS', () async {
      // 1. Arrange
      final repository = _repository();

      // 2. Act
      await repository.saveTexts(_kTexts);

      // 3. Assert
      final texts = await SharingResumePreferencesService().readTexts();
      final failures = texts!['failures']! as Map<String, Object?>;
      expect(
        failures['locationOff'],
        'A localização do aparelho está desligada',
      );
      expect(texts.keys, isNot(contains('waitingForGps')));
      expect(failures.keys, isNot(contains('waitingForGps')));
    });

    test('Edge Case: saving again replaces the texts', () async {
      // 1. Arrange
      final repository = _repository();
      await repository.saveTexts(_kTexts);
      const english = SharingResumeTexts(
        notificationTitle: 'Your location is being shared',
        notificationContent: 'Sharing is on.',
        failureChannel: 'Sharing',
        failureTitle: 'Sharing could not resume',
        failures: {ResumeFailure.noGroup: 'You share in no group'},
      );

      // 2. Act
      await repository.saveTexts(english);

      // 3. Assert
      final texts = await SharingResumePreferencesService().readTexts();
      expect(texts!['notificationTitle'], 'Your location is being shared');
      expect(texts['failures'], {'noGroup': 'You share in no group'});
    });

    test('Sad Path: saveTexts throws when the storage fails', () async {
      // 1. Arrange
      SharedPreferencesAsyncPlatform.instance = _BrokenPreferences();
      final repository = _repository();

      // 2. Act
      final saving = repository.saveTexts(_kTexts);

      // 3. Assert
      await expectLater(saving, throwsStateError);
    });
  });
}
