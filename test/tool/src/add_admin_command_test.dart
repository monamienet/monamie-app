import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/src/access_token_source.dart';
import '../../../tool/src/add_admin_command.dart';
import '../../../tool/src/firestore_documents.dart';
import '../../../tool/src/organizations.dart';

/// personKey('owner@example.com'), computed once with `sha256sum`.
const ownerKey =
    'c8cd3c6427301eaf6665bccacd65ddb614527acc843a15463e3faba57124c351';
const membershipPath = 'organizations/acme/organizationMemberships/$ownerKey';
const accountPath = 'accounts/$ownerKey';

/// A write the command made.
typedef Write = ({
  String kind,
  String projectId,
  String path,
  Map<String, Object?> data,
});

/// [FirestoreDocuments] answering reads from [documents] (by project and
/// path) and recording every write.
class RecordingFirestoreDocuments implements FirestoreDocuments {
  RecordingFirestoreDocuments(this.documents);

  /// Documents by `projectId/path`.
  final Map<String, Map<String, Object?>> documents;
  final writes = <Write>[];

  @override
  Future<Map<String, Object?>?> get({
    required String projectId,
    required String path,
    String? accessToken,
  }) async => documents['$projectId/$path'];

  @override
  Future<List<FirestoreDocument>> list({
    required String projectId,
    required String collectionPath,
    required String accessToken,
  }) async => const [];

  @override
  Future<void> set({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required String accessToken,
  }) async =>
      writes.add((kind: 'set', projectId: projectId, path: path, data: data));

  @override
  Future<void> update({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required List<String> fieldPaths,
    required String accessToken,
  }) async => writes.add((
    kind: 'update',
    projectId: projectId,
    path: path,
    data: data,
  ));
}

class FixedTokens implements AccessTokenSource {
  @override
  Future<String> accessToken() async => 'token';
}

/// Runs `add-admin` with [args] against [firestore].
Future<void> runAddAdmin(
  RecordingFirestoreDocuments firestore,
  List<String> args,
) =>
    (CommandRunner<void>('organization', 'test')
          ..addCommand(AddAdminCommand(firestore, FixedTokens())))
        .run(['add-admin', ...args]);

final addedBefore = DateTime.utc(2026, 1, 2);

void main() {
  group('AddAdminCommand - Unit Test Suite', () {
    test('Happy Path: a Standard organization gets the admin membership in its '
        'own project, then the accounts entry centrally', () async {
      // 1. Arrange
      final firestore = RecordingFirestoreDocuments({
        '$centralProjectId/organizations/acme': {'plan': 'standard'},
      });

      // 2. Act
      await runAddAdmin(firestore, ['acme', ' Owner@Example.com ']);

      // 3. Assert
      expect(
        [for (final w in firestore.writes) (w.kind, w.projectId, w.path)],
        [
          ('set', 'monamienet-acme', membershipPath),
          ('update', centralProjectId, accountPath),
        ],
      );
      expect(firestore.writes[0].data['email'], 'owner@example.com');
      expect(firestore.writes[0].data['role'], 'admin');
      expect(firestore.writes[1].data['organizationIds'], ['acme']);
    });

    test(
      'Edge Case: a Community organization is written in the shared project',
      () async {
        // 1. Arrange
        final firestore = RecordingFirestoreDocuments({
          '$centralProjectId/organizations/acme': {'plan': 'community'},
        });

        // 2. Act
        await runAddAdmin(firestore, ['acme', 'owner@example.com']);

        // 3. Assert
        expect(firestore.writes.first.projectId, communityProjectId);
      },
    );

    test('Edge Case: --community chooses the shared project when the registry '
        'has no entry', () async {
      // 1. Arrange
      final firestore = RecordingFirestoreDocuments({});

      // 2. Act
      await runAddAdmin(firestore, [
        '--community',
        'acme',
        'owner@example.com',
      ]);

      // 3. Assert
      expect(firestore.writes.first.projectId, communityProjectId);
    });

    test('Edge Case: promoting a member keeps when they were added and the '
        'other organizations of their entry', () async {
      // 1. Arrange
      final firestore = RecordingFirestoreDocuments({
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
      expect(firestore.writes[0].data['addedAt'], addedBefore);
      expect(firestore.writes[1].data['organizationIds'], ['acme', 'zeta']);
    });

    test(
      'Sad Path: an invalid e-mail is refused before anything is written',
      () async {
        // 1. Arrange
        final firestore = RecordingFirestoreDocuments({});

        // 2. Act
        final run = runAddAdmin(firestore, ['acme', 'owner.example.com']);

        // 3. Assert
        await expectLater(run, throwsA(isA<OrganizationToolException>()));
        expect(firestore.writes, isEmpty);
      },
    );

    test('Sad Path: a reserved organization id is refused before anything is '
        'written', () async {
      // 1. Arrange
      final firestore = RecordingFirestoreDocuments({});

      // 2. Act
      final run = runAddAdmin(firestore, ['community', 'owner@example.com']);

      // 3. Assert
      await expectLater(run, throwsA(isA<OrganizationToolException>()));
      expect(firestore.writes, isEmpty);
    });

    test('Sad Path: a missing e-mail is a usage error', () async {
      // 1. Arrange
      final firestore = RecordingFirestoreDocuments({});

      // 2. Act
      final run = runAddAdmin(firestore, ['acme']);

      // 3. Assert
      await expectLater(run, throwsA(isA<UsageException>()));
    });
  });
}
