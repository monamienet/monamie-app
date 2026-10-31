import 'dart:io';

import 'package:args/command_runner.dart';

import 'access_token_source.dart';
import 'check_command.dart';
import 'firebase_cli.dart';
import 'firestore_documents.dart';
import 'group_directory.dart';
import 'organization_check.dart';
import 'organizations.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

/// Path of organization `<id>`'s entry in the central registry.
String registryDocumentPath(String id) => FirestorePaths.organization(id);

/// Path of the marker that retires `<id>` forever.
String retiredDocumentPath(String id) => 'retiredOrganizationIds/$id';

/// Statuses from which MonAmieNet may activate an organization by hand.
///
/// This is the manual onboarding path, outside the in-app flow: an organization
/// set up from `docs/en-us/white-label.md` (no entry yet, or a legacy entry
/// with `active: true` and no `status`), one whose provisioning stopped
/// (`provisioning`, `failed`), or an `active` one being checked again.
const manualActivationStatuses = {null, 'provisioning', 'failed', 'active'};

/// Returns why organization `<id>` must not be activated by hand, or `null` when
/// it may.
///
/// [registry] is its entry in the central registry (`null` when missing);
/// [retired] is whether its id was retired.
String? activationProblem(
  String id,
  Map<String, Object?>? registry, {
  required bool retired,
}) {
  if (retired) {
    return "Organization id '$id' is retired: its project and groups were "
        'deleted, and the id can never be used again.';
  }
  final status = registry?['status'];
  if (status != null && status is! String) {
    return "Organization '$id' has a malformed status in the registry.";
  }
  if (!manualActivationStatuses.contains(status)) {
    return "Organization '$id' is '$status'; only an organization with no status, or "
        "in 'provisioning', 'failed' or 'active', can be activated by hand.";
  }
  return null;
}

/// `activate <id>`: sets an organization's status to `active` in the central
/// registry, but only after `check` passes and only from the statuses in
/// [manualActivationStatuses].
class ActivateCommand extends Command<void> {
  ActivateCommand(this._cli, this._groups, this._firestore, this._tokens) {
    argParser.addOption(
      'owner',
      help:
          "E-mail of the organization's owner (titular), who created it; "
          'deleting their account deletes the organization. Administration powers '
          'come from the root group, not from this.',
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
      'Activate an organization in the central registry ($centralProjectId), after '
      'the same checks as `check`.';

  @override
  String get invocation => '${runner!.executableName} $name <id>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      usageException('Expected exactly one organization id.');
    }
    final id = rest.single;
    checkOrganizationId(id);
    final accessToken = await _tokens.accessToken();
    final registry = await _firestore.get(
      projectId: centralProjectId,
      path: registryDocumentPath(id),
      accessToken: accessToken,
    );
    final retired = await _firestore.get(
      projectId: centralProjectId,
      path: retiredDocumentPath(id),
      accessToken: accessToken,
    );
    final problem = activationProblem(id, registry, retired: retired != null);
    if (problem != null) throw OrganizationToolException(problem);

    final plan = registry?['plan'];
    final results = await checkOrganization(
      id: id,
      cli: _cli,
      groups: _groups,
      firestore: _firestore,
      plan: plan is String ? plan : null,
    );
    printCheckResults(results);
    if (results.any((r) => !r.passed)) {
      throw OrganizationToolException(
        "Not activating '$id': fix the failed checks first.",
      );
    }
    // The mask also removes the legacy `active` flag and any `deleteAt`,
    // and keeps every other field (the creator, the plan…).
    final owner = argResults!.option('owner')?.trim().toLowerCase();
    await _firestore.update(
      projectId: centralProjectId,
      path: registryDocumentPath(id),
      data: {
        'status': 'active',
        'updatedAt': DateTime.now(),
        'ownerEmail': ?owner,
      },
      fieldPaths: [
        'status',
        'updatedAt',
        'active',
        'deleteAt',
        if (owner != null) 'ownerEmail',
      ],
      accessToken: accessToken,
    );
    stdout.writeln("Organization '$id' is now active in $centralProjectId.");
  }
}
