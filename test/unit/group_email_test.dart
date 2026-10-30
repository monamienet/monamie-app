import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/utils/group_email.dart';

void main() {
  group('normalizeGroupEmail - Unit Test Suite', () {
    test('Happy Path: lowercases a display-name-cased group email', () {
      // 1. Arrange
      const email = 'AquariusTur01@MonAmieNet.org';

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
  });
}
