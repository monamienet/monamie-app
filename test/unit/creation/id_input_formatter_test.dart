import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/creation/create_organization_controller.dart';
import 'package:monamie_app/app/modules/creation/id_input_formatter.dart';

TextEditingValue _typed(String text, {int? caret}) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret ?? text.length),
);

void main() {
  const old = TextEditingValue.empty;

  group('IdInputFormatter changed text', () {
    // input, expected cleaned text
    final cases = <(String, String, String)>[
      ('capital is lowered', 'Rota', 'rota'),
      ('accent is dropped', 'ásia', 'asia'),
      ('cedilla is dropped', 'maçã', 'maca'),
      ('digit is removed', 'rota1', 'rota'),
      ('space is removed', 'rota sul', 'rotasul'),
      ('symbol is removed', 'ro-ta_!', 'rota'),
    ];
    for (final (name, input, expected) in cases) {
      test('$name', () {
        // 1. Arrange
        final calls = <bool>[];
        final formatter = IdInputFormatter(calls.add);

        // 2. Act
        final result = formatter.formatEditUpdate(old, _typed(input));

        // 3. Assert
        expect(result.text, expected);
        expect(result.selection, TextSelection.collapsed(offset: expected.length));
        expect(calls, [true]);
      });
    }

    test('text over the maximum length is truncated like suggestPartnerId', () {
      // 1. Arrange
      final long = List.filled(60, 'a').join();
      final max = suggestPartnerId(long).length;
      final calls = <bool>[];
      final formatter = IdInputFormatter(calls.add);

      // 2. Act
      final result = formatter.formatEditUpdate(old, _typed(long));

      // 3. Assert
      expect(max, lessThan(60));
      expect(result.text.length, max);
      expect(result.selection, TextSelection.collapsed(offset: max));
      expect(calls, [true]);
    });

    test('a change in the middle still puts the caret at the end', () {
      // 1. Arrange
      final calls = <bool>[];
      final formatter = IdInputFormatter(calls.add);
      final edited = _typed('ro9ta', caret: 3);

      // 2. Act
      final result = formatter.formatEditUpdate(_typed('rota'), edited);

      // 3. Assert
      expect(result.text, 'rota');
      expect(result.selection, const TextSelection.collapsed(offset: 4));
      expect(calls, [true]);
    });
  });

  group('IdInputFormatter kept text', () {
    test('lowercase letters are kept and reported as not adjusted', () {
      // 1. Arrange
      final calls = <bool>[];
      final formatter = IdInputFormatter(calls.add);
      final value = _typed('rotasul', caret: 3);

      // 2. Act
      final result = formatter.formatEditUpdate(old, value);

      // 3. Assert
      expect(result, same(value));
      expect(result.selection, const TextSelection.collapsed(offset: 3));
      expect(calls, [false]);
    });

    test('empty text is kept and reported as not adjusted', () {
      // 1. Arrange
      final calls = <bool>[];
      final formatter = IdInputFormatter(calls.add);
      final value = _typed('');

      // 2. Act
      final result = formatter.formatEditUpdate(_typed('a'), value);

      // 3. Assert
      expect(result.text, '');
      expect(result.selection, const TextSelection.collapsed(offset: 0));
      expect(calls, [false]);
    });

    test('text of only invalid characters becomes empty (adjusted)', () {
      // 1. Arrange
      final calls = <bool>[];
      final formatter = IdInputFormatter(calls.add);

      // 2. Act
      final result = formatter.formatEditUpdate(old, _typed('123 -'));

      // 3. Assert
      expect(result.text, '');
      expect(result.selection, const TextSelection.collapsed(offset: 0));
      expect(calls, [true]);
    });
  });
}
