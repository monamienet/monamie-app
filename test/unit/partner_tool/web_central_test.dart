import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/src/firebase_cli.dart';
import '../../../tool/src/partners.dart';
import '../../../tool/src/web_central.dart';
import '../support/fake_firebase_cli.dart';

const centralWebApp = FirebaseWebApp(
  appId: '1:222:web:central',
  displayName: 'MonAmie',
);
const centralAndroidApp = FirebaseAndroidApp(
  appId: '1:222:android:central',
  packageName: appPackageName,
);

/// The web SDK config of the central project's web app.
Map<String, Object?> sdkConfig() => {
  'apiKey': secretMarker,
  'appId': '1:222:web:central',
  'projectId': centralProjectId,
  'messagingSenderId': '222',
  'authDomain': 'monamienet-app.firebaseapp.com',
  'storageBucket': 'monamienet-app.firebasestorage.app',
  'measurementId': 'G-XXXX',
};

/// A CLI where the central project has one web app with [webSdkConfig] and
/// one MonAmie Android app whose config has an OAuth web client.
FakeFirebaseCli centralCli({
  List<FirebaseWebApp> webApps = const [centralWebApp],
  Map<String, Object?>? webSdkConfig,
  List<FirebaseAndroidApp> apps = const [centralAndroidApp],
  List<int> oauthClientTypes = const [1, 3],
}) => FakeFirebaseCli(
  webApps: webApps,
  webSdkConfig: webSdkConfig ?? sdkConfig(),
  apps: apps,
  config: googleServicesJson(
    projectId: centralProjectId,
    clients: [
      androidClient(appPackageName, oauthClientTypes: oauthClientTypes),
    ],
  ),
);

