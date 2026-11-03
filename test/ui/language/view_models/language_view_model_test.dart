import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/language/language_repository.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<LanguageRepository>()])
import 'language_view_model_test.mocks.dart';

const _brazilian = Locale('pt', 'BR');
const _german = Locale('de', 'DE');

/// A [ValueNotifier] that counts the listeners it has.
class _CountingNotifier extends ValueNotifier<AppLanguage?> {
  _CountingNotifier(super.value);

  int listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }
}

/// A [LanguageViewModel] over a mocked [LanguageRepository] whose `language`
/// is the [chosen] notifier the test controls, and over [deviceLocales], the
/// list the device's languages come from (replace its content to simulate the
/// person changing the device's language).
class _Harness {
  _Harness({
    AppLanguage? chosenLanguage,
    List<Locale> deviceLocales = const [_brazilian],
  }) : chosen = _CountingNotifier(chosenLanguage),
       device = List.of(deviceLocales) {
    when(repository.language).thenReturn(chosen);
    when(repository.choose(any)).thenAnswer((_) async => const Ok<void>(null));
    controller = LanguageViewModel(
      repository: repository,
      deviceLocales: () => device,
    );
    controller.addListener(() => notifications++);
  }

  final repository = MockLanguageRepository();
  final _CountingNotifier chosen;
  final List<Locale> device;
  late final LanguageViewModel controller;

  /// How many times the view model told its listeners about a change.
  int notifications = 0;
}

