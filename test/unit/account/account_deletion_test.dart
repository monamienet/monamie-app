import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/account/account_deletion.dart';

/// A complete deletion as the central functions return it.
Map<String, Object?> _json([Map<String, Object?> overrides = const {}]) => {
  'deleteAt': '2026-11-25T12:00:00.000Z',
  'ownedOrganizationIds': ['rotasul'],
  'ownedOrganizationNames': {'rotasul': 'Rota Sul'},
  ...overrides,
};

void main() {
  group('AccountDeletion.fromJson - Unit Test Suite', () {
    test('Happy Path: reads a complete deletion', () {
      // 1. Arrange
      final json = _json();

      // 2. Act
      final deletion = AccountDeletion.fromJson(json);

      // 3. Assert
      expect(deletion, isNotNull);
      expect(deletion!.deleteAt, DateTime.utc(2026, 11, 25, 12));
      expect(deletion.ownedOrganizationIds, ['rotasul']);
      expect(deletion.ownedOrganizationNames, {'rotasul': 'Rota Sul'});
    });

    test('Edge Case: a member without owned fields owns nothing', () {
      // 1. Arrange
      final json = {'deleteAt': '2026-11-25T12:00:00.000Z'};

      // 2. Act
      final deletion = AccountDeletion.fromJson(json);

      // 3. Assert
      expect(deletion!.ownedOrganizationIds, isEmpty);
      expect(deletion.ownedOrganizationNames, isEmpty);
    });

    test('Edge Case: non-string owned ids are dropped', () {
      // 1. Arrange
      final json = _json({
        'ownedOrganizationIds': ['rotasul', 7, null, 'frota'],
      });

      // 2. Act
      final deletion = AccountDeletion.fromJson(json);

      // 3. Assert
      expect(deletion!.ownedOrganizationIds, ['rotasul', 'frota']);
    });

    test('Edge Case: only string-to-string names are kept', () {
      // 1. Arrange
      final json = _json({
        'ownedOrganizationNames': {
          'rotasul': 'Rota Sul',
          'frota': 3,
          4: 'Quatro',
        },
      });

      // 2. Act
      final deletion = AccountDeletion.fromJson(json);

      // 3. Assert
      expect(deletion!.ownedOrganizationNames, {'rotasul': 'Rota Sul'});
    });

    test('Edge Case: owned fields of the wrong type read as empty', () {
      // 1. Arrange
      final json = _json({
        'ownedOrganizationIds': 'rotasul',
        'ownedOrganizationNames': 'x',
      });

      // 2. Act
      final deletion = AccountDeletion.fromJson(json);

      // 3. Assert
      expect(deletion!.ownedOrganizationIds, isEmpty);
      expect(deletion.ownedOrganizationNames, isEmpty);
    });

    final notDeletions = <String, Object?>{
      'null': null,
      'a list': ['2026-11-25T12:00:00.000Z'],
      'a string': '2026-11-25T12:00:00.000Z',
      'a map without deleteAt': {'ownedOrganizationIds': <String>[]},
      'a malformed deleteAt': _json({'deleteAt': 'amanhã'}),
    };
    for (final MapEntry(key: label, value: json) in notDeletions.entries) {
      test('Sad Path: $label is not a deletion', () {
        // 1. Arrange
        final input = json;

        // 2. Act
        final deletion = AccountDeletion.fromJson(input);

        // 3. Assert
        expect(deletion, isNull);
      });
    }
  });

  group('AccountDeletion.organizationName - Unit Test Suite', () {
    final deleteAt = DateTime.utc(2026, 11, 25);

    test('Happy Path: the first owned organization is named', () {
      // 1. Arrange
      final deletion = AccountDeletion(
        deleteAt: deleteAt,
        ownedOrganizationIds: const ['rotasul', 'frota'],
        ownedOrganizationNames: const {'rotasul': 'Rota Sul', 'frota': 'Frota'},
      );

      // 2. Act
      final name = deletion.organizationName;

      // 3. Assert
      expect(name, 'Rota Sul');
    });

    test('Edge Case: an organization without a name shows its id', () {
      // 1. Arrange
      final deletion = AccountDeletion(
        deleteAt: deleteAt,
        ownedOrganizationIds: const ['rotasul'],
      );

      // 2. Act
      final name = deletion.organizationName;

      // 3. Assert
      expect(name, 'rotasul');
    });

    test('Sad Path: a plain member has no organization', () {
      // 1. Arrange
      final deletion = AccountDeletion(
        deleteAt: deleteAt,
        ownedOrganizationNames: const {'rotasul': 'Rota Sul'},
      );

      // 2. Act
      final name = deletion.organizationName;

      // 3. Assert
      expect(name, isNull);
    });
  });

  group('longDate - Unit Test Suite', () {
    test('Happy Path: a date is written out in Portuguese', () {
      // 1. Arrange
      final date = DateTime(2026, 11, 25, 12);

      // 2. Act
      final text = longDate(date);

      // 3. Assert
      expect(text, '25 de novembro de 2026');
    });

    test('Edge Case: a UTC instant is shown on its local day', () {
      // 1. Arrange
      // Half past midnight local on 1 March, as UTC: the local day must win
      // whatever the machine's time zone.
      final date = DateTime(2026, 3, 1, 0, 30).toUtc();

      // 2. Act
      final text = longDate(date);

      // 3. Assert
      expect(text, '1 de março de 2026');
    });

    test('Edge Case: December is the last month', () {
      // 1. Arrange
      final date = DateTime(2026, 12, 31, 23, 59);

      // 2. Act
      final text = longDate(date);

      // 3. Assert
      expect(text, '31 de dezembro de 2026');
    });
  });

  group('daysLeft - Unit Test Suite', () {
    final now = DateTime.utc(2026, 10, 26, 12);
    final cases = <String, (Duration, int)>{
      'Happy Path: exactly 30 days are 30': (const Duration(days: 30), 30),
      'Edge Case: a started day counts as one': (
        const Duration(days: 29, minutes: 1),
        30,
      ),
      'Edge Case: one minute left is one day': (const Duration(minutes: 1), 1),
      'Edge Case: no time left is zero': (Duration.zero, 0),
      'Sad Path: a past deadline never goes below zero': (
        const Duration(days: -3),
        0,
      ),
    };
    for (final MapEntry(key: label, value: (left, expected)) in cases.entries) {
      test(label, () {
        // 1. Arrange
        final deleteAt = now.add(left);

        // 2. Act
        final days = daysLeft(deleteAt, now);

        // 3. Assert
        expect(days, expected);
      });
    }
  });

  group('inDays - Unit Test Suite', () {
    final cases = <String, (int, String)>{
      'Happy Path: several days': (30, 'em 30 dias'),
      'Edge Case: one day is singular': (1, 'em 1 dia'),
      'Edge Case: zero days is today': (0, 'hoje'),
      'Edge Case: two days are plural': (2, 'em 2 dias'),
    };
    for (final MapEntry(key: label, value: (days, expected)) in cases.entries) {
      test(label, () {
        // 1. Arrange
        final input = days;

        // 2. Act
        final text = inDays(input);

        // 3. Assert
        expect(text, expected);
      });
    }
  });

  group('confirmsId - Unit Test Suite', () {
    final cases = <String, (String, bool)>{
      'Happy Path: the exact id confirms': ('rotasul', true),
      'Edge Case: upper case confirms': ('RotaSul', true),
      'Edge Case: surrounding spaces confirm': ('  rotasul \n', true),
      'Sad Path: another id does not confirm': ('rotasu', false),
      'Sad Path: an empty text does not confirm': ('', false),
      'Sad Path: inner spaces do not confirm': ('rota sul', false),
    };
    for (final MapEntry(key: label, value: (typed, expected))
        in cases.entries) {
      test(label, () {
        // 1. Arrange
        const id = 'rotasul';

        // 2. Act
        final confirmed = confirmsId(typed, id);

        // 3. Assert
        expect(confirmed, expected);
      });
    }
  });
}
