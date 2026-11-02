import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';

/// Collection of the theme catalog in the central project.
const themesCollectionPath = FirestorePaths.themes;

const _catalogTimeout = Duration(seconds: 10);

/// [ThemeRepository] read from the central project's Firestore (the
/// `[DEFAULT]` app). The catalog is public: names and colors only.
class ThemeRepositoryFirestore implements ThemeRepository {
  const ThemeRepositoryFirestore();

  @override
  Future<Map<String, OrganizationTheme>> themes() async {
    final snapshot = await FirebaseFirestore.instanceFor(
      app: Firebase.app(),
    ).collection(themesCollectionPath).get().timeout(_catalogTimeout);
    return {
      for (final doc in snapshot.docs)
        doc.id: ?OrganizationTheme.fromJson(doc.id, doc.data()),
    };
  }
}
