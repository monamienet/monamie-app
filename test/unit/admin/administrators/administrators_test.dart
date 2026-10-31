import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators.dart';

void main() {
  group('OrganizationAdministrators.fromJson - Unit Test Suite', () {
    test('Happy Path: the owner is flagged and members are read', () {
      // 1. Arrange
      final json = {
        'administrators': [
          {'email': 'olga@x.com', 'owner': true},
          {'email': 'ana@x.com', 'owner': false},
        ],
        'members': [
          {'email': 'caio@x.com'},
        ],
      };

      // 2. Act
      final result = OrganizationAdministrators.fromJson(json);

      // 3. Assert
      expect(
        [
          for (final a in result.administrators) '${a.email}:${a.owner}',
          ...result.members,
        ],
        ['olga@x.com:true', 'ana@x.com:false', 'caio@x.com'],
      );
    });

    test('Edge Case: owner missing or not true reads as not the owner', () {
      // 1. Arrange
      final json = {
        'administrators': [
          {'email': 'ana@x.com'},
          {'email': 'rui@x.com', 'owner': 'true'},
        ],
      };

      // 2. Act
      final result = OrganizationAdministrators.fromJson(json);

      // 3. Assert
      expect([for (final a in result.administrators) a.owner], [false, false]);
    });

    test('Edge Case: an empty e-mail is left out', () {
      // 1. Arrange
      final json = {
        'administrators': <Object>[],
        'members': [
          {'email': ''},
          {'email': 'caio@x.com'},
        ],
      };

      // 2. Act
      final result = OrganizationAdministrators.fromJson(json);

      // 3. Assert
      expect(result.members, ['caio@x.com']);
    });

    test('Sad Path: a response that is not a map is empty', () {
      // 1. Arrange
      const json = 'administrators';

      // 2. Act
      final result = OrganizationAdministrators.fromJson(json);

      // 3. Assert
      expect([result.administrators, result.members], [isEmpty, isEmpty]);
    });

    test('Sad Path: entries without an e-mail are left out', () {
      // 1. Arrange
      final json = {
        'administrators': [
          {'owner': true},
          'olga@x.com',
        ],
        'members': 7,
      };

      // 2. Act
      final result = OrganizationAdministrators.fromJson(json);

      // 3. Assert
      expect([result.administrators, result.members], [isEmpty, isEmpty]);
    });
  });
}
