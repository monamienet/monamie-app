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
}
