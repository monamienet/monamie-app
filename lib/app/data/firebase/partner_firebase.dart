import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The Firebase services of the partner the user is bound to.
///
/// Every read and write of partner data (sessions, locations, groups,
/// claims) goes through this contract instead of `FirebaseAuth.instance`
/// and friends, which always point to the `[DEFAULT]` app.
abstract interface class PartnerFirebase {
  FirebaseAuth get auth;
  FirebaseFirestore get firestore;
  FirebaseFunctions get functions;

  /// `partners/{id}` of the bound partner: the root of all its data. A
  /// Standard project holds one partner and the shared Community project
  /// many, with the same layout.
  DocumentReference<Map<String, dynamic>> get partnerData;
}
