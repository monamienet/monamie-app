import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';

import 'theme_catalog.dart';

/// Collection of the theme catalog in the central project.
const themesCollectionPath = 'themes';

const _catalogTimeout = Duration(seconds: 10);

/// [ThemeCatalog] read from the central project's Firestore (the
/// `[DEFAULT]` app). The catalog is public: names and colors only.
class FirestoreThemeCatalog implements ThemeCatalog {
  const FirestoreThemeCatalog();

  @override
  Future<Map<String, PartnerTheme>> themes() async {
    final snapshot = await FirebaseFirestore.instanceFor(
      app: Firebase.app(),
    ).collection(themesCollectionPath).get().timeout(_catalogTimeout);
    return {
      for (final doc in snapshot.docs)
        doc.id: ?PartnerTheme.fromJson(doc.id, doc.data()),
    };
  }
}
