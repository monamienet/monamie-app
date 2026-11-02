import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../tool/src/firebase_cli.dart';
import '../../../tool/src/firestore_documents.dart';
import '../../../tool/src/organization_check.dart';
import '../../../tool/src/organizations.dart';

@GenerateNiceMocks([MockSpec<FirebaseCli>(), MockSpec<FirestoreDocuments>()])
import 'organization_check_test.mocks.dart';

const androidApp = FirebaseAndroidApp(
  appId: '1:111:android:app',
  packageName: appPackageName,
);
const webApp = FirebaseWebApp(appId: '1:111:web:app', displayName: 'MonAmie');

/// A [MockFirebaseCli] answering [apps] and [webApps] for any project.
MockFirebaseCli mockCli({
  List<FirebaseAndroidApp> apps = const [],
  List<FirebaseWebApp> webApps = const [],
}) {
  final cli = MockFirebaseCli();
  when(cli.listAndroidApps(any)).thenAnswer((_) async => apps);
  when(cli.listWebApps(any)).thenAnswer((_) async => webApps);
  return cli;
}

/// personKey of `owner@example.com` (the lowercase-hex SHA-256 of the
/// e-mail, computed once with `sha256sum`).
const ownerKey =
    'c8cd3c6427301eaf6665bccacd65ddb614527acc843a15463e3faba57124c351';

/// A [MockFirestoreDocuments] that answers from [documents] by path (any
/// project), throws [error] on the paths in [failing] and refuses writes.
MockFirestoreDocuments mockFirestore(
  Map<String, Map<String, Object?>> documents, {
  OrganizationToolException? error,
  Set<String> failing = const {},
}) {
  void maybeFail(String path) {
    if (failing.any(path.startsWith)) throw error!;
  }

  final firestore = MockFirestoreDocuments();
  when(
    firestore.get(
      projectId: anyNamed('projectId'),
      path: anyNamed('path'),
      accessToken: anyNamed('accessToken'),
    ),
  ).thenAnswer((invocation) async {
    final path = invocation.namedArguments[#path] as String;
    maybeFail(path);
    return documents[path];
  });
  when(
    firestore.list(
      projectId: anyNamed('projectId'),
      collectionPath: anyNamed('collectionPath'),
      accessToken: anyNamed('accessToken'),
    ),
  ).thenAnswer((invocation) async {
    final collectionPath = invocation.namedArguments[#collectionPath] as String;
    maybeFail(collectionPath);
    return [
      for (final MapEntry(:key, :value) in documents.entries)
        if (key.startsWith('$collectionPath/') &&
            !key.substring(collectionPath.length + 1).contains('/'))
          (id: key.split('/').last, data: value),
    ];
  });
  when(
    firestore.set(
      projectId: anyNamed('projectId'),
      path: anyNamed('path'),
      data: anyNamed('data'),
      accessToken: anyNamed('accessToken'),
    ),
  ).thenAnswer(
    (_) async => throw UnimplementedError('checkOrganization must not write'),
  );
  when(
    firestore.update(
      projectId: anyNamed('projectId'),
      path: anyNamed('path'),
      data: anyNamed('data'),
      fieldPaths: anyNamed('fieldPaths'),
      accessToken: anyNamed('accessToken'),
    ),
  ).thenAnswer(
    (_) async => throw UnimplementedError('checkOrganization must not write'),
  );
  return firestore;
}

/// Every document and collection [firestore] read, as project and path.
Set<({String projectId, String path})> readsOf(
  MockFirestoreDocuments firestore,
) {
  final gets = verify(
    firestore.get(
      projectId: captureAnyNamed('projectId'),
      path: captureAnyNamed('path'),
      accessToken: anyNamed('accessToken'),
    ),
  ).captured;
  final lists = verify(
    firestore.list(
      projectId: captureAnyNamed('projectId'),
      collectionPath: captureAnyNamed('collectionPath'),
      accessToken: anyNamed('accessToken'),
    ),
  ).captured;
  final captured = [...gets, ...lists];
  return {
    for (var i = 0; i < captured.length; i += 2)
      (projectId: captured[i] as String, path: captured[i + 1] as String),
  };
}

/// A CLI where `monamienet-acme` has the MonAmie Android and web apps.
MockFirebaseCli readyCli() =>
    mockCli(apps: const [androidApp], webApps: const [webApp]);

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

MockFirestoreDocuments readyFirestore() => mockFirestore(readyDocuments());

/// [readyDocuments] with [path] set to [data], or removed when `null`.
MockFirestoreDocuments firestoreWith(
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
  return mockFirestore(documents, error: error, failing: failing);
}

Future<List<CheckResult>> check({
  MockFirebaseCli? cli,
  MockFirestoreDocuments? firestore,
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
      expect(readsOf(firestore), {
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
        final listed = {
          ...verify(cli.listAndroidApps(captureAny)).captured,
          ...verify(cli.listWebApps(captureAny)).captured,
        };
        expect(listed, {'monamienet-community'});
      },
    );

    test(
      'Edge Case: other Android apps next to the MonAmie one pass',
      () async {
        // 1. Arrange
        final cli = mockCli(
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
      final cli = mockCli(
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
      final cli = mockCli(
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
      final cli = readyCli();
      when(cli.listWebApps(any)).thenAnswer(
        (_) async => throw OrganizationToolException('web apps unavailable'),
      );

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
      final firestore = mockFirestore(
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
      final firestore = mockFirestore({});

      // 2. Act
      final results = await check(cli: mockCli(), firestore: firestore);

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
