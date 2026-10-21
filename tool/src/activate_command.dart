import 'dart:io';

import 'package:args/command_runner.dart';

import 'access_token_source.dart';
import 'check_command.dart';
import 'firebase_cli.dart';
import 'firestore_documents.dart';
import 'group_directory.dart';
import 'partner_check.dart';
import 'partners.dart';

/// Path of partner `<id>`'s entry in the central registry.
String registryDocumentPath(String id) => 'partners/$id';

/// `activate <id>`: marks a partner active in the central registry, but only
/// after `check` passes. `--deactivate` stops new sign-ins to it.
class ActivateCommand extends Command<void> {
  ActivateCommand(this._cli, this._groups, this._firestore, this._tokens) {
    argParser.addFlag(
      'deactivate',
      help: 'Mark the partner inactive instead (no check is run).',
    );
  }

  final FirebaseCli _cli;
  final GroupDirectory _groups;
  final FirestoreDocuments _firestore;
  final AccessTokenSource _tokens;

  @override
  String get name => 'activate';

  @override
  String get description =>
      'Activate a partner in the central registry ($centralProjectId), after '
      'the same checks as `check`.';

  @override
  String get invocation => '${runner!.executableName} $name <id>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) usageException('Expected exactly one partner id.');
    final id = rest.single;
    checkPartnerId(id);
    final active = !argResults!.flag('deactivate');
    if (active) {
      final results = await checkPartner(
        id: id,
        cli: _cli,
        groups: _groups,
        firestore: _firestore,
      );
      printCheckResults(results);
      if (results.any((r) => !r.passed)) {
        throw PartnerToolException(
          "Not activating '$id': fix the failed checks first.",
        );
      }
    }
    await _firestore.set(
      projectId: centralProjectId,
      path: registryDocumentPath(id),
      data: {'active': active, 'updatedAt': DateTime.now()},
      accessToken: await _tokens.accessToken(),
    );
    stdout.writeln(
      "Partner '$id' is now ${active ? 'active' : 'inactive'} in "
      '$centralProjectId.',
    );
  }
}
