import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';

void main() {
  group('Group.fromJson - Unit Test Suite', () {
    test('Happy Path: a full entry becomes a group with its people', () {
      // 1. Arrange
      final json = {
        'id': 'g1AbC',
        'name': 'Equipe Norte',
        'createdAt': '2026-10-01T12:00:00.000Z',
        'people': [
          {
            'email': 'ana@x.com',
            'roles': ['publisher', 'subscriber'],
          },
        ],
      };

      // 2. Act
      final group = Group.fromJson(json);

      // 3. Assert
      expect(group?.id, 'g1AbC');
      expect(group?.name, 'Equipe Norte');
      expect(group?.createdAt, DateTime.utc(2026, 10, 1, 12));
      expect(group?.people.single.email, 'ana@x.com');
      expect(group?.people.single.roles, {
        GroupRole.publisher,
        GroupRole.subscriber,
      });
    });

    test('Edge Case: unknown roles are dropped, maintainer is kept', () {
      // 1. Arrange
      final json = {
        'id': 'g1AbC',
        'name': 'Equipe Norte',
        'people': [
          {
            'email': 'ana@x.com',
            'roles': ['maintainer', 'subscriber', 7],
          },
        ],
      };

      // 2. Act
      final group = Group.fromJson(json);

      // 3. Assert
      expect(group?.people.single.roles, {
        GroupRole.maintainer,
        GroupRole.subscriber,
      });
    });

    test('Edge Case: missing people and date give an empty group', () {
      // 1. Arrange
      final json = {'id': 'g2', 'name': 'Equipe Sul'};

      // 2. Act
      final group = Group.fromJson(json);

      // 3. Assert
      expect([group?.people, group?.createdAt], [isEmpty, isNull]);
    });

    final malformed = <String, Object?>{
      'not a map': ['g1', 'Equipe Norte'],
      'null': null,
      'missing id': {'name': 'Equipe Norte'},
      'empty id': {'id': '', 'name': 'Equipe Norte'},
      'id as a number': {'id': 1, 'name': 'Norte'},
      'missing name': {'id': 'g1'},
      'name as null': {'id': 'g1', 'name': null},
    };
    for (final MapEntry(key: label, value: json) in malformed.entries) {
      test('Sad Path: $label gives null', () {
        // 1. Arrange
        final input = json;

        // 2. Act
        final group = Group.fromJson(input);

        // 3. Assert
        expect(group, isNull);
      });
    }
  });

  group('Group.peopleLabel - Unit Test Suite', () {
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
        final team = Group(
          id: 'g1',
          name: 'Equipe Norte',
          people: [
            for (var i = 0; i < count; i++)
              GroupPerson(email: 'p$i@x.com', roles: {GroupRole.publisher}),
          ],
        );

        // 2. Act
        final label = team.peopleLabel;

        // 3. Assert
        expect(label, expected);
      });
    }
  });

  group('normalizeGroupName - Unit Test Suite', () {
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
        final normalized = normalizeGroupName(name);

        // 3. Assert
        expect(normalized, expected);
      });
    }
  });

  group('groupNameProblem - Unit Test Suite', () {
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
        final problem = groupNameProblem(name, existing);

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
        final problem = groupNameProblem(name, existing);

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
        final problem = groupNameProblem(name, existing);

        // 3. Assert
        expect(problem, 'Já existe o grupo Equipe Léste.');
      });
    }
  });

  group('groupRolesLabel - Unit Test Suite', () {
    final cases = <(String, Set<GroupRole>, String)>[
      (
        'Happy Path: both roles in GroupRole order',
        {GroupRole.subscriber, GroupRole.publisher},
        'Em campo · Vê o mapa',
      ),
      ('Edge Case: only Em campo', {GroupRole.publisher}, 'Em campo'),
      ('Edge Case: only Vê o mapa', {GroupRole.subscriber}, 'Vê o mapa'),
      ('Sad Path: no roles give empty text', <GroupRole>{}, ''),
    ];
    for (final (label, input, expected) in cases) {
      test('$label reads "$expected"', () {
        // 1. Arrange
        final roles = input;

        // 2. Act
        final text = groupRolesLabel(roles);

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

  group('groupDeletionLines - Unit Test Suite', () {
    const lastLine =
        'Os trajetos publicados neste grupo são apagados junto. Não dá para '
        'desfazer.';

    test('Happy Path: plural counts give one line each, in order', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = groupDeletionLines(
        loses: 3,
        stays: 2,
        invites: 4,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [
        '3 pessoas só estavam neste grupo e perdem o acesso à Rota Sul.',
        '2 pessoas continuam nos outros grupos.',
        'Os 4 convites pendentes são cancelados.',
        lastLine,
      ]);
    });

    test('Edge Case: counts of one use the singular', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = groupDeletionLines(
        loses: 1,
        stays: 1,
        invites: 1,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [
        '1 pessoa só estava neste grupo e perde o acesso à Rota Sul.',
        '1 pessoa continua nos outros grupos.',
        'O convite pendente é cancelado.',
        lastLine,
      ]);
    });

    test('Edge Case: zero counts leave only the last line', () {
      // 1. Arrange
      const organization = 'Rota Sul';

      // 2. Act
      final lines = groupDeletionLines(
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
      final lines = groupDeletionLines(
        loses: -1,
        stays: -2,
        invites: -3,
        organization: organization,
      );

      // 3. Assert
      expect(lines, [lastLine]);
    });
  });

  group('deletedGroupText - Unit Test Suite', () {
    const stays = 'Quem estava em outros grupos continua neles.';
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
        final text = deletedGroupText(loses: loses, organization: organization);

        // 3. Assert
        expect(text, expected);
      });
    }
  });

  group('rolesChoiceProblem - Unit Test Suite', () {
    test('Happy Path: an administrator may leave only Gestor do grupo', () {
      // 1. Arrange
      final roles = {GroupRole.maintainer};

      // 2. Act
      final problem = rolesChoiceProblem(roles, byAdmin: true);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Sad Path: a maintainer must keep an everyday role', () {
      // 1. Arrange
      final roles = {GroupRole.maintainer};

      // 2. Act
      final problem = rolesChoiceProblem(roles, byAdmin: false);

      // 3. Assert
      expect(problem, 'Marque pelo menos uma opção.');
    });

    test('Happy Path: a maintainer may keep Gestor do grupo with an '
        'everyday role', () {
      // 1. Arrange
      final roles = {GroupRole.maintainer, GroupRole.subscriber};

      // 2. Act
      final problem = rolesChoiceProblem(roles, byAdmin: false);

      // 3. Assert
      expect(problem, isNull);
    });

    for (final byAdmin in [true, false]) {
      test('Sad Path: no role at all is refused '
          '(${byAdmin ? 'administrator' : 'maintainer'})', () {
        // 1. Arrange
        final roles = <GroupRole>{};

        // 2. Act
        final problem = rolesChoiceProblem(roles, byAdmin: byAdmin);

        // 3. Assert
        expect(problem, 'Marque pelo menos uma opção.');
      });
    }
  });

  group('GroupRole.everyday - Unit Test Suite', () {
    test('Happy Path: the everyday roles are Em campo and Vê o mapa', () {
      // 1. Arrange
      const roles = GroupRole.everyday;

      // 2. Act
      final ids = [for (final role in roles) role.id];

      // 3. Assert
      expect(ids, ['publisher', 'subscriber']);
    });
  });

  group('assignableRolesFor - Unit Test Suite', () {
    test('Happy Path: an administrator gives every role', () {
      // 1. Arrange
      const byAdmin = true;

      // 2. Act
      final roles = assignableRolesFor(byAdmin: byAdmin);

      // 3. Assert
      expect(roles, [
        GroupRole.publisher,
        GroupRole.subscriber,
        GroupRole.maintainer,
      ]);
    });

    test('Sad Path: a maintainer never gives Gestor do grupo', () {
      // 1. Arrange
      const byAdmin = false;

      // 2. Act
      final roles = assignableRolesFor(byAdmin: byAdmin);

      // 3. Assert
      expect(roles, [GroupRole.publisher, GroupRole.subscriber]);
    });
  });

  group('canRemoveFromGroup - Unit Test Suite', () {
    const maintainer = GroupPerson(
      email: 'vera@x.com',
      roles: {GroupRole.maintainer, GroupRole.subscriber},
    );
    const fieldWorker = GroupPerson(
      email: 'ana@x.com',
      roles: {GroupRole.publisher},
    );

    test('Happy Path: a maintainer removes someone who is not a '
        'maintainer', () {
      // 1. Arrange
      const person = fieldWorker;

      // 2. Act
      final allowed = canRemoveFromGroup(person, byAdmin: false);

      // 3. Assert
      expect(allowed, isTrue);
    });

    test('Edge Case: an administrator removes a maintainer', () {
      // 1. Arrange
      const person = maintainer;

      // 2. Act
      final allowed = canRemoveFromGroup(person, byAdmin: true);

      // 3. Assert
      expect(allowed, isTrue);
    });

    test('Sad Path: a maintainer cannot remove a maintainer', () {
      // 1. Arrange
      const person = maintainer;

      // 2. Act
      final allowed = canRemoveFromGroup(person, byAdmin: false);

      // 3. Assert
      expect(allowed, isFalse);
    });
  });
}
