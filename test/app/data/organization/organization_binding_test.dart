import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart';
import 'package:monamie_app/app/data/organization/organization_binding.dart';

const fullOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-acme',
  messagingSenderId: '111',
  storageBucket: 'monamienet-acme.firebasestorage.app',
  authDomain: 'monamienet-acme.firebaseapp.com',
);

const requiredOnlyOptions = FirebaseOptions(
  apiKey: 'api-key',
  appId: '1:111:android:abc',
  projectId: 'monamienet-acme',
  messagingSenderId: '111',
);

const acme = OrganizationConfig(
  id: 'acme',
  name: 'Acme',
  themeId: 'oceano',
  logoVersion: 7,
);

/// Bytes standing for the organization's logo PNG.
final logoBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 255, 128]);

/// [acme] with its logo downloaded.
final acmeWithLogo = OrganizationConfig(
  id: 'acme',
  name: 'Acme',
  themeId: 'oceano',
  logoVersion: 7,
  logoPng: logoBytes,
);

const oceano = OrganizationTheme(
  id: 'oceano',
  name: 'Oceano',
  primary: Color(0xFF0B7F7B),
  dark: Color(0xFF0A3D3B),
  light: Color(0xFFD3EEEC),
  onPrimary: Color(0xFFFFFFFF),
  onDark: Color(0xFFFFFFFF),
);

/// [acme] with the catalog theme it resolved to.
const themedAcme = OrganizationConfig(
  id: 'acme',
  name: 'Acme',
  themeId: 'oceano',
  theme: oceano,
);

/// A stored binding with [options] replaced, as decoded JSON.
Map<String, Object?> storedJson({Object? options, Object? id = 'acme'}) => {
  'id': id,
  'options': options,
  'branding': {'name': 'Acme'},
};

Map<String, Object?> requiredOptionsJson() => {
  'apiKey': 'api-key',
  'appId': '1:111:android:abc',
  'projectId': 'monamienet-acme',
  'messagingSenderId': '111',
};

