import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';

/// A member's organization membership document.
const member = <String, Object?>{'email': 'ana@x.com', 'role': 'member'};

/// An administrator's organization membership document.
const admin = <String, Object?>{'email': 'olga@x.com', 'role': 'admin'};

void main() {
  group('Capabilities.fromMemberships - Unit Test Suite', () {
    test('Happy Path: a member gets their roles in each group, not admin', () {
      // 1. Arrange
      const groupRoles = <String, Object?>{
        'guias': ['publisher', 'subscriber'],
        'recepcao': ['subscriber'],
      };

      // 2. Act
      final caps = Capabilities.fromMemberships(
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
      final caps = Capabilities.fromMemberships(
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
      final caps = Capabilities.fromMemberships(
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
      final caps = Capabilities.fromMemberships(
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
        final caps = Capabilities.fromMemberships(
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
      final caps = Capabilities.fromMemberships(
        organizationMembership: membership,
        groupRoles: const {},
      );

      // 3. Assert
      expect([caps.isMember, caps.isAdmin], [true, false]);
    });
  });

  group('Capabilities (what the roles allow) - Unit Test Suite', () {
    const caps = Capabilities(
      isMember: true,
      rolesByGroup: {
        'recepcao': {'publisher'},
        'guias': {'publisher', 'subscriber'},
        'bar': {'subscriber'},
      },
    );

    test('Happy Path: publisher and subscriber groups come sorted', () {
      // 1. Arrange
      const subject = caps;

      // 2. Act
      final groups = [subject.publisherGroupIds, subject.subscriberGroupIds];

      // 3. Assert
      expect(groups, [
        ['guias', 'recepcao'],
        ['bar', 'guias'],
      ]);
    });

    test('Happy Path: a subscriber watches only their own groups', () {
      // 1. Arrange
      const subject = caps;

      // 2. Act
      final watches = [
        for (final id in ['guias', 'bar', 'recepcao', 'outro'])
          subject.canWatchGroup(id),
      ];

      // 3. Assert
      expect(watches, [true, true, false, false]);
    });

    test('Edge Case: an administrator in no group watches every group and '
        'publishes in none', () {
      // 1. Arrange
      const subject = Capabilities(isMember: true, isAdmin: true);

      // 2. Act
      final result = [
        subject.canWatch,
        subject.canWatchGroup('any'),
        subject.canPublish,
      ];

      // 3. Assert
      expect(result, [true, true, false]);
    });

    test('Sad Path: someone who only publishes watches no map', () {
      // 1. Arrange
      const subject = Capabilities(
        isMember: true,
        rolesByGroup: {
          'guias': {'publisher'},
        },
      );

      // 2. Act
      final result = [subject.canPublish, subject.canWatch];

      // 3. Assert
      expect(result, [true, false]);
    });
  });

  group('Capabilities (group maintainers) - Unit Test Suite', () {
    test(
      'Happy Path: the maintained groups come sorted and allow managing',
      () {
        // 1. Arrange
        const caps = Capabilities(
          isMember: true,
          rolesByGroup: {
            'recepcao': {'maintainer', 'publisher'},
            'guias': {'subscriber'},
            'bar': {'maintainer'},
          },
        );

        // 2. Act
        final result = [caps.maintainerGroupIds, caps.canManageGroups];

        // 3. Assert
        expect(result, [
          ['bar', 'recepcao'],
          isTrue,
        ]);
      },
    );

    test('Edge Case: an administrator in no group manages groups', () {
      // 1. Arrange
      const caps = Capabilities(isMember: true, isAdmin: true);

      // 2. Act
      final result = [caps.maintainerGroupIds, caps.canManageGroups];

      // 3. Assert
      expect(result, [isEmpty, isTrue]);
    });

    test('Sad Path: publishing and watching do not allow managing', () {
      // 1. Arrange
      const caps = Capabilities(
        isMember: true,
        rolesByGroup: {
          'guias': {'publisher', 'subscriber'},
        },
      );

      // 2. Act
      final result = caps.canManageGroups;

      // 3. Assert
      expect(result, isFalse);
    });

    test('Sad Path: Gestor do grupo alone shows no map', () {
      // 1. Arrange
      const caps = Capabilities(
        isMember: true,
        rolesByGroup: {
          'guias': {'maintainer'},
        },
      );

      // 2. Act
      final result = [caps.canWatch, caps.canWatchGroup('guias')];

      // 3. Assert
      expect(result, [isFalse, isFalse]);
    });
  });

  group('Capabilities equality - Unit Test Suite', () {
    test('Happy Path: the same roles in another order are equal', () {
      // 1. Arrange
      const a = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'publisher', 'subscriber'},
          'g2': {'subscriber'},
        },
      );
      const b = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g2': {'subscriber'},
          'g1': {'subscriber', 'publisher'},
        },
      );

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isTrue);
    });

    test('Edge Case: the same groups with another role differ', () {
      // 1. Arrange
      const a = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'publisher'},
        },
      );
      const b = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'subscriber'},
        },
      );

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isFalse);
    });

    test('Sad Path: becoming an administrator is a change', () {
      // 1. Arrange
      const a = Capabilities(isMember: true);
      const b = Capabilities(isMember: true, isAdmin: true);

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isFalse);
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
