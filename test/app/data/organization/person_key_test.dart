import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/organization/person_key.dart';

/// sha256 of `ana@example.com`, computed once with `sha256sum`: the same
/// fixed vector the rules and both functions codebases are tested with.
const anaKey =
    '8e43ca37701228e74983efdbd0cff5c16b3b1e5d4e29a7c05626d4d25a018e11';

void main() {
  group('personKey - Unit Test Suite', () {
    test('Happy Path: an e-mail gives the fixed known key', () {
      // 1. Arrange
      const email = 'ana@example.com';

      // 2. Act
      final key = personKey(email);

      // 3. Assert
      expect(key, anaKey);
    });

    test('Edge Case: case and surrounding spaces do not change the key', () {
      // 1. Arrange
      const email = '  Ana@Example.COM ';

      // 2. Act
      final key = personKey(email);

      // 3. Assert
      expect(key, anaKey);
    });

    test('Sad Path: another e-mail gives another key', () {
      // 1. Arrange
      const email = 'ana@example.org';

      // 2. Act
      final key = personKey(email);

      // 3. Assert
      expect(key, isNot(anaKey));
    });
  });
}
