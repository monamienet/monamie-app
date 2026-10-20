import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/partners.dart';
import '../../tool/src/web_staging.dart';

/// Creates `partners/<id>/partner.json` under [repoRoot] with [bytes].
void writePartnerBytes(Directory repoRoot, String id, List<int> bytes) {
  File(p.join(repoRoot.path, 'partners', id, partnerConfigFileName))
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

/// Creates `partners/<id>/partner.json` under [repoRoot] with [json].
void writePartner(Directory repoRoot, String id, String json) {
  File(p.join(repoRoot.path, 'partners', id, partnerConfigFileName))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json);
}

/// The staging folder `web/partner/` inside [repoRoot].
Directory stageDir(Directory repoRoot) =>
    Directory(p.join(repoRoot.path, webPartnerDirPath));

/// The staged `web/partner/partner.json` inside [repoRoot].
File stagedConfig(Directory repoRoot) =>
    File(p.join(stageDir(repoRoot).path, partnerConfigFileName));

/// Relative paths of every file under the staging folder, sorted.
List<String> stagedFiles(Directory repoRoot) {
  final dir = stageDir(repoRoot);
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => p.relative(file.path, from: dir.path))
      .toList()
    ..sort();
}

const acmeJson = '{"name": "MonAmie Acme", "primaryColor": "#112233"}';
const betaJson = '{"name": "MonAmie Beta", "primaryColor": "#445566"}';

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

  group('stageWebPartner - Unit Test Suite', () {
    test('Happy Path: copies partner.json into web/partner/ byte for '
        'byte', () {
      // 1. Arrange
      final sourceBytes = utf8.encode(
        '{\r\n  "name": "MonAmie Acmé",\r\n  "primaryColor": "#112233"\r\n}\n',
      );
      writePartnerBytes(repoRoot, 'acme', sourceBytes);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsBytesSync(), sourceBytes);
    });

    test('Happy Path: returns the staged paths relative to web/partner/', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);

      // 2. Act
      final staged = stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(staged, [partnerConfigFileName]);
    });

    test('Happy Path: creates web/ when the repository has none yet', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedFiles(repoRoot), [partnerConfigFileName]);
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

    test('Edge Case: re-staging removes a stale file from web/partner/', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');
      File(p.join(stageDir(repoRoot).path, 'stale.txt')).writeAsStringSync('x');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedFiles(repoRoot), [partnerConfigFileName]);
    });

    test('Edge Case: re-staging removes a stale nested folder', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      File(p.join(stageDir(repoRoot).path, 'icons', 'old.png'))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(
        Directory(p.join(stageDir(repoRoot).path, 'icons')).existsSync(),
        isFalse,
      );
    });

    test('Edge Case: accepts an empty JSON object', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '{}');

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsStringSync(), '{}');
    });

    test('Edge Case: does not copy other files of the partner folder', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      File(p.join(repoRoot.path, 'partners', 'acme', 'android', 'icon.png'))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);

      // 2. Act
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 3. Assert
      expect(stagedFiles(repoRoot), [partnerConfigFileName]);
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

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'nope');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsStringSync(), acmeJson);
    });

    test('Sad Path: an invalid id throws and keeps the previous staging '
        'intact', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', acmeJson);
      writePartner(repoRoot, 'testing', betaJson);
      stageWebPartner(repoRoot: repoRoot, id: 'acme');

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'testing');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsStringSync(), acmeJson);
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

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'broken');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsStringSync(), acmeJson);
    });

    test('Sad Path: a JSON array throws PartnerToolException', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '[{"name": "MonAmie Acme"}]');

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

      // 2. Act
      try {
        stageWebPartner(repoRoot: repoRoot, id: 'list');
      } on PartnerToolException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(stagedConfig(repoRoot).readAsStringSync(), acmeJson);
    });

    test('Sad Path: a JSON scalar throws PartnerToolException', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '"MonAmie Acme"');

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
      expect(
        File(p.join(outside.path, partnerConfigFileName)).existsSync(),
        isFalse,
      );
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
      expect(stagedFiles(repoRoot), [partnerConfigFileName]);
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
  });
}
