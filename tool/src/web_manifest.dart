import 'dart:convert';

import 'partners.dart';

/// Name of the Web App Manifest staged in `web/partner/`.
const webManifestFileName = 'manifest.json';

/// PWA icons every partner provides under `partners/<id>/web/`, with their
/// paths relative to that folder (and to the staged manifest).
const webManifestIcons = <({String src, String sizes, bool maskable})>[
  (src: 'icons/Icon-192.png', sizes: '192x192', maskable: false),
  (src: 'icons/Icon-512.png', sizes: '512x512', maskable: false),
  (src: 'icons/Icon-maskable-192.png', sizes: '192x192', maskable: true),
  (src: 'icons/Icon-maskable-512.png', sizes: '512x512', maskable: true),
];

/// Returns the Web App Manifest of partner [name] with [themeColor]
/// (`#RRGGBB`), as written to `web/partner/manifest.json`.
///
/// URLs in a manifest resolve against the manifest's own URL, so
/// `start_url` goes one level up from `partner/` to the app root, and the
/// icons point at `partner/icons/`.
Map<String, Object> webManifest({
  required String name,
  required String themeColor,
}) {
  final displayName = partnerDisplayName(name);
  return {
    'name': displayName,
    'short_name': displayName,
    'start_url': '../',
    'display': 'standalone',
    'background_color': '#ffffff',
    'theme_color': themeColor,
    'description': 'A new Flutter project.',
    'orientation': 'portrait-primary',
    'prefer_related_applications': false,
    'icons': [
      for (final icon in webManifestIcons)
        {
          'src': icon.src,
          'sizes': icon.sizes,
          'type': 'image/png',
          if (icon.maskable) 'purpose': 'maskable',
        },
    ],
  };
}

/// Encodes [manifest] as indented JSON with a trailing newline.
String encodeWebManifest(Map<String, Object> manifest) =>
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
