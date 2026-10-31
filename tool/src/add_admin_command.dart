import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';
import 'package:monamie_app/app/data/organization/person_key.dart';

import 'access_token_source.dart';
import 'firestore_documents.dart';
import 'memberships.dart';
import 'organizations.dart';

/// A plausible e-mail address: something, `@`, a domain with a dot.
final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// `add-admin <id> <email>`: makes a person an administrator of an
/// organization, for organizations onboarded by hand (an organization created
/// in the app already has its creator as administrator).
///
/// Writes `organizations/<id>/organizationMemberships/<personKey>` with
/// `role: admin` in the organization's project, then adds the organization
/// to `accounts/<personKey>` in the central project, the same two writes
/// the central functions make (organization project first).
class AddAdminCommand extends Command<void> {
  AddAdminCommand(this._firestore, this._tokens) {
    argParser.addFlag(
      'community',
      negatable: false,
      help:
          'The organization is on the Community plan ($communityProjectId); '
          'only needed while it has no registry entry.',
    );
  }

  final FirestoreDocuments _firestore;
  final AccessTokenSource _tokens;

  @override
  String get name => 'add-admin';

  @override
  String get description =>
      "Make a person an administrator of an organization: their membership "
      "in the organization's project and their entry in the central "
      'accounts index.';

  @override
  String get invocation => '${runner!.executableName} $name <id> <email>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 2) {
      usageException('Expected an organization id and an e-mail.');
    }
    final id = rest[0];
    checkOrganizationId(id);
    final email = rest[1].trim().toLowerCase();
    if (!_email.hasMatch(email)) {
      throw OrganizationToolException("Invalid e-mail '${rest[1]}'.");
    }
    final key = personKey(email);
    final accessToken = await _tokens.accessToken();
    final registry = await _firestore.get(
      projectId: centralProjectId,
      path: FirestorePaths.organization(id),
      accessToken: accessToken,
    );
    final plan = registry?['plan'];
    final projectId = firebaseProjectId(
      id,
      plan: plan is String
          ? plan
          : (argResults!.flag('community') ? 'community' : null),
    );

    final membershipPath = FirestorePaths.organizationMembership(id, key);
    final membership = await _firestore.get(
      projectId: projectId,
      path: membershipPath,
      accessToken: accessToken,
    );
    await _firestore.set(
      projectId: projectId,
      path: membershipPath,
      data: adminMembership(email, now: DateTime.now(), existing: membership),
      accessToken: accessToken,
    );
    stdout.writeln('Wrote $membershipPath ($email) in $projectId.');

    final accountPath = FirestorePaths.account(key);
    final account = await _firestore.get(
      projectId: centralProjectId,
      path: accountPath,
      accessToken: accessToken,
    );
    await _firestore.update(
      projectId: centralProjectId,
      path: accountPath,
      data: accountWithOrganization(email, id, existing: account),
      fieldPaths: const [AccountFields.email, AccountFields.organizationIds],
      accessToken: accessToken,
    );
    stdout.writeln('Added $id to $accountPath ($email) in $centralProjectId.');
  }
}
