import 'dart:io';

import 'package:args/command_runner.dart';

import 'access_token_source.dart';
import 'branding.dart';
import 'firestore_documents.dart';
import 'partners.dart';

/// `publish <id>`: writes the partner's branding to its own Firestore.
class PublishCommand extends Command<void> {
  PublishCommand(this._firestore, this._tokens) {
    argParser
      ..addOption('name', help: 'Partner name, without "MonAmie " (required).')
      ..addOption('primary', help: 'Brand color, #RRGGBB.')
      ..addOption('secondary', help: 'Background color, #RRGGBB.')
      ..addOption('logo', help: 'SVG logo with the name (logo-com-texto.svg).')
      ..addOption('icon', help: 'SVG logo without text (logo-sem-texto.svg).')
      ..addFlag('dry-run', help: 'Validate and print, but do not write.');
  }

  final FirestoreDocuments _firestore;
  final AccessTokenSource _tokens;

  @override
  String get name => 'publish';

  @override
  String get description =>
      "Write a partner's branding (name, colors, logos) to config/branding in "
      'its Firebase project. Only the name is required; what is left out uses '
      'the app fallbacks.';

  @override
  String get invocation => '${runner!.executableName} $name <id> --name <name>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) usageException('Expected exactly one partner id.');
    final id = rest.single;
    checkPartnerId(id);
    final name = argResults!.option('name');
    if (name == null) usageException('--name is required.');

    File? file(String option) {
      final path = argResults!.option(option);
      return path == null ? null : File(path);
    }

    final document = buildBrandingDocument(
      name: name,
      primary: argResults!.option('primary'),
      secondary: argResults!.option('secondary'),
      logo: file('logo'),
      icon: file('icon'),
    );
    for (final (option, key) in [
      ('--logo', 'logoSvg'),
      ('--icon', 'iconSvg'),
    ]) {
      if (document[key] case final String svg) {
        svgWarnings(option, svg).forEach((w) => stderr.writeln('Warning: $w'));
      }
    }

    final projectId = firebaseProjectId(id);
    stdout.writeln(
      "Branding of '$id': name '${document['name']}', colors "
      "${document['colors']}, logo ${document.containsKey('logoSvg') ? 'yes' : 'no (name as text)'}, "
      "icon ${document.containsKey('iconSvg') ? 'yes' : 'no (initial)'}.",
    );
    if (argResults!.flag('dry-run')) {
      stdout.writeln('Dry run: nothing written.');
      return;
    }
    await _firestore.set(
      projectId: projectId,
      path: brandingDocumentPath,
      data: document,
      accessToken: await _tokens.accessToken(),
    );
    stdout.writeln('Wrote $brandingDocumentPath in $projectId.');
  }
}
