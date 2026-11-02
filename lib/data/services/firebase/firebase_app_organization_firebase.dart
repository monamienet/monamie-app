import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'organization_firebase.dart';
import 'firestore_paths.dart';

/// [OrganizationFirebase] backed by one [FirebaseApp].
class FirebaseAppOrganizationFirebase implements OrganizationFirebase {
  const FirebaseAppOrganizationFirebase(this.app, this.organizationId);

  final FirebaseApp app;

  /// The organization whose data this app reads: `organizations/{organizationId}`.
  final String organizationId;

  @override
  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);

  @override
  FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(app: app);

  @override
  FirebaseFunctions get functions => FirebaseFunctions.instanceFor(app: app);

  @override
  FirebaseStorage get storage => FirebaseStorage.instanceFor(app: app);

  @override
  DocumentReference<Map<String, dynamic>> get organizationData =>
      firestore.doc(organizationDataPath(organizationId));
}

/// `organizations/{organizationId}`: where an organization's data lives in its project.
String organizationDataPath(String organizationId) =>
    FirestorePaths.organization(organizationId);
