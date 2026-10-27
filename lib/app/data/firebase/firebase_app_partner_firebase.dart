import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'partner_firebase.dart';

/// [PartnerFirebase] backed by one [FirebaseApp].
class FirebaseAppPartnerFirebase implements PartnerFirebase {
  const FirebaseAppPartnerFirebase(this.app, this.partnerId);

  final FirebaseApp app;

  /// The partner whose data this app reads: `partners/{partnerId}`.
  final String partnerId;

  @override
  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);

  @override
  FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(app: app);

  @override
  FirebaseFunctions get functions => FirebaseFunctions.instanceFor(app: app);

  @override
  DocumentReference<Map<String, dynamic>> get partnerData =>
      firestore.doc(partnerDataPath(partnerId));
}

/// `partners/{partnerId}`: where a partner's data lives in its project.
String partnerDataPath(String partnerId) => 'partners/$partnerId';
