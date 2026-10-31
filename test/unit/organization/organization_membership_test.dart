import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/organization/organization_membership.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';

Map<String, dynamic> groupOf(String email) => {'email': email, 'name': email};

void main() {
  group('belongsToOrganization - Unit Test Suite', () {
    test('Happy Path: a share leaf of the organization means membership', () {
      // 1. Arrange
      final groups = [groupOf('aquariustur01w@monamienet.org')];

      // 2. Act
      final belongs = belongsToOrganization('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Happy Path: one matching group among others is enough', () {
      // 1. Arrange
      final groups = [
        groupOf('ti-suporte@monamienet.org'),
        groupOf('beta01w@monamienet.org'),
        groupOf('aquariustur02r@monamienet.org'),
      ];

      // 2. Act
      final belongs = belongsToOrganization('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Edge Case: group emails in display-name case still match', () {
      // 1. Arrange
      final groups = [groupOf('AquariusTur01R@MonAmieNet.org')];

      // 2. Act
      final belongs = belongsToOrganization('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Edge Case: the root group alone means membership', () {
      // 1. Arrange
      final groups = [groupOf('aquariustur00@monamienet.org')];

      // 2. Act
      final belongs = belongsToOrganization('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Edge Case: no groups means no membership', () {
      // 1. Arrange
      final groups = <Map<String, dynamic>>[];

      // 2. Act
      final belongs = belongsToOrganization('aquariustur', groups);

      // 3. Assert
      expect(belongs, isFalse);
    });

    test('Edge Case: a direct team group alone means no membership', () {
      // 1. Arrange
      final groups = [groupOf('aquariustur01@monamienet.org')];

      // 2. Act
      final belongs = belongsToOrganization('aquariustur', groups);

      // 3. Assert
      expect(belongs, isFalse);
    });

    test(
      'Sad Path: only groups of other organizations means no membership',
      () {
        // 1. Arrange
        final groups = [
          groupOf('beta01w@monamienet.org'),
          groupOf('aquariustur01w@gmail.com'),
        ];

        // 2. Act
        final belongs = belongsToOrganization('aquariustur', groups);

        // 3. Assert
        expect(belongs, isFalse);
      },
    );

    test('Sad Path: groups without a string email are ignored', () {
      // 1. Arrange
      final groups = <Map<String, dynamic>>[
        {'name': 'aquariustur01w@monamienet.org'},
        {'email': null},
        {'email': 42},
      ];

      // 2. Act
      final belongs = belongsToOrganization('aquariustur', groups);

      // 3. Assert
      expect(belongs, isFalse);
    });
  });

  group('claimsShowNoAccess - Unit Test Suite', () {
    test('Happy Path: empty capabilities show the user has no access left', () {
      // 1. Arrange
      const capabilities = Capabilities();

      // 2. Act
      final noAccess = claimsShowNoAccess(capabilities);

      // 3. Assert
      expect(noAccess, isTrue);
    });

    final withAccess = <(String, Capabilities)>[
      ('share', const Capabilities(share: {'aquariustur01'})),
      ('watch', const Capabilities(watch: {'aquariustur01'})),
      ('admin', const Capabilities(admin: {'aquariustur'})),
    ];
    for (final (label, capabilities) in withAccess) {
      test('Edge Case: a single $label capability still gives access', () {
        // 1. Arrange
        final input = capabilities;

        // 2. Act
        final noAccess = claimsShowNoAccess(input);

        // 3. Assert
        expect(noAccess, isFalse);
      });
    }

    test('Sad Path: null capabilities (failed sync) are not evidence of '
        'removal', () {
      // 1. Arrange
      const Capabilities? capabilities = null;

      // 2. Act
      final noAccess = claimsShowNoAccess(capabilities);

      // 3. Assert
      expect(noAccess, isFalse);
    });
  });
}
