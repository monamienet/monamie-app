import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/firebase_cli.dart';
import '../../../tool/src/firestore_documents.dart';
import '../../../tool/src/organization_check.dart';
import '../../../tool/src/organizations.dart';
import '../support/fake_firebase_cli.dart';

const androidApp = FirebaseAndroidApp(
  appId: '1:111:android:app',
  packageName: appPackageName,
);
const webApp = FirebaseWebApp(appId: '1:111:web:app', displayName: 'MonAmie');

/// [FakeFirebaseCli] whose web app listing fails on its own.
class WebListFailingCli extends FakeFirebaseCli {
  WebListFailingCli() : super(apps: const [androidApp]);

  @override
  Future<List<FirebaseWebApp>> listWebApps(String projectId) async =>
      throw OrganizationToolException('web apps unavailable');
}

/// personKey of `owner@example.com` (the lowercase-hex SHA-256 of the
/// e-mail, computed once with `sha256sum`).
const ownerKey =
    'c8cd3c6427301eaf6665bccacd65ddb614527acc843a15463e3faba57124c351';

/// [FirestoreDocuments] that answers from [documents] by path (any
/// project), or throws [error] on the paths in [failing].
class FakeFirestoreDocuments implements FirestoreDocuments {
  FakeFirestoreDocuments(this.documents, {this.error, this.failing = const {}});

  final Map<String, Map<String, Object?>> documents;
  final OrganizationToolException? error;
  final Set<String> failing;
  final reads = <({String projectId, String path})>[];

  void _maybeFail(String path) {
    if (failing.any(path.startsWith)) throw error!;
  }

  @override
  Future<Map<String, Object?>?> get({
    required String projectId,
    required String path,
    String? accessToken,
  }) async {
    reads.add((projectId: projectId, path: path));
    _maybeFail(path);
    return documents[path];
  }

  @override
  Future<List<FirestoreDocument>> list({
    required String projectId,
    required String collectionPath,
    required String accessToken,
  }) async {
    reads.add((projectId: projectId, path: collectionPath));
    _maybeFail(collectionPath);
    return [
      for (final MapEntry(:key, :value) in documents.entries)
        if (key.startsWith('$collectionPath/') &&
            !key.substring(collectionPath.length + 1).contains('/'))
          (id: key.split('/').last, data: value),
    ];
  }

  @override
  Future<void> set({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required String accessToken,
  }) => throw UnimplementedError('checkOrganization must not write');

  @override
  Future<void> update({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required List<String> fieldPaths,
    required String accessToken,
  }) => throw UnimplementedError('checkOrganization must not write');
}

/// A CLI where `monamienet-acme` has the MonAmie Android and web apps.
FakeFirebaseCli readyCli() =>
    FakeFirebaseCli(apps: const [androidApp], webApps: const [webApp]);

const brandingPath = 'organizations/acme/config/branding';
const ownerMembershipPath =
    'organizations/acme/organizationMemberships/$ownerKey';
const ownerAccountPath = 'accounts/$ownerKey';

/// Documents of a ready organization: branding, one administrator and their
/// accounts entry.
Map<String, Map<String, Object?>> readyDocuments() => {
  brandingPath: {'name': 'Acme'},
  ownerMembershipPath: {'email': 'owner@example.com', 'role': 'admin'},
  ownerAccountPath: {
    'email': 'owner@example.com',
    'organizationIds': ['acme'],
  },
};

FakeFirestoreDocuments readyFirestore() =>
    FakeFirestoreDocuments(readyDocuments());

/// [readyDocuments] with [path] set to [data], or removed when `null`.
FakeFirestoreDocuments firestoreWith(
  String path,
  Map<String, Object?>? data, {
  OrganizationToolException? error,
  Set<String> failing = const {},
}) {
  final documents = readyDocuments();
  if (data == null) {
    documents.remove(path);
  } else {
    documents[path] = data;
  }
  return FakeFirestoreDocuments(documents, error: error, failing: failing);
}

Future<List<CheckResult>> check({
  FakeFirebaseCli? cli,
  FakeFirestoreDocuments? firestore,
  String? plan,
}) => checkOrganization(
  id: 'acme',
  cli: cli ?? readyCli(),
  firestore: firestore ?? readyFirestore(),
  accessToken: 'token',
  plan: plan,
);

/// Whether each of the four checks passed, in order: Android app, web app,
/// memberships, branding name.
List<bool> passedOf(List<CheckResult> results) => [
  for (final result in results) result.passed,
];

