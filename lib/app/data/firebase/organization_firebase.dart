import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// The Firebase services of the organization the user is bound to.
///
/// Every read and write of organization data (sessions, locations, groups,
/// claims) goes through this contract instead of `FirebaseAuth.instance`
/// and friends, which always point to the `[DEFAULT]` app.
abstract interface class OrganizationFirebase {
  FirebaseAuth get auth;
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;
  FirebaseStorage get storage;

  /// `organizations/{id}` of the bound organization: the root of all its data. A
  /// Standard project holds one organization and the shared Community project
  /// many, with the same layout.
  DocumentReference<Map<String, dynamic>> get organizationData;
}
