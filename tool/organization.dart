import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'src/activate_command.dart';
import 'src/add_admin_command.dart';
import 'src/check_command.dart';
import 'src/firebase_command.dart';
import 'src/gcloud.dart';
import 'src/http_firestore_documents.dart';
import 'src/organizations.dart';
import 'src/process_firebase_cli.dart';
import 'src/publish_command.dart';
import 'src/themes_command.dart';
import 'src/web_command.dart';

/// Organization tooling for the white-label app. Run from anywhere in the repo:
/// `dart run tool/organization.dart <command>`.
Future<void> main(List<String> args) async {
  // tool/organization.dart -> repository root, independent of the working directory.
  final repoRoot = Directory(p.dirname(p.dirname(p.fromUri(Platform.script))));

  const cli = ProcessFirebaseCli();
  const tokens = GcloudAccessTokenSource();
  final firestore = HttpFirestoreDocuments();

  final runner =
      CommandRunner<void>(
          'dart run tool/organization.dart',
          'MonAmie organization tooling: central Firebase config and organization onboarding.',
        )
        ..addCommand(FirebaseCommand(repoRoot, cli))
        ..addCommand(WebCommand(repoRoot, cli))
        ..addCommand(PublishCommand(firestore, tokens))
        ..addCommand(CheckCommand(cli, firestore, tokens))
        ..addCommand(AddAdminCommand(firestore, tokens))
        ..addCommand(ActivateCommand(cli, firestore, tokens))
        ..addCommand(ThemesCommand(firestore, tokens));

  try {
    await runner.run(args);
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  } on OrganizationToolException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}
