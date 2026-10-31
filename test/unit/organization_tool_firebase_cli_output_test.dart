import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/firebase_cli.dart';
import '../../tool/src/organizations.dart';
import '../../tool/src/process_firebase_cli.dart';

/// A fake API key: no error message may ever contain it.
const secretMarker = 'AIzaFAKE-secret-key-0123456789';

/// `google-services.json` contents carrying [secretMarker].
final secretConfigContents = jsonEncode({
  'project_info': {'project_id': 'monamienet-acme'},
  'client': [
    {
      'client_info': {
        'android_client_info': {'package_name': 'org.monamienet.acme'},
      },
      'api_key': [
        {'current_key': secretMarker},
      ],
    },
  ],
});

/// One app object as firebase-tools 15.x prints it in `apps:list --json`.
Map<String, Object?> appObject(String appId, String packageName) => {
  'name': 'projects/monamienet-acme/androidApps/$appId',
  'appId': appId,
  'displayName': 'MonAmie Acme',
  'projectId': 'monamienet-acme',
  'packageName': packageName,
  'platform': 'ANDROID',
};

/// Returns the message of the [OrganizationToolException] thrown by [action], or
/// fails the test when it does not throw one.
String organizationToolErrorMessage(void Function() action) {
  try {
    action();
  } on OrganizationToolException catch (error) {
    return error.message;
  }
  fail('Expected an OrganizationToolException');
}

