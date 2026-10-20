import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/android_firebase_config.dart';
import '../../tool/src/firebase_cli.dart';
import '../../tool/src/partners.dart';
import 'support/fake_firebase_cli.dart';

const acmeProject = 'monamienet-acme';
const acmePackage = 'org.monamienet.acme';
const acmeApp = FirebaseAndroidApp(
  appId: '1:111:android:acme',
  packageName: acmePackage,
);
const otherApp = FirebaseAndroidApp(
  appId: '1:111:android:other',
  packageName: 'org.monamienet.other',
);

/// A config the spec accepts for partner `acme`.
final validAcmeConfig = googleServicesJson(
  projectId: acmeProject,
  clients: [androidClient(acmePackage)],
);

/// Bytes of a config written by an earlier run, including a non-UTF-8 byte
/// so that any rewrite would show up.
const previousConfigBytes = <int>[
  0x7B,
  0x22,
  0x6F,
  0x6C,
  0x64,
  0x22,
  0xFF,
  0x7D,
];

/// Runs [fetchAndroidFirebaseConfig] and returns the message of the
/// [PartnerToolException] it throws, or fails the test when it succeeds.
Future<String> fetchErrorMessage(
  Directory repoRoot,
  FirebaseCli cli, {
  String id = 'acme',
}) async {
  try {
    await fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: id, cli: cli);
  } on PartnerToolException catch (error) {
    return error.message;
  }
  fail('Expected a PartnerToolException');
}

