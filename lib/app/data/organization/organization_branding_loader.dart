import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart';
import 'package:monamie_app/app/data/theme/firestore_theme_catalog.dart';
import 'package:monamie_app/app/data/theme/theme_catalog.dart';

import 'organization_binding.dart';
import 'organization_directory.dart';
import 'organization_session.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

/// Path of organization [organizationId]'s branding document in its project.
String brandingDocumentPath(String organizationId) =>
    FirestorePaths.brandingDocument(organizationId);

const _brandingTimeout = Duration(seconds: 10);

/// Reads an organization's public branding document and pairs it with the
/// organization's Firebase options.
class OrganizationBrandingLoader {
  OrganizationBrandingLoader({ThemeCatalog? themes, http.Client? client})
    : _themes = themes,
      _http = client ?? http.Client();

  final ThemeCatalog? _themes;
  final http.Client _http;

  /// The binding of [candidate]. A branding that cannot be read never blocks
  /// the sign-in: the organization then shows its fallbacks (the capitalized id as
  /// name, MonAmie colors, the name instead of a logo).
  Future<OrganizationBinding> load(OrganizationCandidate candidate) async {
    final binding = OrganizationBinding(
      organization: OrganizationConfig.fromBranding(candidate.id, null),
      options: candidate.options,
    );
    return OrganizationBinding(
      organization: await readBranding(binding),
      options: candidate.options,
    );
  }

  /// The current branding of [binding]'s organization, or its stored one when the
  /// document cannot be read.
  Future<OrganizationConfig> readBranding(OrganizationBinding binding) async {
    try {
      final app = await organizationFirebaseApp(binding);
      final snapshot = await FirebaseFirestore.instanceFor(app: app)
          .doc(brandingDocumentPath(binding.organization.id))
          .get()
          .timeout(_brandingTimeout);
      final data = snapshot.data();
      final read = OrganizationConfig.fromBranding(
        binding.organization.id,
        data,
      );
      return OrganizationConfig.fromBranding(
        binding.organization.id,
        data,
        theme: await _resolveTheme(read.themeId, binding.organization.theme),
        logoPng: await _logo(binding, read.logoVersion),
      );
    } catch (error) {
      debugPrint(
        'Could not read the branding of ${binding.organization.id}: $error',
      );
      return binding.organization;
    }
  }

  /// The catalog theme [themeId] names, or the default theme when it is
  /// missing or unknown. When the catalog cannot be read, the theme already
  /// stored with the binding is kept if it is the same id.
  Future<OrganizationTheme> _resolveTheme(
    String? themeId,
    OrganizationTheme? stored,
  ) async {
    if (themeId == null) return defaultOrganizationTheme;
    try {
      final catalog = await (_themes ?? const FirestoreThemeCatalog()).themes();
      return resolveOrganizationTheme(themeId, catalog);
    } catch (error) {
      debugPrint('Could not read the theme catalog: $error');
      return stored != null && stored.id == themeId
          ? stored
          : defaultOrganizationTheme;
    }
  }

  /// The logo PNG for [version]: the one stored with the binding when it is
  /// the same version, else downloaded from the organization's public Storage
  /// path. `null` when there is no logo or it cannot be fetched (the app
  /// then shows the name's initial).
  Future<Uint8List?> _logo(OrganizationBinding binding, int? version) async {
    if (version == null) return null;
    final stored = binding.organization;
    if (stored.logoVersion == version && stored.logoPng != null) {
      return stored.logoPng;
    }
    try {
      final response = await _http
          .get(organizationLogoUri(binding.options, stored.id, version))
          .timeout(_brandingTimeout);
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (error) {
      debugPrint('Could not download the logo of ${stored.id}: $error');
      return null;
    }
  }
}

/// Public download URL of organization [organizationId]'s logo,
/// `organizations/<id>/logo.png` in the default bucket of its project.
/// [version] only defeats caches between uploads.
Uri organizationLogoUri(
  FirebaseOptions options,
  String organizationId,
  int version,
) {
  final bucket =
      options.storageBucket ?? '${options.projectId}.firebasestorage.app';
  // The object name goes in one path segment, so its slashes are escaped
  // once (`Uri.https` would escape the `%` again).
  return Uri.parse(
    'https://firebasestorage.googleapis.com/v0/b/$bucket/o/'
    '${Uri.encodeComponent(organizationLogoPath(organizationId))}?alt=media&v=$version',
  );
}

/// Storage path of organization [organizationId]'s logo.
String organizationLogoPath(String organizationId) =>
    FirestorePaths.logo(organizationId);
