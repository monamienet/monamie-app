import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';
import 'package:monamie_app/app/data/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';

import 'partner_binding.dart';
import 'partner_directory.dart';
import 'partner_session.dart';

/// Path of the branding document in every partner project.
const brandingDocumentPath = 'config/branding';

const _brandingTimeout = Duration(seconds: 10);

/// Reads a partner's public branding document and pairs it with the
/// partner's Firebase options.
class PartnerBrandingLoader {
  const PartnerBrandingLoader({ThemeCatalog? themes}) : _themes = themes;

  final ThemeCatalog? _themes;

  /// The binding of [candidate]. A branding that cannot be read never blocks
  /// the sign-in: the partner then shows its fallbacks (the capitalized id as
  /// name, MonAmie colors, the name instead of a logo).
  Future<PartnerBinding> load(PartnerCandidate candidate) async {
    final binding = PartnerBinding(
      partner: PartnerConfig.fromBranding(candidate.id, null),
      options: candidate.options,
    );
    return PartnerBinding(
      partner: await readBranding(binding),
      options: candidate.options,
    );
  }

  /// The current branding of [binding]'s partner, or its stored one when the
  /// document cannot be read.
  Future<PartnerConfig> readBranding(PartnerBinding binding) async {
    try {
      final app = await partnerFirebaseApp(binding);
      final snapshot = await FirebaseFirestore.instanceFor(
        app: app,
      ).doc(brandingDocumentPath).get().timeout(_brandingTimeout);
      final data = snapshot.data();
      return PartnerConfig.fromBranding(
        binding.partner.id,
        data,
        theme: await _resolveTheme(data?['themeId'], binding.partner.theme),
      );
    } catch (error) {
      debugPrint(
        'Could not read the branding of ${binding.partner.id}: $error',
      );
      return binding.partner;
    }
  }

  /// The catalog theme [themeId] names. When the catalog cannot be read, the
  /// theme already stored with the binding is kept, if it is the same id.
  /// A branding without `themeId` keeps its legacy colors (`null`).
  Future<PartnerTheme?> _resolveTheme(
    Object? themeId,
    PartnerTheme? stored,
  ) async {
    if (themeId is! String) return null;
    try {
      final catalog = await (_themes ?? const FirestoreThemeCatalog()).themes();
      return resolvePartnerTheme(themeId, catalog);
    } catch (error) {
      debugPrint('Could not read the theme catalog: $error');
      return stored?.id == themeId ? stored : defaultPartnerTheme;
    }
  }
}