void main() {
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('partner_tool_firebase_');
    writePartner(repoRoot, 'acme');
  });

  tearDown(() {
    if (repoRoot.existsSync()) repoRoot.deleteSync(recursive: true);
  });

  group('androidFirebaseConfigPath - Unit Test Suite', () {
    test('Happy Path: points into the flavor source set of the partner', () {
      // 1. Arrange
      const id = 'acme';

      // 2. Act
      final path = androidFirebaseConfigPath(id);

      // 3. Assert
      expect(
        path,
        p.join('android', 'app', 'src', 'acme', 'google-services.json'),
      );
    });

    test('Edge Case: keeps digits of the id in the folder name', () {
      // 1. Arrange
      const id = 'acme2go';

      // 2. Act
      final path = androidFirebaseConfigPath(id);

      // 3. Assert
      expect(
        path,
        p.join('android', 'app', 'src', 'acme2go', 'google-services.json'),
      );
    });

    test('Sad Path: is never the unflavored, previously versioned '
        'android/app/google-services.json', () {
      // 1. Arrange
      const id = 'acme';

      // 2. Act
      final path = androidFirebaseConfigPath(id);

      // 3. Assert
      expect(path, isNot(p.join('android', 'app', 'google-services.json')));
    });
  });

  group('oauthWebClientType - Unit Test Suite', () {
    test('Happy Path: is the client_type of the OAuth web client (3)', () {
      // 1. Arrange
      const expected = 3;

      // 2. Act
      const type = oauthWebClientType;

      // 3. Assert
      expect(type, expected);
    });
  });

  group('fetchAndroidFirebaseConfig - Unit Test Suite', () {
    test('Happy Path: writes the fetched contents verbatim to '
        'android/app/src/<id>/google-services.json', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(
        specConfigFile(repoRoot, 'acme').readAsStringSync(),
        validAcmeConfig,
      );
    });

    test('Happy Path: returns the app id of the matching app', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      final appId = await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(appId, acmeApp.appId);
    });

    test('Happy Path: lists the apps of Firebase project monamienet-<id> '
        'exactly once', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(cli.listedProjects, [acmeProject]);
    });

    test('Happy Path: requests the config of the matching app in '
        'monamienet-<id>', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(cli.configRequests, [
        (projectId: acmeProject, appId: acmeApp.appId),
      ]);
    });

    test('Happy Path: picks the app with package org.monamienet.<id> among '
        'apps of other packages', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [
          otherApp,
          acmeApp,
          const FirebaseAndroidApp(
            appId: '1:111:android:legacy',
            packageName: 'com.example.monamie',
          ),
        ],
        config: validAcmeConfig,
      );

      // 2. Act
      final appId = await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(appId, acmeApp.appId);
    });

    test('Happy Path: replaces a previously fetched file on success', () async {
      // 1. Arrange
      specConfigFile(repoRoot, 'acme')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(previousConfigBytes);
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(
        specConfigFile(repoRoot, 'acme').readAsStringSync(),
        validAcmeConfig,
      );
    });

    test('Edge Case: accepts a config that also holds clients of other '
        'packages', () async {
      // 1. Arrange
      final config = googleServicesJson(
        projectId: acmeProject,
        clients: [
          androidClient(otherApp.packageName, oauthClientTypes: const [1]),
          androidClient(acmePackage),
        ],
      );
      final cli = FakeFirebaseCli(apps: [acmeApp], config: config);

      // 2. Act
      await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(specConfigFile(repoRoot, 'acme').readAsStringSync(), config);
    });

    test('Edge Case: accepts a matching client whose only OAuth client is the '
        'web client', () async {
      // 1. Arrange
      final config = googleServicesJson(
        projectId: acmeProject,
        clients: [
          androidClient(acmePackage, oauthClientTypes: const [3]),
        ],
      );
      final cli = FakeFirebaseCli(apps: [acmeApp], config: config);

      // 2. Act
      final appId = await fetchAndroidFirebaseConfig(
        repoRoot: repoRoot,
        id: 'acme',
        cli: cli,
      );

      // 3. Assert
      expect(appId, acmeApp.appId);
    });

    test('Edge Case: packages that only extend org.monamienet.<id> do not '
        'match', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: const [
          FirebaseAndroidApp(
            appId: '1:111:android:dev',
            packageName: 'org.monamienet.acme.dev',
          ),
          FirebaseAndroidApp(
            appId: '1:111:android:x',
            packageName: 'org.monamienet.acmex',
          ),
        ],
        config: validAcmeConfig,
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: no app with the package fails listing the candidate '
        'apps', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [otherApp], config: validAcmeConfig);

      // 2. Act
      final message = await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(
        message,
        allOf(contains(otherApp.appId), contains(otherApp.packageName)),
      );
    });

    test('Sad Path: no app with the package never requests a config', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [otherApp], config: validAcmeConfig);

      // 2. Act
      await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(cli.configRequests, isEmpty);
    });

    test('Sad Path: a project without Android apps throws '
        'PartnerToolException', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: const [], config: validAcmeConfig);

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: several apps with the package fail listing every '
        'candidate', () async {
      // 1. Arrange
      const duplicate = FirebaseAndroidApp(
        appId: '1:111:android:acme-dup',
        packageName: acmePackage,
      );
      final cli = FakeFirebaseCli(
        apps: [acmeApp, duplicate],
        config: validAcmeConfig,
      );

      // 2. Act
      final message = await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(
        message,
        allOf(contains(acmeApp.appId), contains(duplicate.appId)),
      );
    });

    test('Sad Path: several apps with the package write no file', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [
          acmeApp,
          const FirebaseAndroidApp(
            appId: '1:111:android:acme-dup',
            packageName: acmePackage,
          ),
        ],
        config: validAcmeConfig,
      );

      // 2. Act
      await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(specConfigFile(repoRoot, 'acme').existsSync(), isFalse);
    });

    test(
      'Sad Path: a config of another Firebase project is rejected',
      () async {
        // 1. Arrange
        final cli = FakeFirebaseCli(
          apps: [acmeApp],
          config: googleServicesJson(
            projectId: 'monamienet-other',
            clients: [androidClient(acmePackage)],
          ),
        );

        // 2. Act
        Future<String> action() => fetchAndroidFirebaseConfig(
          repoRoot: repoRoot,
          id: 'acme',
          cli: cli,
        );

        // 3. Assert
        await expectLater(action, throwsA(isA<PartnerToolException>()));
      },
    );

    test(
      'Sad Path: a config of another Firebase project writes no file',
      () async {
        // 1. Arrange
        final cli = FakeFirebaseCli(
          apps: [acmeApp],
          config: googleServicesJson(
            projectId: 'monamienet-other',
            clients: [androidClient(acmePackage)],
          ),
        );

        // 2. Act
        await fetchErrorMessage(repoRoot, cli);

        // 3. Assert
        expect(specConfigFile(repoRoot, 'acme').existsSync(), isFalse);
      },
    );

    test('Sad Path: a config without a client for the package is '
        'rejected', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [androidClient(otherApp.packageName)],
        ),
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a config with two clients for the package is '
        'rejected', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [androidClient(acmePackage), androidClient(acmePackage)],
        ),
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a matching client without an OAuth web client is '
        'rejected', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [
            androidClient(acmePackage, oauthClientTypes: const [1]),
          ],
        ),
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a matching client without an oauth_client list is '
        'rejected', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [androidClient(acmePackage, oauthClientTypes: null)],
        ),
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test("Sad Path: a web client of another package's client does not count "
        'for the partner', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [
            androidClient(otherApp.packageName),
            androidClient(acmePackage, oauthClientTypes: const [1]),
          ],
        ),
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: contents that are not valid JSON are rejected', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: validAcmeConfig.substring(0, validAcmeConfig.length ~/ 2),
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: contents that are a JSON list are rejected', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: '[$validAcmeConfig]',
      );

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a rejected config keeps the previous file '
        'byte-for-byte', () async {
      // 1. Arrange
      specConfigFile(repoRoot, 'acme')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(previousConfigBytes);
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [
            androidClient(acmePackage, oauthClientTypes: const [1]),
          ],
        ),
      );

      // 2. Act
      await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(
        specConfigFile(repoRoot, 'acme').readAsBytesSync(),
        previousConfigBytes,
      );
    });

    test('Sad Path: invalid JSON contents keep the previous file '
        'byte-for-byte', () async {
      // 1. Arrange
      specConfigFile(repoRoot, 'acme')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(previousConfigBytes);
      final cli = FakeFirebaseCli(apps: [acmeApp], config: '{"broken": ');

      // 2. Act
      await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(
        specConfigFile(repoRoot, 'acme').readAsBytesSync(),
        previousConfigBytes,
      );
    });

    test('Sad Path: a failing apps listing keeps the previous file '
        'byte-for-byte', () async {
      // 1. Arrange
      specConfigFile(repoRoot, 'acme')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(previousConfigBytes);
      final cli = FakeFirebaseCli(
        listError: PartnerToolException('HTTP Error: 403, permission denied'),
      );

      // 2. Act
      await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(
        specConfigFile(repoRoot, 'acme').readAsBytesSync(),
        previousConfigBytes,
      );
    });

    test('Sad Path: a failing config download keeps the previous file '
        'byte-for-byte', () async {
      // 1. Arrange
      specConfigFile(repoRoot, 'acme')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(previousConfigBytes);
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        configError: PartnerToolException('HTTP Error: 404, app not found'),
      );

      // 2. Act
      await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(
        specConfigFile(repoRoot, 'acme').readAsBytesSync(),
        previousConfigBytes,
      );
    });

    test(
      'Sad Path: a CLI failure propagates as PartnerToolException',
      () async {
        // 1. Arrange
        final cli = FakeFirebaseCli(
          listError: PartnerToolException('HTTP Error: 403, permission denied'),
        );

        // 2. Act
        final message = await fetchErrorMessage(repoRoot, cli);

        // 3. Assert
        expect(message, contains('HTTP Error: 403, permission denied'));
      },
    );

    test('Sad Path: the wrong-project error never contains the config '
        'contents', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: 'monamienet-other',
          clients: [androidClient(acmePackage)],
        ),
      );

      // 2. Act
      final message = await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test('Sad Path: the missing-client error never contains the config '
        'contents', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [androidClient(otherApp.packageName)],
        ),
      );

      // 2. Act
      final message = await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test('Sad Path: the missing-web-client error never contains the config '
        'contents', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: acmeProject,
          clients: [
            androidClient(acmePackage, oauthClientTypes: const [1]),
          ],
        ),
      );

      // 2. Act
      final message = await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test('Sad Path: the invalid-JSON error never contains the config '
        'contents', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: validAcmeConfig.substring(0, validAcmeConfig.length - 5),
      );

      // 2. Act
      final message = await fetchErrorMessage(repoRoot, cli);

      // 3. Assert
      expect(message, isNot(contains(secretMarker)));
    });

    test('Sad Path: an invalid id throws PartnerToolException', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'Acme', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: an invalid id never calls the Firebase CLI', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      await fetchErrorMessage(repoRoot, cli, id: '../acme');

      // 3. Assert
      expect(cli.callCount, 0);
    });

    test('Sad Path: a reserved id never calls the Firebase CLI', () async {
      // 1. Arrange
      writePartner(repoRoot, 'main');
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      await fetchErrorMessage(repoRoot, cli, id: 'main');

      // 3. Assert
      expect(cli.callCount, 0);
    });

    test('Sad Path: an unknown partner throws PartnerToolException', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      Future<String> action() =>
          fetchAndroidFirebaseConfig(repoRoot: repoRoot, id: 'beta', cli: cli);

      // 3. Assert
      await expectLater(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: an unknown partner never calls the Firebase CLI', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);

      // 2. Act
      await fetchErrorMessage(repoRoot, cli, id: 'beta');

      // 3. Assert
      expect(cli.callCount, 0);
    });
  });
}
