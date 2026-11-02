import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../tool/src/access_token_source.dart';
import '../../../tool/src/add_admin_command.dart';
import '../../../tool/src/firestore_documents.dart';
import '../../../tool/src/organizations.dart';

@GenerateNiceMocks([
  MockSpec<FirestoreDocuments>(),
  MockSpec<AccessTokenSource>(),
])
import 'add_admin_command_test.mocks.dart';

/// personKey('owner@example.com'), computed once with `sha256sum`.
const ownerKey =
    'c8cd3c6427301eaf6665bccacd65ddb614527acc843a15463e3faba57124c351';
const membershipPath = 'organizations/acme/organizationMemberships/$ownerKey';
const accountPath = 'accounts/$ownerKey';

/// A [MockFirestoreDocuments] answering reads from [documents] (by
/// `projectId/path`).
MockFirestoreDocuments mockFirestore(
  Map<String, Map<String, Object?>> documents,
) {
  final firestore = MockFirestoreDocuments();
  when(
    firestore.get(
      projectId: anyNamed('projectId'),
      path: anyNamed('path'),
      accessToken: anyNamed('accessToken'),
    ),
  ).thenAnswer((invocation) async {
    final projectId = invocation.namedArguments[#projectId];
    final path = invocation.namedArguments[#path];
    return documents['$projectId/$path'];
  });
  when(
    firestore.list(
      projectId: anyNamed('projectId'),
      collectionPath: anyNamed('collectionPath'),
      accessToken: anyNamed('accessToken'),
    ),
  ).thenAnswer((_) async => const []);
  return firestore;
}

/// The `set` call of [firestore] in [projectId] at [path], with its data
/// captured.
Future<void> setAt(
  MockFirestoreDocuments firestore,
  String projectId,
  String path,
) => firestore.set(
  projectId: projectId,
  path: path,
  data: captureAnyNamed('data'),
  accessToken: anyNamed('accessToken'),
);

/// The `update` call of [firestore] in [projectId] at [path], with its data
/// captured.
Future<void> updateAt(
  MockFirestoreDocuments firestore,
  String projectId,
  String path,
) => firestore.update(
  projectId: projectId,
  path: path,
  data: captureAnyNamed('data'),
  fieldPaths: anyNamed('fieldPaths'),
  accessToken: anyNamed('accessToken'),
);

/// Verifies [firestore] wrote, in order, the admin membership in
/// [projectId] and then the central accounts entry, and nothing else.
/// Returns the data of both writes.
({Map<String, Object?> membership, Map<String, Object?> account}) writtenAdmin(
  MockFirestoreDocuments firestore,
  String projectId,
) {
  final [membership, account] = verifyInOrder([
    setAt(firestore, projectId, membershipPath),
    updateAt(firestore, centralProjectId, accountPath),
  ]);
  verifyNoWrites(firestore);
  return (
    membership: membership.captured.single as Map<String, Object?>,
    account: account.captured.single as Map<String, Object?>,
  );
}

/// Verifies [firestore] received no write still unverified.
void verifyNoWrites(MockFirestoreDocuments firestore) {
  verifyNever(
    firestore.set(
      projectId: anyNamed('projectId'),
      path: anyNamed('path'),
      data: anyNamed('data'),
      accessToken: anyNamed('accessToken'),
    ),
  );
  verifyNever(
    firestore.update(
      projectId: anyNamed('projectId'),
      path: anyNamed('path'),
      data: anyNamed('data'),
      fieldPaths: anyNamed('fieldPaths'),
      accessToken: anyNamed('accessToken'),
    ),
  );
}

/// Runs `add-admin` with [args] against [firestore].
Future<void> runAddAdmin(MockFirestoreDocuments firestore, List<String> args) {
  final tokens = MockAccessTokenSource();
  when(tokens.accessToken()).thenAnswer((_) async => 'token');
  return (CommandRunner<void>('organization', 'test')
        ..addCommand(AddAdminCommand(firestore, tokens)))
      .run(['add-admin', ...args]);
}

final addedBefore = DateTime.utc(2026, 1, 2);

void main() {
  group('AddAdminCommand - Unit Test Suite', () {
    test('Happy Path: a Standard organization gets the admin membership in its '
        'own project, then the accounts entry centrally', () async {
      // 1. Arrange
      final firestore = mockFirestore({
        '$centralProjectId/organizations/acme': {'plan': 'standard'},
      });

      // 2. Act
      await runAddAdmin(firestore, ['acme', ' Owner@Example.com ']);

      // 3. Assert
      final written = writtenAdmin(firestore, 'monamienet-acme');
      expect(written.membership['email'], 'owner@example.com');
      expect(written.membership['role'], 'admin');
      expect(written.account['organizationIds'], ['acme']);
    });

    test(
      'Edge Case: a Community organization is written in the shared project',
      () async {
        // 1. Arrange
        final firestore = mockFirestore({
          '$centralProjectId/organizations/acme': {'plan': 'community'},
        });

        // 2. Act
        await runAddAdmin(firestore, ['acme', 'owner@example.com']);

        // 3. Assert
        writtenAdmin(firestore, communityProjectId);
      },
    );

    test('Edge Case: --community chooses the shared project when the registry '
        'has no entry', () async {
      // 1. Arrange
      final firestore = mockFirestore({});

      // 2. Act
      await runAddAdmin(firestore, [
        '--community',
        'acme',
        'owner@example.com',
      ]);

      // 3. Assert
      writtenAdmin(firestore, communityProjectId);
    });

    test('Edge Case: promoting a member keeps when they were added and the '
        'other organizations of their entry', () async {
      // 1. Arrange
      final firestore = mockFirestore({
        'monamienet-acme/$membershipPath': {
          'email': 'owner@example.com',
          'role': 'member',
          'addedAt': addedBefore,
        },
        '$centralProjectId/$accountPath': {
          'email': 'owner@example.com',
          'organizationIds': ['zeta'],
        },
      });

      // 2. Act
      await runAddAdmin(firestore, ['acme', 'owner@example.com']);

      // 3. Assert
      final written = writtenAdmin(firestore, 'monamienet-acme');
      expect(written.membership['addedAt'], addedBefore);
      expect(written.account['organizationIds'], ['acme', 'zeta']);
    });

    test(
      'Sad Path: an invalid e-mail is refused before anything is written',
      () async {
        // 1. Arrange
        final firestore = mockFirestore({});

        // 2. Act
        final run = runAddAdmin(firestore, ['acme', 'owner.example.com']);

        // 3. Assert
        await expectLater(run, throwsA(isA<OrganizationToolException>()));
        verifyNoWrites(firestore);
      },
    );

    test('Sad Path: a reserved organization id is refused before anything is '
        'written', () async {
      // 1. Arrange
      final firestore = mockFirestore({});

      // 2. Act
      final run = runAddAdmin(firestore, ['community', 'owner@example.com']);

      // 3. Assert
      await expectLater(run, throwsA(isA<OrganizationToolException>()));
      verifyNoWrites(firestore);
    });

    test('Sad Path: a missing e-mail is a usage error', () async {
      // 1. Arrange
      final firestore = mockFirestore({});

      // 2. Act
      final run = runAddAdmin(firestore, ['acme']);

      // 3. Assert
      await expectLater(run, throwsA(isA<UsageException>()));
    });
  });
}
