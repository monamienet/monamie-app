import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';
import 'package:monamie_app/app/data/organization/person_key.dart';

import 'organization_membership_check.dart';

/// [OrganizationMembershipCheck] reading the person's own document from the
/// server of the bound organization ([CurrentOrganizationFirebase]).
class FirestoreOrganizationMembershipCheck
    implements OrganizationMembershipCheck {
  const FirestoreOrganizationMembershipCheck();

  @override
  Future<bool?> isMemberOf(String organizationId) async {
    try {
      final firebase = CurrentOrganizationFirebase.instance;
      final email = firebase.auth.currentUser?.email;
      if (email == null) return null;
      final doc = await firebase.firestore
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
