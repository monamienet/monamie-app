import 'package:firebase_core/firebase_core.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';

import 'fake_outcomes.dart';

/// [OrganizationDirectory] over [organizations]. A failure asked for with
/// `fail` throws, as the central directory does.
class FakeOrganizationDirectory
    with FakeOutcomes
    implements OrganizationDirectory {
  FakeOrganizationDirectory({List<OrganizationCandidate>? organizations})
    : organizations = [...?organizations];

  /// The signed-in user's active organizations; listed sorted by id.
  final List<OrganizationCandidate> organizations;

  @override
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser() => run(
    'organizationsOfSignedInUser',
    const [],
    () => [...organizations]..sort((a, b) => a.id.compareTo(b.id)),
  );
}

/// An organization of the signed-in user, with made-up Firebase options of
/// project `monamienet-<id>`.
OrganizationCandidate fakeCandidate(String id, {bool owner = false}) =>
    OrganizationCandidate(
      id: id,
      owner: owner,
      options: FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:111:android:$id',
        messagingSenderId: '111',
        projectId: 'monamienet-$id',
      ),
    );
