import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/partners.dart';
import '../../tool/src/web_staging.dart';

/// Brand files the spec requires under `partners/<id>/web/`, staged with the
/// same relative paths. Written out here so the tests do not trust the
/// implementation's own list.
const specBrandFiles = <String>[
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];

/// Every file a successful run leaves in `web/partner/`, sorted.
final expectedStagedFiles = <String>[
  ...specBrandFiles,
  'manifest.json',
  'partner.json',
]..sort();

/// The 8-byte signature that starts every PNG file.
const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

/// Distinct PNG-like bytes for brand file [path] of partner [id].
List<int> brandBytes(String id, String path) => [
  ...pngSignature,
  ...utf8.encode('$id/$path'),
];

/// Creates `partners/<id>/partner.json` under [repoRoot] with [bytes] and no
/// brand files.
void writeConfigBytes(Directory repoRoot, String id, List<int> bytes) {
  File(p.join(repoRoot.path, 'partners', id, partnerConfigFileName))
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

/// Creates `partners/<id>/partner.json` under [repoRoot] with [json] and no
/// brand files.
void writeConfigOnly(Directory repoRoot, String id, String json) {
  writeConfigBytes(repoRoot, id, utf8.encode(json));
}

/// Creates every brand file of [specBrandFiles] in `partners/<id>/web/`,
/// except the ones listed in [skip].
void writeBrandFiles(
  Directory repoRoot,
  String id, {
  Set<String> skip = const {},
}) {
  for (final path in specBrandFiles) {
    if (skip.contains(path)) continue;
    File(p.join(repoRoot.path, 'partners', id, 'web', path))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(brandBytes(id, path));
  }
}

/// Creates a complete partner [id]: `partner.json` with [bytes] plus every
/// brand file.
void writePartnerBytes(Directory repoRoot, String id, List<int> bytes) {
  writeConfigBytes(repoRoot, id, bytes);
  writeBrandFiles(repoRoot, id);
}

/// Creates a complete partner [id]: `partner.json` with [json] plus every
/// brand file.
void writePartner(Directory repoRoot, String id, String json) {
  writePartnerBytes(repoRoot, id, utf8.encode(json));
}

/// The staging folder `web/partner/` inside [repoRoot].
Directory stageDir(Directory repoRoot) =>
    Directory(p.join(repoRoot.path, webPartnerDirPath));

/// The staged `web/partner/partner.json` inside [repoRoot].
File stagedConfig(Directory repoRoot) =>
    File(p.join(stageDir(repoRoot).path, partnerConfigFileName));

/// The staged `web/partner/manifest.json` inside [repoRoot], decoded.
Map<String, dynamic> stagedManifest(Directory repoRoot) =>
    jsonDecode(
          File(
            p.join(stageDir(repoRoot).path, 'manifest.json'),
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

/// Relative paths (with `/`) of every file under the staging folder, sorted.
List<String> stagedFiles(Directory repoRoot) {
  final dir = stageDir(repoRoot);
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map(
        (file) =>
            p.posix.joinAll(p.split(p.relative(file.path, from: dir.path))),
      )
      .toList()
    ..sort();
}

/// The bytes of every staged file, keyed by its relative path.
Map<String, List<int>> stagedSnapshot(Directory repoRoot) => {
  for (final path in stagedFiles(repoRoot))
    path: File(p.join(stageDir(repoRoot).path, path)).readAsBytesSync(),
};

/// The manifest the spec expects for partner [name] with color [primary].
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
  'icons': [
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
  ],
};

/// Copies the real repository partner [id] into `partners/<id>/` of
/// [repoRoot], following the folder recursively.
void copyRealPartner(Directory repoRoot, String id) {
  final source = Directory(p.join('partners', id));
  for (final file in source.listSync(recursive: true).whereType<File>()) {
    final relative = p.relative(file.path, from: source.path);
    File(p.join(repoRoot.path, 'partners', id, relative))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(file.readAsBytesSync());
  }
}

const acmeJson = '{"name": "Acme", "colors": {"primary": "#112233"}}';
const betaJson = '{"name": "Beta", "colors": {"primary": "#445566"}}';

void main() {
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('partner_tool_web_');
  });

  tearDown(() {
    if (repoRoot.existsSync()) {
      repoRoot.deleteSync(recursive: true);
    }
  });

  group('webPartnerDirPath - Unit Test Suite', () {
    test('Happy Path: points at web/partner', () {
      // 1. Arrange
      const expected = 'web/partner';

      // 2. Act
      const path = webPartnerDirPath;

      // 3. Assert
      expect(path, expected);
    });
  });

  group('requiredWebBrandFiles - Unit Test Suite', () {
    test('Happy Path: holds the favicon and the four PWA icons', () {
      // 1. Arrange
      const expected = specBrandFiles;

      // 2. Act
      final required = requiredWebBrandFiles;

      // 3. Assert
      expect(required, unorderedEquals(expected));
    });
  });

  group('stageWebPartner - Unit Test Suite', () {
    test('Happy Path: copies partner.json into web/partner/ byte for '
        'byte', () {
      // 1. Arrange
      final sourceBytes = utf8.encode(
        '{\r\n  "name": "Acmé",\r\n  "colors": {"primary": "#112233"}\r\n}\n',
      );
      writePartnerBytes(repoRoot, 'acme', sourceBytes);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsBytesSync(), sourceBytes);
    });

    test('Happy Path: copies every brand file byte for byte with the same '
        'relative path', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final expected = {
        for (final path in specBrandFiles) path: brandBytes('acme', path),
      };

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(
        stagedSnapshot(repoRoot)
          ..remove('partner.json')
          ..remove('manifest.json'),
        expected,
      );
    });

    test('Happy Path: generates manifest.json from partner.json', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedManifest(repoRoot), expectedManifest('Acme', '#112233'));
    });

    test('Happy Path: every icon of the generated manifest is staged next to '
        'it', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      final icons = (stagedManifest(repoRoot)['icons'] as List).map(
        (icon) => (icon as Map<String, dynamic>)['src'] as String,
      );
      expect(stagedFiles(repoRoot), containsAll(icons));
    });

    test('Happy Path: returns the staged paths relative to web/partner/', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);

      // 2. Act
      final staged = stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(staged, unorderedEquals(expectedStagedFiles));
    });

    test('Happy Path: creates web/ when the repository has none yet', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedFiles(repoRoot), expectedStagedFiles);
    });

    test('Happy Path: staging a second partner replaces the first', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      writePartner(repoRoot, 'beta', betaJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'beta');

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsStringSync(), betaJson);
    });

    test('Happy Path: staging a second partner replaces the brand files of '
        'the first', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      writePartner(repoRoot, 'beta', betaJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'beta');

      // 3. Assert
      expect(
        File(p.join(stageDir(repoRoot).path, 'favicon.png')).readAsBytesSync(),
        brandBytes('beta', 'favicon.png'),
      );
    });

    test('Happy Path: staging a second partner regenerates the manifest', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      writePartner(repoRoot, 'beta', betaJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'beta');

      // 3. Assert
      expect(stagedManifest(repoRoot), expectedManifest('Beta', '#445566'));
    });

    test('Happy Path: the real aquariustur partner stages a manifest named '
        '"MonAmie AquariusTur" with theme color #0ABAB5', () {
      // 1. Arrange
      copyRealPartner(repoRoot, 'aquariustur');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'aquariustur');

      // 3. Assert
      expect(
        stagedManifest(repoRoot),
        allOf(
          containsPair('name', 'MonAmie AquariusTur'),
          containsPair('short_name', 'MonAmie AquariusTur'),
          containsPair('theme_color', '#0ABAB5'),
        ),
      );
    });

    test('Happy Path: leaves the rest of web/ untouched', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final indexHtml = File(p.join(repoRoot.path, 'web', 'index.html'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('<html></html>');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(indexHtml.readAsStringSync(), '<html></html>');
    });

    test('Edge Case: keeps a lowercase primary color as written', () {
      // 1. Arrange
      writePartner(
        repoRoot,
        'acme',
        '{"name": "Acme", "colors": {"primary": "#0abab5"}}',
      );

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedManifest(repoRoot), containsPair('theme_color', '#0abab5'));
    });

    test('Edge Case: keeps spaces and accents of the partner name', () {
      // 1. Arrange
      writePartner(
        repoRoot,
        'acme',
        '{"name": "Acmé Tur", "colors": {"primary": "#112233"}}',
      );

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(
        stagedManifest(repoRoot),
        containsPair('name', 'MonAmie Acmé Tur'),
      );
    });

    test('Edge Case: accepts unrelated extra keys in partner.json', () {
      // 1. Arrange
      writePartner(
        repoRoot,
        'acme',
        '{"name": "Acme", "colors": {"primary": "#112233", '
            '"secondary": "#FFFFFF"}, "extra": [1, 2]}',
      );

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedManifest(repoRoot), expectedManifest('Acme', '#112233'));
    });

    test('Edge Case: re-staging removes a stale file from web/partner/', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');
      File(p.join(stageDir(repoRoot).path, 'stale.txt')).writeAsStringSync('x');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedFiles(repoRoot), expectedStagedFiles);
    });

    test('Edge Case: re-staging removes a stale file in a nested folder', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final stale = File(p.join(stageDir(repoRoot).path, 'icons', 'old.png'))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stale.existsSync(), isFalse);
    });

    test('Edge Case: does not copy the Android files of the partner '
        'folder', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      File(p.join(repoRoot.path, 'partners', 'acme', 'android', 'icon.png'))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedFiles(repoRoot), expectedStagedFiles);
    });

    test('Edge Case: leaves the source partner.json unchanged', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final source = File(
        p.join(repoRoot.path, 'partners', 'acme', partnerConfigFileName),
      );

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(source.readAsStringSync(), acmeJson);
    });

    test('Edge Case: leaves the source brand files unchanged', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final source = File(
        p.join(repoRoot.path, 'partners', 'acme', 'web', 'icons/Icon-512.png'),
      );

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(
        source.readAsBytesSync(),
        brandBytes('acme', 'icons/Icon-512.png'),
      );
    });

    test('Sad Path: throws PartnerToolException for an unknown id', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'nope');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: an unknown id keeps the previous staging intact', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');
      final before = stagedSnapshot(repoRoot);

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'nope');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedSnapshot(repoRoot), before);
    });

    test('Sad Path: an invalid id throws and keeps the previous staging '
        'intact', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      writePartner(repoRoot, 'testing', betaJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');
      final before = stagedSnapshot(repoRoot);

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'testing');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedSnapshot(repoRoot), before);
    });

    test('Sad Path: a reserved id is rejected even when its folder '
        'exists', () {
      // 1. Arrange
      writePartner(repoRoot, 'debug', acmeJson);

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'debug');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: malformed JSON throws PartnerToolException', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '{"name": ');

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: malformed JSON keeps the previous staging intact', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      writePartner(repoRoot, 'broken', '{"name": ');
      stageWebPartner(repoRoot: repoRoot, id: 'acme');
      final before = stagedSnapshot(repoRoot);

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'broken');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedSnapshot(repoRoot), before);
    });

    test('Sad Path: a JSON array throws PartnerToolException', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '[$acmeJson]');

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a JSON array keeps the previous staging intact', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      writePartner(repoRoot, 'list', '[1, 2, 3]');
      stageWebPartner(repoRoot: repoRoot, id: 'acme');
      final before = stagedSnapshot(repoRoot);

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'list');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedSnapshot(repoRoot), before);
    });

    test('Sad Path: a JSON scalar throws PartnerToolException', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '"Acme"');

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a JSON null throws PartnerToolException', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', 'null');

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: an empty partner.json throws PartnerToolException', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '');

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: invalid UTF-8 throws PartnerToolException', () {
      // 1. Arrange
      writePartnerBytes(repoRoot, 'acme', [0x7B, 0xFF, 0xFE, 0x7D]);

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a failed first run does not create web/partner/', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', 'not json');

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'acme');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stageDir(repoRoot).existsSync(), isFalse);
    });
  });

  group('stageWebPartner partner.json identity validation - Unit Test '
      'Suite', () {
    /// Invalid `partner.json` bodies, keyed by a description of the problem.
    const invalidConfigs = <String, String>{
      'an empty JSON object': '{}',
      'a missing "name"': '{"colors": {"primary": "#112233"}}',
      'a null "name"': '{"name": null, "colors": {"primary": "#112233"}}',
      'a numeric "name"': '{"name": 42, "colors": {"primary": "#112233"}}',
      'an empty "name"': '{"name": "", "colors": {"primary": "#112233"}}',
      'a blank "name"': '{"name": "  \\t ", "colors": {"primary": "#112233"}}',
      'a missing "colors"': '{"name": "Acme"}',
      'a "colors" that is not an object':
          '{"name": "Acme", "colors": "#112233"}',
      'a missing "colors.primary"':
          '{"name": "Acme", "colors": {"secondary": "#FFFFFF"}}',
      'a short "#RGB" primary color':
          '{"name": "Acme", "colors": {"primary": "#123"}}',
      'a primary color without "#"':
          '{"name": "Acme", "colors": {"primary": "112233"}}',
      'a primary color with non-hex digits':
          '{"name": "Acme", "colors": {"primary": "#GGHHII"}}',
      'a "#AARRGGBB" primary color':
          '{"name": "Acme", "colors": {"primary": "#FF112233"}}',
      'a named primary color':
          '{"name": "Acme", "colors": {"primary": "teal"}}',
      'a numeric primary color':
          '{"name": "Acme", "colors": {"primary": 1122867}}',
    };

    for (final MapEntry(key: problem, value: json) in invalidConfigs.entries) {
      test('Sad Path: $problem throws PartnerToolException', () {
        // 1. Arrange
        writePartner(repoRoot, 'acme', json);

        // 2. Act
        void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

        // 3. Assert
        expect(action, throwsA(isA<PartnerToolException>()));
      });

      test('Sad Path: $problem keeps the previous staging intact', () {
        // 1. Arrange
        writePartner(repoRoot, 'good', acmeJson);
        writePartner(repoRoot, 'bad', json);
        stageWebPartner(repoRoot: repoRoot, id: 'good');
        final before = stagedSnapshot(repoRoot);

        // 2. Act
        try {
          stageWebPartner(repoRoot: repoRoot, id: 'bad');
        } on PartnerToolException {
          // Expected: the assertion checks the folder left behind.
        }

        // 3. Assert
        expect(stagedSnapshot(repoRoot), before);
      });
    }
  });

  group('stageWebPartner brand file validation - Unit Test Suite', () {
    for (final missing in specBrandFiles) {
      test('Sad Path: a missing web/$missing throws PartnerToolException', () {
        // 1. Arrange
        writeConfigOnly(repoRoot, 'acme', acmeJson);
        writeBrandFiles(repoRoot, 'acme', skip: {missing});

        // 2. Act
        void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

        // 3. Assert
        expect(action, throwsA(isA<PartnerToolException>()));
      });

      test('Sad Path: a missing web/$missing keeps the previous staging '
          'intact', () {
        // 1. Arrange
        writePartner(repoRoot, 'good', acmeJson);
        writeConfigOnly(repoRoot, 'bad', betaJson);
        writeBrandFiles(repoRoot, 'bad', skip: {missing});
        stageWebPartner(repoRoot: repoRoot, id: 'good');
        final before = stagedSnapshot(repoRoot);

        // 2. Act
        try {
          stageWebPartner(repoRoot: repoRoot, id: 'bad');
        } on PartnerToolException {
          // Expected: the assertion checks the folder left behind.
        }

        // 3. Assert
        expect(stagedSnapshot(repoRoot), before);
      });
    }

    test('Sad Path: a partner without a web/ folder throws '
        'PartnerToolException', () {
      // 1. Arrange
      writeConfigOnly(repoRoot, 'acme', acmeJson);

      // 2. Act
      void action() => stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a partner without a web/ folder keeps the previous '
        'staging intact', () {
      // 1. Arrange
      writePartner(repoRoot, 'good', acmeJson);
      writeConfigOnly(repoRoot, 'bad', betaJson);
      stageWebPartner(repoRoot: repoRoot, id: 'good');
      final before = stagedSnapshot(repoRoot);

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'bad');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedSnapshot(repoRoot), before);
    });

    test('Sad Path: a missing brand file on the first run does not create '
        'web/partner/', () {
      // 1. Arrange
      writeConfigOnly(repoRoot, 'acme', acmeJson);
      writeBrandFiles(repoRoot, 'acme', skip: {'favicon.png'});

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'acme');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stageDir(repoRoot).existsSync(), isFalse);
    });
  });

  group('stageWebPartner existing web/partner entity - Unit Test Suite', () {
    test('Happy Path: replaces a regular file at web/partner with the '
        'staged folder', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      File(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('not a folder');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsStringSync(), acmeJson);
    });

    test('Happy Path: replaces a symlink at web/partner with a real '
        'folder', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final outside = Directory(p.join(repoRoot.path, 'outside'))..createSync();
      Link(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..createSync(outside.path);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(
        FileSystemEntity.typeSync(
          p.join(repoRoot.path, webPartnerDirPath),
          followLinks: false,
        ),
        FileSystemEntityType.directory,
      );
    });

    test('Edge Case: removing a symlinked web/partner keeps the files of '
        'the link target', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final outside = Directory(p.join(repoRoot.path, 'outside'))..createSync();
      final precious = File(p.join(outside.path, 'precious.txt'))
        ..writeAsStringSync('keep me');
      Link(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..createSync(outside.path);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(precious.readAsStringSync(), 'keep me');
    });

    test('Edge Case: staging through a symlinked web/partner does not write '
        'into the link target', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final outside = Directory(p.join(repoRoot.path, 'outside'))..createSync();
      Link(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..createSync(outside.path);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(outside.listSync(), isEmpty);
    });

    test('Edge Case: replaces a dangling symlink at web/partner', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      Link(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..createSync(p.join(repoRoot.path, 'does-not-exist'));

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedFiles(repoRoot), expectedStagedFiles);
    });

    test('Sad Path: a failed run keeps a symlinked web/partner in place', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      final outside = Directory(p.join(repoRoot.path, 'outside'))..createSync();
      final link = Link(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..createSync(outside.path);

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'nope');
      } on PartnerToolException {
        // Expected: the assertion checks the link left behind.
      }

      // 3. Assert
      expect(link.targetSync(), outside.path);
    });

    test('Sad Path: a failed run keeps a regular file at web/partner', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '[1]');
      final file = File(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('not a folder');

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'acme');
      } on PartnerToolException {
        // Expected: the assertion checks the file left behind.
      }

      // 3. Assert
      expect(file.readAsStringSync(), 'not a folder');
    });

    test('Sad Path: a missing brand file keeps a regular file at '
        'web/partner', () {
      // 1. Arrange
      writeConfigOnly(repoRoot, 'acme', acmeJson);
      writeBrandFiles(repoRoot, 'acme', skip: {'icons/Icon-512.png'});
      final file = File(p.join(repoRoot.path, webPartnerDirPath))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('not a folder');

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'acme');
      } on PartnerToolException {
        // Expected: the assertion checks the file left behind.
      }

      // 3. Assert
      expect(file.readAsStringSync(), 'not a folder');
    });
  });
}
