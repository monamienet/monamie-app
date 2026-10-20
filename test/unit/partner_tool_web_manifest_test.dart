import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/web_manifest.dart';

/// The icons the spec requires, with `src` relative to `partner/` (the
/// folder that holds the manifest).
const specIcons = <Map<String, String>>[
  {'src': 'icons/Icon-192.png', 'sizes': '192x192', 'type': 'image/png'},
  {'src': 'icons/Icon-512.png', 'sizes': '512x512', 'type': 'image/png'},
  {
    'src': 'icons/Icon-maskable-192.png',
    'sizes': '192x192',
    'type': 'image/png',
    'purpose': 'maskable',
  },
  {
    'src': 'icons/Icon-maskable-512.png',
    'sizes': '512x512',
    'type': 'image/png',
    'purpose': 'maskable',
  },
];

/// The manifest the spec expects for partner [name] with color [primary]:
/// the old static manifest with the partner fields and the paths rebased on
/// `partner/manifest.json`.
Map<String, Object> expectedManifest(String name, String primary) => {
  'name': 'MonAmie $name',
  'short_name': 'MonAmie $name',
  'start_url': '../',
  'display': 'standalone',
  'background_color': '#ffffff',
  'theme_color': primary,
  'description': 'A new Flutter project.',
  'orientation': 'portrait-primary',
  'prefer_related_applications': false,
  'icons': specIcons,
};

