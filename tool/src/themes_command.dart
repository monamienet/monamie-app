import 'dart:io';

import 'package:args/command_runner.dart';

import 'access_token_source.dart';
import 'firestore_documents.dart';
import 'partners.dart';

/// One theme of the catalog: a name and three tones, plus the text colors
/// on the primary and dark tones. Every theme passes WCAG AA for white text
/// on [primary] and [dark], and for [dark] text on [light].
class CatalogTheme {
  const CatalogTheme(this.id, this.name, this.primary, this.dark, this.light);

  final String id;
  final String name;
  final String primary;
  final String dark;
  final String light;
}

/// The theme catalog seeded into the central project, in picker order.
/// None is close to the MonAmie coral. Grafite is the default theme of a
/// partner whose `themeId` is missing or unknown.
const themeCatalog = [
  CatalogTheme('oceano', 'Oceano', '#315399', '#131A34', '#D4DBE9'),
  CatalogTheme('turquesa', 'Turquesa', '#0B7F7B', '#093A3E', '#CDF0EF'),
  CatalogTheme('floresta', 'Floresta', '#2F7347', '#163123', '#D6E7DC'),
  CatalogTheme('oliva', 'Oliva', '#5E6B1F', '#2B3512', '#E6EAD3'),
  CatalogTheme('ambar', 'Âmbar', '#9A5B00', '#433104', '#F3E2CA'),
  CatalogTheme('petroleo', 'Petróleo', '#1F6A85', '#102837', '#D2E5EB'),
  CatalogTheme('ameixa', 'Ameixa', '#74408F', '#2A1730', '#E1D7E6'),
  CatalogTheme('grafite', 'Grafite', '#3F4754', '#1F2128', '#DCDEE2'),
];

/// Path of theme [id] in the central project.
String themeDocumentPath(String id) => 'themes/$id';

/// The document of [theme] at position [index] (0-based) of the catalog.
Map<String, Object?> themeDocument(CatalogTheme theme, int index) => {
  'name': theme.name,
  'primary': theme.primary,
  'dark': theme.dark,
  'light': theme.light,
  'onPrimary': '#FFFFFF',
  'onDark': '#FFFFFF',
  'order': index + 1,
  'active': true,
};

/// `themes`: writes [themeCatalog] to `themes/{id}` in the central project.
///
/// Only the fields above are written (an update mask), so seeding again
/// after changing a tone here updates it in place. A theme retired by hand
/// (`active: false`) becomes active again: retire it in [themeCatalog] too.
class ThemesCommand extends Command<void> {
  ThemesCommand(this._firestore, this._tokens) {
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Print the documents without writing them.',
    );
  }

  final FirestoreDocuments _firestore;
  final AccessTokenSource _tokens;

  @override
  String get name => 'themes';

  @override
  String get description =>
      'Seed the theme catalog into the central project ($centralProjectId).';

  @override
  Future<void> run() async {
    final dryRun = argResults!.flag('dry-run');
    final accessToken = dryRun ? null : await _tokens.accessToken();
    for (final (index, theme) in themeCatalog.indexed) {
      final document = themeDocument(theme, index);
      if (accessToken == null) {
        stdout.writeln('${themeDocumentPath(theme.id)}: $document');
        continue;
      }
      await _firestore.update(
        projectId: centralProjectId,
        path: themeDocumentPath(theme.id),
        data: document,
        fieldPaths: document.keys.toList(),
        accessToken: accessToken,
      );
      stdout.writeln('Wrote ${themeDocumentPath(theme.id)}.');
    }
  }
}
