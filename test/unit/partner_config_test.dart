import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';

/// A valid decoded `partner.json`, as `jsonDecode` returns it.
Map<String, dynamic> validJson({
  Object? name = 'Acme',
  Object? primary = '#112233',
  Object? secondary = '#FFFFFF',
}) =>
    jsonDecode(
          jsonEncode({
            'name': name,
            'colors': {'primary': primary, 'secondary': secondary},
          }),
        )
        as Map<String, dynamic>;

/// Matches a [FormatException] whose message mentions [field].
Matcher formatExceptionNaming(String field) => throwsA(
  isA<FormatException>().having(
    (error) => error.message,
    'message',
    contains(field),
  ),
);

/// Matches the [FormatException] of an invalid id: its message starts with
/// `"id": `.
final throwsIdFormatException = throwsA(
  isA<FormatException>().having(
    (error) => error.message,
    'message',
    startsWith('"id": '),
  ),
);

void main() {
  group('partnerIdProblem - Unit Test Suite', () {
    test('Happy Path: a lowercase id has no problem', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: a single letter has no problem', () {
      // 1. Arrange
      const id = 'a';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: digits after the first letter have no problem', () {
      // 1. Arrange
      const id = 'acme2go';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: "test" after the start has no problem', () {
      // 1. Arrange
      const id = 'contest';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: an id that only starts with a reserved name has no '
        'problem', () {
      // 1. Arrange
      const id = 'debugger';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Sad Path: an uppercase id is reported naming the id', () {
      // 1. Arrange
      const id = 'Acme';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, contains("'Acme'"));
    });

    test('Sad Path: the problem states every rule', () {
      // 1. Arrange
      const id = 'acme-tur';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(
        problem,
        allOf([
          contains('acme-tur'),
          contains(r'^[a-z][a-z0-9]*$'),
          contains("'test'"),
          contains('lint'),
          contains('main'),
          contains('debug'),
          contains('release'),
          contains('profile'),
        ]),
      );
    });

    test('Sad Path: an empty id is reported', () {
      // 1. Arrange
      const id = '';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: an id starting with a digit is reported', () {
      // 1. Arrange
      const id = '9acme';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, contains('9acme'));
    });

    test('Sad Path: an id with a trailing newline is reported', () {
      // 1. Arrange
      const id = 'acme\n';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: an id starting with "test" is reported', () {
      // 1. Arrange
      const id = 'testacme';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, contains('testacme'));
    });

    test('Sad Path: the reserved id "lint" is reported', () {
      // 1. Arrange
      const id = 'lint';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: the reserved id "main" is reported', () {
      // 1. Arrange
      const id = 'main';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: the reserved id "debug" is reported', () {
      // 1. Arrange
      const id = 'debug';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: the reserved id "release" is reported', () {
      // 1. Arrange
      const id = 'release';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: the reserved id "profile" is reported', () {
      // 1. Arrange
      const id = 'profile';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });
  });

  group('PartnerConfig.fromJson valid content - Unit Test Suite', () {
    test('Happy Path: keeps the given id', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.id, 'acme');
    });

    test('Happy Path: reads the name', () {
      // 1. Arrange
      final json = validJson(name: 'Acme');

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.name, 'Acme');
    });

    test('Happy Path: derives displayName as "MonAmie <name>"', () {
      // 1. Arrange
      final json = validJson(name: 'AquariusTur');

      // 2. Act
      final config = PartnerConfig.fromJson('aquariustur', json);

      // 3. Assert
      expect(config.displayName, 'MonAmie AquariusTur');
    });

    test('Happy Path: exposes colors.primary as an opaque Color', () {
      // 1. Arrange
      final json = validJson(primary: '#0ABAB5');

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.primaryColor, const Color(0xFF0ABAB5));
    });

    test('Happy Path: exposes colors.secondary as an opaque Color', () {
      // 1. Arrange
      final json = validJson(secondary: '#FFFFFF');

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.secondaryColor, const Color(0xFFFFFFFF));
    });

    test('Happy Path: parses the real-world partner.json shape', () {
      // 1. Arrange
      final json = jsonDecode('''
{
  "name": "AquariusTur",
  "colors": {
    "primary": "#0ABAB5",
    "secondary": "#FFFFFF"
  }
}
''');

      // 2. Act
      final config = PartnerConfig.fromJson('aquariustur', json);

      // 3. Assert
      expect(
        [config.id, config.name, config.primaryColor, config.secondaryColor],
        [
          'aquariustur',
          'AquariusTur',
          const Color(0xFF0ABAB5),
          const Color(0xFFFFFFFF),
        ],
      );
    });

    test('Edge Case: accepts a lowercase #rrggbb color', () {
      // 1. Arrange
      final json = validJson(primary: '#0abab5');

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.primaryColor, const Color(0xFF0ABAB5));
    });

    test('Edge Case: accepts a mixed-case color', () {
      // 1. Arrange
      final json = validJson(secondary: '#aBcDeF');

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.secondaryColor, const Color(0xFFABCDEF));
    });

    test('Edge Case: #000000 becomes opaque black, not transparent', () {
      // 1. Arrange
      final json = validJson(primary: '#000000');

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.primaryColor.a, 1.0);
    });

    test('Edge Case: keeps spaces and accents of the name', () {
      // 1. Arrange
      final json = validJson(name: 'Acmé Tur');

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.displayName, 'MonAmie Acmé Tur');
    });

    test('Edge Case: ignores unrelated extra keys', () {
      // 1. Arrange
      final json = validJson()
        ..['extra'] = [1, 2]
        ..['colors']['tertiary'] = '#000000';

      // 2. Act
      final config = PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(config.name, 'Acme');
    });

    test('Edge Case: accepts an id with digits after the first letter', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      final config = PartnerConfig.fromJson('acme2go', json);

      // 3. Assert
      expect(config.id, 'acme2go');
    });

    test('Edge Case: accepts an id that only contains "test" after its '
        'start', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      final config = PartnerConfig.fromJson('contest', json);

      // 3. Assert
      expect(config.id, 'contest');
    });

    test('Edge Case: accepts an id that only starts with a reserved name', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      final config = PartnerConfig.fromJson('mainstreet', json);

      // 3. Assert
      expect(config.id, 'mainstreet');
    });
  });

  group('PartnerConfig.fromJson invalid id - Unit Test Suite', () {
    test('Sad Path: rejects an empty id', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id with uppercase letters', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('Acme', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id starting with a digit', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('1acme', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id with a hyphen', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme-tur', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id with an underscore', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme_tur', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id with surrounding whitespace', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson(' acme ', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id with a trailing newline', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme\n', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id with a path separator', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme/beta', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects the id "test"', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('test', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects an id starting with "test"', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('testing', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects the reserved id "lint"', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('lint', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects the reserved id "main"', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('main', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects the reserved id "debug"', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('debug', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects the reserved id "release"', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('release', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });

    test('Sad Path: rejects the reserved id "profile"', () {
      // 1. Arrange
      final json = validJson();

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('profile', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });
  });

  group('PartnerConfig.fromJson id message - Unit Test Suite', () {
    test('Sad Path: the id error carries the partnerIdProblem message', () {
      // 1. Arrange
      final json = validJson();
      final expected = '"id": ${partnerIdProblem('Acme')}';

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('Acme', json);

      // 3. Assert
      expect(
        action,
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            expected,
          ),
        ),
      );
    });

    test('Sad Path: the id is checked before the content', () {
      // 1. Arrange
      final json = jsonDecode('[1, 2]');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('debug', json);

      // 3. Assert
      expect(action, throwsIdFormatException);
    });
  });

  group('PartnerConfig.fromJson invalid content - Unit Test Suite', () {
    test('Sad Path: rejects a JSON array', () {
      // 1. Arrange
      final json = jsonDecode('[1, 2]');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: rejects a JSON string', () {
      // 1. Arrange
      final json = jsonDecode('"Acme"');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: rejects a JSON null', () {
      // 1. Arrange
      final json = jsonDecode('null');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: an empty object names "name" as the invalid field', () {
      // 1. Arrange
      final json = jsonDecode('{}');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"name"'));
    });

    test('Sad Path: rejects a missing name', () {
      // 1. Arrange
      final json = validJson()..remove('name');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"name"'));
    });

    test('Sad Path: rejects a null name', () {
      // 1. Arrange
      final json = validJson(name: null);

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"name"'));
    });

    test('Sad Path: rejects a numeric name', () {
      // 1. Arrange
      final json = validJson(name: 42);

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"name"'));
    });

    test('Sad Path: rejects an empty name', () {
      // 1. Arrange
      final json = validJson(name: '');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"name"'));
    });

    test('Sad Path: rejects a blank name', () {
      // 1. Arrange
      final json = validJson(name: ' \t\n ');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"name"'));
    });

    test('Sad Path: rejects a missing colors', () {
      // 1. Arrange
      final json = validJson()..remove('colors');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"colors"'));
    });

    test('Sad Path: rejects a colors that is a string', () {
      // 1. Arrange
      final json = validJson()..['colors'] = '#112233';

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"colors"'));
    });

    test('Sad Path: rejects a colors that is an array', () {
      // 1. Arrange
      final json = validJson()..['colors'] = ['#112233', '#FFFFFF'];

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('"colors"'));
    });

    test('Sad Path: rejects a missing colors.primary', () {
      // 1. Arrange
      final json = validJson()..['colors'].remove('primary');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a missing colors.secondary', () {
      // 1. Arrange
      final json = validJson()..['colors'].remove('secondary');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.secondary'));
    });

    test('Sad Path: rejects a short #RGB primary color', () {
      // 1. Arrange
      final json = validJson(primary: '#123');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a #AARRGGBB primary color', () {
      // 1. Arrange
      final json = validJson(primary: '#FF112233');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a primary color without "#"', () {
      // 1. Arrange
      final json = validJson(primary: '112233');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a primary color with non-hex digits', () {
      // 1. Arrange
      final json = validJson(primary: '#GGHHII');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a primary color with surrounding whitespace', () {
      // 1. Arrange
      final json = validJson(primary: ' #112233 ');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a named primary color', () {
      // 1. Arrange
      final json = validJson(primary: 'teal');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a numeric primary color', () {
      // 1. Arrange
      final json = validJson(primary: 0x112233);

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.primary'));
    });

    test('Sad Path: rejects a short #RGB secondary color', () {
      // 1. Arrange
      final json = validJson(secondary: '#FFF');

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.secondary'));
    });

    test('Sad Path: rejects a null secondary color', () {
      // 1. Arrange
      final json = validJson(secondary: null);

      // 2. Act
      PartnerConfig action() => PartnerConfig.fromJson('acme', json);

      // 3. Assert
      expect(action, formatExceptionNaming('colors.secondary'));
    });
  });

  group('PartnerConfig.displayName - Unit Test Suite', () {
    test('Happy Path: prefixes the name with "MonAmie "', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        primaryColor: Color(0xFF112233),
        secondaryColor: Color(0xFFFFFFFF),
      );

      // 2. Act
      final displayName = config.displayName;

      // 3. Assert
      expect(displayName, 'MonAmie Acme');
    });
  });
}
