import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/ui/language/widgets/language_button.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';

import 'language_harness.dart';

Widget _screen(LanguageHarness harness, LanguageScheme scheme) => Scaffold(
  body: Center(
    child: LanguageButton(controller: harness.controller, scheme: scheme),
  ),
);

void main() {
  group('LanguageButton - Widget Test Suite', () {
    testWidgets('Happy Path: shows the globe and the code of the language in '
        'use', (tester) async {
      // 1. Arrange / 2. Act
      final harness = LanguageHarness();
      await harness.pump(tester, home: _screen(harness, LanguageScheme.login));

      // 3. Assert
      expect(find.byIcon(Icons.language), findsOneWidget);
      expect(find.text('PT'), findsOneWidget);
      expect(find.text('EN'), findsNothing);
    });

    testWidgets('Edge Case: shows EN when English is in use', (tester) async {
      // 1. Arrange / 2. Act
      final harness = LanguageHarness(stored: AppLanguage.en);
      await harness.pump(tester, home: _screen(harness, LanguageScheme.login));

      // 3. Assert
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('PT'), findsNothing);
    });

    testWidgets('Edge Case: follows the language chosen elsewhere, in its '
        'code and its label', (tester) async {
      // 1. Arrange
      final semantics = tester.ensureSemantics();
      final harness = LanguageHarness();
      await harness.pump(tester, home: _screen(harness, LanguageScheme.login));
      expect(find.text('PT'), findsOneWidget);

      // 2. Act
      await harness.repository.choose(AppLanguage.en);
      await tester.pump();

      // 3. Assert
      expect(find.text('EN'), findsOneWidget);
      expect(find.bySemanticsLabel('Language: English'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('Happy Path: has the accessibility label of a button naming '
        'the language in use', (tester) async {
      // 1. Arrange
      final semantics = tester.ensureSemantics();
      final harness = LanguageHarness();
      await harness.pump(tester, home: _screen(harness, LanguageScheme.login));

      // 2. Act
      final node = tester.getSemantics(
        find.bySemanticsLabel('Idioma: Português'),
      );

      // 3. Assert
      expect(node, isSemantics(label: 'Idioma: Português', isButton: true));
      // The code and the globe do not add their own readings.
      expect(find.bySemanticsLabel('PT'), findsNothing);
      semantics.dispose();
    });

    for (final scheme in LanguageScheme.values) {
      testWidgets(
        'Happy Path: tapping it opens the sheet in the ${scheme.name} '
        'scheme',
        (tester) async {
          // 1. Arrange
          final harness = LanguageHarness();
          await harness.pump(tester, home: _screen(harness, scheme));
          expect(find.byType(LanguageSheet), findsNothing);

          // 2. Act
          await tester.tap(find.byType(LanguageButton));
          await tester.pumpAndSettle();

          // 3. Assert
          final sheet = tester.widget<LanguageSheet>(
            find.byType(LanguageSheet),
          );
          expect(sheet.scheme, scheme);
          expect(sheet.controller, same(harness.controller));
          expect(find.text('Idioma'), findsOneWidget);
        },
      );
    }

    testWidgets('Edge Case: the button keeps a 44 px touch target', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      final harness = LanguageHarness();
      await harness.pump(
        tester,
        home: _screen(harness, LanguageScheme.organization),
      );

      // 3. Assert
      final size = tester.getSize(find.byType(LanguageButton));
      expect(size.height, greaterThanOrEqualTo(44));
      expect(size.width, greaterThanOrEqualTo(44));
    });
  });
}
