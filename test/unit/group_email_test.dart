import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/utils/group_email.dart';

void main() {
  group('normalizeGroupEmail - Unit Test Suite', () {
    // -------------------------------------------------------------
    // HAPPY PATH
    // -------------------------------------------------------------
    test('Happy Path: returns an already canonical email unchanged', () {
      // 1. Arrange
      const email = 'aquariustur01@monamienet.org';

      // 2. Act
      final result = normalizeGroupEmail(email);

      // 3. Assert
      expect(result, 'aquariustur01@monamienet.org');
    });

    test('Happy Path: lowercases a display-name-cased group email', () {
      // 1. Arrange
      const email = 'AquariusTur01@MonAmieNet.org';

      // 2. Act
      final result = normalizeGroupEmail(email);

      // 3. Assert
      expect(result, 'aquariustur01@monamienet.org');
    });

    test(
      'Happy Path: mixed-case input maps to the same key as its lowercase form',
      () {
        // 1. Arrange
        final canonicalKey = normalizeGroupEmail('ti-suporte@monamienet.org');
        const mixedCaseEmail = 'TI-Suporte@MonAmieNet.ORG';

        // 2. Act
        final result = normalizeGroupEmail(mixedCaseEmail);

        // 3. Assert
        expect(result, canonicalKey);
      },
    );

    test(
      'Happy Path: normalized value matches a lowercase group_roles claim key',
      () {
        // 1. Arrange
        const groupRoles = <String, String>{
          'aquariustur01@monamienet.org': 'member',
        };
        const groupId = 'AquariusTur01@monamienet.org';

        // 2. Act
        final key = normalizeGroupEmail(groupId);

        // 3. Assert
        expect(groupRoles.containsKey(key), isTrue);
      },
    );

    // -------------------------------------------------------------
    // EDGE CASES
    // -------------------------------------------------------------
    test('Edge Case: trims leading and trailing spaces', () {
      // 1. Arrange
      const email = '   aquariustur01@monamienet.org   ';

      // 2. Act
      final result = normalizeGroupEmail(email);

      // 3. Assert
      expect(result, 'aquariustur01@monamienet.org');
    });

    test(
      'Edge Case: trims tabs and newlines and lowercases at the same time',
      () {
        // 1. Arrange
        const email = '\t\n AquariusTur01@MonAmieNet.org \r\n';

        // 2. Act
        final result = normalizeGroupEmail(email);

        // 3. Assert
        expect(result, 'aquariustur01@monamienet.org');
      },
    );

    test('Edge Case: returns an empty string for an empty input', () {
      // 1. Arrange
      const email = '';

      // 2. Act
      final result = normalizeGroupEmail(email);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Edge Case: returns an empty string for a whitespace-only input', () {
      // 1. Arrange
      const email = '   \t  ';

      // 2. Act
      final result = normalizeGroupEmail(email);

      // 3. Assert
      expect(result, isEmpty);
    });

    test(
      'Edge Case: preserves inner whitespace (only peripheral whitespace is trimmed)',
      () {
        // 1. Arrange
        const email = ' Group Name@MonAmieNet.org ';

        // 2. Act
        final result = normalizeGroupEmail(email);

        // 3. Assert
        expect(result, 'group name@monamienet.org');
      },
    );

    test(
      'Edge Case: is idempotent when applied to an already normalized value',
      () {
        // 1. Arrange
        final alreadyNormalized = normalizeGroupEmail(
          '  AquariusTur01@MonAmieNet.org ',
        );

        // 2. Act
        final result = normalizeGroupEmail(alreadyNormalized);

        // 3. Assert
        expect(result, alreadyNormalized);
      },
    );

    // -------------------------------------------------------------
    // SAD PATH
    // -------------------------------------------------------------
    test(
      'Sad Path: throws TypeError when a null value bypasses static typing',
      () {
        // 1. Arrange
        const dynamic email = null;

        // 2. Act
        String action() => normalizeGroupEmail(email);

        // 3. Assert
        expect(action, throwsA(isA<TypeError>()));
      },
    );

    test(
      'Sad Path: throws TypeError when a non-String value bypasses static typing',
      () {
        // 1. Arrange
        const dynamic email = 12345;

        // 2. Act
        String action() => normalizeGroupEmail(email);

        // 3. Assert
        expect(action, throwsA(isA<TypeError>()));
      },
    );

    test(
      'Sad Path: does not validate format and only normalizes a malformed email',
      () {
        // 1. Arrange
        const email = ' Not-An-Email ';

        // 2. Act
        final result = normalizeGroupEmail(email);

        // 3. Assert
        expect(result, 'not-an-email');
      },
    );
  });
}
