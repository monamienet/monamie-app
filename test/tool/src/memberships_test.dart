import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/memberships.dart';

final now = DateTime.utc(2026, 10, 31, 12);

void main() {
  group('adminMembership - Unit Test Suite', () {
    test('Happy Path: a new administrator gets role admin and addedAt now', () {
      // 1. Arrange
      const email = 'ana@example.com';

      // 2. Act
      final membership = adminMembership(email, now: now);

      // 3. Assert
      expect(membership, {'email': email, 'role': 'admin', 'addedAt': now});
    });

    test('Edge Case: promoting a member keeps when they were added', () {
      // 1. Arrange
      final added = DateTime.utc(2026, 1, 2);

      // 2. Act
      final membership = adminMembership(
        'ana@example.com',
        now: now,
        existing: {'role': 'member', 'addedAt': added},
      );

      // 3. Assert
      expect(membership['addedAt'], added);
    });

    test('Sad Path: an existing membership without addedAt gets now', () {
      // 1. Arrange
      final existing = <String, Object?>{'role': 'member'};

      // 2. Act
      final membership = adminMembership(
        'ana@example.com',
        now: now,
        existing: existing,
      );

      // 3. Assert
      expect(membership['addedAt'], now);
    });
  });

  group('accountWithOrganization - Unit Test Suite', () {
    test('Happy Path: a new entry lists only the organization', () {
      // 1. Arrange
      const email = 'ana@example.com';

      // 2. Act
      final account = accountWithOrganization(email, 'acme');

      // 3. Assert
      expect(account, {
        'email': email,
        'organizationIds': ['acme'],
      });
    });

    test('Edge Case: existing ids are kept, sorted, without duplicates', () {
      // 1. Arrange
      final existing = <String, Object?>{
        'organizationIds': ['zeta', 'acme'],
      };

      // 2. Act
      final account = accountWithOrganization(
        'ana@example.com',
        'acme',
        existing: existing,
      );

      // 3. Assert
      expect(account['organizationIds'], ['acme', 'zeta']);
    });

    test('Sad Path: malformed ids are dropped', () {
      // 1. Arrange
      final existing = <String, Object?>{
        'organizationIds': [42, null, 'beta'],
      };

      // 2. Act
      final account = accountWithOrganization(
        'ana@example.com',
        'acme',
        existing: existing,
      );

      // 3. Assert
      expect(account['organizationIds'], ['acme', 'beta']);
    });
  });

  group('membershipProblem - Unit Test Suite', () {
    const anaKey =
        '8e43ca37701228e74983efdbd0cff5c16b3b1e5d4e29a7c05626d4d25a018e11';

    test('Happy Path: an administrator listed in accounts is no problem', () {
      // 1. Arrange
      final memberships = [
        (
          id: anaKey,
          data: <String, Object?>{'email': 'ana@example.com', 'role': 'admin'},
        ),
      ];

      // 2. Act
      final problem = membershipProblem('acme', memberships, {
        anaKey: {
          'organizationIds': ['acme'],
        },
      });

      // 3. Assert
      expect(problem, isNull);
    });

    test(
      'Edge Case: a document whose key is not the e-mail\'s is reported',
      () {
        // 1. Arrange
        final memberships = [
          (
            id: 'wrong',
            data: <String, Object?>{
              'email': 'ana@example.com',
              'role': 'admin',
            },
          ),
        ];

        // 2. Act
        final problem = membershipProblem('acme', memberships, {});

        // 3. Assert
        expect(problem, contains('ana@example.com (wrong)'));
      },
    );

    test('Sad Path: no memberships at all means no administrator', () {
      // 1. Arrange
      final memberships = <({String id, Map<String, Object?> data})>[];

      // 2. Act
      final problem = membershipProblem('acme', memberships, {});

      // 3. Assert
      expect(problem, contains('no administrator'));
    });
  });

  group('membershipProblem (accounts index) - Unit Test Suite', () {
    const anaKey =
        '8e43ca37701228e74983efdbd0cff5c16b3b1e5d4e29a7c05626d4d25a018e11';
    // personKey('owner@example.com'), computed once with `sha256sum`.
    const ownerKey =
        'c8cd3c6427301eaf6665bccacd65ddb614527acc843a15463e3faba57124c351';
    final admin = (
      id: ownerKey,
      data: <String, Object?>{'email': 'owner@example.com', 'role': 'admin'},
    );
    final member = (
      id: anaKey,
      data: <String, Object?>{'email': 'ana@example.com', 'role': 'member'},
    );
    final adminAccount = <String, Map<String, Object?>?>{
      ownerKey: {
        'organizationIds': ['acme'],
      },
    };

    test('Happy Path: a member whose entry lists another organization only is '
        'reported without the add-admin hint', () {
      // 1. Arrange
      final accounts = {
        ...adminAccount,
        anaKey: <String, Object?>{
          'organizationIds': ['beta'],
        },
      };

      // 2. Act
      final problem = membershipProblem('acme', [admin, member], accounts);

      // 3. Assert
      expect(problem, isNotNull);
      expect(problem, contains('accounts/$anaKey does not list acme'));
      expect(problem, isNot(contains('add-admin acme ana@example.com')));
    });

    test('Edge Case: an administrator missing from accounts gets the add-admin '
        'hint with their e-mail', () {
      // 1. Arrange
      final accounts = <String, Map<String, Object?>?>{ownerKey: null};

      // 2. Act
      final problem = membershipProblem('acme', [admin], accounts);

      // 3. Assert
      expect(problem, contains('add-admin acme owner@example.com'));
    });

    test('Sad Path: a membership without an e-mail is reported', () {
      // 1. Arrange
      final noEmail = (id: anaKey, data: <String, Object?>{'role': 'member'});

      // 2. Act
      final problem = membershipProblem('acme', [admin, noEmail], adminAccount);

      // 3. Assert
      expect(problem, contains('(no e-mail) ($anaKey)'));
    });
  });
}
