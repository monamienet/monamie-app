import 'dart:io';

import 'package:args/command_runner.dart';

import 'access_token_source.dart';
import 'firebase_cli.dart';
import 'firestore_documents.dart';
import 'organization_check.dart';
import 'organizations.dart';

/// `check <id>`: reports whether an organization is ready to be activated.
class CheckCommand extends Command<void> {
  CheckCommand(this._cli, this._firestore, this._tokens) {
    argParser.addFlag(
      'community',
      negatable: false,
      help: 'The organization is on the Community plan ($communityProjectId).',
    );
  }

  final FirebaseCli _cli;
  final FirestoreDocuments _firestore;
  final AccessTokenSource _tokens;

  @override
  String get name => 'check';

  @override
  String get description =>
      'Check that an organization has its Firebase project apps, an '
      'administrator (with memberships matching the central accounts index) '
      'and a branding name, the things required before activation.';

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
      firestore: _firestore,
      accessToken: await _tokens.accessToken(),
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