void main() {
  group('OrganizationBinding.toJson / fromJson - Unit Test Suite', () {
    test('Happy Path: options with every field survive a JSON round trip', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: acme,
        options: fullOptions,
      );
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(copy.options, fullOptions);
    });

    test('Happy Path: the organization and its branding survive a JSON round '
        'trip', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: acme,
        options: fullOptions,
      );
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(
        [
          copy.organization.id,
          copy.organization.name,
          copy.organization.themeId,
          copy.organization.logoVersion,
        ],
        ['acme', 'Acme', 'oceano', 7],
      );
    });

    test('Happy Path: toJson writes the keys the native side reads', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: acme,
        options: fullOptions,
      );

      // 2. Act
      final json = binding.toJson();

      // 3. Assert
      expect(json, {
        'id': 'acme',
        'options': {
          'apiKey': 'api-key',
          'appId': '1:111:android:abc',
          'projectId': 'monamienet-acme',
          'messagingSenderId': '111',
          'storageBucket': 'monamienet-acme.firebasestorage.app',
          'authDomain': 'monamienet-acme.firebaseapp.com',
        },
        'branding': acme.toBranding(),
      });
    });

    test('Happy Path: the app name is organization-<id>', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: acme,
        options: fullOptions,
      );

      // 2. Act
      final name = binding.appName;

      // 3. Assert
      expect(name, 'organization-acme');
    });

    test('Edge Case: absent optional options are left out of toJson', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: acme,
        options: requiredOnlyOptions,
      );

      // 2. Act
      final options = binding.toJson()['options'] as Map;

      // 3. Assert
      expect(
        options.keys,
        isNot(anyOf(contains('storageBucket'), contains('authDomain'))),
      );
    });

    test('Edge Case: absent optional options survive a JSON round trip as '
        'null', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: acme,
        options: requiredOnlyOptions,
      );
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(copy.options, requiredOnlyOptions);
    });

    test('Edge Case: empty optional options are read as null', () {
      // 1. Arrange
      final json = storedJson(
        options: {
          ...requiredOptionsJson(),
          'storageBucket': '',
          'authDomain': '',
        },
      );

      // 2. Act
      final binding = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(
        [binding.options.storageBucket, binding.options.authDomain],
        [null, null],
      );
    });

    test('Edge Case: a missing branding gives the fallback name', () {
      // 1. Arrange
      final json = {'id': 'acme', 'options': requiredOptionsJson()};

      // 2. Act
      final binding = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(binding.organization.name, 'Acme');
    });

    test('Sad Path: null is not a binding', () {
      // 1. Arrange
      const Object? json = null;

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: a JSON list is not a binding', () {
      // 1. Arrange
      final json = ['acme', requiredOptionsJson()];

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: a missing id throws a FormatException', () {
      // 1. Arrange
      final json = {'options': requiredOptionsJson()};

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: an id that is not a string throws a FormatException', () {
      // 1. Arrange
      final json = storedJson(id: 42, options: requiredOptionsJson());

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: missing options throw a FormatException', () {
      // 1. Arrange
      final json = {'id': 'acme'};

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: options that are not a map throw a FormatException', () {
      // 1. Arrange
      final json = storedJson(options: 'api-key');

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    const requiredKeys = ['apiKey', 'appId', 'projectId', 'messagingSenderId'];
    for (final key in requiredKeys) {
      test('Sad Path: a missing options.$key throws a FormatException naming '
          'it', () {
        // 1. Arrange
        final json = storedJson(options: requiredOptionsJson()..remove(key));

        // 2. Act
        OrganizationBinding action() => OrganizationBinding.fromJson(json);

        // 3. Assert
        expect(
          action,
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('options.$key'),
            ),
          ),
        );
      });
    }

    test('Sad Path: an empty required option throws a FormatException', () {
      // 1. Arrange
      final json = storedJson(
        options: {...requiredOptionsJson(), 'apiKey': ''},
      );

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: a required option that is not a string throws a '
        'FormatException', () {
      // 1. Arrange
      final json = storedJson(
        options: {...requiredOptionsJson(), 'messagingSenderId': 111},
      );

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: an invalid organization id throws an ArgumentError', () {
      // 1. Arrange
      final json = storedJson(id: 'app', options: requiredOptionsJson());

      // 2. Act
      OrganizationBinding action() => OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsArgumentError);
    });
  });

  group('OrganizationBinding theme - Unit Test Suite', () {
    test('Happy Path: the resolved theme survives a JSON round trip', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: themedAcme,
        options: fullOptions,
      );
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(
        [copy.organization.theme?.id, copy.organization.theme?.primary],
        ['oceano', const Color(0xFF0B7F7B)],
      );
    });

    test('Happy Path: toJson stores the theme under "theme" with its id', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: themedAcme,
        options: fullOptions,
      );

      // 2. Act
      final json = binding.toJson();

      // 3. Assert
      expect(
        json['theme'],
        isA<Map>()
            .having((theme) => theme['id'], 'id', 'oceano')
            .having((theme) => theme['primary'], 'primary', '#0B7F7B'),
      );
    });

    test('Edge Case: a stored binding without "theme" restores no theme', () {
      // 1. Arrange
      final json = storedJson(options: requiredOptionsJson());

      // 2. Act
      final binding = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(binding.organization.theme, isNull);
    });

    test('Sad Path: a stored theme with malformed colors restores no '
        'theme', () {
      // 1. Arrange
      final json = {
        ...storedJson(options: requiredOptionsJson()),
        'theme': {
          'id': 'oceano',
          'name': 'Oceano',
          'primary': 'teal',
          'dark': '#0A3D3B',
          'light': '#D3EEEC',
        },
      };

      // 2. Act
      final binding = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(binding.organization.theme, isNull);
    });
  });

  group('OrganizationBinding logo - Unit Test Suite', () {
    test('Happy Path: the logo bytes survive a JSON round trip', () {
      // 1. Arrange
      final binding = OrganizationBinding(
        organization: acmeWithLogo,
        options: fullOptions,
      );
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(copy.organization.logoPng, logoBytes);
    });

    test('Happy Path: toJson stores the logo as base64 under "logoPng"', () {
      // 1. Arrange
      final binding = OrganizationBinding(
        organization: acmeWithLogo,
        options: fullOptions,
      );

      // 2. Act
      final json = binding.toJson();

      // 3. Assert
      expect(json['logoPng'], 'iVBORwD/gA==');
    });

    test('Edge Case: an organization without a logo has no "logoPng" key', () {
      // 1. Arrange
      const binding = OrganizationBinding(
        organization: acme,
        options: fullOptions,
      );

      // 2. Act
      final json = binding.toJson();

      // 3. Assert
      expect(json.containsKey('logoPng'), isFalse);
    });

    test('Edge Case: a stored binding without "logoPng" restores no logo', () {
      // 1. Arrange
      final json = {
        ...storedJson(options: requiredOptionsJson()),
        'branding': {'name': 'Acme', 'logoVersion': 7},
      };

      // 2. Act
      final binding = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(binding.organization.logoPng, isNull);
    });

    test('Edge Case: stored logo bytes without a logoVersion restore no '
        'logo', () {
      // 1. Arrange
      final json = {
        ...storedJson(options: requiredOptionsJson()),
        'logoPng': 'iVBORwD/gA==',
      };

      // 2. Act
      final binding = OrganizationBinding.fromJson(json);

      // 3. Assert
      expect(binding.organization.logoPng, isNull);
    });

    const malformed = <String, Object?>{
      'malformed base64': 'not base64 at all!',
      'a number': 42,
    };
    for (final MapEntry(key: label, value: stored) in malformed.entries) {
      test('Sad Path: $label as "logoPng" restores no logo', () {
        // 1. Arrange
        final json = {
          ...storedJson(options: requiredOptionsJson()),
          'branding': {'name': 'Acme', 'logoVersion': 7},
          'logoPng': stored,
        };

        // 2. Act
        final binding = OrganizationBinding.fromJson(json);

        // 3. Assert
        expect(binding.organization.logoPng, isNull);
      });
    }
  });

  group('firebaseAppNameFor - Unit Test Suite', () {
    test('Happy Path: names the app organization-<id>', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final name = firebaseAppNameFor(id);

      // 3. Assert
      expect(name, 'organization-aquariustur');
    });

    test('Edge Case: different organizations never share an app name', () {
      // 1. Arrange
      final first = firebaseAppNameFor('tur');

      // 2. Act
      final second = firebaseAppNameFor('tur2');

      // 3. Assert
      expect(second, isNot(first));
    });

    test('Sad Path: the app name is never the default app name', () {
      // 1. Arrange
      const id = 'acme';

      // 2. Act
      final name = firebaseAppNameFor(id);

      // 3. Assert
      expect(name, isNot(defaultFirebaseAppName));
    });
  });
}
