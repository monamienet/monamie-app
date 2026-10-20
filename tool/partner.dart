import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'src/firebase_command.dart';
import 'src/partners.dart';
import 'src/process_firebase_cli.dart';
import 'src/web_command.dart';

/// Partner tooling for the white-label app. Run from anywhere in the repo:
/// `dart run tool/partner.dart <command>`.
Future<void> main(List<String> args) async {
  // tool/partner.dart -> repository root, independent of the working directory.
  final repoRoot = Directory(p.dirname(p.dirname(p.fromUri(Platform.script))));

  final runner =
      CommandRunner<void>(
          'dart run tool/partner.dart',
          'Manage the white-label partners in partners/<id>/.',
        )
        ..addCommand(FirebaseCommand(repoRoot, const ProcessFirebaseCli()))
        ..addCommand(WebCommand(repoRoot));

  try {
    await runner.run(args);
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  } on PartnerToolException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}
