import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';
import 'package:monamie_app/app/data/organization/person_key.dart';

import 'membership_source.dart';

/// [MembershipSource] over the bound organization's Firestore
/// ([CurrentOrganizationFirebase], set in each isolate).
class FirestoreMembershipSource implements MembershipSource {
  /// [_firestore] defaults to the bound organization's.
  const FirestoreMembershipSource([this._firestore]);

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db =>
      _firestore ?? CurrentOrganizationFirebase.instance.firestore;

  @override
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

  @override
  Stream<Map<String, Object?>> groupRoles(
    String organizationId,
    String email,
  ) => _db
      .collectionGroup(FirestorePaths.groupMemberships)
      .where(GroupMembershipFields.email, isEqualTo: email.trim().toLowerCase())
      .where(GroupMembershipFields.organizationId, isEqualTo: organizationId)
      .snapshots(includeMetadataChanges: true)
      .where((s) => s.docs.isNotEmpty || !s.metadata.isFromCache)
      .map(
        (s) => {
          for (final doc in s.docs)
            // groups/{groupId}/groupMemberships/{personKey}
            if (doc.reference.parent.parent case final group?)
              group.id: doc.data()[GroupMembershipFields.roles],
        },
      );

  @override
  Stream<Map<String, String>> allGroupNames(String organizationId) => _db
      .collection(
        '${FirestorePaths.organization(organizationId)}/${FirestorePaths.groups}',
      )
      .snapshots()
      .map((s) => {for (final doc in s.docs) doc.id: _name(doc.data())});

  @override
  Stream<String?> groupName(String organizationId, String groupId) => _db
      .doc(FirestorePaths.group(organizationId, groupId))
      .snapshots()
      .map((s) => s.exists ? _name(s.data()) : null);

  static String _name(Map<String, Object?>? data) {
    final name = data?[GroupFields.name];
    return name is String ? name.trim() : '';
  }
}
