import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart'
    as theme;
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/organization/organization_branding_loader.dart';
import 'package:monamie_app/app/data/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';

import 'appearance_backend.dart';

/// [AppearanceBackend] over the organization's Storage and its `setBranding`
/// function, with themes from the central catalog.
class FirebaseAppearanceBackend implements AppearanceBackend {
  FirebaseAppearanceBackend({ThemeCatalog? themes})
    : _themes = themes ?? const FirestoreThemeCatalog();

  final ThemeCatalog _themes;

  Reference _logo(String organizationId) => CurrentOrganizationFirebase
      .instance
      .storage
      .ref(organizationLogoPath(organizationId));

  @override
  Future<List<theme.OrganizationTheme>> pickableThemes() async =>
      theme.pickableThemes((await _themes.themes()).values);

  @override
  Future<void> uploadLogo(String organizationId, Uint8List png) async {
    await _logo(
      organizationId,
    ).putData(png, SettableMetadata(contentType: 'image/png'));
  }

  @override
  Future<void> deleteLogo(String organizationId) async {
    try {
      await _logo(organizationId).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  @override
  Future<void> saveBranding(
    String organizationId, {
    String? name,
    String? themeId,
    String? logo,
  }) async {
    try {
      await CurrentOrganizationFirebase.instance.functions
          .httpsCallable('setBranding')
          .call({
            'organizationId': organizationId,
            'name': ?name,
            'themeId': ?themeId,
            'logo': ?logo,
          });
    } on FirebaseFunctionsException catch (e) {
      throw AppearanceException(
        e.code == 'invalid-argument' || e.code == 'permission-denied'
            ? (e.message ?? 'Não foi possível salvar.')
            : 'Não foi possível salvar agora. Verifique a conexão e tente de novo.',
      );
    }
  }
}
