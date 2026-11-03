import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';
import 'package:monamie_app/data/services/firebase/person_key.dart';
import 'package:monamie_app/domain/models/capabilities.dart';

/// The signed-in person's membership documents in the bound organization's
/// project ([CurrentOrganizationFirebase], set in each isolate), and the
/// names of the groups they may read, as raw data: live streams, one-off
/// reads and the check made right after entering an organization.
///
/// Used by the UI isolate and by the background tracking isolate. The
/// streams and futures throw (or emit errors) when Firestore fails, except
/// [isMemberOf], which answers `null`.
class MembershipService {
  /// [_firestore] defaults to the bound organization's.
  const MembershipService([this._firestore]);

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestore ?? CurrentOrganizationFirebase.instance.firestore;

  /// The data of `organizationMemberships/{personKey(email)}`, then every
  /// change. `null` means the server says it does not exist: the person was
  /// removed (a missing document seen only in the local cache is not
  /// emitted).
  Stream<Map<String, Object?>?> organizationMembership(
    String organizationId,
    String email,
  ) => _db
      .doc(
        FirestorePaths.organizationMembership(organizationId, personKey(email)),
      )
      // With metadata changes, the server's answer arrives even when it
      // only confirms what the cache said.
      .snapshots(includeMetadataChanges: true)
      .where((s) => s.exists || !s.metadata.isFromCache)
      .map((s) => s.data());

  /// The raw `roles` of each of the person's group memberships in
  /// [organizationId], by group id, then every change (a collection-group
  /// query on `groupMemberships` filtered by `email` and `organizationId`).
  Stream<Map<String, Object?>> groupRoles(
    String organizationId,
    String email,
  ) => _groupMemberships(organizationId, email)
      .snapshots(includeMetadataChanges: true)
      .where((s) => s.docs.isNotEmpty || !s.metadata.isFromCache)
      .map(_rolesByGroup);

  /// The same as [groupRoles], read once.
  Future<Map<String, Object?>> readGroupRoles(
    String organizationId,
    String email,
  ) async =>
      _rolesByGroup(await _groupMemberships(organizationId, email).get());

  Query<Map<String, dynamic>> _groupMemberships(
    String organizationId,
    String email,
  ) => _db
      .collectionGroup(FirestorePaths.groupMemberships)
      .where(GroupMembershipFields.email, isEqualTo: email.trim().toLowerCase())
      .where(GroupMembershipFields.organizationId, isEqualTo: organizationId);

  static Map<String, Object?> _rolesByGroup(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) => {
    for (final doc in snapshot.docs)
      // groups/{groupId}/groupMemberships/{personKey}
      if (doc.reference.parent.parent case final group?)
        group.id: doc.data()[GroupMembershipFields.roles],
  };

  /// Every group of [organizationId], name by id. Only administrators may
  /// list them.
  Stream<Map<String, String>> allGroupNames(String organizationId) => _db
      .collection(
        '${FirestorePaths.organization(organizationId)}/${FirestorePaths.groups}',
      )
      .snapshots()
      .map((s) => {for (final doc in s.docs) doc.id: _name(doc.data())});

  /// The name of group [groupId], `null` when the group does not exist.
  /// Its members (any role) and the administrators may read it.
  Stream<String?> groupName(String organizationId, String groupId) => _db
      .doc(FirestorePaths.group(organizationId, groupId))
      .snapshots()
      .map((s) => s.exists ? _name(s.data()) : null);

  static String _name(Map<String, Object?>? data) {
    final name = data?[GroupFields.name];
    return name is String ? name.trim() : '';
  }

  /// Whether the person signed in to the bound organization's project still
  /// has an `organizationMemberships` document in [organizationId], read
  /// from the server right after entering, before anything of the
  /// organization is shown. `null` when it could not be read, which is not
  /// evidence of removal; never throws.
  Future<bool?> isMemberOf(String organizationId) async {
    try {
      final email =
          CurrentOrganizationFirebase.instance.auth.currentUser?.email;
      if (email == null) return null;
      final doc = await _db
          .doc(
            FirestorePaths.organizationMembership(
              organizationId,
              personKey(email),
            ),
          )
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      return doc.exists;
    } catch (e) {
      debugPrint('[Membership] Could not read the membership: $e');
      return null;
    }
  }
}

/// Reads the membership documents. [organizationMembership] is the data of
/// `organizationMemberships/{personKey}`, `null` when it does not exist;
/// [groupRoles] the raw `roles` of each of the person's group memberships,
/// by group id. Without an organization membership the person belongs to
/// nothing there, whatever group memberships are left. A malformed field
/// counts as absent, never as an error; unknown roles are kept but grant
/// nothing.
Capabilities capabilitiesFromMemberships({
  required Map<String, Object?>? organizationMembership,
  required Map<String, Object?> groupRoles,
}) {
  if (organizationMembership == null) return const Capabilities();
  return Capabilities(
    isMember: true,
    isAdmin:
        organizationMembership[OrganizationMembershipFields.role] ==
        OrganizationRoles.admin,
    rolesByGroup: {
      for (final MapEntry(:key, :value) in groupRoles.entries)
        if (rolesOf(value) case final roles when roles.isNotEmpty) key: roles,
    },
  );
}

/// The role names in a raw `roles` field: the strings of a list, anything
/// else none.
Set<String> rolesOf(Object? raw) => {
  if (raw is List)
    for (final role in raw)
      if (role is String && role.isNotEmpty) role,
};

/// The ids in [groupRoles] (raw `roles` by group id) whose roles include
/// [role], sorted. The background service uses it for the groups it
/// publishes to.
List<String> groupsWithRole(Map<String, Object?> groupRoles, String role) => [
  for (final MapEntry(:key, :value) in groupRoles.entries)
    if (rolesOf(value).contains(role)) key,
]..sort();
