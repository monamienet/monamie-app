import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/admin/teams/team.dart';

void main() {
  group('Team.fromJson - Unit Test Suite', () {
    test('Happy Path: a full entry becomes a team with its people', () {
      // 1. Arrange
      final json = {
        'team': '01',
        'key': 'rotasul01',
        'name': 'Equipe Norte',
        'people': [
          {
            'email': 'ana@x.com',
            'roles': ['share', 'watch'],
          },
        ],
      };

      // 2. Act
      final team = Team.fromJson(json);

      // 3. Assert
      expect(team?.number, '01');
      expect(team?.key, 'rotasul01');
      expect(team?.name, 'Equipe Norte');
      expect(team?.people.single.email, 'ana@x.com');
      expect(team?.people.single.roles, {TeamRole.share, TeamRole.watch});
    });

    test('Edge Case: unknown roles are dropped, known ones kept', () {
      // 1. Arrange
      final json = {
        'team': '01',
        'key': 'rotasul01',
        'name': 'Equipe Norte',
        'people': [
          {
            'email': 'ana@x.com',
            'roles': ['admin', 'watch', 7],
          },
        ],
      };

      // 2. Act
      final team = Team.fromJson(json);

      // 3. Assert
      expect(team?.people.single.roles, {TeamRole.watch});
    });

    test('Edge Case: missing people give an empty team', () {
      // 1. Arrange
      final json = {'team': '02', 'key': 'rotasul02', 'name': 'Equipe Sul'};

      // 2. Act
      final team = Team.fromJson(json);

      // 3. Assert
      expect(team?.people, isEmpty);
    });

    final malformed = <String, Object?>{
      'not a map': ['01', 'rotasul01', 'Equipe Norte'],
      'null': null,
      'missing team': {'key': 'rotasul01', 'name': 'Equipe Norte'},
      'team as a number': {'team': 1, 'key': 'rotasul01', 'name': 'Norte'},
      'missing key': {'team': '01', 'name': 'Equipe Norte'},
      'key as a number': {'team': '01', 'key': 1, 'name': 'Equipe Norte'},
      'missing name': {'team': '01', 'key': 'rotasul01'},
      'name as null': {'team': '01', 'key': 'rotasul01', 'name': null},
    };
    for (final MapEntry(key: label, value: json) in malformed.entries) {
      test('Sad Path: $label gives null', () {
        // 1. Arrange
        final input = json;

        // 2. Act
        final team = Team.fromJson(input);

        // 3. Assert
        expect(team, isNull);
      });
    }
  });

  group('Team.peopleLabel - Unit Test Suite', () {
    final cases = {
      0: 'Ninguém ainda', // Edge Case: nobody
      1: '1 pessoa', // Edge Case: singular
      3: '3 pessoas', // Happy Path: plural
    };
    for (final MapEntry(key: count, value: expected) in cases.entries) {
      final kind = switch (count) {
        3 => 'Happy Path',
        _ => 'Edge Case',
      };
      test('$kind: $count people read "$expected"', () {
        // 1. Arrange
        final team = Team(
          number: '01',
          key: 'rotasul01',
          name: 'Equipe Norte',
          people: [
            for (var i = 0; i < count; i++)
              TeamPerson(email: 'p$i@x.com', roles: {TeamRole.share}),
          ],
        );

        // 2. Act
        final label = team.peopleLabel;

        // 3. Assert
        expect(label, expected);
      });
    }
  });

  group('normalizeTeamName - Unit Test Suite', () {
    final cases = <(String, String, String)>[
      (
        'Happy Path: accents, case and spaces',
        '  Equipe   Léste ',
        'equipe leste',
      ),
      ('Happy Path: a plain name stays', 'equipe norte', 'equipe norte'),
      ('Edge Case: every Portuguese a', 'áàâãä', 'aaaaa'),
      ('Edge Case: every Portuguese e', 'éèêë', 'eeee'),
      ('Edge Case: every Portuguese i', 'íìîï', 'iiii'),
      ('Edge Case: every Portuguese o', 'óòôõö', 'ooooo'),
      ('Edge Case: every Portuguese u', 'úùûü', 'uuuu'),
      ('Edge Case: cedilla and eñe', 'çñ', 'cn'),
      ('Edge Case: upper case accents', 'AÇÃO ÉÔ', 'acao eo'),
      ('Edge Case: tabs and new lines collapse', 'Equipe\t\nSul', 'equipe sul'),
      ('Sad Path: blank text becomes empty', '   ', ''),
    ];
    for (final (label, input, expected) in cases) {
      test('$label ("$input")', () {
        // 1. Arrange
        final name = input;

        // 2. Act
        final normalized = normalizeTeamName(name);

        // 3. Assert
        expect(normalized, expected);
      });
    }
  });

  group('teamNameProblem - Unit Test Suite', () {
    const existing = ['Equipe Norte', 'Equipe Léste'];

    final valid = <(String, String)>[
      ('Happy Path: a new name', 'Equipe Serra'),
      ('Edge Case: two accented letters are enough', 'Zé'),
      ('Edge Case: exactly 40 characters', 'a' * 40),
      (
        'Edge Case: 40 characters after collapsing spaces',
        '  ${'a' * 20}     ${'b' * 19}  ',
      ),
    ];
    for (final (label, input) in valid) {
      test('$label is valid', () {
        // 1. Arrange
        final name = input;

        // 2. Act
        final problem = teamNameProblem(name, existing);

        // 3. Assert
        expect(problem, isNull);
      });
    }

    final invalid = <(String, String)>[
      ('Sad Path: one letter and a digit', 'A1'),
      ('Sad Path: digits only', '1 2'),
      ('Sad Path: blank text', '    '),
      ('Sad Path: 41 characters', 'a' * 41),
      ('Sad Path: the signs × and ÷ are not letters', '×÷'),
    ];
    for (final (label, input) in invalid) {
      test('$label is refused', () {
        // 1. Arrange
        final name = input;

        // 2. Act
        final problem = teamNameProblem(name, existing);

        // 3. Assert
        expect(problem, isNotNull);
      });
    }

    final duplicates = <(String, String)>[
      ('Sad Path: same name in another case', 'EQUIPE LÉSTE'),
      ('Sad Path: same name without the accent', 'equipe leste'),
      ('Sad Path: same name with extra spaces', '  Equipe    Léste '),
    ];
    for (final (label, input) in duplicates) {
      test('$label names the existing team', () {
        // 1. Arrange
        final name = input;

        // 2. Act
        final problem = teamNameProblem(name, existing);

        // 3. Assert
        expect(problem, 'Já existe a equipe Equipe Léste.');
      });
    }
  });

  group('teamRolesLabel - Unit Test Suite', () {
    final cases = <(String, Set<TeamRole>, String)>[
      (
        'Happy Path: both roles in TeamRole order',
        {TeamRole.watch, TeamRole.share},
        'Em campo · Vê o mapa',
      ),
      ('Edge Case: only Em campo', {TeamRole.share}, 'Em campo'),
      ('Edge Case: only Vê o mapa', {TeamRole.watch}, 'Vê o mapa'),
      ('Sad Path: no roles give empty text', <TeamRole>{}, ''),
    ];
    for (final (label, input, expected) in cases) {
      test('$label reads "$expected"', () {
        // 1. Arrange
        final roles = input;

        // 2. Act
        final text = teamRolesLabel(roles);

        // 3. Assert
        expect(text, expected);
      });
    }
  });

  group('initialsOf - Unit Test Suite', () {
    final cases = <(String, String, String)>[
      ('Happy Path: an e-mail', 'ana.lima@gmail.com', 'AL'),
      ('Happy Path: a full name', 'ana lima', 'AL'),
      ('Edge Case: only the first two words count', 'Ana Maria Lima', 'AM'),
      ('Edge Case: a single word gives one letter', 'davi', 'D'),
      ('Edge Case: repeated separators are skipped', '  .ana@@lima ', 'AL'),
      ('Edge Case: accented letters are capitalized', 'érica ângela', 'ÉÂ'),
      ('Sad Path: empty text', '', '?'),
      ('Sad Path: separators only', ' .@ ', '?'),
    ];
    for (final (label, input, expected) in cases) {
      test('$label ("$input") gives "$expected"', () {
        // 1. Arrange
        final text = input;

        // 2. Act
        final initials = initialsOf(text);

        // 3. Assert
        expect(initials, expected);
      });
    }
  });

  group('pendingInvitesLabel - Unit Test Suite', () {
    final cases = <(String, int, String)>[
      ('Happy Path: plural', 3, '3 convites pendentes'),
      ('Edge Case: singular', 1, '1 convite pendente'),
      ('Edge Case: none', 0, ''),
      ('Sad Path: a negative count reads as none', -1, ''),
    ];
    for (final (label, count, expected) in cases) {
      test('$label ($count) reads "$expected"', () {
        // 1. Arrange
        final input = count;

        // 2. Act
        final text = pendingInvitesLabel(input);

        // 3. Assert
        expect(text, expected);
      });
    }
  });

  group('teamDeletionLines - Unit Test Suite', () {
    const lastLine =
        'Os trajetos antigos continuam no histórico. Não dá para desfazer.';

    test('Happy Path: plural counts give one line each, in order', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = teamDeletionLines(
        loses: 3,
        stays: 2,
        invites: 4,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [
        '3 pessoas só estavam nesta equipe e perdem o acesso à Rota Sul.',
        '2 pessoas continuam nas outras equipes.',
        'Os 4 convites pendentes são cancelados.',
        lastLine,
      ]);
    });

    test('Edge Case: counts of one use the singular', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = teamDeletionLines(
        loses: 1,
        stays: 1,
        invites: 1,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [
        '1 pessoa só estava nesta equipe e perde o acesso à Rota Sul.',
        '1 pessoa continua nas outras equipes.',
        'O convite pendente é cancelado.',
        lastLine,
      ]);
    });

    test('Edge Case: zero counts leave only the last line', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = teamDeletionLines(
        loses: 0,
        stays: 0,
        invites: 0,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [lastLine]);
    });

    test('Sad Path: negative counts are left out', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = teamDeletionLines(
        loses: -1,
        stays: -2,
        invites: -3,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [lastLine]);
    });
  });

  group('deletedTeamText - Unit Test Suite', () {
    const stays = 'Quem estava em outras equipes continua nelas.';
    final cases = <(String, int, String)>[
      (
        'Happy Path: plural',
        3,
        '3 pessoas perderam o acesso à Rota Sul. $stays',
      ),
      ('Edge Case: singular', 1, '1 pessoa perdeu o acesso à Rota Sul. $stays'),
      ('Edge Case: nobody lost access', 0, stays),
      ('Sad Path: a negative count reads as nobody', -2, stays),
    ];
    for (final (label, loses, expected) in cases) {
      test('$label ($loses)', () {
        // 1. Arrange
        const organization = 'Rota Sul';

        // 2. Act
        final text = deletedTeamText(loses: loses, organization: organization);

        // 3. Assert
        expect(text, expected);
      });
    }
  });
}
