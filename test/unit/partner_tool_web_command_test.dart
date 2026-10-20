import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/partners.dart';
import '../../tool/src/web_command.dart';
import '../../tool/src/web_staging.dart';

/// Creates `partners/<id>/partner.json` under [repoRoot] with [json].
void writePartner(Directory repoRoot, String id, String json) {
  File(p.join(repoRoot.path, 'partners', id, partnerConfigFileName))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json);
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
      const json = '{"name": "MonAmie Acme"}';
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
