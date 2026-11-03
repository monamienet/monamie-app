import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/app_language.dart';

void main() {
  group('AppLanguage - Unit Test Suite', () {
    test('Happy Path: each language has its locale, Portuguese Brazilian', () {
      // 1. Arrange / 2. Act
      final locales = {
        for (final language in AppLanguage.values) language: language.locale,
      };

      // 3. Assert
      expect(locales, {
        AppLanguage.pt: const Locale('pt', 'BR'),
        AppLanguage.en: const Locale('en'),
      });
    });

    test('Happy Path: English is the fallback', () {
      // 1. Arrange / 2. Act
      const fallback = AppLanguage.fallback;

      // 3. Assert
      expect(fallback, AppLanguage.en);
    });
  });

  group('AppLanguage.tryParse - Unit Test Suite', () {
    for (final language in AppLanguage.values) {
      test('Happy Path: "${language.name}" gives $language', () {
        // 1. Arrange
        final name = language.name;

        // 2. Act
        final parsed = AppLanguage.tryParse(name);

        // 3. Assert
        expect(parsed, language);
      });
    }

    test('Edge Case: null gives null', () {
      // 1. Arrange / 2. Act
      final parsed = AppLanguage.tryParse(null);

      // 3. Assert
      expect(parsed, isNull);
    });

    test('Sad Path: a name this build does not have gives null', () {
      // 1. Arrange
      const names = ['es', '', 'PT', 'pt_BR'];

      // 2. Act
      final parsed = [for (final name in names) AppLanguage.tryParse(name)];

      // 3. Assert
      expect(parsed, everyElement(isNull));
    });
  });

  group('AppLanguage.resolve - Unit Test Suite', () {
    test('Happy Path: Brazilian Portuguese resolves to Portuguese', () {
      // 1. Arrange / 2. Act
      final language = AppLanguage.resolve(const [Locale('pt', 'BR')]);

      // 3. Assert
      expect(language, AppLanguage.pt);
    });

    test('Happy Path: English from any country resolves to English', () {
      // 1. Arrange / 2. Act
      final language = AppLanguage.resolve(const [Locale('en', 'US')]);

      // 3. Assert
      expect(language, AppLanguage.en);
    });

    test('Edge Case: Portuguese from Portugal resolves to Brazilian '
        'Portuguese', () {
      // 1. Arrange / 2. Act
      final language = AppLanguage.resolve(const [Locale('pt', 'PT')]);

      // 3. Assert
      expect(language, AppLanguage.pt);
      expect(language.locale, const Locale('pt', 'BR'));
    });

    test('Edge Case: a language the app does not have resolves to English', () {
      // 1. Arrange / 2. Act
      final german = AppLanguage.resolve(const [Locale('de', 'DE')]);
      final spanish = AppLanguage.resolve(const [Locale('es', 'ES')]);

      // 3. Assert
      expect(german, AppLanguage.en);
      expect(spanish, AppLanguage.en);
    });

    test('Edge Case: the first language the app has wins, in the order of '
        'the device', () {
      // 1. Arrange / 2. Act
      final skipsGerman = AppLanguage.resolve(const [
        Locale('de'),
        Locale('pt', 'BR'),
      ]);
      final englishFirst = AppLanguage.resolve(const [
        Locale('en', 'GB'),
        Locale('pt', 'BR'),
      ]);

      // 3. Assert
      expect(skipsGerman, AppLanguage.pt);
      expect(englishFirst, AppLanguage.en);
    });

    test('Edge Case: no device language resolves to English', () {
      // 1. Arrange / 2. Act
      final language = AppLanguage.resolve(const []);

      // 3. Assert
      expect(language, AppLanguage.en);
    });
  });
}