void main() {
  group('checkOrganization - Unit Test Suite', () {
    test('Happy Path: a ready organization passes all four checks', () async {
      // 1. Arrange
      final firestore = readyFirestore();

      // 2. Act
      final results = await check(firestore: firestore);

      // 3. Assert
      expect(passedOf(results), [true, true, true, true]);
    });

    test('Happy Path: memberships and branding are read in the organization '
        'project, accounts in the central one', () async {
      // 1. Arrange
      final firestore = readyFirestore();

      // 2. Act
      await check(firestore: firestore);

      // 3. Assert
      expect(firestore.reads.toSet(), {
        (
          projectId: 'monamienet-acme',
          path: 'organizations/acme/organizationMemberships',
        ),
        (projectId: centralProjectId, path: ownerAccountPath),
        (projectId: 'monamienet-acme', path: brandingPath),
      });
    });

    test(
      'Edge Case: a Community organization is checked in the shared project',
      () async {
        // 1. Arrange
        final cli = readyCli();

        // 2. Act
        await check(cli: cli, plan: 'community');

        // 3. Assert
        expect(cli.listedProjects.toSet(), {'monamienet-community'});
      },
    );

    test(
      'Edge Case: other Android apps next to the MonAmie one pass',
      () async {
        // 1. Arrange
        final cli = FakeFirebaseCli(
          apps: const [
            androidApp,
            FirebaseAndroidApp(appId: '1:111:android:old', packageName: 'x.y'),
          ],
          webApps: const [webApp],
        );

        // 2. Act
        final results = await check(cli: cli);

        // 3. Assert
        expect(results[0].passed, isTrue);
      },
    );

    test('Sad Path: no MonAmie Android app fails only that check', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: const [
          FirebaseAndroidApp(appId: '1:111:android:old', packageName: 'x.y'),
        ],
        webApps: const [webApp],
      );

      // 2. Act
      final results = await check(cli: cli);

      // 3. Assert
      expect(passedOf(results), [false, true, true, true]);
    });

    test('Sad Path: two web apps fail the web check listing them', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: const [androidApp],
        webApps: const [
          webApp,
          FirebaseWebApp(appId: '1:111:web:old', displayName: 'Old'),
        ],
      );

      // 2. Act
      final results = await check(cli: cli);

      // 3. Assert
      expect(
        results[1].problem,
        allOf(contains('found 2'), contains('1:111:web:old')),
      );
    });

    test('Sad Path: a failing web listing is reported and the others still '
        'run', () async {
      // 1. Arrange
      final cli = WebListFailingCli();

      // 2. Act
      final results = await check(cli: cli);

      // 3. Assert
      expect(
        [passedOf(results), results[1].problem],
        [
          [true, false, true, true],
          'web apps unavailable',
        ],
      );
    });

    test('Sad Path: no administrator fails only the membership check, '
        'suggesting add-admin', () async {
      // 1. Arrange
      final firestore = firestoreWith(ownerMembershipPath, {
        'email': 'owner@example.com',
        'role': 'member',
      });

      // 2. Act
      final results = await check(firestore: firestore);

      // 3. Assert
      expect(
        [passedOf(results), results[2].problem],
        [
          [true, true, false, true],
          contains('add-admin acme'),
        ],
      );
    });

    test('Sad Path: a membership missing from accounts names the e-mail '
        'next to the key', () async {
      // 1. Arrange
      final firestore = firestoreWith(ownerAccountPath, null);

      // 2. Act
      final results = await check(firestore: firestore);

      // 3. Assert
      expect(
        results[2].problem,
        allOf(contains('owner@example.com ($ownerKey)'), contains('accounts')),
      );
    });

    test('Sad Path: an unreadable membership list is reported and the others '
        'still run', () async {
      // 1. Arrange
      final firestore = FakeFirestoreDocuments(
        readyDocuments(),
        error: OrganizationToolException('HTTP 403'),
        failing: {'organizations/acme/organizationMemberships'},
      );

      // 2. Act
      final results = await check(firestore: firestore);

      // 3. Assert
      expect(
        [passedOf(results), results[2].problem],
        [
          [true, true, false, true],
          'HTTP 403',
        ],
      );
    });

    test(
      'Sad Path: a missing branding document fails only that check',
      () async {
        // 1. Arrange
        final firestore = firestoreWith(brandingPath, null);

        // 2. Act
        final results = await check(firestore: firestore);

        // 3. Assert
        expect(passedOf(results), [true, true, true, false]);
      },
    );

    test('Sad Path: a blank branding name fails the branding check', () async {
      // 1. Arrange
      final firestore = firestoreWith(brandingPath, {'name': '  '});

      // 2. Act
      final results = await check(firestore: firestore);

      // 3. Assert
      expect(results[3].problem, contains('publish acme'));
    });

    test('Sad Path: everything missing reports all four failures', () async {
      // 1. Arrange
      final firestore = FakeFirestoreDocuments({});

      // 2. Act
      final results = await check(cli: FakeFirebaseCli(), firestore: firestore);

      // 3. Assert
      expect(passedOf(results), [false, false, false, false]);
    });

    test(
      'Sad Path: an invalid organization id throws before any check',
      () async {
        // 1. Arrange
        final cli = readyCli();

        // 2. Act
        final checking = checkOrganization(
          id: 'app',
          cli: cli,
          firestore: readyFirestore(),
          accessToken: 'token',
        );

        // 3. Assert
        await expectLater(checking, throwsA(isA<OrganizationToolException>()));
      },
    );
  });
}
