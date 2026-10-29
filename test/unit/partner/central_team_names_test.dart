import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/partner/central_team_names.dart';

Map<String, Object?> response(Map<Object?, Object?> names) => {'names': names};

void main() {
  group('parseTeamNames - Unit Test Suite', () {
    test('Happy Path: every named team is returned by its key', () {
      // 1. Arrange
      final data = response({'rotasul01': 'Centro', 'rotasul02': 'Zona Norte'});

      // 2. Act
      final names = parseTeamNames(data);

      // 3. Assert
      expect(names, {'rotasul01': 'Centro', 'rotasul02': 'Zona Norte'});
    });

    test('Edge Case: keys are lowercased and trimmed, names trimmed', () {
      // 1. Arrange
      final data = response({' RotaSul03 ': '  Zona Sul \n'});

      // 2. Act
      final names = parseTeamNames(data);

      // 3. Assert
      expect(names, {'rotasul03': 'Zona Sul'});
    });

    test('Edge Case: no names give an empty map', () {
      // 1. Arrange
      final data = response({});

      // 2. Act
      final names = parseTeamNames(data);

      // 3. Assert
      expect(names, isEmpty);
    });

    test('Sad Path: blank and non-string entries are skipped', () {
      // 1. Arrange
      final data = response({
        'rotasul01': 'Centro',
        'rotasul02': '   ',
        'rotasul03': '',
        'rotasul04': 7,
        'rotasul05': null,
        6: 'Numero',
      });

      // 2. Act
      final names = parseTeamNames(data);

      // 3. Assert
      expect(names, {'rotasul01': 'Centro'});
    });

    final malformed = <(String, Object?)>[
      ('null', null),
      ('a list', ['rotasul01']),
      ('a string', 'Centro'),
      ('a map without names', {'teams': {}}),
      (
        'names that are a list',
        {
          'names': ['Centro'],
        },
      ),
    ];
    for (final (label, data) in malformed) {
      test('Sad Path: a response that is $label gives an empty map', () {
        // 1. Arrange
        final input = data;

        // 2. Act
        final names = parseTeamNames(input);

        // 3. Assert
        expect(names, isEmpty);
      });
    }
  });
}
