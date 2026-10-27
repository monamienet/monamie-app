import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/group_directory.dart';
import '../../../tool/src/migrate_groups_command.dart';

GroupMember person(String email, String role) =>
    GroupMember(email: email, isGroup: false, role: role);

GroupMember subgroup(String email) => GroupMember(email: email, isGroup: true);

LegacyTeam team(String email, List<GroupMember> members) =>
    LegacyTeam(email: email, name: 'Centro', members: members);

/// The leaves of rotasul01, created and nested.
const leavesOfRotasul01 = [
  'create rotasul01r@monamienet.org ("Centro · vê o mapa")',
  'add rotasul01r@monamienet.org to rotasul01@monamienet.org',
  'create rotasul01w@monamienet.org ("Centro · em campo")',
  'add rotasul01w@monamienet.org to rotasul01@monamienet.org',
];

List<String> plan(
  List<LegacyTeam> teams, {
  Set<String> existingGroups = const {},
  Set<String> ownersAlsoShare = const {},
}) => [
  for (final change in planGroupMigration(
    teams,
    existingGroups: existingGroups,
    ownersAlsoShare: ownersAlsoShare,
  ))
    change.toString(),
];

void main() {
  group('planGroupMigration - Unit Test Suite', () {
    test(
      'Happy Path: creates and nests the leaves, then moves each person',
      () {
        // 1. Arrange
        final teams = [
          team('rotasul01@monamienet.org', [
            person('ana@example.com', 'MEMBER'),
            person('bia@example.com', 'OWNER'),
          ]),
        ];

        // 2. Act
        final changes = plan(teams);

        // 3. Assert
        expect(changes, [
          ...leavesOfRotasul01,
          'add ana@example.com to rotasul01w@monamienet.org',
          'remove ana@example.com from rotasul01@monamienet.org',
          'add bia@example.com to rotasul01r@monamienet.org',
          'remove bia@example.com from rotasul01@monamienet.org',
        ]);
      },
    );

    test('Happy Path: a MANAGER shares, like a MEMBER', () {
      // 1. Arrange
      final teams = [
        team('rotasul01@monamienet.org', [
          person('caio@example.com', 'MANAGER'),
        ]),
      ];

      // 2. Act
      final changes = plan(teams);

      // 3. Assert
      expect(changes, [
        ...leavesOfRotasul01,
        'add caio@example.com to rotasul01w@monamienet.org',
        'remove caio@example.com from rotasul01@monamienet.org',
      ]);
    });

    test('Edge Case: an OWNER listed in ownersAlsoShare joins both leaves', () {
      // 1. Arrange
      final teams = [
        team('rotasul01@monamienet.org', [person('bia@example.com', 'OWNER')]),
      ];

      // 2. Act
      final changes = plan(teams, ownersAlsoShare: {'bia@example.com'});

      // 3. Assert
      expect(changes, [
        ...leavesOfRotasul01,
        'add bia@example.com to rotasul01r@monamienet.org',
        'add bia@example.com to rotasul01w@monamienet.org',
        'remove bia@example.com from rotasul01@monamienet.org',
      ]);
    });

    test(
      'Edge Case: leaves that exist and are nested are not planned again',
      () {
        // 1. Arrange
        final teams = [
          team('rotasul01@monamienet.org', [
            subgroup('rotasul01r@monamienet.org'),
            subgroup('rotasul01w@monamienet.org'),
            person('ana@example.com', 'MEMBER'),
          ]),
        ];

        // 2. Act
        final changes = plan(
          teams,
          existingGroups: {
            'rotasul01r@monamienet.org',
            'rotasul01w@monamienet.org',
          },
        );

        // 3. Assert
        expect(changes, [
          'add ana@example.com to rotasul01w@monamienet.org',
          'remove ana@example.com from rotasul01@monamienet.org',
        ]);
      },
    );

    test('Edge Case: an existing leaf that is not nested is only nested', () {
      // 1. Arrange
      final teams = [team('rotasul01@monamienet.org', const [])];

      // 2. Act
      final changes = plan(
        teams,
        existingGroups: {'rotasul01r@monamienet.org'},
      );

      // 3. Assert
      expect(changes, [
        'add rotasul01r@monamienet.org to rotasul01@monamienet.org',
        'create rotasul01w@monamienet.org ("Centro · em campo")',
        'add rotasul01w@monamienet.org to rotasul01@monamienet.org',
      ]);
    });

    test('Sad Path: teams whose address is not a team group are skipped', () {
      // 1. Arrange
      final members = [person('ana@example.com', 'MEMBER')];
      final teams = [
        team('rotasul00@monamienet.org', members),
        team('rotasul01w@monamienet.org', members),
        team('ti-suporte@monamienet.org', members),
        team('rotasul01@gmail.com', members),
      ];

      // 2. Act
      final changes = plan(teams);

      // 3. Assert
      expect(changes, isEmpty);
    });
  });
}
