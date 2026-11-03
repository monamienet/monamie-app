import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

/// An app configured as `MonAmieApp` is (the app's delegates and
/// [appSupportedLocales], no fixed `locale`), on a device whose languages
/// are [deviceLocales]. Its button opens Material's date picker on
/// 2 November 2026, in [mode].
Future<void> _pumpApp(
  WidgetTester tester, {
  required List<Locale> deviceLocales,
  DatePickerEntryMode mode = DatePickerEntryMode.calendar,
}) async {
  tester.platformDispatcher.localesTestValue = deviceLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 11, 2),
              firstDate: DateTime(2026),
              lastDate: DateTime(2026, 12, 31),
              initialEntryMode: mode,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openPicker(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// The app's [Locale] as resolved under the [Scaffold].
Locale _resolved(WidgetTester tester) =>
    Localizations.localeOf(tester.element(find.byType(Scaffold).first));

void main() {
  group('appSupportedLocales - Unit Test Suite', () {
    test('Happy Path: English comes first, then Brazilian Portuguese and '
        'Spanish', () {
      // 1. Arrange / 2. Act
      const locales = appSupportedLocales;

      // 3. Assert
      expect(locales, const [Locale('en'), Locale('pt', 'BR'), Locale('es')]);
    });

    test('Edge Case: they are the locales of the AppLanguages', () {
      // 1. Arrange / 2. Act
      final locales = {for (final l in AppLanguage.values) l.locale};

      // 3. Assert
      expect(locales, appSupportedLocales.toSet());
    });

    test('Edge Case: every supported language has the app texts', () {
      // 1. Arrange / 2. Act
      final supported = [
        for (final locale in appSupportedLocales)
          AppLocalizations.delegate.isSupported(locale),
      ];

      // 3. Assert
      expect(supported, everyElement(isTrue));
    });
  });

  group('Device language resolution - Widget Test Suite', () {
    testWidgets('Happy Path: a pt_BR device gets pt_BR', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('pt', 'BR')]);

      // 3. Assert
      expect(_resolved(tester), const Locale('pt', 'BR'));
    });

    testWidgets('Happy Path: an English device gets English', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('en', 'US')]);

      // 3. Assert
      expect(_resolved(tester).languageCode, 'en');
    });

    testWidgets('Happy Path: a Spanish device gets Spanish', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('es', 'ES')]);

      // 3. Assert
      expect(_resolved(tester), const Locale('es'));
    });

    testWidgets('Edge Case: a Mexican Spanish device gets the same Spanish', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('es', 'MX')]);

      // 3. Assert
      expect(_resolved(tester), const Locale('es'));
    });

    testWidgets('Edge Case: a French device falls back to English', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('fr', 'FR')]);

      // 3. Assert
      expect(_resolved(tester), const Locale('en'));
    });

    testWidgets('Edge Case: a German device falls back to English', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('de', 'DE')]);

      // 3. Assert
      expect(_resolved(tester), const Locale('en'));
    });

    testWidgets('Edge Case: a pt_PT device gets pt_BR', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('pt', 'PT')]);

      // 3. Assert
      expect(_resolved(tester), const Locale('pt', 'BR'));
    });

    testWidgets('Edge Case: [de, pt_BR] skips German and gets pt_BR', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      await _pumpApp(
        tester,
        deviceLocales: const [Locale('de'), Locale('pt', 'BR')],
      );

      // 3. Assert
      expect(_resolved(tester), const Locale('pt', 'BR'));
    });
  });

  group('resolveAppLocale - Unit Test Suite', () {
    test('Happy Path: the first device language the app has wins', () {
      // 1. Arrange
      const preferred = [Locale('de'), Locale('pt', 'PT'), Locale('en')];

      // 2. Act
      final locale = resolveAppLocale(preferred, appSupportedLocales);

      // 3. Assert
      expect(locale, const Locale('pt', 'BR'));
    });

    test('Edge Case: a null list resolves to English', () {
      // 1. Arrange / 2. Act
      final locale = resolveAppLocale(null, appSupportedLocales);

      // 3. Assert
      expect(locale, const Locale('en'));
    });

    test('Edge Case: an empty list resolves to English', () {
      // 1. Arrange / 2. Act
      final locale = resolveAppLocale(const [], appSupportedLocales);

      // 3. Assert
      expect(locale, const Locale('en'));
    });

    test('Happy Path: a Spanish device language resolves to Spanish', () {
      // 1. Arrange / 2. Act
      final locale = resolveAppLocale(const [
        Locale('es', 'ES'),
      ], appSupportedLocales);

      // 3. Assert
      expect(locale, const Locale('es'));
    });

    test('Edge Case: a language the app does not have resolves to English', () {
      // 1. Arrange / 2. Act
      final locale = resolveAppLocale(const [
        Locale('fr', 'FR'),
      ], appSupportedLocales);

      // 3. Assert
      expect(locale, const Locale('en'));
    });
  });

  // #84: Material's own widgets followed English before the app declared
  // the delegates.
  group('Date picker on a Spanish device - Widget Test Suite', () {
    testWidgets('Happy Path: the buttons and the month are in Spanish', (
      tester,
    ) async {
      // 1. Arrange
      await _pumpApp(tester, deviceLocales: const [Locale('es', 'ES')]);

      // 2. Act
      await _openPicker(tester);

      // 3. Assert
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.textContaining('noviembre'), findsWidgets);
      expect(find.textContaining('November'), findsNothing);
    });

    testWidgets('Edge Case: the week starts on Monday with Spanish letters', (
      tester,
    ) async {
      // 1. Arrange
      await _pumpApp(tester, deviceLocales: const [Locale('es', 'ES')]);

      // 2. Act
      await _openPicker(tester);
      final material = MaterialLocalizations.of(
        tester.element(find.text('Cancelar')),
      );

      // 3. Assert
      expect(
        Localizations.localeOf(tester.element(find.text('Cancelar'))),
        const Locale('es'),
      );
      expect(material.firstDayOfWeekIndex, 1);
      expect(material.narrowWeekdays, ['D', 'L', 'M', 'X', 'J', 'V', 'S']);
    });

    testWidgets('Happy Path: typing a date uses d/M/yyyy', (tester) async {
      // 1. Arrange
      await _pumpApp(
        tester,
        deviceLocales: const [Locale('es', 'MX')],
        mode: DatePickerEntryMode.input,
      );

      // 2. Act
      await _openPicker(tester);

      // 3. Assert
      expect(find.text('2/11/2026'), findsOneWidget);
      expect(find.text('11/2/2026'), findsNothing);
    });
  });

  group('Date picker on a pt_BR device - Widget Test Suite', () {
    testWidgets('Happy Path: the buttons and the month are in Portuguese', (
      tester,
    ) async {
      // 1. Arrange
      await _pumpApp(tester, deviceLocales: const [Locale('pt', 'BR')]);

      // 2. Act
      await _openPicker(tester);

      // 3. Assert
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.textContaining('novembro de 2026'), findsWidgets);
      expect(find.textContaining('November'), findsNothing);
    });

    testWidgets('Happy Path: the week starts on Sunday with Portuguese '
        'letters', (tester) async {
      // 1. Arrange
      await _pumpApp(tester, deviceLocales: const [Locale('pt', 'BR')]);

      // 2. Act
      await _openPicker(tester);
      final material = MaterialLocalizations.of(
        tester.element(find.text('Cancelar')),
      );

      // 3. Assert
      expect(material.firstDayOfWeekIndex, 0);
      expect(material.narrowWeekdays, ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']);
    });

    testWidgets('Happy Path: typing a date uses dd/MM/yyyy', (tester) async {
      // 1. Arrange
      await _pumpApp(
        tester,
        deviceLocales: const [Locale('pt', 'BR')],
        mode: DatePickerEntryMode.input,
      );

      // 2. Act
      await _openPicker(tester);

      // 3. Assert
      expect(find.text('02/11/2026'), findsOneWidget);
      expect(find.text('11/02/2026'), findsNothing);
    });

    testWidgets('Edge Case: on an English device the picker is in English', (
      tester,
    ) async {
      // 1. Arrange
      await _pumpApp(tester, deviceLocales: const [Locale('en', 'US')]);

      // 2. Act
      await _openPicker(tester);

      // 3. Assert
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Cancelar'), findsNothing);
    });
  });
}
