import 'dart:convert';
import 'dart:io';

/// Pure helpers that validate the white-label partner layout:
///
/// * `partners/<id>/partner.json` declares `colors.secondary` as `#RRGGBB`
///   (used as the Android splash background);
/// * `partners/<id>/android/res/` provides every Android brand resource;
/// * `android/app/src/main/res/` holds no brand image, so a partner without
///   icons can never fall back to another partner's icons;
/// * the shared `launch_background.xml` files reference the partner-provided
///   resources instead of hardcoded values.

/// Name of the file that turns a folder under `partners/` into a partner.
const partnerConfigFileName = 'partner.json';

/// Android brand resources every partner must provide, relative to
/// `partners/<id>/android/res/`.
const requiredAndroidBrandResources = <String>[
  'mipmap-mdpi/ic_launcher.png',
  'mipmap-hdpi/ic_launcher.png',
  'mipmap-xhdpi/ic_launcher.png',
  'mipmap-xxhdpi/ic_launcher.png',
  'mipmap-xxxhdpi/ic_launcher.png',
  'drawable/launch_image.png',
];

/// File names that must never exist inside the shared `src/main/res/`.
const forbiddenSharedBrandFileNames = <String>{
  'ic_launcher.png',
  'launch_image.png',
};

/// The 8-byte signature that starts every PNG file.
const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

const _splashBackgroundReference = '@color/splash_background';
const _launchImageReference = '@drawable/launch_image';

final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
final _xmlCommentPattern = RegExp(r'<!--[\s\S]*?-->');
final _backgroundDrawablePattern = RegExp(
  r'<item\b[^>]*\bandroid:drawable\s*=\s*"([^"]*)"',
);
final _bitmapSourcePattern = RegExp(
  r'<bitmap\b[^>]*\bandroid:src\s*=\s*"([^"]*)"',
);

/// Joins path segments with `/`, which `dart:io` accepts on every platform.
String joinPath(String base, String relative) {
  final trimmed = base.endsWith('/') || base.endsWith(r'\')
      ? base.substring(0, base.length - 1)
      : base;
  return '$trimmed/$relative';
}

/// Whether [value] is a string in the `#RRGGBB` format (either case).
bool isValidHexColor(Object? value) {
  return value is String && _hexColorPattern.hasMatch(value);
}

/// Whether [directory] is a partner, i.e. it contains `partner.json`.
bool isPartnerDirectory(Directory directory) {
  return File(joinPath(directory.path, partnerConfigFileName)).existsSync();
}

/// Returns the partner directories directly under [partnersRoot], sorted by
/// path. Folders without `partner.json` are ignored.
List<Directory> listPartnerDirectories(Directory partnersRoot) {
  return partnersRoot
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where(isPartnerDirectory)
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Whether [file] exists, is non-empty and starts with the PNG signature.
bool isPngFile(File file) {
  if (!file.existsSync()) return false;
  final RandomAccessFile handle;
  try {
    handle = file.openSync();
  } on FileSystemException {
    return false;
  }
  try {
    final header = handle.readSync(pngSignature.length);
    if (header.length < pngSignature.length) return false;
    for (var i = 0; i < pngSignature.length; i++) {
      if (header[i] != pngSignature[i]) return false;
    }
    return true;
  } finally {
    handle.closeSync();
  }
}

/// Returns the entries of [requiredAndroidBrandResources] that are missing
/// from [partnerDirectory] or are not real PNG files, in declaration order.
List<String> missingAndroidBrandResources(Directory partnerDirectory) {
  final resRoot = joinPath(partnerDirectory.path, 'android/res');
  return requiredAndroidBrandResources
      .where((resource) => !isPngFile(File(joinPath(resRoot, resource))))
      .toList();
}

/// Returns the problems of the `partner.json` found in [partnerDirectory];
/// an empty list means the configuration satisfies the contract.
List<String> partnerConfigProblems(Directory partnerDirectory) {
  final configFile = File(
    joinPath(partnerDirectory.path, partnerConfigFileName),
  );
  if (!configFile.existsSync()) {
    return ['$partnerConfigFileName is missing'];
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(configFile.readAsStringSync());
  } on FormatException catch (error) {
    return ['$partnerConfigFileName is not valid JSON: ${error.message}'];
  }

  if (decoded is! Map<String, dynamic>) {
    return ['$partnerConfigFileName must be a JSON object'];
  }
  final colors = decoded['colors'];
  if (colors is! Map<String, dynamic>) {
    return ['colors must be a JSON object'];
  }
  final secondary = colors['secondary'];
  if (!isValidHexColor(secondary)) {
    return ['colors.secondary must match #RRGGBB, got: $secondary'];
  }
  return const [];
}

/// Returns the paths, relative to [resRoot], of every forbidden brand image
/// (see [forbiddenSharedBrandFileNames]) found anywhere below it, sorted.
List<String> findForbiddenSharedBrandFiles(Directory resRoot) {
  final rootPrefix = resRoot.absolute.path.replaceAll(r'\', '/');
  return resRoot
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map((file) => file.absolute.path.replaceAll(r'\', '/'))
      .where(
        (path) => forbiddenSharedBrandFileNames.contains(path.split('/').last),
      )
      .map((path) => path.substring(rootPrefix.length + 1))
      .toList()
    ..sort();
}

/// Returns the problems of a `launch_background.xml` source; an empty list
/// means it uses `@color/splash_background` as background and
/// `@drawable/launch_image` as image. XML comments are ignored.
List<String> launchBackgroundProblems(String xmlSource) {
  final source = xmlSource.replaceAll(_xmlCommentPattern, '');
  final problems = <String>[];

  final backgrounds = _backgroundDrawablePattern
      .allMatches(source)
      .map((match) => match.group(1)!)
      .toList();
  if (!backgrounds.contains(_splashBackgroundReference)) {
    problems.add('background must be $_splashBackgroundReference');
  }
  for (final background in backgrounds) {
    if (background != _splashBackgroundReference) {
      problems.add('unexpected background drawable: $background');
    }
  }

  final images = _bitmapSourcePattern
      .allMatches(source)
      .map((match) => match.group(1)!)
      .toList();
  if (!images.contains(_launchImageReference)) {
    problems.add('image must be $_launchImageReference');
  }
  return problems;
}