void main() {
  provideDummy<Result<void>>(const Ok(null));

  group('LanguageViewModel.state - Unit Test Suite', () {
    test(
      'Happy Path: a Brazilian Portuguese device with no choice is in Portuguese',
      () {
        // 1. Arrange / 2. Act
        final harness = _Harness();

        // 3. Assert
        expect(harness.controller.state.inUse, AppLanguage.pt);
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: a device language the app does not have is in English',
      () {
        // 1. Arrange / 2. Act
        final harness = _Harness(deviceLocales: const [_german]);

        // 3. Assert
        expect(harness.controller.state.inUse, AppLanguage.en);
        harness.controller.dispose();
      },
    );

    test('Happy Path: a Spanish device is in Spanish', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(deviceLocales: const [Locale('es', 'MX')]);

      // 3. Assert
      expect(harness.controller.state.inUse, AppLanguage.es);
      harness.controller.dispose();
    });

    test('Edge Case: a device language the app does not have, then Spanish, '
        'gets Spanish', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(
        deviceLocales: const [Locale('fr', 'FR'), Locale('es', 'ES')],
      );

      // 3. Assert
      expect(harness.controller.state.inUse, AppLanguage.es);
      harness.controller.dispose();
    });

    test('Edge Case: the first device language the app has wins', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(
        deviceLocales: const [_german, Locale('pt', 'PT')],
      );

      // 3. Assert
      expect(harness.controller.state.inUse, AppLanguage.pt);
      harness.controller.dispose();
    });

    test('Happy Path: the choice wins over the device languages', () {
      // 1. Arrange / 2. Act
      final harness = _Harness(chosenLanguage: AppLanguage.en);

      // 3. Assert
      expect(harness.controller.state.inUse, AppLanguage.en);
      harness.controller.dispose();
    });

    test('Happy Path: a change of the repository value updates the state and '
        'notifies once', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      harness.chosen.value = AppLanguage.en;

      // 3. Assert
      expect(harness.controller.state.inUse, AppLanguage.en);
      expect(harness.notifications, 1);
      harness.controller.dispose();
    });

    test('Edge Case: a choice equal to the language already in use does not '
        'notify', () {
      // 1. Arrange: Portuguese in use through the device's language.
      final harness = _Harness();

      // 2. Act
      harness.chosen.value = AppLanguage.pt;

      // 3. Assert
      expect(harness.controller.state.inUse, AppLanguage.pt);
      expect(harness.notifications, 0);
      harness.controller.dispose();
    });

    test(
      'Edge Case: forgetting the choice goes back to the device language',
      () {
        // 1. Arrange
        final harness = _Harness(chosenLanguage: AppLanguage.en);

        // 2. Act
        harness.chosen.value = null;

        // 3. Assert
        expect(harness.controller.state.inUse, AppLanguage.pt);
        expect(harness.notifications, 1);
        harness.controller.dispose();
      },
    );
  });

  group('LanguageViewModel.load - Unit Test Suite', () {
    test(
      'Happy Path: reads the device languages again and notifies once',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.device
          ..clear()
          ..add(const Locale('en', 'US'));

        // 2. Act
        final result = await harness.controller.load.execute();

        // 3. Assert
        expect(result, isA<Ok<void>>());
        expect(harness.controller.state.inUse, AppLanguage.en);
        expect(harness.notifications, 1);
        harness.controller.dispose();
      },
    );

    test('Edge Case: unchanged device languages do not notify', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      await harness.controller.load.execute();

      // 3. Assert
      expect(harness.controller.state.inUse, AppLanguage.pt);
      expect(harness.notifications, 0);
      harness.controller.dispose();
    });

    test(
      'Edge Case: a language chosen is not overridden by the device',
      () async {
        // 1. Arrange
        final harness = _Harness(chosenLanguage: AppLanguage.pt);
        harness.device
          ..clear()
          ..add(const Locale('en'));

        // 2. Act
        await harness.controller.load.execute();

        // 3. Assert
        expect(harness.controller.state.inUse, AppLanguage.pt);
        harness.controller.dispose();
      },
    );
  });

  group('LanguageViewModel.choose - Unit Test Suite', () {
    test('Happy Path: delegates the language to the repository', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final result = await harness.controller.choose.execute(AppLanguage.en);

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verify(harness.repository.choose(AppLanguage.en)).called(1);
      harness.controller.dispose();
    });

    test('Sad Path: returns the repository Err as it is', () async {
      // 1. Arrange
      final harness = _Harness();
      const failure = Failure.languageNotSaved();
      when(
        harness.repository.choose(any),
      ).thenAnswer((_) async => const Err<void>(failure));

      // 2. Act
      final result = await harness.controller.choose.execute(AppLanguage.en);

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having((err) => err.failure, 'failure', failure),
      );
      expect(harness.controller.choose.error, isTrue);
      expect(harness.controller.state.inUse, AppLanguage.pt);
      harness.controller.dispose();
    });

    test(
      'Edge Case: tells which language is being stored while it runs',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final answer = Completer<Result<void>>();
        when(harness.repository.choose(any)).thenAnswer((_) => answer.future);

        // 2. Act
        final pending = harness.controller.choose.execute(AppLanguage.en);

        // 3. Assert
        expect(harness.controller.choose.running, isTrue);
        expect(harness.controller.choose.argument, AppLanguage.en);
        expect(await harness.controller.choose.execute(AppLanguage.pt), isNull);
        verify(harness.repository.choose(any)).called(1);
        answer.complete(const Ok(null));
        await pending;
        expect(harness.controller.choose.running, isFalse);
        harness.controller.dispose();
      },
    );
  });

  group('LanguageViewModel.dispose - Unit Test Suite', () {
    test('Happy Path: stops listening to the repository', () {
      // 1. Arrange
      final harness = _Harness();
      expect(harness.chosen.listeners, 1);

      // 2. Act
      harness.controller.dispose();

      // 3. Assert
      expect(harness.chosen.listeners, 0);
    });

    test('Edge Case: a change of the repository after dispose is ignored', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.dispose();

      // 2. Act / 3. Assert: no listener is left to throw or to be notified.
      expect(() => harness.chosen.value = AppLanguage.en, returnsNormally);
      expect(harness.notifications, 0);
    });

    test('Edge Case: disposing twice does nothing the second time', () {
      // 1. Arrange
      final harness = _Harness();
      harness.controller.dispose();

      // 2. Act / 3. Assert
      expect(harness.controller.dispose, returnsNormally);
    });
  });
}