void main() {
  late Directory repoRoot;

  File target() =>
      File(p.join(repoRoot.path, 'web', 'central', 'firebase.json'));

  Object? writtenJson() => jsonDecode(target().readAsStringSync());

  /// Runs [stageCentralWebConfig] and returns the [PartnerToolException]
  /// message, or fails the test when it does not throw one.
  Future<String> failureOf(FakeFirebaseCli cli) async {
    try {
      await stageCentralWebConfig(repoRoot: repoRoot, cli: cli);
    } on PartnerToolException catch (error) {
      return error.message;
    }
    fail('Expected a PartnerToolException.');
  }

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('web_central_test_');
  });

  tearDown(() {
    repoRoot.deleteSync(recursive: true);
  });

  group('stageCentralWebConfig - Unit Test Suite', () {
    test(
      'Happy Path: writes the web options and the Google client id',
      () async {
        // 1. Arrange
        final cli = centralCli();

        // 2. Act
        await stageCentralWebConfig(repoRoot: repoRoot, cli: cli);

        // 3. Assert
        expect(writtenJson(), {
          'options': {
            'apiKey': secretMarker,
            'appId': '1:222:web:central',
            'projectId': centralProjectId,
            'messagingSenderId': '222',
            'authDomain': 'monamienet-app.firebaseapp.com',
            'storageBucket': 'monamienet-app.firebasestorage.app',
          },
          'googleClientId': '3-client.apps.googleusercontent.com',
        });
      },
    );

    test('Happy Path: reads only the central project', () async {
      // 1. Arrange
      final cli = centralCli();

      // 2. Act
      await stageCentralWebConfig(repoRoot: repoRoot, cli: cli);

      // 3. Assert
      expect(
        [cli.listedProjects.toSet(), cli.configRequests],
        [
          {centralProjectId},
          [
            (projectId: centralProjectId, appId: '1:222:web:central'),
            (projectId: centralProjectId, appId: '1:222:android:central'),
          ],
        ],
      );
    });

    test('Edge Case: absent optional web fields are left out', () async {
      // 1. Arrange
      final cli = centralCli(
        webSdkConfig: sdkConfig()
          ..remove('authDomain')
          ..['storageBucket'] = '',
      );

      // 2. Act
      await stageCentralWebConfig(repoRoot: repoRoot, cli: cli);

      // 3. Assert
      final options = (writtenJson() as Map)['options'] as Map;
      expect(options.keys, [
        'apiKey',
        'appId',
        'projectId',
        'messagingSenderId',
      ]);
    });

    test(
      'Edge Case: replaces a previous file and leaves no temp file',
      () async {
        // 1. Arrange
        target()
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('{"old": true}');
        final cli = centralCli();

        // 2. Act
        await stageCentralWebConfig(repoRoot: repoRoot, cli: cli);

        // 3. Assert
        expect(
          [
            (writtenJson() as Map).containsKey('old'),
            target().parent.listSync().map((e) => p.basename(e.path)).toList(),
          ],
          [
            false,
            ['firebase.json'],
          ],
        );
      },
    );

    test('Sad Path: no web app fails without writing', () async {
      // 1. Arrange
      final cli = centralCli(webApps: const []);

      // 2. Act
      final message = await failureOf(cli);

      // 3. Assert
      expect(
        [message, target().existsSync()],
        [allOf(contains('exactly one web app'), contains('(none)')), false],
      );
    });

    test('Sad Path: two web apps fail without writing', () async {
      // 1. Arrange
      final cli = centralCli(
        webApps: const [
          centralWebApp,
          FirebaseWebApp(appId: '1:222:web:old', displayName: 'Old'),
        ],
      );

      // 2. Act
      final message = await failureOf(cli);

      // 3. Assert
      expect(
        [message, target().existsSync()],
        [allOf(contains('found 2'), contains('1:222:web:old')), false],
      );
    });

    test('Sad Path: a failed run keeps the previous file', () async {
      // 1. Arrange
      target()
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{"previous": true}');
      final cli = centralCli(webApps: const []);

      // 2. Act
      await failureOf(cli);

      // 3. Assert
      expect(target().readAsStringSync(), '{"previous": true}');
    });

    const requiredFields = [
      'apiKey',
      'appId',
      'projectId',
      'messagingSenderId',
    ];
    for (final field in requiredFields) {
      test('Sad Path: a web config without $field fails naming it', () async {
        // 1. Arrange
        final cli = centralCli(webSdkConfig: sdkConfig()..remove(field));

        // 2. Act
        final message = await failureOf(cli);

        // 3. Assert
        expect([message, target().existsSync()], [contains("'$field'"), false]);
      });
    }

    test('Sad Path: no MonAmie Android app fails without writing', () async {
      // 1. Arrange
      final cli = centralCli(
        apps: const [
          FirebaseAndroidApp(appId: '1:222:android:x', packageName: 'x.y'),
        ],
      );

      // 2. Act
      final message = await failureOf(cli);

      // 3. Assert
      expect(
        [message, target().existsSync()],
        [allOf(contains(appPackageName), contains('found 0')), false],
      );
    });

    test('Sad Path: no OAuth web client fails without writing', () async {
      // 1. Arrange
      final cli = centralCli(oauthClientTypes: const [1]);

      // 2. Act
      final message = await failureOf(cli);

      // 3. Assert
      expect(
        [message, target().existsSync()],
        [contains('no OAuth web client'), false],
      );
    });

    test('Sad Path: error messages never include the API key', () async {
      // 1. Arrange
      final cli = centralCli(webSdkConfig: sdkConfig()..remove('appId'));

      // 2. Act
      final message = await failureOf(cli);

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    // Regression: a FormatException from jsonDecode used to escape and echo
    // the config, API key included.
    test('Sad Path: a truncated google-services.json fails without leaking '
        'the API key', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        webApps: const [centralWebApp],
        webSdkConfig: sdkConfig(),
        apps: const [centralAndroidApp],
        config: '{"api_key": [{"current_key": "$secretMarker"}], "client": [',
      );

      // 2. Act
      final message = await failureOf(cli);

      // 3. Assert
      expect(
        [message, target().existsSync()],
        [
          allOf(contains('not valid JSON'), isNot(contains(secretMarker))),
          false,
        ],
      );
    });
  });
}
