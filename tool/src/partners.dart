import 'dart:io';

import 'package:path/path.dart' as p;

/// Name of the file that turns a folder under `partners/` into a partner.
const partnerConfigFileName = 'partner.json';

/// Logo every partner provides next to its `partner.json`, shown on the login
/// screen. Kept in sync with `lib/app/config/partner/partner_logo.dart`.
const partnerLogoFileName = 'logo-com-texto.svg';

/// AGP rejects flavor names starting with `test` and these reserved names.
/// Kept in sync with `android/app/build.gradle.kts`.
const reservedPartnerIds = {'lint', 'main', 'debug', 'release', 'profile'};

final _partnerIdPattern = RegExp(r'^[a-z][a-z0-9]*$');
final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// The name users see for partner [name]: `MonAmie <name>`.
/// Kept in sync with `appLabel` in `android/app/build.gradle.kts`.
String partnerDisplayName(String name) => 'MonAmie $name';

/// Whether [value] is a color in the `#RRGGBB` format (either case).
bool isHexColor(Object? value) =>
    value is String && _hexColorPattern.hasMatch(value);

/// A failure the partner tool reports to the user as a plain message.
class PartnerToolException implements Exception {
  PartnerToolException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Returns why [id] is not a valid partner id, or `null` when it is valid.
///
/// The id becomes the Android flavor name and the Play application id
/// (`org.monamienet.<id>`), so it follows the same rules as the Gradle build.
String? partnerIdProblem(String id) {
  if (!_partnerIdPattern.hasMatch(id)) {
    return "Invalid partner id '$id': it must match ${_partnerIdPattern.pattern}.";
  }
  if (id.startsWith('test')) {
    return "Invalid partner id '$id': it must not start with 'test'.";
  }
  if (reservedPartnerIds.contains(id)) {
    return "Invalid partner id '$id': it must not be one of "
        '${reservedPartnerIds.join(', ')}.';
  }
  return null;
}

/// Returns the ids of the folders under `partners/` in [repoRoot] that contain
/// a `partner.json`, sorted. Like the Gradle build, it follows symlinks.
List<String> listPartnerIds(Directory repoRoot) {
  final partnersDir = Directory(p.join(repoRoot.path, 'partners'));
  if (!partnersDir.existsSync()) return const [];
  return partnersDir
      .listSync()
      .whereType<Directory>()
      .where(
        (dir) => File(p.join(dir.path, partnerConfigFileName)).existsSync(),
      )
      .map((dir) => p.basename(dir.path))
      .toList()
    ..sort();
}

/// Returns `partners/<id>/partner.json` in [repoRoot].
///
/// Throws a [PartnerToolException] when [id] is invalid or no such partner
/// exists.
File partnerConfigFile(Directory repoRoot, String id) {
  final problem = partnerIdProblem(id);
  if (problem != null) throw PartnerToolException(problem);

  final file = File(
    p.join(repoRoot.path, 'partners', id, partnerConfigFileName),
  );
  if (!file.existsSync()) {
    final known = listPartnerIds(repoRoot);
    throw PartnerToolException(
      "Unknown partner '$id'. Partners: "
      '${known.isEmpty ? '(none)' : known.join(', ')}.',
    );
  }
  return file;
}
