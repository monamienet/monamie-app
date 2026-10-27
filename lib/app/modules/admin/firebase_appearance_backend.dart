import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart' as theme;
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';
import 'package:monamie_app/app/data/partner/partner_branding_loader.dart';
import 'package:monamie_app/app/data/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';

import 'appearance_backend.dart';

/// [AppearanceBackend] over the partner's Storage and its `setBranding`
/// function, with themes from the central catalog.
class FirebaseAppearanceBackend implements AppearanceBackend {
  FirebaseAppearanceBackend({ThemeCatalog? themes})
    : _themes = themes ?? const FirestoreThemeCatalog();

  final ThemeCatalog _themes;

  Reference _logo(String partnerId) =>
      CurrentPartnerFirebase.instance.storage.ref(partnerLogoPath(partnerId));

  @override
  Future<List<theme.PartnerTheme>> pickableThemes() async =>
      theme.pickableThemes((await _themes.themes()).values);

  @override
  Future<void> uploadLogo(String partnerId, Uint8List png) async {
    await _logo(partnerId).putData(
      png,
      SettableMetadata(contentType: 'image/png'),
    );
  }

  @override
  Future<void> deleteLogo(String partnerId) async {
    try {
      await _logo(partnerId).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  @override
  Future<void> saveBranding(
    String partnerId, {
    String? name,
    String? themeId,
    String? logo,
  }) async {
    try {
      await CurrentPartnerFirebase.instance.functions
          .httpsCallable('setBranding')
          .call({
            'partnerId': partnerId,
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