void main() {
  group('webManifestFileName - Unit Test Suite', () {
    test('Happy Path: is manifest.json', () {
      // 1. Arrange
      const expected = 'manifest.json';

      // 2. Act
      const fileName = webManifestFileName;

      // 3. Assert
      expect(fileName, expected);
    });
  });

  group('webManifestIcons - Unit Test Suite', () {
    test('Happy Path: lists two regular and two maskable PNG icons under '
        'icons/', () {
      // 1. Arrange
      const expected = [
        (src: 'icons/Icon-192.png', sizes: '192x192', maskable: false),
        (src: 'icons/Icon-512.png', sizes: '512x512', maskable: false),
        (src: 'icons/Icon-maskable-192.png', sizes: '192x192', maskable: true),
        (src: 'icons/Icon-maskable-512.png', sizes: '512x512', maskable: true),
      ];

      // 2. Act
      final icons = webManifestIcons;

      // 3. Assert
      expect(icons, expected);
    });
  });

  group('webManifest - Unit Test Suite', () {
    test('Happy Path: builds the full AquariusTur manifest', () {
      // 1. Arrange
      const name = 'AquariusTur';
      const themeColor = '#0ABAB5';

      // 2. Act
      final manifest = webManifest(name: name, themeColor: themeColor);

      // 3. Assert
      expect(manifest, expectedManifest('AquariusTur', '#0ABAB5'));
    });

    test('Happy Path: uses "MonAmie <name>" as name and short_name', () {
      // 1. Arrange
      const name = 'Acme';

      // 2. Act
      final manifest = webManifest(name: name, themeColor: '#112233');

      // 3. Assert
      expect(
        manifest,
        allOf(
          containsPair('name', 'MonAmie Acme'),
          containsPair('short_name', 'MonAmie Acme'),
        ),
      );
    });

    test('Happy Path: uses the primary color as theme_color', () {
      // 1. Arrange
      const themeColor = '#445566';

      // 2. Act
      final manifest = webManifest(name: 'Acme', themeColor: themeColor);

      // 3. Assert
      expect(manifest, containsPair('theme_color', '#445566'));
    });

    test('Happy Path: start_url points from partner/ back to the app '
        'root', () {
      // 1. Arrange
      const name = 'Acme';

      // 2. Act
      final manifest = webManifest(name: name, themeColor: '#112233');

      // 3. Assert
      expect(manifest, containsPair('start_url', '../'));
    });

    test('Happy Path: icon sources are relative to partner/', () {
      // 1. Arrange
      const name = 'Acme';

      // 2. Act
      final manifest = webManifest(name: name, themeColor: '#112233');

      // 3. Assert
      expect(manifest['icons'], specIcons);
    });

    test('Edge Case: keeps a lowercase theme color as given', () {
      // 1. Arrange
      const themeColor = '#0abab5';

      // 2. Act
      final manifest = webManifest(name: 'Acme', themeColor: themeColor);

      // 3. Assert
      expect(manifest, containsPair('theme_color', '#0abab5'));
    });

    test('Edge Case: keeps spaces and accents of the partner name', () {
      // 1. Arrange
      const name = 'Acmé Tur';

      // 2. Act
      final manifest = webManifest(name: name, themeColor: '#112233');

      // 3. Assert
      expect(manifest, containsPair('short_name', 'MonAmie Acmé Tur'));
    });

    test('Edge Case: background_color stays white whatever the theme '
        'color', () {
      // 1. Arrange
      const themeColor = '#000000';

      // 2. Act
      final manifest = webManifest(name: 'Acme', themeColor: themeColor);

      // 3. Assert
      expect(manifest, containsPair('background_color', '#ffffff'));
    });

    test('Sad Path: no icon source is absolute or prefixed with '
        'partner/', () {
      // 1. Arrange
      const name = 'Acme';

      // 2. Act
      final manifest = webManifest(name: name, themeColor: '#112233');

      // 3. Assert
      final sources = (manifest['icons'] as List)
          .map((icon) => (icon as Map)['src'] as String)
          .toList();
      expect(
        sources,
        everyElement(
          allOf(isNot(startsWith('/')), isNot(startsWith('partner/'))),
        ),
      );
    });

    test('Sad Path: start_url is not "." (which would resolve to '
        'partner/)', () {
      // 1. Arrange
      const name = 'Acme';

      // 2. Act
      final manifest = webManifest(name: name, themeColor: '#112233');

      // 3. Assert
      expect(manifest['start_url'], isNot('.'));
    });
  });

  group('encodeWebManifest - Unit Test Suite', () {
    test('Happy Path: encodes JSON that decodes back to the same '
        'manifest', () {
      // 1. Arrange
      final manifest = webManifest(name: 'AquariusTur', themeColor: '#0ABAB5');

      // 2. Act
      final encoded = encodeWebManifest(manifest);

      // 3. Assert
      expect(jsonDecode(encoded), expectedManifest('AquariusTur', '#0ABAB5'));
    });

    test('Happy Path: ends with a single trailing newline', () {
      // 1. Arrange
      final manifest = webManifest(name: 'Acme', themeColor: '#112233');

      // 2. Act
      final encoded = encodeWebManifest(manifest);

      // 3. Assert
      expect(encoded, allOf(endsWith('}\n'), isNot(endsWith('\n\n'))));
    });

    test('Edge Case: indents the JSON with two spaces', () {
      // 1. Arrange
      final manifest = <String, Object>{'name': 'MonAmie Acme'};

      // 2. Act
      final encoded = encodeWebManifest(manifest);

      // 3. Assert
      expect(encoded, '{\n  "name": "MonAmie Acme"\n}\n');
    });

    test('Edge Case: encodes an empty map as an empty object', () {
      // 1. Arrange
      final manifest = <String, Object>{};

      // 2. Act
      final encoded = encodeWebManifest(manifest);

      // 3. Assert
      expect(encoded, '{}\n');
    });

    test('Edge Case: keeps non-ASCII characters decodable', () {
      // 1. Arrange
      final manifest = webManifest(name: 'Acmé', themeColor: '#112233');

      // 2. Act
      final encoded = encodeWebManifest(manifest);

      // 3. Assert
      expect(
        (jsonDecode(encoded) as Map<String, dynamic>)['name'],
        'MonAmie Acmé',
      );
    });

    test('Sad Path: throws JsonUnsupportedObjectError for a value JSON '
        'cannot encode', () {
      // 1. Arrange
      final manifest = <String, Object>{'start': DateTime(2026)};

      // 2. Act
      void action() => encodeWebManifest(manifest);

      // 3. Assert
      expect(action, throwsA(isA<JsonUnsupportedObjectError>()));
    });
  });
}
