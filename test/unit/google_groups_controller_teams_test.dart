import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/monamie/controller/google_groups_controller.dart';
import 'package:monamie_app/app/modules/monamie/models/google_group_model.dart';

Map<String, dynamic> groupEntity(String email, {String? name}) => {
  'type': 'GROUP',
  'email': email,
  'name': ?name,
};

Map<String, dynamic> userEntity(String email) => {
  'type': 'USER',
  'email': email,
};

List<(String, String)> namesAndEmails(List<GoogleGroupModel> teams) => [
  for (final team in teams) (team.name, team.email),
];

void main() {
  group('GoogleGroupsController.teamKeysOf - Unit Test Suite', () {
    test('Happy Path: the partner\'s team groups give their keys', () {
      // 1. Arrange
      final entities = [
        groupEntity('rotasul01@monamienet.org'),
        groupEntity('rotasul02@monamienet.org'),
      ];

      // 2. Act
      final keys = GoogleGroupsController.teamKeysOf('rotasul', entities);

      // 3. Assert
      expect(keys, ['rotasul01', 'rotasul02']);
    });

    test('Edge Case: mixed-case team e-mails give lowercase keys', () {
      // 1. Arrange
      final entities = [groupEntity('RotaSul03@MonAmieNet.org')];

      // 2. Act
      final keys = GoogleGroupsController.teamKeysOf('rotasul', entities);

      // 3. Assert
      expect(keys, ['rotasul03']);
    });

    test(
      'Sad Path: users, leaves, the root and other partners are ignored',
      () {
        // 1. Arrange
        final entities = <Map<String, dynamic>>[
          userEntity('rotasul04@monamienet.org'),
          groupEntity('rotasul01r@monamienet.org'),
          groupEntity('rotasul01w@monamienet.org'),
          groupEntity('rotasul00@monamienet.org'),
          groupEntity('outro01@monamienet.org'),
          {'type': 'GROUP', 'email': 42},
          {'type': 'GROUP'},
          groupEntity('rotasul02@monamienet.org'),
        ];

        // 2. Act
        final keys = GoogleGroupsController.teamKeysOf('rotasul', entities);

        // 3. Assert
        expect(keys, ['rotasul02']);
      },
    );
  });

  group('GoogleGroupsController.teamsFor - Unit Test Suite', () {
    test('Happy Path: one team per key, in order, named from the entries', () {
      // 1. Arrange
      final rootEntities = [
        groupEntity('rotasul02@monamienet.org', name: 'Zona Norte'),
        groupEntity('rotasul01@monamienet.org', name: 'Centro'),
      ];

      // 2. Act
      final teams = GoogleGroupsController.teamsFor(
        ['rotasul01', 'rotasul02'],
        rootEntities,
        const [],
      );

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Centro', 'rotasul01@monamienet.org'),
        ('Zona Norte', 'rotasul02@monamienet.org'),
      ]);
    });

    test('Happy Path: a name from the user\'s groups is used', () {
      // 1. Arrange
      final userGroups = [
        groupEntity('rotasul01@monamienet.org', name: 'Centro'),
      ];

      // 2. Act
      final teams = GoogleGroupsController.teamsFor(
        ['rotasul01'],
        const [],
        userGroups,
      );

      // 3. Assert
      expect(namesAndEmails(teams), [('Centro', 'rotasul01@monamienet.org')]);
    });

    test('Edge Case: the root entities win when both name the team', () {
      // 1. Arrange
      final rootEntities = [
        groupEntity('rotasul01@monamienet.org', name: 'Centro (raiz)'),
      ];
      final userGroups = [
        groupEntity('rotasul01@monamienet.org', name: 'Centro (usuario)'),
      ];

      // 2. Act
      final teams = GoogleGroupsController.teamsFor(
        ['rotasul01'],
        rootEntities,
        userGroups,
      );

      // 3. Assert
      expect(teams.single.name, 'Centro (raiz)');
    });

    test('Edge Case: no keys give no teams', () {
      // 1. Arrange
      final rootEntities = [
        groupEntity('rotasul01@monamienet.org', name: 'Centro'),
      ];

      // 2. Act
      final teams = GoogleGroupsController.teamsFor(
        const [],
        rootEntities,
        const [],
      );

      // 3. Assert
      expect(teams, isEmpty);
    });

    test('Sad Path: a team nobody names falls back to "Equipe NN"', () {
      // 1. Arrange
      // A leaf's name is not the team's name.
      final userGroups = [
        groupEntity('rotasul07w@monamienet.org', name: 'Centro · em campo'),
      ];

      // 2. Act
      final teams = GoogleGroupsController.teamsFor(
        ['rotasul07'],
        const [],
        userGroups,
      );

      // 3. Assert
      expect(namesAndEmails(teams), [
        ('Equipe 07', 'rotasul07@monamienet.org'),
      ]);
    });
  });

  group('GoogleGroupsController.shareLeafEmail - Unit Test Suite', () {
    final cases = <(String, String, String)>[
      (
        'Happy Path: a team gives its share leaf',
        'rotasul01@monamienet.org',
        'rotasul01w@monamienet.org',
      ),
      (
        'Edge Case: a mixed-case team gives a lowercase leaf',
        'RotaSul02@MonAmieNet.org',
        'rotasul02w@monamienet.org',
      ),
      (
        'Sad Path: an unparsable address is returned unchanged',
        'ti-suporte@monamienet.org',
        'ti-suporte@monamienet.org',
      ),
    ];
    for (final (label, input, expected) in cases) {
      test('$label ("$input")', () {
        // 1. Arrange
        final teamEmail = input;

        // 2. Act
        final leaf = GoogleGroupsController.shareLeafEmail(teamEmail);

        // 3. Assert
        expect(leaf, expected);
      });
    }
  });
}
