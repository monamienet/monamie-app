import 'dart:io';

import 'package:path/path.dart' as p;

/// Name of the file that turns a folder under `partners/` into a partner.
const partnerConfigFileName = 'partner.json';

/// Logo every partner provides next to its `partner.json`, shown on the login
/// screen. Kept in sync with `lib/app/config/partner/partner_logo.dart`.
const partnerLogoFileName = 'logo-com-texto.svg';

/// The central MonAmie project is `monamienet-app`, so `app` can never be a
/// partner id. Kept in sync with `lib/app/config/partner/partner_config.dart`.
const reservedPartnerIds = {'app'};

final _partnerIdPattern = RegExp(r'^[a-z][a-z0-9]*$');
final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// The name users see for partner [name]: `MonAmie <name>`.
/// Kept in sync with `appLabel` in `android/app/build.gradle.kts`.
String partnerDisplayName(String name) => 'MonAmie $name';

/// The Firebase project of partner [id]: `monamienet-<id>`.
String firebaseProjectId(String id) => 'monamienet-$id';

/// The Android application id of partner [id]: `org.monamienet.<id>`.
/// Kept in sync with `applicationId` in `android/app/build.gradle.kts`.
String androidApplicationId(String id) => 'org.monamienet.$id';

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
/// The id names the partner's Firebase project (`monamienet-<id>`) and its
/// groups (`<id>NN@monamienet.org`).
String? partnerIdProblem(String id) {
  if (!_partnerIdPattern.hasMatch(id)) {
    return "Invalid partner id '$id': it must match ${_partnerIdPattern.pattern}.";
  }
  if (reservedPartnerIds.contains(id)) {
    return "Invalid partner id '$id': it must not be one of "
        '${reservedPartnerIds.join(', ')}.';
  }
  return null;
}

/// Throws a [PartnerToolException] when [id] is not a valid partner id.
void checkPartnerId(String id) {
  final problem = partnerIdProblem(id);
  if (problem != null) throw PartnerToolException(problem);
}

/// The central MonAmie Firebase project: sign-in and the partner registry.
const centralProjectId = 'monamienet-app';

/// The single Android application id of the MonAmie app.
const appPackageName = 'org.monamienet.app';

/// The root group of partner [id]: `<id>00@monamienet.org`.
String rootGroupEmail(String id) => '${id}00@monamienet.org';

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
