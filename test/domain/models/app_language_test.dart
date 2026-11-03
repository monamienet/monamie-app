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
        AppLanguage.es: const Locale('es'),
      });
    });

    test('Happy Path: Spanish is the neutral one, without a country', () {
      // 1. Arrange / 2. Act
      final locale = AppLanguage.es.locale;

      // 3. Assert
      expect(locale, const Locale('es'));
      expect(locale.countryCode, isNull);
    });

    test('Happy Path: the languages come in the order pt, en, es', () {
      // 1. Arrange / 2. Act
      final values = AppLanguage.values;

      // 3. Assert
      expect(values, [AppLanguage.pt, AppLanguage.en, AppLanguage.es]);
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
      const names = ['fr', '', 'PT', 'ES', 'pt_BR', 'es_MX'];

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

    test('Happy Path: Spanish from any country resolves to Spanish', () {
      // 1. Arrange / 2. Act
      final spain = AppLanguage.resolve(const [Locale('es', 'ES')]);
      final mexico = AppLanguage.resolve(const [Locale('es', 'MX')]);
      final plain = AppLanguage.resolve(const [Locale('es')]);

      // 3. Assert
      expect(spain, AppLanguage.es);
      expect(mexico, AppLanguage.es);
      expect(plain, AppLanguage.es);
      expect(spain.locale, const Locale('es'));
    });

    test('Edge Case: a language the app does not have resolves to English', () {
      // 1. Arrange / 2. Act
      final german = AppLanguage.resolve(const [Locale('de', 'DE')]);
      final french = AppLanguage.resolve(const [Locale('fr', 'FR')]);

      // 3. Assert
      expect(german, AppLanguage.en);
      expect(french, AppLanguage.en);
    });

    test('Edge Case: [de, es] skips German and gets Spanish, [de, fr] gets '
        'English', () {
      // 1. Arrange / 2. Act
      final skipsGerman = AppLanguage.resolve(const [
        Locale('de'),
        Locale('es'),
      ]);
      final noneOffered = AppLanguage.resolve(const [
        Locale('de'),
        Locale('fr'),
      ]);

      // 3. Assert
      expect(skipsGerman, AppLanguage.es);
      expect(noneOffered, AppLanguage.en);
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
      final spanishFirst = AppLanguage.resolve(const [
        Locale('es', 'MX'),
        Locale('en', 'US'),
      ]);

      // 3. Assert
      expect(skipsGerman, AppLanguage.pt);
      expect(englishFirst, AppLanguage.en);
      expect(spanishFirst, AppLanguage.es);
    });

    test('Edge Case: no device language resolves to English', () {
      // 1. Arrange / 2. Act
      final language = AppLanguage.resolve(const []);

      // 3. Assert
      expect(language, AppLanguage.en);
    });
  });
}
