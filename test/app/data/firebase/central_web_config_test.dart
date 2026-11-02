import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';

/// `web/central/firebase.json` as `tool/organization.dart web` writes it, decoded
/// the way the app decodes it.
Object? configJson({
  Map<String, Object?>? options,
  Object? googleClientId = 'web-client.apps.googleusercontent.com',
  bool withClientId = true,
}) => jsonDecode(
  jsonEncode({
    'options':
        options ??
        {
          'apiKey': 'api-key',
          'appId': '1:222:web:abc',
          'projectId': 'monamienet-app',
          'messagingSenderId': '222',
          'authDomain': 'monamienet-app.firebaseapp.com',
          'storageBucket': 'monamienet-app.firebasestorage.app',
        },
    if (withClientId) 'googleClientId': googleClientId,
  }),
);

Map<String, Object?> requiredOptions() => {
  'apiKey': 'api-key',
  'appId': '1:222:web:abc',
  'projectId': 'monamienet-app',
  'messagingSenderId': '222',
};

/// Matches a [CentralFirebaseException] whose message contains [text].
Matcher throwsCentralError(String text) => throwsA(
  isA<CentralFirebaseException>().having(
    (e) => e.message,
    'message',
    contains(text),
  ),
);

void main() {
  group('CentralWebConfig.fromJson - Unit Test Suite', () {
    test('Happy Path: reads every Firebase option', () {
      // 1. Arrange
      final json = configJson();

      // 2. Act
      final config = CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(
        config.options,
        const FirebaseOptions(
          apiKey: 'api-key',
          appId: '1:222:web:abc',
          projectId: 'monamienet-app',
          messagingSenderId: '222',
          authDomain: 'monamienet-app.firebaseapp.com',
          storageBucket: 'monamienet-app.firebasestorage.app',
        ),
      );
    });

    test('Happy Path: reads the Google client id', () {
      // 1. Arrange
      final json = configJson();

      // 2. Act
      final config = CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(config.googleClientId, 'web-client.apps.googleusercontent.com');
    });

    test('Edge Case: missing optional options are null', () {
      // 1. Arrange
      final json = configJson(options: requiredOptions());

      // 2. Act
      final config = CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(
        [config.options.authDomain, config.options.storageBucket],
        [null, null],
      );
    });

    test('Edge Case: empty optional options are null', () {
      // 1. Arrange
      final json = configJson(
        options: {...requiredOptions(), 'authDomain': '', 'storageBucket': ''},
      );

      // 2. Act
      final config = CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(
        [config.options.authDomain, config.options.storageBucket],
        [null, null],
      );
    });

    test('Sad Path: a missing googleClientId throws', () {
      // 1. Arrange
      final json = configJson(withClientId: false);

      // 2. Act
      CentralWebConfig action() => CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(action, throwsCentralError('googleClientId'));
    });

    test('Sad Path: an empty googleClientId throws', () {
      // 1. Arrange
      final json = configJson(googleClientId: '');

      // 2. Act
      CentralWebConfig action() => CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(action, throwsCentralError('googleClientId'));
    });

    test('Sad Path: a googleClientId that is not a string throws', () {
      // 1. Arrange
      final json = configJson(googleClientId: 42);

      // 2. Act
      CentralWebConfig action() => CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(action, throwsA(isA<CentralFirebaseException>()));
    });

    const requiredKeys = ['apiKey', 'appId', 'projectId', 'messagingSenderId'];
    for (final key in requiredKeys) {
      test('Sad Path: a missing options.$key throws naming it', () {
        // 1. Arrange
        final json = configJson(options: requiredOptions()..remove(key));

        // 2. Act
        CentralWebConfig action() => CentralWebConfig.fromJson(json);

        // 3. Assert
        expect(action, throwsCentralError('options.$key'));
      });
    }

    test('Sad Path: an empty required option throws naming it', () {
      // 1. Arrange
      final json = configJson(options: {...requiredOptions(), 'appId': ''});

      // 2. Act
      CentralWebConfig action() => CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(action, throwsCentralError('options.appId'));
    });

    test('Sad Path: a JSON without options throws', () {
      // 1. Arrange
      final json = jsonDecode('{"googleClientId": "web-client"}');

      // 2. Act
      CentralWebConfig action() => CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(action, throwsCentralError('"options"'));
    });

    test('Sad Path: null throws', () {
      // 1. Arrange
      const Object? json = null;

      // 2. Act
      CentralWebConfig action() => CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(action, throwsA(isA<CentralFirebaseException>()));
    });

    test('Sad Path: every error says how to fix the build', () {
      // 1. Arrange
      final json = configJson(withClientId: false);

      // 2. Act
      CentralWebConfig action() => CentralWebConfig.fromJson(json);

      // 3. Assert
      expect(action, throwsCentralError('dart run tool/organization.dart web'));
    });
  });
}
