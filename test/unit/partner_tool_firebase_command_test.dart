import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/src/firebase_cli.dart';
import '../../tool/src/firebase_command.dart';
import '../../tool/src/partners.dart';
import 'support/fake_firebase_cli.dart';

const acmeApp = FirebaseAndroidApp(
  appId: '1:111:android:acme',
  packageName: 'org.monamienet.acme',
);

/// A config the spec accepts for partner `acme`.
final validAcmeConfig = googleServicesJson(
  projectId: 'monamienet-acme',
  clients: [androidClient('org.monamienet.acme')],
);

/// A runner exposing only the `firebase` command bound to [repoRoot].
CommandRunner<void> buildRunner(Directory repoRoot, FirebaseCli cli) =>
    CommandRunner<void>('partner', 'Partner tool under test.')
      ..addCommand(FirebaseCommand(repoRoot, cli));

/// [Stdout] that keeps everything written to it in memory.
class CapturingStdout implements Stdout {
  final _buffer = StringBuffer();

  /// Everything written so far.
  String get text => _buffer.toString();

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) =>
      _buffer.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);

  @override
  void add(List<int> data) => _buffer.write(encoding.decode(data));

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs `firebase` with [args] while capturing `stdout`, and returns what
/// the command printed. Failures propagate.
Future<String> runCapturingStdout(
  CommandRunner<void> runner,
  List<String> args,
) async {
  final captured = CapturingStdout();
  await IOOverrides.runZoned(() => runner.run(args), stdout: () => captured);
  return captured.text;
}

void main() {
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('partner_tool_fb_command_');
    writePartner(repoRoot, 'acme');
  });

  tearDown(() {
    if (repoRoot.existsSync()) repoRoot.deleteSync(recursive: true);
  });

  group('FirebaseCommand - Unit Test Suite', () {
    test('Happy Path: is registered under the name "firebase"', () {
      // 1. Arrange
      final command = FirebaseCommand(repoRoot, FakeFirebaseCli());

      // 2. Act
      final name = command.name;

      // 3. Assert
      expect(name, 'firebase');
    });

    test('Happy Path: writes the config of the partner given as the only '
        'argument', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);
      final runner = buildRunner(repoRoot, cli);

      // 2. Act
      await runCapturingStdout(runner, ['firebase', 'acme']);

      // 3. Assert
      expect(
        specConfigFile(repoRoot, 'acme').readAsStringSync(),
        validAcmeConfig,
      );
    });

    test('Happy Path: asks the CLI about Firebase project '
        'monamienet-<id>', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);
      final runner = buildRunner(repoRoot, cli);

      // 2. Act
      await runCapturingStdout(runner, ['firebase', 'acme']);

      // 3. Assert
      expect(cli.listedProjects, ['monamienet-acme']);
    });

    test('Happy Path: prints exactly one line naming the path and the app '
        'id', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);
      final runner = buildRunner(repoRoot, cli);

      // 2. Act
      final output = await runCapturingStdout(runner, ['firebase', 'acme']);

      // 3. Assert
      expect(const LineSplitter().convert(output.trimRight()), [
        allOf(
          contains(p.join('android', 'app', 'src', 'acme')),
          contains('google-services.json'),
          contains(acmeApp.appId),
        ),
      ]);
    });

    test('Edge Case: the success output never contains the config '
        'contents', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);
      final runner = buildRunner(repoRoot, cli);

      // 2. Act
      final output = await runCapturingStdout(runner, ['firebase', 'acme']);

      // 3. Assert
      expect(
        output,
        allOf(isNot(contains(secretMarker)), isNot(contains('project_info'))),
      );
    });

    test('Sad Path: throws UsageException when no id is given', () {
      // 1. Arrange
      final runner = buildRunner(repoRoot, FakeFirebaseCli());

      // 2. Act
      Future<void> action() => runner.run(['firebase']);

      // 3. Assert
      expect(action, throwsA(isA<UsageException>()));
    });

    test('Sad Path: throws UsageException when two ids are given', () {
      // 1. Arrange
      writePartner(repoRoot, 'beta');
      final runner = buildRunner(repoRoot, FakeFirebaseCli());

      // 2. Act
      Future<void> action() => runner.run(['firebase', 'acme', 'beta']);

      // 3. Assert
      expect(action, throwsA(isA<UsageException>()));
    });

    test('Sad Path: two ids never call the Firebase CLI', () async {
      // 1. Arrange
      writePartner(repoRoot, 'beta');
      final cli = FakeFirebaseCli(apps: [acmeApp], config: validAcmeConfig);
      final runner = buildRunner(repoRoot, cli);

      // 2. Act
      try {
        await runner.run(['firebase', 'acme', 'beta']);
      } on UsageException {
        // Expected: the assertion checks the CLI was left alone.
      }

      // 3. Assert
      expect(cli.callCount, 0);
    });

    test('Sad Path: propagates PartnerToolException for an unknown id', () {
      // 1. Arrange
      final runner = buildRunner(repoRoot, FakeFirebaseCli());

      // 2. Act
      Future<void> action() => runner.run(['firebase', 'nope']);

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: propagates PartnerToolException for an invalid id', () {
      // 1. Arrange
      final runner = buildRunner(repoRoot, FakeFirebaseCli());

      // 2. Act
      Future<void> action() => runner.run(['firebase', 'test1']);

      // 3. Assert
      expect(action, throwsA(isA<PartnerToolException>()));
    });

    test('Sad Path: a rejected config prints nothing to stdout', () async {
      // 1. Arrange
      final cli = FakeFirebaseCli(
        apps: [acmeApp],
        config: googleServicesJson(
          projectId: 'monamienet-other',
          clients: [androidClient('org.monamienet.acme')],
        ),
      );
      final runner = buildRunner(repoRoot, cli);
      final captured = CapturingStdout();

      // 2. Act
      try {
        await IOOverrides.runZoned(
          () => runner.run(['firebase', 'acme']),
          stdout: () => captured,
        );
      } on PartnerToolException {
        // Expected: the assertion checks what was printed.
      }

      // 3. Assert
      expect(captured.text, isEmpty);
    });
  });
}
