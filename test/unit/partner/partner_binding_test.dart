import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/data/partner/partner_binding.dart';

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

const acme = PartnerConfig(
  id: 'acme',
  name: 'Acme',
  primaryColor: Color(0xFF112233),
  secondaryColor: Color(0xFFFFFFFF),
  logoSvg: '<svg><rect/></svg>',
  iconSvg: '<svg><circle/></svg>',
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
  group('PartnerBinding.toJson / fromJson - Unit Test Suite', () {
    test('Happy Path: options with every field survive a JSON round trip', () {
      // 1. Arrange
      const binding = PartnerBinding(partner: acme, options: fullOptions);
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = PartnerBinding.fromJson(json);

      // 3. Assert
      expect(copy.options, fullOptions);
    });

    test('Happy Path: the partner and its branding survive a JSON round '
        'trip', () {
      // 1. Arrange
      const binding = PartnerBinding(partner: acme, options: fullOptions);
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = PartnerBinding.fromJson(json);

      // 3. Assert
      expect(
        [
          copy.partner.id,
          copy.partner.name,
          copy.partner.primaryColor,
          copy.partner.secondaryColor,
          copy.partner.logoSvg,
          copy.partner.iconSvg,
        ],
        [
          acme.id,
          acme.name,
          acme.primaryColor,
          acme.secondaryColor,
          acme.logoSvg,
          acme.iconSvg,
        ],
      );
    });

    test('Happy Path: toJson writes the keys the native side reads', () {
      // 1. Arrange
      const binding = PartnerBinding(partner: acme, options: fullOptions);

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

    test('Happy Path: the app name is partner-<id>', () {
      // 1. Arrange
      const binding = PartnerBinding(partner: acme, options: fullOptions);

      // 2. Act
      final name = binding.appName;

      // 3. Assert
      expect(name, 'partner-acme');
    });

    test('Edge Case: absent optional options are left out of toJson', () {
      // 1. Arrange
      const binding = PartnerBinding(
        partner: acme,
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
      const binding = PartnerBinding(
        partner: acme,
        options: requiredOnlyOptions,
      );
      final json = jsonDecode(jsonEncode(binding.toJson()));

      // 2. Act
      final copy = PartnerBinding.fromJson(json);

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
      final binding = PartnerBinding.fromJson(json);

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
      final binding = PartnerBinding.fromJson(json);

      // 3. Assert
      expect(binding.partner.name, 'Acme');
    });

    test('Sad Path: null is not a binding', () {
      // 1. Arrange
      const Object? json = null;

      // 2. Act
      PartnerBinding action() => PartnerBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: a JSON list is not a binding', () {
      // 1. Arrange
      final json = ['acme', requiredOptionsJson()];

      // 2. Act
      PartnerBinding action() => PartnerBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: a missing id throws a FormatException', () {
      // 1. Arrange
      final json = {'options': requiredOptionsJson()};

      // 2. Act
      PartnerBinding action() => PartnerBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: an id that is not a string throws a FormatException', () {
      // 1. Arrange
      final json = storedJson(id: 42, options: requiredOptionsJson());

      // 2. Act
      PartnerBinding action() => PartnerBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: missing options throw a FormatException', () {
      // 1. Arrange
      final json = {'id': 'acme'};

      // 2. Act
      PartnerBinding action() => PartnerBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: options that are not a map throw a FormatException', () {
      // 1. Arrange
      final json = storedJson(options: 'api-key');

      // 2. Act
      PartnerBinding action() => PartnerBinding.fromJson(json);

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
        PartnerBinding action() => PartnerBinding.fromJson(json);

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
      PartnerBinding action() => PartnerBinding.fromJson(json);

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
      PartnerBinding action() => PartnerBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: an invalid partner id throws an ArgumentError', () {
      // 1. Arrange
      final json = storedJson(id: 'app', options: requiredOptionsJson());

      // 2. Act
      PartnerBinding action() => PartnerBinding.fromJson(json);

      // 3. Assert
      expect(action, throwsArgumentError);
    });
  });

  group('firebaseAppNameFor - Unit Test Suite', () {
    test('Happy Path: names the app partner-<id>', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final name = firebaseAppNameFor(id);

      // 3. Assert
      expect(name, 'partner-aquariustur');
    });

    test('Edge Case: different partners never share an app name', () {
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
