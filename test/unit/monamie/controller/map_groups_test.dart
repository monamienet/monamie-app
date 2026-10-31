import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/modules/monamie/controller/map_groups.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

const names = {'g1': 'Recepção', 'g2': 'guias', 'g3': 'Bar'};
const guias = MapGroup(id: 'g2', name: 'guias');
const recepcao = MapGroup(id: 'g1', name: 'Recepção');
const bar = MapGroup(id: 'g3', name: 'Bar');

void main() {
  group('mapGroupsFor - Unit Test Suite', () {
    test('Happy Path: an administrator sees every named group, by name', () {
      // 1. Arrange
      const caps = Capabilities(isMember: true, isAdmin: true);

      // 2. Act
      final groups = mapGroupsFor(caps, names: names, allGroupIds: names.keys);

      // 3. Assert
      expect(groups, [bar, guias, recepcao]);
    });

    test('Happy Path: anyone else sees only their subscriber groups', () {
      // 1. Arrange
      const caps = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'subscriber'},
          'g2': {'publisher'},
        },
      );

      // 2. Act
      final groups = mapGroupsFor(caps, names: names, allGroupIds: names.keys);

      // 3. Assert
      expect(groups, [recepcao]);
    });

    test('Edge Case: a group whose name is not known yet is left out', () {
      // 1. Arrange
      const caps = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g1': {'subscriber'},
          'novo': {'subscriber'},
        },
      );

      // 2. Act
      final groups = mapGroupsFor(caps, names: names);

      // 3. Assert
      expect(groups, [recepcao]);
    });

    test('Sad Path: someone who only publishes sees no group', () {
      // 1. Arrange
      const caps = Capabilities(
        isMember: true,
        rolesByGroup: {
          'g2': {'publisher'},
        },
      );

      // 2. Act
      final groups = mapGroupsFor(caps, names: names);

      // 3. Assert
      expect(groups, isEmpty);
    });
  });

  group('namedGroups - Unit Test Suite', () {
    test('Happy Path: groups come by name ignoring case, once each', () {
      // 1. Arrange
      const ids = ['g1', 'g2', 'g3', 'g2'];

      // 2. Act
      final groups = namedGroups(ids, names);

      // 3. Assert
      expect(groups, [bar, guias, recepcao]);
    });

    test('Edge Case: groups with the same name are ordered by id', () {
      // 1. Arrange
      const sameName = {'b': 'Guias', 'a': 'guias'};

      // 2. Act
      final groups = namedGroups(sameName.keys, sameName);

      // 3. Assert
      expect(groups.map((g) => g.id), ['a', 'b']);
    });

    test('Sad Path: a blank name is shown as "Grupo sem nome"', () {
      // 1. Arrange
      const blank = {'g9': ''};

      // 2. Act
      final groups = namedGroups(blank.keys, blank);

      // 3. Assert
      expect(groups, [const MapGroup(id: 'g9', name: 'Grupo sem nome')]);
    });
  });

  group('groupToObserve - Unit Test Suite', () {
    test('Happy Path: with nothing observed the first group is chosen', () {
      // 1. Arrange
      final groups = [bar, guias];

      // 2. Act
      final next = groupToObserve(groups, null);

      // 3. Assert
      expect(next, bar);
    });

    test('Edge Case: a group still listed stays observed', () {
      // 1. Arrange
      final groups = [bar, guias];

      // 2. Act
      final next = groupToObserve(groups, guias);

      // 3. Assert
      expect(next, isNull);
    });

    test(
      'Edge Case: an observed group no longer listed moves to the first',
      () {
        // 1. Arrange
        final groups = [bar, guias];

        // 2. Act
        final next = groupToObserve(groups, recepcao);

        // 3. Assert
        expect(next, bar);
      },
    );

    test('Sad Path: no groups leave the map as it is', () {
      // 1. Arrange
      final groups = <MapGroup>[];

      // 2. Act
      final next = groupToObserve(groups, guias);

      // 3. Assert
      expect(next, isNull);
    });
  });

  group('renamedSelection - Unit Test Suite', () {
    test('Happy Path: a renamed observed group comes with its new name', () {
      // 1. Arrange
      final groups = [const MapGroup(id: 'g2', name: 'Guias Norte')];

      // 2. Act
      final renamed = renamedSelection(groups, guias);

      // 3. Assert
      expect(renamed, const MapGroup(id: 'g2', name: 'Guias Norte'));
    });

    test('Edge Case: an unchanged name is no rename', () {
      // 1. Arrange
      final groups = [guias];

      // 2. Act
      final renamed = renamedSelection(groups, guias);

      // 3. Assert
      expect(renamed, isNull);
    });

    for (final (label, current) in <(String, MapGroup?)>[
      ('a group no longer listed', recepcao),
      ('nothing observed', null),
    ]) {
      test('Sad Path: $label is no rename', () {
        // 1. Arrange
        final groups = [guias];

        // 2. Act
        final renamed = renamedSelection(groups, current);

        // 3. Assert
        expect(renamed, isNull);
      });
    }
  });

  group('membersOf - Unit Test Suite', () {
    test('Happy Path: people come by name ignoring case', () {
      // 1. Arrange
      final positions = [
        UserModel(email: 'vera@x.com', name: 'vera'),
        UserModel(email: 'ana@x.com', name: 'Ana'),
      ];

      // 2. Act
      final members = membersOf(positions);

      // 3. Assert
      expect(members.map((m) => (m.name, m.email)), [
        ('Ana', 'ana@x.com'),
        ('vera', 'vera@x.com'),
      ]);
    });

    test('Edge Case: surrounding spaces are trimmed from the name', () {
      // 1. Arrange
      final positions = [UserModel(email: 'ana@x.com', name: '  Ana ')];

      // 2. Act
      final members = membersOf(positions);

      // 3. Assert
      expect(members.single.name, 'Ana');
    });

    for (final (label, name) in <(String, String?)>[
      ('a blank name', '   '),
      ('no name', null),
    ]) {
      test('Sad Path: $label shows the e-mail', () {
        // 1. Arrange
        final positions = [UserModel(email: 'ana@x.com', name: name)];

        // 2. Act
        final members = membersOf(positions);

        // 3. Assert
        expect(members.single.name, 'ana@x.com');
      });
    }
  });
}
