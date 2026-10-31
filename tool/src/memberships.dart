import 'package:monamie_app/app/data/firebase/firestore_paths.dart';
import 'package:monamie_app/app/data/organization/person_key.dart';

import 'firestore_documents.dart';

/// Path of the collection of organization [id]'s memberships, in its
/// project.
String organizationMembershipsPath(String id) =>
    '${FirestorePaths.organization(id)}/${FirestorePaths.organizationMemberships}';

/// The organization membership that makes [email] an administrator,
/// keeping the `addedAt` of an [existing] membership.
Map<String, Object?> adminMembership(
  String email, {
  required DateTime now,
  Map<String, Object?>? existing,
}) => {
  OrganizationMembershipFields.email: email,
  OrganizationMembershipFields.role: 'admin',
  OrganizationMembershipFields.addedAt:
      existing?[OrganizationMembershipFields.addedAt] ?? now,
};

/// The `accounts/{personKey}` entry of [email] once it lists organization
/// [id]: the [existing] ids plus [id], without duplicates, sorted.
Map<String, Object?> accountWithOrganization(
  String email,
  String id, {
  Map<String, Object?>? existing,
}) {
  final ids = existing?[AccountFields.organizationIds];
  return {
    AccountFields.email: email,
    AccountFields.organizationIds: {
      if (ids is List)
        for (final other in ids)
          if (other is String) other,
      id,
    }.toList()..sort(),
  };
}

/// Why organization [id]'s memberships disagree with the central
/// `accounts` index, or `null` when they agree.
///
/// [memberships] are the documents of `organizationMemberships`;
/// [accounts] holds each one's `accounts/{key}` entry by key (`null` when
/// missing). Each problem names the e-mail next to its key, because the
/// keys alone (hashes) say nothing to a person.
String? membershipProblem(
  String id,
  List<FirestoreDocument> memberships,
  Map<String, Map<String, Object?>?> accounts,
) {
  final problems = <String>[];
  if (!memberships.any(
    (m) => m.data[OrganizationMembershipFields.role] == 'admin',
  )) {
    problems.add(
      'no administrator. Run `dart run tool/organization.dart add-admin '
      '$id <email>`',
    );
  }
  for (final (id: key, :data) in memberships) {
    final email = data[OrganizationMembershipFields.email];
    final who = '${email is String ? email : '(no e-mail)'} ($key)';
    if (email is! String || personKey(email) != key) {
      problems.add('$who: the key is not personKey(email)');
      continue;
    }
    final ids = accounts[key]?[AccountFields.organizationIds];
    if (ids is! List || !ids.contains(id)) {
      final isAdmin = data[OrganizationMembershipFields.role] == 'admin';
      problems.add(
        '$who: accounts/$key does not list $id'
        '${isAdmin ? ' (run `dart run tool/organization.dart add-admin $id $email`)' : ''}',
      );
    }
  }
  return problems.isEmpty ? null : '${problems.join('; ')}.';
}
