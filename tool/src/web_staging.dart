import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'partners.dart';
import 'web_manifest.dart';

/// Folder, relative to the repository root, that holds the staged partner.
///
/// Flutter has no `--flavor` for web, but `flutter build web` copies `web/`
/// into the output and `flutter run -d chrome` serves it, so the web app reads
/// its partner from `partner/` over HTTP. The folder is gitignored.
const webPartnerDirPath = 'web/partner';

/// Staged file with the partner id: `partner.json` is copied as is and has
/// no id, and web has no `--flavor` to carry it.
const webPartnerIdFileName = 'id.txt';

/// Brand files every partner must provide under `partners/<id>/web/`. They are
/// staged with the same relative paths, where `web/index.html` and the
/// generated manifest link to them.
final requiredWebBrandFiles = <String>[
  'favicon.png',
  for (final icon in webManifestIcons) icon.src,
];

/// Recreates `web/partner/` in [repoRoot] for partner [id] and returns the
/// staged paths relative to that folder: `partner.json` as is, `id.txt`
/// with [id], the brand files of `partners/<id>/web/` and the generated
/// `manifest.json`.
///
/// Everything is validated before the folder is deleted, so a failed run
/// keeps the previous staging. Throws a [PartnerToolException] on failure.
List<String> stageWebPartner({
  required Directory repoRoot,
  required String id,
}) {
  final configFile = partnerConfigFile(repoRoot, id);
  final configBytes = configFile.readAsBytesSync();
  final config = _decodeJsonObject(configBytes, configFile.path);
  final manifest = webManifest(
    name: _partnerName(config, configFile.path),
    themeColor: _primaryColor(config, configFile.path),
  );

  final brandDir = p.join(p.dirname(configFile.path), 'web');
  final missing = requiredWebBrandFiles
      .where((path) => !File(p.join(brandDir, path)).existsSync())
      .toList();
  if (missing.isNotEmpty) {
    throw PartnerToolException(
      "Partner '$id' is missing web brand files in $brandDir: "
      '${missing.join(', ')}.',
    );
  }

  final stageDir = Directory(p.join(repoRoot.path, webPartnerDirPath));
  _deleteEntity(stageDir.path);
  stageDir.createSync(recursive: true);

  File(
    p.join(stageDir.path, partnerConfigFileName),
  ).writeAsBytesSync(configBytes);
  File(p.join(stageDir.path, webPartnerIdFileName)).writeAsStringSync('$id\n');
  for (final path in requiredWebBrandFiles) {
    final target = File(p.join(stageDir.path, path));
    target.parent.createSync(recursive: true);
    File(p.join(brandDir, path)).copySync(target.path);
  }
  File(
    p.join(stageDir.path, webManifestFileName),
  ).writeAsStringSync(encodeWebManifest(manifest));

  return [
    partnerConfigFileName,
    webPartnerIdFileName,
    webManifestFileName,
    ...requiredWebBrandFiles,
  ];
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

Map<String, dynamic> _decodeJsonObject(List<int> bytes, String path) {
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes));
  } on FormatException catch (error) {
    throw PartnerToolException('$path is not valid JSON: ${error.message}.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw PartnerToolException('$path must contain a JSON object.');
  }
  return decoded;
}

// Same rules and messages as the Gradle build (android/app/build.gradle.kts).
String _partnerName(Map<String, dynamic> config, String path) {
  final name = config['name'];
  if (name is! String || name.trim().isEmpty) {
    throw PartnerToolException('$path: "name" must be a non-empty string.');
  }
  return name;
}

String _primaryColor(Map<String, dynamic> config, String path) {
  final colors = config['colors'];
  final primary = colors is Map<String, dynamic> ? colors['primary'] : null;
  if (!isHexColor(primary)) {
    throw PartnerToolException(
      '$path: "colors.primary" must be a color like "#RRGGBB".',
    );
  }
  return primary as String;
}
