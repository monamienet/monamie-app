import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';
import 'package:monamie_app/utils/result.dart';

import 'language_harness.dart';

/// The French texts, read from the generated localizations.
final _fr = lookupAppLocalizations(const Locale('fr'));

const _notSaved = 'Não foi possível guardar o idioma. Tente de novo.';

/// A screen with one button, 'Abrir', that opens the picker in [scheme].
Widget _opener(LanguageHarness harness, LanguageScheme scheme) => Scaffold(
  body: Builder(
    builder: (context) => TextButton(
      onPressed: () => showLanguageSheet(
        context,
        controller: harness.controller,
        scheme: scheme,
      ),
      child: const Text('Abrir'),
    ),
  ),
);

Future<void> _open(
  WidgetTester tester,
  LanguageHarness harness, {
  LanguageScheme scheme = LanguageScheme.menu,
}) async {
  await harness.pump(tester, home: _opener(harness, scheme));
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

/// Whether the sheet's own background is [scheme]'s.
Finder _sheetOf(LanguageScheme scheme) => find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  return decoration is BoxDecoration &&
      decoration.borderRadius != null &&
      decoration.color == LanguageColors.of(scheme).sheet;
});

void main() {
  group('LanguageSheet - Widget Test Suite', () {
    for (final scheme in LanguageScheme.values) {
      testWidgets(
        'Happy Path: ${scheme.name} scheme lists each language in itself, '
        'marking the one in use',
        (tester) async {
          // 1. Arrange / 2. Act
          final harness = LanguageHarness();
          await _open(tester, harness, scheme: scheme);

          // 3. Assert
          expect(find.text('Idioma'), findsOneWidget);
          expect(find.text('Português'), findsOneWidget);
          expect(find.text('English'), findsOneWidget);
          expect(find.text('Español'), findsOneWidget);
          expect(find.text('Français'), findsOneWidget);
          expect(find.text('PT'), findsOneWidget);
          expect(find.text('EN'), findsOneWidget);
          expect(find.text('ES'), findsOneWidget);
          expect(find.text('FR'), findsOneWidget);
          expect(_sheetOf(scheme), findsOneWidget);
          expect(
            find.descendant(
              of: languageRow('Português'),
              matching: find.byIcon(Icons.check),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: languageRow('English'),
              matching: find.byIcon(Icons.check),
            ),
            findsNothing,
          );
          expect(find.byType(CircularProgressIndicator), findsNothing);
        },
      );
    }

    testWidgets('Edge Case: one row per AppLanguage', (tester) async {
      // 1. Arrange / 2. Act
      final harness = LanguageHarness();
      await _open(tester, harness);

      // 3. Assert
      for (final language in AppLanguage.values) {
        expect(find.text(language.name.toUpperCase()), findsOneWidget);
        expect(find.text(languageName(language)), findsOneWidget);
      }
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Edge Case: four rows, one per language, in the order pt, en, '
        'es, fr', (tester) async {
      // 1. Arrange / 2. Act
      final harness = LanguageHarness();
      await _open(tester, harness);

      // 3. Assert
      const names = ['Português', 'English', 'Español', 'Français'];
      for (final name in names) {
        expect(languageRow(name), findsOneWidget);
      }
      final tops = [
        for (final name in names) tester.getTopLeft(find.text(name)).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(tops.toSet(), hasLength(4));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Edge Case: marks Français on a French device', (tester) async {
      // 1. Arrange / 2. Act: nothing was chosen.
      final harness = LanguageHarness(
        deviceLocales: const [Locale('fr', 'CA')],
      );
      await _open(tester, harness);

      // 3. Assert: the sheet itself is in French.
      expect(find.text(_fr.languageTitle), findsOneWidget);
      expect(
        find.descendant(
          of: languageRow('Français'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Happy Path: marks Français when it is the choice, whatever '
        'the device speaks', (tester) async {
      // 1. Arrange / 2. Act
      final harness = LanguageHarness(stored: AppLanguage.fr);
      await _open(tester, harness);

      // 3. Assert
      expect(find.text(_fr.languageTitle), findsOneWidget);
      expect(
        find.descendant(
          of: languageRow('Français'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: languageRow('Português'),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );
    });

    testWidgets('Happy Path: choosing Français stores it, redraws the sheet '
        'in French and closes it', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      await _open(tester, harness);

      // 2. Act
      await tester.tap(languageRow('Français'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 3. Assert: the sheet, still leaving, is already in French.
      expect(find.text(_fr.languageTitle), findsOneWidget);
      expect(find.text('Idioma'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(LanguageSheet), findsNothing);
      expect(harness.repository.stored, AppLanguage.fr);
      expect(harness.controller.state.inUse, AppLanguage.fr);
      expect(harness.repository.argumentsOf('choose'), [
        [AppLanguage.fr],
      ]);
    });

    testWidgets('Edge Case: marks Español on a Spanish device', (tester) async {
      // 1. Arrange / 2. Act: nothing was chosen.
      final harness = LanguageHarness(
        deviceLocales: const [Locale('es', 'MX')],
      );
      await _open(tester, harness);

      // 3. Assert
      expect(
        find.descendant(
          of: languageRow('Español'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Happy Path: choosing Español stores it and closes the '
        'sheet', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      await _open(tester, harness);

      // 2. Act
      await tester.tap(languageRow('Español'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsNothing);
      expect(harness.repository.stored, AppLanguage.es);
      expect(harness.controller.state.inUse, AppLanguage.es);
    });

    testWidgets('Edge Case: marks English on a device whose language the app '
        'does not have', (tester) async {
      // 1. Arrange / 2. Act: nothing was chosen.
      final harness = LanguageHarness(deviceLocales: const [Locale('de')]);
      await _open(tester, harness);

      // 3. Assert
      expect(find.text('Language'), findsOneWidget);
      expect(
        find.descendant(
          of: languageRow('English'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Edge Case: opening the sheet reads the device languages '
        'again', (tester) async {
      // 1. Arrange: the device changes its language after the app started.
      final harness = LanguageHarness();
      await harness.pump(tester, home: _opener(harness, LanguageScheme.menu));
      harness.deviceLocales
        ..clear()
        ..add(const Locale('en', 'US'));

      // 2. Act
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(
        find.descendant(
          of: languageRow('English'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Happy Path: choosing a language stores it, redraws the '
        'texts at once and closes the sheet', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      await _open(tester, harness);

      // 2. Act
      await tester.tap(languageRow('English'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 3. Assert: the sheet, still leaving, is already in English.
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Idioma'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(LanguageSheet), findsNothing);
      expect(harness.repository.stored, AppLanguage.en);
      expect(harness.repository.argumentsOf('choose'), [
        [AppLanguage.en],
      ]);
    });

    testWidgets('Edge Case: choosing the language already in use still '
        'stores it and closes the sheet', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      await _open(tester, harness);

      // 2. Act
      await tester.tap(languageRow('Português'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsNothing);
      expect(harness.repository.stored, AppLanguage.pt);
    });

    testWidgets('Sad Path: a choice that cannot be stored keeps the sheet '
        'open and says so', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      harness.repository.fail('choose', const Failure.languageNotSaved());
      await _open(tester, harness);

      // 2. Act
      await tester.tap(languageRow('English'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsOneWidget);
      expect(find.text(_notSaved), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
      expect(harness.repository.stored, isNull);
      expect(harness.controller.state.inUse, AppLanguage.pt);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Sad Path: trying again after a failure clears the message '
        'and closes the sheet', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      harness.repository.fail('choose', const Failure.languageNotSaved());
      await _open(tester, harness);
      await tester.tap(languageRow('English'));
      await tester.pumpAndSettle();
      harness.repository.succeed('choose');

      // 2. Act
      await tester.tap(languageRow('English'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsNothing);
      expect(find.text(_notSaved), findsNothing);
      expect(harness.repository.stored, AppLanguage.en);
    });

    testWidgets('Edge Case: while the choice is stored its row shows a '
        'spinner and the other rows do nothing', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      final gate = harness.repository.hold('choose');
      await _open(tester, harness);

      // 2. Act
      await tester.tap(languageRow('English'));
      await tester.pump();
      await tester.tap(languageRow('Português'));
      await tester.pump();

      // 3. Assert
      expect(
        find.descendant(
          of: languageRow('English'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(harness.repository.callCount('choose'), 1);
      expect(find.byType(LanguageSheet), findsOneWidget);

      // The answer arrives: the sheet closes.
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LanguageSheet), findsNothing);
      expect(harness.repository.stored, AppLanguage.en);
    });

    testWidgets('Edge Case: the sheet cannot be dismissed with the back '
        'button while the choice is stored', (tester) async {
      // 1. Arrange
      final harness = LanguageHarness();
      final gate = harness.repository.hold('choose');
      await _open(tester, harness);
      await tester.tap(languageRow('English'));
      await tester.pump();

      // 2. Act
      await tester.binding.handlePopRoute();
      await tester.pump();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
    });
  });
}
