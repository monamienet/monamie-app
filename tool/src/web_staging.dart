import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'partners.dart';

/// Folder, relative to the repository root, that holds the staged partner.
///
/// Flutter has no `--flavor` for web, but `flutter build web` copies `web/`
/// into the output and `flutter run -d chrome` serves it, so the web app reads
/// its partner from `partner/` over HTTP. The folder is gitignored.
const webPartnerDirPath = 'web/partner';

/// Recreates `web/partner/` in [repoRoot] with the files of partner [id] and
/// returns their paths relative to that folder.
///
/// Everything is validated before the folder is deleted, so a failed run
/// keeps the previous staging. Throws a [PartnerToolException] on failure.
List<String> stageWebPartner({
  required Directory repoRoot,
  required String id,
}) {
  final configFile = partnerConfigFile(repoRoot, id);
  final configBytes = configFile.readAsBytesSync();
  _checkJsonObject(configBytes, configFile.path);

  final stageDir = Directory(p.join(repoRoot.path, webPartnerDirPath));
  _deleteEntity(stageDir.path);
  stageDir.createSync(recursive: true);

  File(
    p.join(stageDir.path, partnerConfigFileName),
  ).writeAsBytesSync(configBytes);
  return const [partnerConfigFileName];
}

/// Deletes whatever is at [path] (folder, file or link) without following
/// links, so a symlinked `web/partner` never deletes files outside `web/`.
void _deleteEntity(String path) {
  switch (FileSystemEntity.typeSync(path, followLinks: false)) {
    case FileSystemEntityType.notFound:
      return;
    case FileSystemEntityType.directory:
      Directory(path).deleteSync(recursive: true);
    case FileSystemEntityType.link:
      Link(path).deleteSync();
    default:
      File(path).deleteSync();
  }
}

void _checkJsonObject(List<int> bytes, String path) {
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } on FormatException catch (error) {
    throw PartnerToolException('$path is not valid JSON: ${error.message}.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw PartnerToolException('$path must contain a JSON object.');
  }
}