void main() {
  group('parseAppsListOutput - Unit Test Suite', () {
    test('Happy Path: returns every app of a success envelope', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': [
          appObject('1:111:android:aaa', 'org.monamienet.acme'),
          appObject('1:111:android:bbb', 'org.monamienet.other'),
        ],
      });

      // 2. Act
      final apps = parseAppsListOutput(stdout);

      // 3. Assert
      expect(apps, const [
        FirebaseAndroidApp(
          appId: '1:111:android:aaa',
          packageName: 'org.monamienet.acme',
        ),
        FirebaseAndroidApp(
          appId: '1:111:android:bbb',
          packageName: 'org.monamienet.other',
        ),
      ]);
    });

    test('Happy Path: accepts app objects with only appId and packageName', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': [
          {'appId': '1:111:android:aaa', 'packageName': 'org.monamienet.acme'},
        ],
      });

      // 2. Act
      final apps = parseAppsListOutput(stdout);

      // 3. Assert
      expect(apps, const [
        FirebaseAndroidApp(
          appId: '1:111:android:aaa',
          packageName: 'org.monamienet.acme',
        ),
      ]);
    });

    test('Edge Case: returns an empty list when the project has no Android '
        'apps', () {
      // 1. Arrange
      final stdout = jsonEncode({'status': 'success', 'result': <Object?>[]});

      // 2. Act
      final apps = parseAppsListOutput(stdout);

      // 3. Assert
      expect(apps, isEmpty);
    });

    test('Edge Case: tolerates surrounding whitespace and a trailing '
        'newline', () {
      // 1. Arrange
      final stdout =
          '\n  ${jsonEncode({
            'status': 'success',
            'result': [appObject('1:111:android:aaa', 'org.monamienet.acme')],
          })}\n';

      // 2. Act
      final apps = parseAppsListOutput(stdout);

      // 3. Assert
      expect(apps.single.appId, '1:111:android:aaa');
    });

    test(
      'Sad Path: an error envelope throws OrganizationToolException with the '
      "CLI's error text",
      () {
        // 1. Arrange
        final stdout = jsonEncode({
          'status': 'error',
          'error': 'Failed to list Firebase Android apps. HTTP Error: 403',
        });

        // 2. Act
        final message = organizationToolErrorMessage(
          () => parseAppsListOutput(stdout),
        );

        // 3. Assert
        expect(
          message,
          contains('Failed to list Firebase Android apps. HTTP Error: 403'),
        );
      },
    );

    test('Happy Path: an error envelope names the project when given', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'error',
        'error': 'Failed to list Firebase Android apps.',
      });

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseAppsListOutput(stdout, projectId: 'monamienet-acme'),
      );

      // 3. Assert
      expect(
        message,
        allOf(
          contains("failed for project 'monamienet-acme'"),
          contains('Failed to list Firebase Android apps.'),
          contains("Firebase project 'monamienet-acme' exists"),
        ),
      );
    });

    test('Edge Case: an error envelope without a project id still carries '
        'the CLI error and names no project', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'error',
        'error': 'Failed to list Firebase Android apps.',
      });

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseAppsListOutput(stdout),
      );

      // 3. Assert
      expect(
        message,
        allOf(
          contains("'firebase apps:list' failed: "),
          contains('Failed to list Firebase Android apps.'),
          isNot(contains('for project')),
          isNot(contains('null')),
        ),
      );
    });

    test('Edge Case: a success envelope parses the same with a project id', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': [appObject('1:111:android:aaa', 'org.monamienet.acme')],
      });

      // 2. Act
      final apps = parseAppsListOutput(stdout, projectId: 'monamienet-acme');

      // 3. Assert
      expect(apps, const [
        FirebaseAndroidApp(
          appId: '1:111:android:aaa',
          packageName: 'org.monamienet.acme',
        ),
      ]);
    });

    test(
      'Sad Path: output that is not JSON throws OrganizationToolException',
      () {
        // 1. Arrange
        const stdout = 'i  Preparing the list of your Firebase ANDROID apps';

        // 2. Act
        void action() => parseAppsListOutput(stdout);

        // 3. Assert
        expect(action, throwsA(isA<OrganizationToolException>()));
      },
    );

    test('Sad Path: empty output throws OrganizationToolException', () {
      // 1. Arrange
      const stdout = '';

      // 2. Act
      void action() => parseAppsListOutput(stdout);

      // 3. Assert
      expect(action, throwsA(isA<OrganizationToolException>()));
    });

    test('Sad Path: a JSON value without a status throws '
        'OrganizationToolException', () {
      // 1. Arrange
      final stdout = jsonEncode([
        appObject('1:111:android:aaa', 'org.monamienet.acme'),
      ]);

      // 2. Act
      void action() => parseAppsListOutput(stdout);

      // 3. Assert
      expect(action, throwsA(isA<OrganizationToolException>()));
    });

    test('Sad Path: a success envelope whose result is not a list throws '
        'OrganizationToolException', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': appObject('1:111:android:aaa', 'org.monamienet.acme'),
      });

      // 2. Act
      void action() => parseAppsListOutput(stdout);

      // 3. Assert
      expect(action, throwsA(isA<OrganizationToolException>()));
    });

    test(
      'Sad Path: an app without packageName throws OrganizationToolException',
      () {
        // 1. Arrange
        final stdout = jsonEncode({
          'status': 'success',
          'result': [
            {'appId': '1:111:android:aaa', 'platform': 'ANDROID'},
          ],
        });

        // 2. Act
        void action() => parseAppsListOutput(stdout);

        // 3. Assert
        expect(action, throwsA(isA<OrganizationToolException>()));
      },
    );

    test('Sad Path: an app whose appId is not a string throws '
        'OrganizationToolException', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': [
          {'appId': 42, 'packageName': 'org.monamienet.acme'},
        ],
      });

      // 2. Act
      void action() => parseAppsListOutput(stdout);

      // 3. Assert
      expect(action, throwsA(isA<OrganizationToolException>()));
    });
  });

  group('parseSdkConfigOutput - Unit Test Suite', () {
    test('Happy Path: returns fileContents of a success envelope verbatim', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'fileContents': secretConfigContents,
        },
      });

      // 2. Act
      final contents = parseSdkConfigOutput(stdout);

      // 3. Assert
      expect(contents, secretConfigContents);
    });

    test('Edge Case: keeps the exact formatting of fileContents', () {
      // 1. Arrange
      const fileContents = '{\n  "project_info": {\n    "x": 1\n  }\n}\n';
      final stdout = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'fileContents': fileContents,
        },
      });

      // 2. Act
      final contents = parseSdkConfigOutput(stdout);

      // 3. Assert
      expect(contents, fileContents);
    });

    test(
      'Sad Path: an error envelope throws OrganizationToolException with the '
      "CLI's error text",
      () {
        // 1. Arrange
        final stdout = jsonEncode({
          'status': 'error',
          'error':
              'Failed to get app config. The caller does not have permission',
        });

        // 2. Act
        final message = organizationToolErrorMessage(
          () => parseSdkConfigOutput(stdout),
        );

        // 3. Assert
        expect(
          message,
          contains(
            'Failed to get app config. The caller does not have permission',
          ),
        );
      },
    );

    test('Happy Path: an error envelope names the project when given', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'error',
        'error': 'Failed to get app config.',
      });

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseSdkConfigOutput(stdout, projectId: 'monamienet-acme'),
      );

      // 3. Assert
      expect(
        message,
        allOf(
          contains(
            "'firebase apps:sdkconfig' failed for project "
            "'monamienet-acme': Failed to get app config.",
          ),
          contains("Firebase project 'monamienet-acme' exists"),
        ),
      );
    });

    test('Edge Case: an error envelope without a project id still carries '
        'the CLI error and names no project', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'error',
        'error': 'Failed to get app config.',
      });

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseSdkConfigOutput(stdout),
      );

      // 3. Assert
      expect(
        message,
        allOf(
          contains(
            "'firebase apps:sdkconfig' failed: "
            'Failed to get app config.',
          ),
          isNot(contains('for project')),
          isNot(contains('null')),
        ),
      );
    });

    test('Edge Case: a success envelope returns the contents verbatim with a '
        'project id', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'fileContents': secretConfigContents,
        },
      });

      // 2. Act
      final contents = parseSdkConfigOutput(
        stdout,
        projectId: 'monamienet-acme',
      );

      // 3. Assert
      expect(contents, secretConfigContents);
    });

    test('Sad Path: malformed output never leaks the contents when a project '
        'id is given', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'fileContents': jsonDecode(secretConfigContents),
        },
      });

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseSdkConfigOutput(stdout, projectId: 'monamienet-acme'),
      );

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test('Sad Path: a truncated envelope never leaks the contents when a '
        'project id is given', () {
      // 1. Arrange
      final full = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'fileContents': secretConfigContents,
        },
      });
      final stdout = full.substring(0, full.length - 3);

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseSdkConfigOutput(stdout, projectId: 'monamienet-acme'),
      );

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test(
      'Sad Path: output that is not JSON throws OrganizationToolException',
      () {
        // 1. Arrange
        const stdout = 'Error: not logged in';

        // 2. Act
        void action() => parseSdkConfigOutput(stdout);

        // 3. Assert
        expect(action, throwsA(isA<OrganizationToolException>()));
      },
    );

    test('Sad Path: a success envelope without fileContents throws '
        'OrganizationToolException', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': {'fileName': 'google-services.json'},
      });

      // 2. Act
      void action() => parseSdkConfigOutput(stdout);

      // 3. Assert
      expect(action, throwsA(isA<OrganizationToolException>()));
    });

    test('Sad Path: a success envelope whose result is a list throws '
        'OrganizationToolException', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': [secretConfigContents],
      });

      // 2. Act
      void action() => parseSdkConfigOutput(stdout);

      // 3. Assert
      expect(action, throwsA(isA<OrganizationToolException>()));
    });

    test('Sad Path: a truncated envelope holding a key never leaks the key in '
        'the error message', () {
      // 1. Arrange
      final full = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'fileContents': secretConfigContents,
        },
      });
      final stdout = full.substring(0, full.length - 3);

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseSdkConfigOutput(stdout),
      );

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test('Sad Path: contents under an unexpected key never leak in the error '
        'message', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'contents': secretConfigContents,
        },
      });

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseSdkConfigOutput(stdout),
      );

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test('Sad Path: non-string fileContents holding a key never leak in the '
        'error message', () {
      // 1. Arrange
      final stdout = jsonEncode({
        'status': 'success',
        'result': {
          'fileName': 'google-services.json',
          'fileContents': jsonDecode(secretConfigContents),
        },
      });

      // 2. Act
      final message = organizationToolErrorMessage(
        () => parseSdkConfigOutput(stdout),
      );

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });
  });

  group('ProcessFirebaseCli - Unit Test Suite', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('process_firebase_cli_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('Happy Path: defaults to the "firebase" executable', () {
      // 1. Arrange
      const cli = ProcessFirebaseCli();

      // 2. Act
      final executable = cli.executable;

      // 3. Assert
      expect(executable, 'firebase');
    });

    test('Edge Case: a missing executable also fails the config call with '
        'OrganizationToolException', () async {
      // 1. Arrange
      final cli = ProcessFirebaseCli(
        executable: p.join(tempDir.path, 'no-such-firebase'),
      );

      // 2. Act
      Future<void> action() => cli.androidConfig(
        projectId: 'monamienet-acme',
        appId: '1:111:android:aaa',
      );

      // 3. Assert
      await expectLater(action, throwsA(isA<OrganizationToolException>()));
    });

    test(
      'Sad Path: a missing executable throws OrganizationToolException telling '
      'to install the Firebase CLI',
      () async {
        // 1. Arrange
        final cli = ProcessFirebaseCli(
          executable: p.join(tempDir.path, 'no-such-firebase'),
        );

        // 2. Act
        Future<void> action() => cli.listAndroidApps('monamienet-acme');

        // 3. Assert
        await expectLater(
          action,
          throwsA(
            isA<OrganizationToolException>().having(
              (error) => error.message.toLowerCase(),
              'message',
              allOf(contains('install'), contains('firebase cli')),
            ),
          ),
        );
      },
    );
  });
}
