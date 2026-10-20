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
///   resources instead of hardcoded values;
/// * `partners/<id>/partner.json` declares a non-blank `name` and a
///   `colors.primary` as `#RRGGBB` (used by the web manifest);
/// * `partners/<id>/web/` provides every web brand file as a real PNG;
/// * the files of `web/` outside the staged `web/partner/` hold no partner
///   name, primary color or brand image, and `web/index.html` links to the
///   staged `partner/` files;
/// * `partners/<id>/logo-com-texto.svg` is a non-empty SVG (the login logo).

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

/// Web brand files every partner must provide, relative to
/// `partners/<id>/web/` (and to the staged `web/partner/`).
const requiredWebBrandFiles = <String>[
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];

/// Folder of `web/` where the partner is staged; it is gitignored, so it is
/// left out of the partner-neutral checks.
const webStagingFolderName = 'partner';

/// Marker of the only `web/` line allowed to stay partner-specific for now.
const googleSignInClientIdMarker = 'google-signin-client_id';

/// The `<link>` elements `web/index.html` must have, as `rel` to `href`.
const requiredWebIndexLinks = <String, String>{
  'manifest': 'partner/manifest.json',
  'icon': 'partner/favicon.png',
  'apple-touch-icon': 'partner/icons/Icon-192.png',
};

/// The partner-neutral title of the web app.
const neutralWebAppTitle = 'MonAmie';

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
final _htmlCommentPattern = RegExp(r'<!--[\s\S]*?-->');
final _htmlTitlePattern = RegExp(r'<title\b[^>]*>([\s\S]*?)</title>');
final _htmlLinkPattern = RegExp(r'<link\b[^>]*>');
final _htmlMetaPattern = RegExp(r'<meta\b[^>]*>');
final _htmlAttributePattern = RegExp(r'([\w:-]+)\s*=\s*"([^"]*)"');

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

/// Returns the entries of [requiredWebBrandFiles] that are missing from
/// `web/` of [partnerDirectory] or are not real PNG files, in declaration
/// order.
List<String> missingWebBrandFiles(Directory partnerDirectory) {
  final webRoot = joinPath(partnerDirectory.path, 'web');
  return requiredWebBrandFiles
      .where((path) => !isPngFile(File(joinPath(webRoot, path))))
      .toList();
}

/// Reads the `partner.json` of [partnerDirectory] as a JSON object, or
/// returns the problem that prevents it as a [String].
Object _readPartnerConfig(Directory partnerDirectory) {
  final configFile = File(
    joinPath(partnerDirectory.path, partnerConfigFileName),
  );
  if (!configFile.existsSync()) {
    return '$partnerConfigFileName is missing';
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(configFile.readAsStringSync());
  } on FormatException catch (error) {
    return '$partnerConfigFileName is not valid JSON: ${error.message}';
  }
  if (decoded is! Map<String, dynamic>) {
    return '$partnerConfigFileName must be a JSON object';
  }
  return decoded;
}

/// Returns the problems of the identity fields of the `partner.json` found
/// in [partnerDirectory]: `name` must be a non-blank string and
/// `colors.primary` must match `#RRGGBB`. An empty list means both are valid.
List<String> partnerIdentityProblems(Directory partnerDirectory) {
  final config = _readPartnerConfig(partnerDirectory);
  if (config is String) return [config];
  config as Map<String, dynamic>;

  final problems = <String>[];
  final name = config['name'];
  if (name is! String || name.trim().isEmpty) {
    problems.add('name must be a non-blank string, got: $name');
  }
  final colors = config['colors'];
  final primary = colors is Map<String, dynamic> ? colors['primary'] : null;
  if (!isValidHexColor(primary)) {
    problems.add('colors.primary must match #RRGGBB, got: $primary');
  }
  return problems;
}

/// Returns the strings that identify the partner in [partnerDirectory]: its
/// `name` and the six hex digits of its `colors.primary` (without `#`, so
/// `0xFF...` spellings are caught too). Invalid or missing fields are left
/// out, so an unreadable `partner.json` yields an empty list.
List<String> partnerBrandTerms(Directory partnerDirectory) {
  final config = _readPartnerConfig(partnerDirectory);
  if (config is! Map<String, dynamic>) return const [];

  final terms = <String>[];
  final name = config['name'];
  if (name is String && name.trim().isNotEmpty) terms.add(name.trim());
  final colors = config['colors'];
  final primary = colors is Map<String, dynamic> ? colors['primary'] : null;
  if (isValidHexColor(primary)) terms.add((primary as String).substring(1));
  return terms;
}

/// Returns `line <n>: <term>` for every line of [source] that contains one
/// of [terms], ignoring case. Lines holding [googleSignInClientIdMarker] are
/// skipped, and blank terms never match.
List<String> brandMentions(String source, Iterable<String> terms) {
  final needles = terms
      .map((term) => term.trim().toLowerCase())
      .where((term) => term.isNotEmpty)
      .toSet();
  final mentions = <String>[];
  final lines = source.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].toLowerCase();
    if (line.contains(googleSignInClientIdMarker)) continue;
    for (final needle in needles) {
      if (line.contains(needle)) mentions.add('line ${index + 1}: $needle');
    }
  }
  return mentions;
}

