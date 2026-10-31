import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/firebase_cli.dart';
import '../../../tool/src/firestore_documents.dart';
import '../../../tool/src/group_directory.dart';
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

/// [GroupDirectory] that answers from memory, or throws [error].
class FakeGroupDirectory implements GroupDirectory {
  FakeGroupDirectory([this.membership = const {}, this.error]);

  final Map<String, List<GroupMember>> membership;
  final OrganizationToolException? error;
  final requested = <String>[];

  @override
  Future<List<GroupMember>> members(String groupEmail) async {
    requested.add(groupEmail);
    if (error case final error?) throw error;
    return membership[groupEmail] ?? const [];
  }
}

/// [FirestoreDocuments] that answers [document] to every read, or throws
/// [error].
class FakeFirestoreDocuments implements FirestoreDocuments {
  FakeFirestoreDocuments([this.document, this.error]);

  final Map<String, Object?>? document;
  final OrganizationToolException? error;
  final reads = <({String projectId, String path})>[];

  @override
  Future<Map<String, Object?>?> get({
    required String projectId,
    required String path,
    String? accessToken,
  }) async {
    reads.add((projectId: projectId, path: path));
    if (error case final error?) throw error;
    return document;
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

GroupMember subgroup(String email) => GroupMember(email: email, isGroup: true);
GroupMember person(String email) => GroupMember(email: email, isGroup: false);

/// A CLI where `monamienet-acme` has the MonAmie Android and web apps.
FakeFirebaseCli readyCli() =>
    FakeFirebaseCli(apps: const [androidApp], webApps: const [webApp]);

/// A root group `acme00` with well-named subgroups.
FakeGroupDirectory readyGroups() => FakeGroupDirectory({
  'acme00@monamienet.org': [
    subgroup('acme01@monamienet.org'),
    subgroup('acme02@monamienet.org'),
    person('someone@example.com'),
  ],
});

FakeFirestoreDocuments readyFirestore() =>
    FakeFirestoreDocuments({'name': 'Acme'});

/// Whether each of the four checks passed, in order: Android app, web app,
/// root group, branding name.
List<bool> passedOf(List<CheckResult> results) => [
  for (final result in results) result.passed,
];

void main() {
  group('checkOrganization - Unit Test Suite', () {
    test('Happy Path: a ready organization passes all four checks', () async {
      // 1. Arrange
      final cli = readyCli();

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: readyGroups(),
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(passedOf(results), [true, true, true, true]);
    });

    test('Happy Path: checks the organization project, root group and branding '
        'document', () async {
      // 1. Arrange
      final cli = readyCli();
      final groups = readyGroups();
      final firestore = readyFirestore();

      // 2. Act
      await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: groups,
        firestore: firestore,
      );

      // 3. Assert
      expect(
        [cli.listedProjects.toSet(), groups.requested, firestore.reads],
        [
          {'monamienet-acme'},
          ['acme00@monamienet.org'],
          [
            (
              projectId: 'monamienet-acme',
              path: 'organizations/acme/config/branding',
            ),
          ],
        ],
      );
    });

    test(
      'Edge Case: a Community organization is checked in the shared project',
      () async {
        // 1. Arrange
        final cli = readyCli();
        final firestore = readyFirestore();

        // 2. Act
        await checkOrganization(
          id: 'acme',
          cli: cli,
          groups: readyGroups(),
          firestore: firestore,
          plan: 'community',
        );

        // 3. Assert
        expect(
          [cli.listedProjects.toSet(), firestore.reads],
          [
            {'monamienet-community'},
            [
              (
                projectId: 'monamienet-community',
                path: 'organizations/acme/config/branding',
              ),
            ],
          ],
        );
      },
    );

    test('Edge Case: a root group with no subgroups passes', () async {
      // 1. Arrange
      final groups = FakeGroupDirectory({
        'acme00@monamienet.org': [person('owner@example.com')],
      });

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: readyCli(),
        groups: groups,
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(results[2].passed, isTrue);
    });

    test('Edge Case: subgroups in display-name case pass', () async {
      // 1. Arrange
      final groups = FakeGroupDirectory({
        'acme00@monamienet.org': [subgroup(' Acme01@MonAmieNet.org ')],
      });

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: readyCli(),
        groups: groups,
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(results[2].passed, isTrue);
    });

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
        final results = await checkOrganization(
          id: 'acme',
          cli: cli,
          groups: readyGroups(),
          firestore: readyFirestore(),
        );

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
      final results = await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: readyGroups(),
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(passedOf(results), [false, true, true, true]);
    });

    test('Sad Path: two MonAmie Android apps fail the Android check', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: const [
          androidApp,
          FirebaseAndroidApp(
            appId: '1:111:android:dup',
            packageName: appPackageName,
          ),
        ],
        webApps: const [webApp],
      );

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: readyGroups(),
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(results[0].problem, contains('found 2'));
    });

    test('Sad Path: no web app fails only the web check', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: const [androidApp]);

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: readyGroups(),
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(passedOf(results), [true, false, true, true]);
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
      final results = await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: readyGroups(),
        firestore: readyFirestore(),
      );

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
      final results = await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: readyGroups(),
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(
        [passedOf(results), results[1].problem],
        [
          [true, false, true, true],
          'web apps unavailable',
        ],
      );
    });

    test(
      'Sad Path: a failing CLI fails both app checks but not the others',
      () async {
        // 1. Arrange
        final cli = FakeFirebaseCli(
          listError: OrganizationToolException('firebase: not logged in'),
        );

        // 2. Act
        final results = await checkOrganization(
          id: 'acme',
          cli: cli,
          groups: readyGroups(),
          firestore: readyFirestore(),
        );

        // 3. Assert
        expect(passedOf(results), [false, false, true, true]);
      },
    );

    test(
      'Sad Path: misnamed subgroups fail the group check listing them',
      () async {
        // 1. Arrange
        final groups = FakeGroupDirectory({
          'acme00@monamienet.org': [
            subgroup('acme01@monamienet.org'),
            subgroup('ti-suporte@monamienet.org'),
            subgroup('acme1@monamienet.org'),
            subgroup('acmex01@monamienet.org'),
            subgroup('acme01@gmail.com'),
          ],
        });

        // 2. Act
        final results = await checkOrganization(
          id: 'acme',
          cli: readyCli(),
          groups: groups,
          firestore: readyFirestore(),
        );

        // 3. Assert
        expect(
          results[2].problem,
          allOf(
            contains('ti-suporte@monamienet.org'),
            contains('acme1@monamienet.org'),
            contains('acmex01@monamienet.org'),
            contains('acme01@gmail.com'),
          ),
        );
      },
    );

    test('Sad Path: a misnamed subgroup fails only the group check', () async {
      // 1. Arrange
      final groups = FakeGroupDirectory({
        'acme00@monamienet.org': [subgroup('beta01@monamienet.org')],
      });

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: readyCli(),
        groups: groups,
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(passedOf(results), [true, true, false, true]);
    });

    test('Sad Path: an unreadable root group is reported and the others '
        'still run', () async {
      // 1. Arrange
      final groups = FakeGroupDirectory(
        const {},
        OrganizationToolException('group acme00 does not exist'),
      );

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: readyCli(),
        groups: groups,
        firestore: readyFirestore(),
      );

      // 3. Assert
      expect(
        [passedOf(results), results[2].problem],
        [
          [true, true, false, true],
          'group acme00 does not exist',
        ],
      );
    });

    test(
      'Sad Path: a missing branding document fails only that check',
      () async {
        // 1. Arrange
        final firestore = FakeFirestoreDocuments();

        // 2. Act
        final results = await checkOrganization(
          id: 'acme',
          cli: readyCli(),
          groups: readyGroups(),
          firestore: firestore,
        );

        // 3. Assert
        expect(passedOf(results), [true, true, true, false]);
      },
    );

    test('Sad Path: a blank branding name fails the branding check', () async {
      // 1. Arrange
      final firestore = FakeFirestoreDocuments({'name': '  '});

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: readyCli(),
        groups: readyGroups(),
        firestore: firestore,
      );

      // 3. Assert
      expect(results[3].problem, contains('publish acme'));
    });

    test('Sad Path: a branding name that is not a string fails', () async {
      // 1. Arrange
      final firestore = FakeFirestoreDocuments({'name': 42});

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: readyCli(),
        groups: readyGroups(),
        firestore: firestore,
      );

      // 3. Assert
      expect(results[3].passed, isFalse);
    });

    test('Sad Path: an unreadable branding document is reported', () async {
      // 1. Arrange
      final firestore = FakeFirestoreDocuments(
        null,
        OrganizationToolException('HTTP 403'),
      );

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: readyCli(),
        groups: readyGroups(),
        firestore: firestore,
      );

      // 3. Assert
      expect(
        [passedOf(results), results[3].problem],
        [
          [true, true, true, false],
          'HTTP 403',
        ],
      );
    });

    test('Sad Path: everything missing reports all four failures', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli();
      final groups = FakeGroupDirectory({
        'acme00@monamienet.org': [subgroup('beta01@monamienet.org')],
      });

      // 2. Act
      final results = await checkOrganization(
        id: 'acme',
        cli: cli,
        groups: groups,
        firestore: FakeFirestoreDocuments(),
      );

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
          groups: readyGroups(),
          firestore: readyFirestore(),
        );

        // 3. Assert
        await expectLater(checking, throwsA(isA<OrganizationToolException>()));
      },
    );
  });
}
