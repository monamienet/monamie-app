import 'dart:io';

import 'package:args/command_runner.dart';

import 'access_token_source.dart';
import 'branding.dart';
import 'firestore_documents.dart';
import 'partners.dart';
import 'themes_command.dart';

/// `publish <id>`: writes the partner's branding to its own Firestore.
class PublishCommand extends Command<void> {
  PublishCommand(this._firestore, this._tokens) {
    argParser
      ..addOption(
        'name',
        help: 'Partner name, never starting with "MonAmie " (required).',
      )
      ..addOption(
        'theme',
        help: 'Catalog theme id (required).',
        allowed: [for (final theme in themeCatalog) theme.id],
      )
      ..addFlag('dry-run', help: 'Validate and print, but do not write.');
  }

  final FirestoreDocuments _firestore;
  final AccessTokenSource _tokens;

  @override
  String get name => 'publish';

  @override
  String get description =>
      "Write a partner's branding (name and catalog theme) to "
      'partners/<id>/config/branding in its Firebase project. For partners '
      'onboarded by hand; partners created in the app set it themselves.';

  @override
  String get invocation =>
      '${runner!.executableName} $name <id> --name <name> --theme <id>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) usageException('Expected exactly one partner id.');
    final id = rest.single;
    checkPartnerId(id);
    final name = argResults!.option('name');
    if (name == null) usageException('--name is required.');
    final themeId = argResults!.option('theme');
    if (themeId == null) usageException('--theme is required.');
    final document = buildBrandingDocument(
      name: name,
      themeId: themeId,
      themeIds: [for (final theme in themeCatalog) theme.id],
    );
    stdout.writeln(
      "Branding of '$id': name '${document['name']}', theme $themeId.",
    );
    if (argResults!.flag('dry-run')) {
      stdout.writeln('Dry run: nothing written.');
      return;
    }
    final accessToken = await _tokens.accessToken();
    final registry = await _firestore.get(
      projectId: centralProjectId,
      path: 'partners/$id',
      accessToken: accessToken,
    );
    final plan = registry?['plan'];
    final projectId = firebaseProjectId(id, plan: plan is String ? plan : null);
    // A masked write keeps what the owner set from the app (the logo).
    await _firestore.update(
      projectId: projectId,
      path: brandingDocumentPath(id),
      data: {...document, 'updatedAt': DateTime.now()},
      fieldPaths: const [
        'name',
        'themeId',
        'updatedAt',
        'colors',
        'logoSvg',
        'iconSvg',
      ],
      accessToken: accessToken,
    );
    stdout.writeln('Wrote ${brandingDocumentPath(id)} in $projectId.');
  }
}
