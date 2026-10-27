import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';

const logoSvg = '<svg xmlns="http://www.w3.org/2000/svg"><rect/></svg>';
const iconSvg = '<svg xmlns="http://www.w3.org/2000/svg"><circle/></svg>';

/// A complete `config/branding` document, as the partner tool publishes it.
Map<String, Object?> fullBranding() => {
  'name': 'AquariusTur',
  'colors': {'primary': '#0ABAB5', 'secondary': '#FFFFFF'},
  'logoSvg': logoSvg,
  'iconSvg': iconSvg,
};

/// The fields of [config], so two configs can be compared by value.
List<Object?> fieldsOf(PartnerConfig config) => [
  config.id,
  config.name,
  config.primaryColor,
  config.secondaryColor,
  config.logoSvg,
  config.iconSvg,
];

void main() {
  group('partnerIdProblem - Unit Test Suite', () {
    test('Happy Path: a lowercase id is valid', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Happy Path: an id with digits after the first letter is valid', () {
      // 1. Arrange
      const id = 'tur2';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: a single letter is a valid id', () {
      // 1. Arrange
      const id = 'x';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNull);
    });

    test('Sad Path: the reserved id "app" is invalid', () {
      // 1. Arrange
      const id = 'app';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, allOf(isNotNull, contains("'app'")));
    });

    test('Sad Path: an empty id is invalid', () {
      // 1. Arrange
      const id = '';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: an id with upper case letters is invalid', () {
      // 1. Arrange
      const id = 'AquariusTur';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: an id starting with a digit is invalid', () {
      // 1. Arrange
      const id = '2tur';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });

    test('Sad Path: an id with a hyphen is invalid', () {
      // 1. Arrange
      const id = 'aquarius-tur';

      // 2. Act
      final problem = partnerIdProblem(id);

      // 3. Assert
      expect(problem, isNotNull);
    });
  });

  group('partnerIdFromGroupEmail - Unit Test Suite', () {
    const cases = <({String label, String email, String? expected})>[
      (
        label: 'Happy Path: a subgroup gives its partner id',
        email: 'aquariustur01@monamienet.org',
        expected: 'aquariustur',
      ),
      (
        label: 'Happy Path: the root group (00) gives its partner id',
        email: 'aquariustur00@monamienet.org',
        expected: 'aquariustur',
      ),
      (
        label: 'Edge Case: upper case letters are normalized',
        email: 'AquariusTur01@MonAmieNet.ORG',
        expected: 'aquariustur',
      ),
      (
        label: 'Edge Case: surrounding whitespace is ignored',
        email: '  aquariustur01@monamienet.org \n',
        expected: 'aquariustur',
      ),
      (
        label: 'Edge Case: only the last two digits are the suffix',
        email: 'tur201@monamienet.org',
        expected: 'tur2',
      ),
      (
        label: 'Edge Case: the shortest valid local part (3 characters)',
        email: 'x01@monamienet.org',
        expected: 'x',
      ),
      (
        label: 'Sad Path: the reserved id "app" gives null',
        email: 'app01@monamienet.org',
        expected: null,
      ),
      (
        label: 'Sad Path: another domain gives null',
        email: 'aquariustur01@gmail.com',
        expected: null,
      ),
      (
        label: 'Sad Path: a subdomain of the group domain gives null',
        email: 'aquariustur01@sub.monamienet.org',
        expected: null,
      ),
      (
        label: 'Sad Path: a local part without a suffix gives null',
        email: 'aquariustur@monamienet.org',
        expected: null,
      ),
      (
        label: 'Sad Path: a one-digit suffix gives null',
        email: 'aquariustur1@monamienet.org',
        expected: null,
      ),
      (
        label: 'Sad Path: a local part shorter than 3 characters gives null',
        email: '01@monamienet.org',
        expected: null,
      ),
      (
        label: 'Sad Path: an id that is not valid gives null',
        email: '2tur01@monamienet.org',
        expected: null,
      ),
      (
        label: 'Sad Path: an id with a hyphen gives null',
        email: 'ti-suporte01@monamienet.org',
        expected: null,
      ),
      (
        label: 'Sad Path: a text without @ gives null',
        email: 'aquariustur01',
        expected: null,
      ),
      (label: 'Sad Path: an empty text gives null', email: '', expected: null),
    ];

    for (final c in cases) {
      test('${c.label} ("${c.email.trim()}")', () {
        // 1. Arrange
        final email = c.email;

        // 2. Act
        final id = partnerIdFromGroupEmail(email);

        // 3. Assert
        expect(id, c.expected);
      });
    }
  });

  group('rootGroupEmailFor / firebaseProjectIdFor - Unit Test Suite', () {
    test('Happy Path: the root group is <id>00@monamienet.org', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final email = rootGroupEmailFor(id);

      // 3. Assert
      expect(email, 'aquariustur00@monamienet.org');
    });

    test('Edge Case: the root group maps back to its partner id', () {
      // 1. Arrange
      final email = rootGroupEmailFor('tur2');

      // 2. Act
      final id = partnerIdFromGroupEmail(email);

      // 3. Assert
      expect(id, 'tur2');
    });

    test('Happy Path: the Firebase project is monamienet-<id>', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final projectId = firebaseProjectIdFor(id);

      // 3. Assert
      expect(projectId, 'monamienet-aquariustur');
    });
  });

  group('fallbackPartnerName - Unit Test Suite', () {
    test('Happy Path: capitalizes the first letter of the id', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final name = fallbackPartnerName(id);

      // 3. Assert
      expect(name, 'Aquariustur');
    });

    test('Edge Case: a one-letter id becomes upper case', () {
      // 1. Arrange
      const id = 'x';

      // 2. Act
      final name = fallbackPartnerName(id);

      // 3. Assert
      expect(name, 'X');
    });

    test('Edge Case: an empty id gives an empty name', () {
      // 1. Arrange
      const id = '';

      // 2. Act
      final name = fallbackPartnerName(id);

      // 3. Assert
      expect(name, '');
    });
  });

  group('PartnerConfig.fromBranding - Unit Test Suite', () {
    test('Happy Path: reads every field of a complete document', () {
      // 1. Arrange
      final data = fullBranding();

      // 2. Act
      final config = PartnerConfig.fromBranding('aquariustur', data);

      // 3. Assert
      expect(fieldsOf(config), [
        'aquariustur',
        'AquariusTur',
        const Color(0xFF0ABAB5),
        const Color(0xFFFFFFFF),
        logoSvg,
        iconSvg,
      ]);
    });

    test('Happy Path: derived names use the id', () {
      // 1. Arrange
      final data = fullBranding();

      // 2. Act
      final config = PartnerConfig.fromBranding('aquariustur', data);

      // 3. Assert
      expect(
        [config.rootGroupEmail, config.firebaseProjectId],
        ['aquariustur00@monamienet.org', 'monamienet-aquariustur'],
      );
    });

    test('Edge Case: lower case hex colors are accepted', () {
      // 1. Arrange
      final data = {
        'name': 'Acme',
        'colors': {'primary': '#0abab5'},
      };

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.primaryColor, const Color(0xFF0ABAB5));
    });

    test('Edge Case: the name is trimmed', () {
      // 1. Arrange
      final data = {'name': '  Acme Tours \t'};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.name, 'Acme Tours');
    });

    test('Edge Case: a missing name becomes the fallback name', () {
      // 1. Arrange
      final data = {
        'colors': {'primary': '#0ABAB5'},
      };

      // 2. Act
      final config = PartnerConfig.fromBranding('aquariustur', data);

      // 3. Assert
      expect(config.name, 'Aquariustur');
    });

    test('Edge Case: a blank name becomes the fallback name', () {
      // 1. Arrange
      final data = {'name': '   '};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.name, 'Acme');
    });

    test(
      'Edge Case: a name only document leaves every optional field null',
      () {
        // 1. Arrange
        final data = {'name': 'Acme'};

        // 2. Act
        final config = PartnerConfig.fromBranding('acme', data);

        // 3. Assert
        expect([
          config.primaryColor,
          config.secondaryColor,
          config.logoSvg,
          config.iconSvg,
        ], everyElement(isNull));
      },
    );

    test('Edge Case: only the missing color is null', () {
      // 1. Arrange
      final data = {
        'name': 'Acme',
        'colors': {'secondary': '#000000'},
      };

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(
        [config.primaryColor, config.secondaryColor],
        [null, const Color(0xFF000000)],
      );
    });

    test('Edge Case: a blank logo SVG becomes null', () {
      // 1. Arrange
      final data = {'name': 'Acme', 'logoSvg': '  \n '};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.logoSvg, isNull);
    });

    test('Edge Case: a blank icon SVG becomes null', () {
      // 1. Arrange
      final data = {'name': 'Acme', 'iconSvg': ''};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.iconSvg, isNull);
    });

    const malformedColors = <String, Object?>{
      'a color name': 'teal',
      'a hex color without #': '0ABAB5',
      'a 3-digit hex color': '#0AB',
      'an 8-digit hex color with alpha': '#FF0ABAB5',
      'non-hex digits': '#GGGGGG',
      'a number': 0xFF0ABAB5,
      'surrounding spaces': ' #0ABAB5 ',
    };
    for (final MapEntry(key: label, value: color) in malformedColors.entries) {
      test('Sad Path: $label as colors.primary becomes null', () {
        // 1. Arrange
        final data = {
          'name': 'Acme',
          'colors': {'primary': color},
        };

        // 2. Act
        final config = PartnerConfig.fromBranding('acme', data);

        // 3. Assert
        expect(config.primaryColor, isNull);
      });
    }

    test('Sad Path: a malformed secondary color becomes null', () {
      // 1. Arrange
      final data = {
        'name': 'Acme',
        'colors': {'primary': '#0ABAB5', 'secondary': 'white'},
      };

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.secondaryColor, isNull);
    });

    test('Sad Path: colors that are not a map give null colors', () {
      // 1. Arrange
      final data = {
        'name': 'Acme',
        'colors': ['#0ABAB5', '#FFFFFF'],
      };

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect([config.primaryColor, config.secondaryColor], [null, null]);
    });

    test('Sad Path: a name that is not a string becomes the fallback', () {
      // 1. Arrange
      final data = {'name': 42};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.name, 'Acme');
    });

    test('Sad Path: an SVG that is not a string becomes null', () {
      // 1. Arrange
      final data = {
        'name': 'Acme',
        'logoSvg': {'svg': logoSvg},
      };

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.logoSvg, isNull);
    });

    test('Sad Path: null data gives a config with only id and fallback '
        'name', () {
      // 1. Arrange
      const Object? data = null;

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(fieldsOf(config), ['acme', 'Acme', null, null, null, null]);
    });

    test('Sad Path: a list as data gives a config with only id and fallback '
        'name', () {
      // 1. Arrange
      final data = ['AquariusTur', '#0ABAB5'];

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(fieldsOf(config), ['acme', 'Acme', null, null, null, null]);
    });

    test('Sad Path: a string as data gives the fallback name', () {
      // 1. Arrange
      const data = 'AquariusTur';

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.name, 'Acme');
    });

    const invalidIds = ['', 'app', 'Acme', '2tur', 'aquarius-tur'];
    for (final id in invalidIds) {
      test('Sad Path: the invalid id "$id" throws an ArgumentError', () {
        // 1. Arrange
        final data = fullBranding();

        // 2. Act
        PartnerConfig action() => PartnerConfig.fromBranding(id, data);

        // 3. Assert
        expect(action, throwsArgumentError);
      });
    }
  });

  group('PartnerConfig.toBranding - Unit Test Suite', () {
    test('Happy Path: a complete config survives a round trip through '
        'fromBranding', () {
      // 1. Arrange
      final original = PartnerConfig.fromBranding('acme', fullBranding());

      // 2. Act
      final copy = PartnerConfig.fromBranding('acme', original.toBranding());

      // 3. Assert
      expect(fieldsOf(copy), fieldsOf(original));
    });

    test('Happy Path: writes the document in the published format', () {
      // 1. Arrange
      final config = PartnerConfig.fromBranding('acme', fullBranding());

      // 2. Act
      final branding = config.toBranding();

      // 3. Assert
      expect(branding, fullBranding());
    });

    test('Edge Case: colors are written as upper case #RRGGBB', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        primaryColor: Color(0xFF0abab5),
        secondaryColor: Color(0xFF000001),
      );

      // 2. Act
      final branding = config.toBranding();

      // 3. Assert
      expect(branding['colors'], {
        'primary': '#0ABAB5',
        'secondary': '#000001',
      });
    });

    test('Edge Case: missing optional fields are left out', () {
      // 1. Arrange
      const config = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      final branding = config.toBranding();

      // 3. Assert
      expect(branding, {'name': 'Acme', 'colors': <String, Object?>{}});
    });

    test('Edge Case: a name only config survives a round trip', () {
      // 1. Arrange
      const original = PartnerConfig(id: 'acme', name: 'Acme Tours');

      // 2. Act
      final copy = PartnerConfig.fromBranding('acme', original.toBranding());

      // 3. Assert
      expect(fieldsOf(copy), fieldsOf(original));
    });

    test('Sad Path: a translucent color loses its alpha in the round trip', () {
      // 1. Arrange
      const original = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        primaryColor: Color(0x800ABAB5),
      );

      // 2. Act
      final copy = PartnerConfig.fromBranding('acme', original.toBranding());

      // 3. Assert
      expect(copy.primaryColor, const Color(0xFF0ABAB5));
    });
  });
}
