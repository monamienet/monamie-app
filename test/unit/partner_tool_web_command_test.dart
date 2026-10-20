import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/partners.dart';
import '../../tool/src/web_command.dart';
import '../../tool/src/web_staging.dart';

/// Brand files the spec requires under `partners/<id>/web/`.
const specBrandFiles = <String>[
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];

/// Creates `partners/<id>/partner.json` under [repoRoot] with [json], the
/// login logo `partners/<id>/logo-com-texto.svg` and every brand file in
/// `partners/<id>/web/`.
void writePartner(Directory repoRoot, String id, String json) {
  File(p.join(repoRoot.path, 'partners', id, partnerConfigFileName))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json);
  File(
    p.join(repoRoot.path, 'partners', id, 'logo-com-texto.svg'),
  ).writeAsStringSync('<svg xmlns="http://www.w3.org/2000/svg"/>');
  for (final path in specBrandFiles) {
    File(p.join(repoRoot.path, 'partners', id, 'web', path))
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  }
}

/// A runner exposing only the `web` command bound to [repoRoot].
CommandRunner<void> buildRunner(Directory repoRoot) =>
    CommandRunner<void>('partner', 'Partner tool under test.')
      ..addCommand(WebCommand(repoRoot));

void main() {
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('partner_tool_command_');
  });

  tearDown(() {
    if (repoRoot.existsSync()) {
      repoRoot.deleteSync(recursive: true);
    }
  });

  group('WebCommand - Unit Test Suite', () {
    test('Happy Path: is registered under the name "web"', () {
      // 1. Arrange
      final command = WebCommand(repoRoot);

      // 2. Act
      final name = command.name;

      // 3. Assert
      expect(name, 'web');
    });

    test('Happy Path: stages the partner given as the only argument', () async {
      // 1. Arrange
      const json = '{"name": "Acme", "colors": {"primary": "#112233"}}';
      writePartner(repoRoot, 'acme', json);
      final runner = buildRunner(repoRoot);

      // 2. Act
      await runner.run(['web', 'acme']);

      // 3. Assert
      expect(
        File(
          p.join(repoRoot.path, webPartnerDirPath, partnerConfigFileName),
        ).readAsStringSync(),
        json,
      );
    });

    test('Happy Path: writes the given id to web/partner/id.txt', () async {
      // 1. Arrange
      writePartner(
        repoRoot,
        'acme',
        '{"name": "Acme", "colors": {"primary": "#112233"}}',
      );
      final runner = buildRunner(repoRoot);

      // 2. Act
      await runner.run(['web', 'acme']);

      // 3. Assert
      expect(
        File(
          p.join(repoRoot.path, webPartnerDirPath, webPartnerIdFileName),
        ).readAsStringSync(),
        'acme\n',
      );
    });

    test('Sad Path: throws UsageException when no id is given', () {
      // 1. Arrange
      final runner = buildRunner(repoRoot);

      // 2. Act
      Future<void> action() => runner.run(['web']);

      // 3. Assert
      expect(action, throwsA(isA<UsageException>()));
    });

    test('Sad Path: throws UsageException when two ids are given', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '{}');
      writePartner(repoRoot, 'beta', '{}');
      final runner = buildRunner(repoRoot);

      // 2. Act
      Future<void> action() => runner.run(['web', 'acme', 'beta']);

      // 3. Assert
      expect(action, throwsA(isA<UsageException>()));
    });

    test('Sad Path: two ids do not create web/partner/', () async {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '{}');
      writePartner(repoRoot, 'beta', '{}');
      final runner = buildRunner(repoRoot);

      // 2. Act
      try {
        await runner.run(['web', 'acme', 'beta']);
      } on UsageException {
        // Expected: the assertion checks the folder left behind.
      }

      // 3. Assert
      expect(
        Directory(p.join(repoRoot.path, webPartnerDirPath)).existsSync(),
        isFalse,
      );
    });

    test('Sad Path: propagates PartnerToolException for an unknown id', () {
      // 1. Arrange
      writePartner(repoRoot, 'acme', '{}');
      final runner = buildRunner(repoRoot);

      // 2. Act
      Future<void> action() => runner.run(['web', 'nope']);

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });
  });
}
