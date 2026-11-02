import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/domain/models/capabilities.dart';

/// A member's organization membership document.
const member = <String, Object?>{'email': 'ana@x.com', 'role': 'member'};

/// An administrator's organization membership document.
const admin = <String, Object?>{'email': 'olga@x.com', 'role': 'admin'};

void main() {
  group('capabilitiesFromMemberships - Unit Test Suite', () {
    test('Happy Path: a member gets their roles in each group, not admin', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{
        'guias': ['publisher', 'subscriber'],
        'recepcao': ['subscriber'],
      };

      // 2. Act
      final caps = capabilitiesFromMemberships(
        organizationMembership: member,
        groupRoles: groupRoles,
      );

      // 3. Assert
      expect(caps.isMember, isTrue);
      expect(caps.isAdmin, isFalse);
      expect(caps.rolesByGroup, {
        'guias': {'publisher', 'subscriber'},
        'recepcao': {'subscriber'},
      });
    });

    test('Happy Path: role admin makes an administrator', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{};

      // 2. Act
      final caps = capabilitiesFromMemberships(
        organizationMembership: admin,
        groupRoles: groupRoles,
      );

      // 3. Assert
      expect(caps.isAdmin, isTrue);
    });

    test('Edge Case: without an organization membership the group memberships '
        'left grant nothing', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{
        'guias': ['publisher', 'subscriber'],
      };

      // 2. Act
      final caps = capabilitiesFromMemberships(
        organizationMembership: null,
        groupRoles: groupRoles,
      );

      // 3. Assert
      expect(caps, const Capabilities());
    });

    test('Edge Case: unknown roles are kept but grant nothing', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{
        'guias': ['maintainer'],
      };

      // 2. Act
      final caps = capabilitiesFromMemberships(
        organizationMembership: member,
        groupRoles: groupRoles,
      );

      // 3. Assert
      expect(caps.rolesByGroup, {
        'guias': {'maintainer'},
      });
      expect([caps.canPublish, caps.canWatch], [false, false]);
    });

    final malformed = <(String, Object?)>[
      ('a roles field that is not a list', 'publisher'),
      ('an empty list', <Object?>[]),
      ('a list of non-text values', <Object?>[1, null, '']),
    ];
    for (final (label, raw) in malformed) {
      test('Sad Path: $label leaves the group out', () {
        // 1. Arrange
        final groupRoles = <String, Object?>{'guias': raw};

        // 2. Act
        final caps = capabilitiesFromMemberships(
          organizationMembership: member,
          groupRoles: groupRoles,
        );

        // 3. Assert
        expect(caps.rolesByGroup, isEmpty);
      });
    }

    test('Sad Path: a malformed role field is not an administrator', () {
      // 1. Arrange
      const membership = <String, Object?>{
        'role': ['admin'],
      };

      // 2. Act
      final caps = capabilitiesFromMemberships(
        organizationMembership: membership,
        groupRoles: const {},
      );

      // 3. Assert
      expect([caps.isMember, caps.isAdmin], [true, false]);
    });
  });

  group('rolesOf - Unit Test Suite', () {
    test('Happy Path: the strings of a list are the roles', () {
      // 1. Arrange
      const raw = ['publisher', 'subscriber', 'publisher'];

      // 2. Act
      final roles = rolesOf(raw);

      // 3. Assert
      expect(roles, {'publisher', 'subscriber'});
    });

    test('Edge Case: blank and non-text entries are dropped', () {
      // 1. Arrange
      const raw = ['publisher', '', 3, null];

      // 2. Act
      final roles = rolesOf(raw);

      // 3. Assert
      expect(roles, {'publisher'});
    });

    test('Sad Path: anything but a list has no roles', () {
      // 1. Arrange
      const raw = {'publisher': true};

      // 2. Act
      final roles = rolesOf(raw);

      // 3. Assert
      expect(roles, isEmpty);
    });
  });

  group('groupsWithRole - Unit Test Suite', () {
    test('Happy Path: the groups holding the role come sorted', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{
        'recepcao': ['publisher'],
        'bar': ['subscriber'],
        'guias': ['subscriber', 'publisher'],
      };

      // 2. Act
      final ids = groupsWithRole(groupRoles, 'publisher');

      // 3. Assert
      expect(ids, ['guias', 'recepcao']);
    });

    test('Edge Case: a malformed roles field is skipped', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{
        'guias': 'publisher',
        'bar': ['publisher'],
      };

      // 2. Act
      final ids = groupsWithRole(groupRoles, 'publisher');

      // 3. Assert
      expect(ids, ['bar']);
    });

    test('Sad Path: no groups give no ids', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{};

      // 2. Act
      final ids = groupsWithRole(groupRoles, 'publisher');

      // 3. Assert
      expect(ids, isEmpty);
    });
  });
}
