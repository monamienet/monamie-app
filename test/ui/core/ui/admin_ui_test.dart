import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';
import 'package:monamie_app/utils/result.dart';

const _generic = 'Não foi possível concluir agora. Tente de novo.';

void main() {
  group('sheetFailureOf - Unit Test Suite', () {
    test('Happy Path: an Ok shows nothing', () {
      // 1. Arrange & 2. Act
      final shown = sheetFailureOf(const Ok(null));

      // 3. Assert
      expect(shown, isNull);
    });

    test("Happy Path: an Err shows its message", () {
      // 1. Arrange & 2. Act
      final shown = sheetFailureOf(const Err('Convite não encontrado.'));

      // 3. Assert
      expect(shown, 'Convite não encontrado.');
    });

    test('Edge Case: an Err with an empty message shows the generic one', () {
      // 1. Arrange & 2. Act
      final shown = sheetFailureOf(const Err(''));

      // 3. Assert
      expect(shown, _generic);
    });

    test('Sad Path: an ignored call (null) shows the generic message', () {
      // 1. Arrange & 2. Act
      final shown = sheetFailureOf(null);

      // 3. Assert
      expect(shown, _generic);
    });
  });
}
