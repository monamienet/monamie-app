import 'dart:io';

import 'package:args/command_runner.dart';

import 'firebase_cli.dart';
import 'firestore_documents.dart';
import 'group_directory.dart';
import 'organization_check.dart';
import 'organizations.dart';

/// `check <id>`: reports whether an organization is ready to be activated.
class CheckCommand extends Command<void> {
  CheckCommand(this._cli, this._groups, this._firestore) {
    argParser.addFlag(
      'community',
      negatable: false,
      help: 'The organization is on the Community plan ($communityProjectId).',
    );
  }

  final FirebaseCli _cli;
  final GroupDirectory _groups;
  final FirestoreDocuments _firestore;

  @override
  String get name => 'check';

  @override
  String get description =>
      'Check that an organization has its Firebase project, root group and '
      'branding name, the three things required before activation.';

  @override
  String get invocation => '${runner!.executableName} $name <id>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      usageException('Expected exactly one organization id.');
    }
    final results = await checkOrganization(
      id: rest.single,
      cli: _cli,
      groups: _groups,
      firestore: _firestore,
      plan: argResults!.flag('community') ? 'community' : null,
    );
    printCheckResults(results);
    if (results.any((r) => !r.passed)) {
      throw OrganizationToolException(
        "Organization '${rest.single}' is not ready.",
      );
    }
  }
}

/// Prints one line per check.
void printCheckResults(List<CheckResult> results) {
  for (final result in results) {
    stdout.writeln(
      result.passed
          ? '[ok]   ${result.label}'
          : '[fail] ${result.label}: ${result.problem}',
    );
  }
}
