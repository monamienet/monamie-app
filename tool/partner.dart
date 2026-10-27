import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'src/activate_command.dart';
import 'src/check_command.dart';
import 'src/firebase_command.dart';
import 'src/gcloud.dart';
import 'src/http_firestore_documents.dart';
import 'src/migrate_groups_command.dart';
import 'src/migrate_layout_command.dart';
import 'src/partners.dart';
import 'src/process_firebase_cli.dart';
import 'src/publish_command.dart';
import 'src/themes_command.dart';
import 'src/web_command.dart';

/// Partner tooling for the white-label app. Run from anywhere in the repo:
/// `dart run tool/partner.dart <command>`.
Future<void> main(List<String> args) async {
  // tool/partner.dart -> repository root, independent of the working directory.
  final repoRoot = Directory(p.dirname(p.dirname(p.fromUri(Platform.script))));

  const cli = ProcessFirebaseCli();
  const groups = GcloudGroupDirectory();
  const tokens = GcloudAccessTokenSource();
  final firestore = HttpFirestoreDocuments();

  final runner =
      CommandRunner<void>(
          'dart run tool/partner.dart',
          'MonAmie partner tooling: central Firebase config and partner onboarding.',
        )
        ..addCommand(FirebaseCommand(repoRoot, cli))
        ..addCommand(WebCommand(repoRoot, cli))
        ..addCommand(PublishCommand(firestore, tokens))
        ..addCommand(CheckCommand(cli, groups, firestore))
        ..addCommand(ActivateCommand(cli, groups, firestore, tokens))
        ..addCommand(ThemesCommand(firestore, tokens))
        ..addCommand(MigrateGroupsCommand(groups, runGcloudIdentity))
        ..addCommand(MigrateLayoutCommand(tokens));

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
