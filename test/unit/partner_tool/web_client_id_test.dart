import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/android_firebase_config.dart';
import '../../../tool/src/partners.dart';
import '../support/fake_firebase_cli.dart';

/// Returns the message of the [PartnerToolException] thrown by [action], or
/// fails the test when it does not throw one.
String messageOf(void Function() action) {
  try {
    action();
  } on PartnerToolException catch (error) {
    return error.message;
  }
  fail('Expected a PartnerToolException.');
}

void main() {
  group('webClientIdFromGoogleServices - Unit Test Suite', () {
    test('Happy Path: returns the client id of the OAuth web client', () {
      // 1. Arrange
      final contents = googleServicesJson(
        projectId: 'monamienet-app',
        clients: [androidClient(appPackageName)],
      );

      // 2. Act
      final clientId = webClientIdFromGoogleServices(contents);

      // 3. Assert
      expect(clientId, '3-client.apps.googleusercontent.com');
    });

    test('Edge Case: the web client may be listed before others', () {
      // 1. Arrange
      final contents = googleServicesJson(
        projectId: 'monamienet-app',
        clients: [
          androidClient(appPackageName, oauthClientTypes: [3, 1]),
        ],
      );

      // 2. Act
      final clientId = webClientIdFromGoogleServices(contents);

      // 3. Assert
      expect(clientId, '3-client.apps.googleusercontent.com');
    });

    test('Edge Case: finds the web client in a later Android client', () {
      // 1. Arrange
      final contents = googleServicesJson(
        projectId: 'monamienet-app',
        clients: [
          androidClient('org.example.other', oauthClientTypes: null),
          androidClient(appPackageName),
        ],
      );

      // 2. Act
      final clientId = webClientIdFromGoogleServices(contents);

      // 3. Assert
      expect(clientId, '3-client.apps.googleusercontent.com');
    });

    test('Sad Path: no OAuth web client throws', () {
      // 1. Arrange
      final contents = googleServicesJson(
        projectId: 'monamienet-app',
        clients: [
          androidClient(appPackageName, oauthClientTypes: [1]),
        ],
      );

      // 2. Act
      final message = messageOf(() => webClientIdFromGoogleServices(contents));

      // 3. Assert
      expect(message, contains('no OAuth web client'));
    });

    test('Sad Path: a client without oauth_client throws', () {
      // 1. Arrange
      final contents = googleServicesJson(
        projectId: 'monamienet-app',
        clients: [androidClient(appPackageName, oauthClientTypes: null)],
      );

      // 2. Act
      final message = messageOf(() => webClientIdFromGoogleServices(contents));

      // 3. Assert
      expect(message, contains('no OAuth web client'));
    });

    test('Sad Path: a file without clients throws', () {
      // 1. Arrange
      final contents = jsonEncode({
        'project_info': {'project_id': 'monamienet-app'},
      });

      // 2. Act
      final message = messageOf(() => webClientIdFromGoogleServices(contents));

      // 3. Assert
      expect(message, contains('no OAuth web client'));
    });

    // Regression: a FormatException from jsonDecode used to escape and echo
    // the config, API key included.
    test('Sad Path: invalid JSON throws a PartnerToolException without the '
        'API key', () {
      // 1. Arrange
      const contents = '{"api_key": [{"current_key": "$secretMarker"}], oops';

      // 2. Act
      final message = messageOf(() => webClientIdFromGoogleServices(contents));

      // 3. Assert
      expect(
        message,
        allOf(contains('not valid JSON'), isNot(contains(secretMarker))),
      );
    });

    test('Sad Path: a client_type given as text is not the web client', () {
      // 1. Arrange
      final contents = jsonEncode({
        'client': [
          {
            'oauth_client': [
              {'client_id': 'web-client', 'client_type': '3'},
            ],
          },
        ],
      });

      // 2. Act
      final message = messageOf(() => webClientIdFromGoogleServices(contents));

      // 3. Assert
      expect(message, contains('no OAuth web client'));
    });

    test('Sad Path: the error never includes the API key', () {
      // 1. Arrange
      final contents = googleServicesJson(
        projectId: 'monamienet-app',
        clients: [
          androidClient(appPackageName, oauthClientTypes: [1]),
        ],
      );

      // 2. Act
      final message = messageOf(() => webClientIdFromGoogleServices(contents));

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });
  });
}
