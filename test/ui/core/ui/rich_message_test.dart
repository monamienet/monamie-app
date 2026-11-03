import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/ui/rich_message.dart';

const _bold = TextStyle(fontWeight: FontWeight.w800);

/// Each span as (text, whether it has [_bold]).
List<(String?, bool)> _shape(List<TextSpan> spans) => [
  for (final span in spans) (span.text, span.style == _bold),
];

void main() {
  group('spansAround - Unit Test Suite', () {
    test('Happy Path: the value sits between two plain parts', () {
      // 1. Arrange
      String message(String name) => 'Sua equipe vai ver $name no topo do app';

      // 2. Act
      final spans = spansAround(message, 'Rota Sul', valueStyle: _bold);

      // 3. Assert
      expect(_shape(spans), [
        ('Sua equipe vai ver ', false),
        ('Rota Sul', true),
        (' no topo do app', false),
      ]);
    });

    test('Edge Case: a value at the start leaves no empty span before it', () {
      // 1. Arrange
      String message(String name) => '$name is ready.';

      // 2. Act
      final spans = spansAround(message, 'Rota Sul', valueStyle: _bold);

      // 3. Assert
      expect(_shape(spans), [('Rota Sul', true), (' is ready.', false)]);
    });

    test('Edge Case: a value at the end leaves no empty span after it', () {
      // 1. Arrange
      String message(String terms) => 'Li e aceito os $terms';

      // 2. Act
      final spans = spansAround(message, 'Termos', valueStyle: _bold);

      // 3. Assert
      expect(_shape(spans), [('Li e aceito os ', false), ('Termos', true)]);
    });

    test('Edge Case: a message that is only the value is one span', () {
      // 1. Arrange
      String message(String value) => value;

      // 2. Act
      final spans = spansAround(message, 'Rota Sul', valueStyle: _bold);

      // 3. Assert
      expect(_shape(spans), [('Rota Sul', true)]);
    });

    test('Edge Case: a value used twice is drawn bold both times', () {
      // 1. Arrange
      String message(String name) => '$name, $name!';

      // 2. Act
      final spans = spansAround(message, 'Ana', valueStyle: _bold);

      // 3. Assert
      expect(_shape(spans), [
        ('Ana', true),
        (', ', false),
        ('Ana', true),
        ('!', false),
      ]);
    });

    test('Edge Case: a value with the same words as the message is not '
        'split', () {
      // 1. Arrange
      String message(String name) => 'Abrir $name';

      // 2. Act
      final spans = spansAround(message, 'Abrir', valueStyle: _bold);

      // 3. Assert
      expect(_shape(spans), [('Abrir ', false), ('Abrir', true)]);
    });

    test('Sad Path: a translation without the placeholder shows no value', () {
      // 1. Arrange
      String message(String _) => 'Sem o valor';

      // 2. Act
      final spans = spansAround(message, 'Rota Sul', valueStyle: _bold);

      // 3. Assert
      expect(_shape(spans), [('Sem o valor', false)]);
    });

    test('Happy Path: the plain text joined back is the translated sentence '
        'in both languages', () {
      // 1. Arrange
      final languages = [
        lookupAppLocalizations(const Locale('pt')),
        lookupAppLocalizations(const Locale('en')),
      ];

      // 2. Act
      final joined = [
        for (final l10n in languages)
          spansAround(
            l10n.creationTermsAccept,
            l10n.creationTerms,
            valueStyle: _bold,
          ).map((span) => span.text).join(),
      ];

      // 3. Assert
      expect(joined, [
        'Li e aceito os Termos para organizações.',
        'I have read and accept the Terms for organizations.',
      ]);
    });

    testWidgets('Happy Path: Text.rich shows the sentence with the value '
        'bold', (tester) async {
      // 1. Arrange
      String message(String name) => 'Sua equipe vai ver $name no topo do app';

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          home: Text.rich(
            TextSpan(
              children: spansAround(message, 'Rota Sul', valueStyle: _bold),
            ),
          ),
        ),
      );

      // 3. Assert
      expect(
        find.text('Sua equipe vai ver Rota Sul no topo do app'),
        findsOneWidget,
      );
      final rich = tester.widget<RichText>(find.byType(RichText).last);
      final bold = <String>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.style == _bold) bold.add(span.text!);
        return true;
      });
      expect(bold, ['Rota Sul']);
    });
  });
}
