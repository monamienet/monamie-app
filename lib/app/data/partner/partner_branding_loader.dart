import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';
import 'package:monamie_app/app/data/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';

import 'partner_binding.dart';
import 'partner_directory.dart';
import 'partner_session.dart';

/// Path of partner [partnerId]'s branding document in its project.
String brandingDocumentPath(String partnerId) =>
    'partners/$partnerId/config/branding';

const _brandingTimeout = Duration(seconds: 10);

/// Reads a partner's public branding document and pairs it with the
/// partner's Firebase options.
class PartnerBrandingLoader {
  PartnerBrandingLoader({ThemeCatalog? themes, http.Client? client})
    : _themes = themes,
      _http = client ?? http.Client();

  final ThemeCatalog? _themes;
  final http.Client _http;

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
      final snapshot = await FirebaseFirestore.instanceFor(app: app)
          .doc(brandingDocumentPath(binding.partner.id))
          .get()
          .timeout(_brandingTimeout);
      final data = snapshot.data();
      final read = PartnerConfig.fromBranding(binding.partner.id, data);
      return PartnerConfig.fromBranding(
        binding.partner.id,
        data,
        theme: await _resolveTheme(read.themeId, binding.partner.theme),
        logoPng: await _logo(binding, read.logoVersion),
      );
    } catch (error) {
      debugPrint(
        'Could not read the branding of ${binding.partner.id}: $error',
      );
      return binding.partner;
    }
  }

  /// The catalog theme [themeId] names, or the default theme when it is
  /// missing or unknown. When the catalog cannot be read, the theme already
  /// stored with the binding is kept if it is the same id.
  Future<PartnerTheme> _resolveTheme(
    String? themeId,
    PartnerTheme? stored,
  ) async {
    if (themeId == null) return defaultPartnerTheme;
    try {
      final catalog = await (_themes ?? const FirestoreThemeCatalog()).themes();
      return resolvePartnerTheme(themeId, catalog);
    } catch (error) {
      debugPrint('Could not read the theme catalog: $error');
      return stored != null && stored.id == themeId ? stored : defaultPartnerTheme;
    }
  }

  /// The logo PNG for [version]: the one stored with the binding when it is
  /// the same version, else downloaded from the partner's public Storage
  /// path. `null` when there is no logo or it cannot be fetched (the app
  /// then shows the name's initial).
  Future<Uint8List?> _logo(PartnerBinding binding, int? version) async {
    if (version == null) return null;
    final stored = binding.partner;
    if (stored.logoVersion == version && stored.logoPng != null) {
      return stored.logoPng;
    }
    try {
      final response = await _http
          .get(partnerLogoUri(binding.options, stored.id, version))
          .timeout(_brandingTimeout);
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (error) {
      debugPrint('Could not download the logo of ${stored.id}: $error');
      return null;
    }
  }
}

/// Public download URL of partner [partnerId]'s logo,
/// `partners/<id>/logo.png` in the default bucket of its project.
/// [version] only defeats caches between uploads.
Uri partnerLogoUri(FirebaseOptions options, String partnerId, int version) {
  final bucket =
      options.storageBucket ?? '${options.projectId}.firebasestorage.app';
  // The object name goes in one path segment, so its slashes are escaped
  // once (`Uri.https` would escape the `%` again).
  return Uri.parse(
    'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
    '${Uri.encodeComponent(partnerLogoPath(partnerId))}?alt=media&v=$version',
  );
}

/// Storage path of partner [partnerId]'s logo.
String partnerLogoPath(String partnerId) => 'partners/$partnerId/logo.png';
