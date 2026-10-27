import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';

/// Bytes standing for a downloaded logo PNG.
final logoBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);

const oceano = PartnerTheme(
  id: 'oceano',
  name: 'Oceano',
  primary: Color(0xFF0B7F7B),
  dark: Color(0xFF0A3D3B),
  light: Color(0xFFD3EEEC),
  onPrimary: Color(0xFFFFFFFF),
  onDark: Color(0xFFFFFFFF),
);

/// A complete `config/branding` document, as the app and the tool write it.
Map<String, Object?> fullBranding() => {
  'name': 'AquariusTur',
  'themeId': 'oceano',
  'logoVersion': 1700000000000,
};

/// The branding fields of [config], so two configs can be compared by value.
List<Object?> fieldsOf(PartnerConfig config) => [
  config.id,
  config.name,
  config.themeId,
  config.logoVersion,
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
        label: 'Happy Path: a share leaf gives its partner id',
        email: 'aquariustur01w@monamienet.org',
        expected: 'aquariustur',
      ),
      (
        label: 'Happy Path: the root group (00) gives its partner id',
        email: 'aquariustur00@monamienet.org',
        expected: 'aquariustur',
      ),
      (
        label: 'Edge Case: upper case letters are normalized',
        email: 'AquariusTur01W@MonAmieNet.ORG',
        expected: 'aquariustur',
      ),
      (
        label: 'Edge Case: surrounding whitespace is ignored',
        email: '  aquariustur01r@monamienet.org \n',
        expected: 'aquariustur',
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
      final email = rootGroupEmailFor('rotasul');

      // 2. Act
      final id = partnerIdFromGroupEmail(email);

      // 3. Assert
      expect(id, 'rotasul');
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
        'oceano',
        1700000000000,
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

    test('Happy Path: keeps the given theme', () {
      // 1. Arrange
      final data = fullBranding();

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data, theme: oceano);

      // 3. Assert
      expect(config.theme, same(oceano));
    });

    test('Happy Path: keeps the logo bytes when logoVersion is an int', () {
      // 1. Arrange
      final data = fullBranding();

      // 2. Act
      final config = PartnerConfig.fromBranding(
        'acme',
        data,
        logoPng: logoBytes,
      );

      // 3. Assert
      expect(config.logoPng, logoBytes);
    });

    test('Edge Case: the name is trimmed', () {
      // 1. Arrange
      final data = {'name': '  Acme Tours \t'};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.name, 'Acme Tours');
    });

    test('Edge Case: themeId is trimmed', () {
      // 1. Arrange
      final data = {'name': 'Acme', 'themeId': '  oceano '};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.themeId, 'oceano');
    });

    test('Edge Case: a missing name becomes the fallback name', () {
      // 1. Arrange
      final data = {'themeId': 'oceano'};

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

    test('Edge Case: a name only document leaves every optional field '
        'null', () {
      // 1. Arrange
      final data = {'name': 'Acme'};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect([
        config.themeId,
        config.theme,
        config.logoVersion,
        config.logoPng,
      ], everyElement(isNull));
    });

    test('Edge Case: logo bytes without a logoVersion give no logo', () {
      // 1. Arrange
      final data = {'name': 'Acme', 'themeId': 'oceano'};

      // 2. Act
      final config = PartnerConfig.fromBranding(
        'acme',
        data,
        logoPng: logoBytes,
      );

      // 3. Assert
      expect(config.logoPng, isNull);
    });

    test('Edge Case: a logoVersion without bytes keeps the version and no '
        'logo', () {
      // 1. Arrange
      final data = {'name': 'Acme', 'logoVersion': 3};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect([config.logoVersion, config.logoPng], [3, null]);
    });

    test('Sad Path: a blank themeId is read as null', () {
      // 1. Arrange
      final data = {'name': 'Acme', 'themeId': '   '};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.themeId, isNull);
    });

    test('Sad Path: a themeId that is not a string is read as null', () {
      // 1. Arrange
      final data = {'name': 'Acme', 'themeId': 7};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.themeId, isNull);
    });

    const badVersions = <String, Object?>{
      'a string': '1700000000000',
      'a double': 1.5,
      'a map': {'v': 1},
    };
    for (final MapEntry(key: label, value: version) in badVersions.entries) {
      test('Sad Path: $label as logoVersion gives no version and no logo', () {
        // 1. Arrange
        final data = {'name': 'Acme', 'logoVersion': version};

        // 2. Act
        final config = PartnerConfig.fromBranding(
          'acme',
          data,
          logoPng: logoBytes,
        );

        // 3. Assert
        expect([config.logoVersion, config.logoPng], [null, null]);
      });
    }

    test('Sad Path: a name that is not a string becomes the fallback', () {
      // 1. Arrange
      final data = {'name': 42};

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(config.name, 'Acme');
    });

    test('Sad Path: null data gives a config with only id and fallback '
        'name', () {
      // 1. Arrange
      const Object? data = null;

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(fieldsOf(config), ['acme', 'Acme', null, null]);
    });

    test('Sad Path: a list as data gives a config with only id and fallback '
        'name', () {
      // 1. Arrange
      final data = ['AquariusTur', 'oceano'];

      // 2. Act
      final config = PartnerConfig.fromBranding('acme', data);

      // 3. Assert
      expect(fieldsOf(config), ['acme', 'Acme', null, null]);
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

  group('PartnerConfig.effectiveTheme - Unit Test Suite', () {
    test('Happy Path: a resolved theme is the effective theme', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        themeId: 'oceano',
        theme: oceano,
      );

      // 2. Act
      final theme = config.effectiveTheme;

      // 3. Assert
      expect(theme, same(oceano));
    });

    test('Edge Case: a themeId without a resolved theme uses Grafite', () {
      // 1. Arrange
      const config = PartnerConfig(id: 'acme', name: 'Acme', themeId: 'neon');

      // 2. Act
      final theme = config.effectiveTheme;

      // 3. Assert
      expect(theme.id, 'grafite');
    });

    test('Sad Path: no theme at all uses Grafite', () {
      // 1. Arrange
      const config = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      final theme = config.effectiveTheme;

      // 3. Assert
      expect(theme, same(defaultPartnerTheme));
    });
  });

  group('PartnerConfig.toBranding - Unit Test Suite', () {
    test('Happy Path: writes the document in the published format', () {
      // 1. Arrange
      final config = PartnerConfig.fromBranding('acme', fullBranding());

      // 2. Act
      final branding = config.toBranding();

      // 3. Assert
      expect(branding, fullBranding());
    });

    test('Happy Path: a complete config survives a round trip through '
        'fromBranding', () {
      // 1. Arrange
      final original = PartnerConfig.fromBranding('acme', fullBranding());

      // 2. Act
      final copy = PartnerConfig.fromBranding('acme', original.toBranding());

      // 3. Assert
      expect(fieldsOf(copy), fieldsOf(original));
    });

    test('Edge Case: missing optional fields are left out', () {
      // 1. Arrange
      const config = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      final branding = config.toBranding();

      // 3. Assert
      expect(branding, {'name': 'Acme'});
    });

    test('Sad Path: the logo bytes and the resolved theme are not written', () {
      // 1. Arrange
      final config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        theme: oceano,
        logoVersion: 2,
        logoPng: logoBytes,
      );

      // 2. Act
      final branding = config.toBranding();

      // 3. Assert
      expect(branding, {'name': 'Acme', 'logoVersion': 2});
    });
  });
}