/// Returns the paths, relative to [webRoot] and joined with `/`, of every
/// file below it except those in the staged [webStagingFolderName] folder,
/// sorted. Links are not followed.
List<String> listSharedWebFiles(Directory webRoot) {
  final rootPrefix = webRoot.absolute.path.replaceAll(r'\', '/');
  return webRoot
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .map(
        (file) => file.absolute.path
            .replaceAll(r'\', '/')
            .substring(rootPrefix.length + 1),
      )
      .where(
        (path) =>
            path != webStagingFolderName &&
            !path.startsWith('$webStagingFolderName/'),
      )
      .toList()
    ..sort();
}

/// Returns the shared files of [webRoot] (see [listSharedWebFiles]) whose
/// bytes are identical to one of the web brand files of [partnerDirectory].
List<String> findBrandFileCopies(
  Directory webRoot,
  Directory partnerDirectory,
) {
  final brandContents = requiredWebBrandFiles
      .map((path) => File(joinPath(partnerDirectory.path, 'web/$path')))
      .where((file) => file.existsSync())
      .map((file) => file.readAsBytesSync())
      .toList();
  bool sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  return listSharedWebFiles(webRoot).where((path) {
    final bytes = File(joinPath(webRoot.path, path)).readAsBytesSync();
    return brandContents.any((brand) => sameBytes(brand, bytes));
  }).toList();
}

Map<String, String> _htmlAttributes(String tag) => {
  for (final match in _htmlAttributePattern.allMatches(tag))
    match.group(1)!.toLowerCase(): match.group(2)!,
};

/// Returns the problems of a `web/index.html` source; an empty list means it
/// is partner-neutral: its `<title>` and `apple-mobile-web-app-title` are
/// [neutralWebAppTitle], it has every link of [requiredWebIndexLinks], and no
/// manifest or icon link points outside `partner/`. HTML comments are
/// ignored.
List<String> webIndexProblems(String html) {
  final source = html.replaceAll(_htmlCommentPattern, '');
  final problems = <String>[];

  final titles = _htmlTitlePattern
      .allMatches(source)
      .map((match) => match.group(1)!.trim())
      .toList();
  if (titles.isEmpty) {
    problems.add('<title> is missing');
  }
  for (final title in titles) {
    if (title != neutralWebAppTitle) {
      problems.add('<title> must be $neutralWebAppTitle, got: $title');
    }
  }

  final appleTitles = _htmlMetaPattern
      .allMatches(source)
      .map((match) => _htmlAttributes(match.group(0)!))
      .where((attrs) => attrs['name'] == 'apple-mobile-web-app-title')
      .map((attrs) => attrs['content'])
      .toList();
  if (appleTitles.isEmpty) {
    problems.add('apple-mobile-web-app-title is missing');
  }
  for (final title in appleTitles) {
    if (title != neutralWebAppTitle) {
      problems.add(
        'apple-mobile-web-app-title must be $neutralWebAppTitle, got: $title',
      );
    }
  }

  final links = _htmlLinkPattern
      .allMatches(source)
      .map((match) => _htmlAttributes(match.group(0)!))
      .toList();
  for (final MapEntry(key: rel, value: href) in requiredWebIndexLinks.entries) {
    final present = links.any(
      (attrs) => attrs['rel'] == rel && attrs['href'] == href,
    );
    if (!present) problems.add('missing <link rel="$rel" href="$href">');
  }
  for (final attrs in links) {
    final rel = attrs['rel'];
    final href = attrs['href'] ?? '';
    if (requiredWebIndexLinks.containsKey(rel) &&
        !href.startsWith('$webStagingFolderName/')) {
      problems.add('<link rel="$rel"> must point into partner/, got: $href');
    }
  }
  return problems;
}

/// Login logo every partner must provide next to its `partner.json`: the
/// file name of the onboarding form upload. Written out here so the contract
/// does not trust the app's own constant.
const requiredPartnerLogoFileName = 'logo-com-texto.svg';

/// Returns the problems of the login logo of [partnerDirectory]; an empty
/// list means `logo-com-texto.svg` exists, is not empty and holds an
/// `<svg` element.
List<String> partnerLogoProblems(Directory partnerDirectory) {
  final logo = File(
    joinPath(partnerDirectory.path, requiredPartnerLogoFileName),
  );
  if (!logo.existsSync()) {
    return ['$requiredPartnerLogoFileName is missing'];
  }
  final bytes = logo.readAsBytesSync();
  if (bytes.isEmpty) {
    return ['$requiredPartnerLogoFileName is empty'];
  }
  if (!utf8.decode(bytes, allowMalformed: true).contains('<svg')) {
    return ['$requiredPartnerLogoFileName is not an SVG'];
  }
  return const [];
}

/// Returns the paths of [files] whose text contains [needle], in the order
/// given. Files that do not exist are skipped.
List<String> filesMentioning(Iterable<File> files, String needle) {
  return files
      .where((file) => file.existsSync())
      .where(
        (file) => utf8
            .decode(file.readAsBytesSync(), allowMalformed: true)
            .contains(needle),
      )
      .map((file) => file.path)
      .toList();
}
