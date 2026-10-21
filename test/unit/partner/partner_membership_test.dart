import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/partner/partner_membership.dart';

Map<String, dynamic> groupOf(String email) => {'email': email, 'name': email};

void main() {
  group('belongsToPartner - Unit Test Suite', () {
    test('Happy Path: a subgroup of the partner means membership', () {
      // 1. Arrange
      final groups = [groupOf('aquariustur01@monamienet.org')];

      // 2. Act
      final belongs = belongsToPartner('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Happy Path: one matching group among others is enough', () {
      // 1. Arrange
      final groups = [
        groupOf('ti-suporte@monamienet.org'),
        groupOf('beta01@monamienet.org'),
        groupOf('aquariustur02@monamienet.org'),
      ];

      // 2. Act
      final belongs = belongsToPartner('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Edge Case: group emails in display-name case still match', () {
      // 1. Arrange
      final groups = [groupOf('AquariusTur01@MonAmieNet.org')];

      // 2. Act
      final belongs = belongsToPartner('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Edge Case: the root group alone means membership', () {
      // 1. Arrange
      final groups = [groupOf('aquariustur00@monamienet.org')];

      // 2. Act
      final belongs = belongsToPartner('aquariustur', groups);

      // 3. Assert
      expect(belongs, isTrue);
    });

    test('Edge Case: no groups means no membership', () {
      // 1. Arrange
      final groups = <Map<String, dynamic>>[];

      // 2. Act
      final belongs = belongsToPartner('aquariustur', groups);

      // 3. Assert
      expect(belongs, isFalse);
    });

    test('Edge Case: a partner whose id is a prefix of another does not '
        'match its groups', () {
      // 1. Arrange
      // tur201 belongs to "tur2", not to "tur".
      final groups = [groupOf('tur201@monamienet.org')];

      // 2. Act
      final belongs = belongsToPartner('tur', groups);

      // 3. Assert
      expect(belongs, isFalse);
    });

    test('Sad Path: only groups of other partners means no membership', () {
      // 1. Arrange
      final groups = [
        groupOf('beta01@monamienet.org'),
        groupOf('aquariustur01@gmail.com'),
      ];

      // 2. Act
      final belongs = belongsToPartner('aquariustur', groups);

      // 3. Assert
      expect(belongs, isFalse);
    });

    test('Sad Path: groups without a string email are ignored', () {
      // 1. Arrange
      final groups = <Map<String, dynamic>>[
        {'name': 'aquariustur01@monamienet.org'},
        {'email': null},
        {'email': 42},
      ];

      // 2. Act
      final belongs = belongsToPartner('aquariustur', groups);

      // 3. Assert
      expect(belongs, isFalse);
    });
  });

  group('claimsShowNoAccess - Unit Test Suite', () {
    test('Happy Path: empty claims show the user has no access left', () {
      // 1. Arrange
      final roles = <String, dynamic>{};

      // 2. Act
      final noAccess = claimsShowNoAccess(roles);

      // 3. Assert
      expect(noAccess, isTrue);
    });

    test('Edge Case: claims with one role still give access', () {
      // 1. Arrange
      final roles = <String, dynamic>{'aquariustur01@monamienet.org': 'member'};

      // 2. Act
      final noAccess = claimsShowNoAccess(roles);

      // 3. Assert
      expect(noAccess, isFalse);
    });

    test('Sad Path: null claims (failed sync) are not evidence of removal', () {
      // 1. Arrange
      const Map<String, dynamic>? roles = null;

      // 2. Act
      final noAccess = claimsShowNoAccess(roles);

      // 3. Assert
      expect(noAccess, isFalse);
    });
  });
}
