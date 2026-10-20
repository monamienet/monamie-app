import 'package:path/path.dart' as p;

/// Pure helpers that read the `flutter: assets:` list of a `pubspec.yaml` and
/// check that each partner folder is bundled only into its own flavor.
///
/// `package:yaml` is only a transitive dependency of this project, so the
/// list is read with a small parser for the YAML subset pubspec asset lists
/// use: block sequences of plain or quoted scalars, block mappings with
/// scalar, flow-sequence or block-sequence values, and `# comments`. Anything
/// else (flow mappings, anchors, aliases, tags, block scalars, duplicate keys)
/// throws a [FormatException], so an unsupported spelling fails the contract
/// instead of being skipped.

/// Root folder of the partners, relative to the repository root.
const partnersFolder = 'partners';

/// One entry of `flutter: assets:`.
class PubspecAsset {
  const PubspecAsset({
    required this.line,
    required this.path,
    this.fields = const {},
    this.isMap = false,
  });

  /// 1-based line of the entry in the source.
  final int line;

  /// The string entry, or the `path:` value of a map entry (null when a map
  /// entry has no string `path`).
  final String? path;

  /// Every key of a map entry with its value: a [String] or a
  /// `List<String>`. Empty for a string entry.
  final Map<String, Object> fields;

  /// Whether the entry is a map (`- path: ...`) instead of a string.
  final bool isMap;

  /// The `flavors:` value of a map entry, or null when it is missing or not a
  /// list.
  List<String>? get flavors {
    final value = fields['flavors'];
    return value is List<String> ? value : null;
  }

  @override
  String toString() => isMap ? 'line $line: $fields' : 'line $line: $path';
}

final _mapKeyPattern = RegExp(r'^([A-Za-z_][\w-]*):(?:\s+(.*))?$');

/// Removes a `# comment` (a `#` at the start or after whitespace, outside
/// quotes) and trailing whitespace from [line].
String stripYamlComment(String line) {
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (quote != null) {
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
    } else if (char == '#' && (i == 0 || line[i - 1].trim().isEmpty)) {
      return line.substring(0, i).trimRight();
    }
  }
  return line.trimRight();
}

int _indentOf(String line) => line.length - line.trimLeft().length;

/// Parses a YAML scalar of an asset list: plain, `'single'` or `"double"`
/// quoted. Throws a [FormatException] for anchors, aliases, tags, block
/// scalars and flow collections.
String parseYamlScalar(String text, {int? line}) {
  final value = text.trim();
  final where = line == null ? '' : 'line $line: ';
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value.substring(1, value.length - 1).replaceAll(r'\"', '"');
  }
  if (value.length >= 2 && value.startsWith("'") && value.endsWith("'")) {
    return value.substring(1, value.length - 1).replaceAll("''", "'");
  }
  if (value.isEmpty ||
      '&*!|>{}[]"\''.contains(value[0]) ||
      value.startsWith('- ') ||
      value == '-') {
    throw FormatException('${where}unsupported YAML scalar: $text');
  }
  return value;
}

/// Parses a one-line YAML flow sequence of scalars, such as `[a, 'b']`.
List<String> parseYamlFlowSequence(String text, {int? line}) {
  final value = text.trim();
  final where = line == null ? '' : 'line $line: ';
  if (!value.startsWith('[') || !value.endsWith(']')) {
    throw FormatException('${where}expected a [flow, sequence]: $text');
  }
  final inner = value.substring(1, value.length - 1).trim();
  if (inner.isEmpty) return <String>[];
  if (inner.contains('[') || inner.contains('{')) {
    throw FormatException('${where}nested flow collections: $text');
  }
  return inner
      .split(',')
      .map((item) => parseYamlScalar(item, line: line))
      .toList();
}

/// A non-blank line of the source with its 1-based number.
typedef _Line = ({int number, int indent, String text});

/// Returns the entries of `flutter: assets:` in the pubspec [source], in
/// order. Returns an empty list when there is no `flutter:` or `assets:`
/// section. Throws a [FormatException] for YAML outside the supported
/// subset.
List<PubspecAsset> parsePubspecAssets(String source) {
  final lines = <_Line>[];
  final rawLines = source.split('\n');
  for (var i = 0; i < rawLines.length; i++) {
    final text = stripYamlComment(rawLines[i].replaceAll('\r', ''));
    if (text.trim().isEmpty) continue;
    if (text.substring(0, _indentOf(text)).contains('\t')) {
      throw FormatException('line ${i + 1}: tabs are not valid indentation');
    }
    lines.add((number: i + 1, indent: _indentOf(text), text: text.trim()));
  }

  final flutterIndexes = [
    for (var i = 0; i < lines.length; i++)
      if (lines[i].indent == 0 && lines[i].text == 'flutter:') i,
  ];
  if (flutterIndexes.isEmpty) return const [];
  if (flutterIndexes.length > 1) {
    throw const FormatException('duplicate top-level "flutter:" key');
  }

  final flutterBlock = <_Line>[];
  for (var i = flutterIndexes.single + 1; i < lines.length; i++) {
    if (lines[i].indent == 0) break;
    flutterBlock.add(lines[i]);
  }
  if (flutterBlock.isEmpty) return const [];
  final childIndent = flutterBlock.first.indent;

  final assetsIndexes = [
    for (var i = 0; i < flutterBlock.length; i++)
      if (flutterBlock[i].indent == childIndent &&
          (flutterBlock[i].text == 'assets:' ||
              flutterBlock[i].text.startsWith('assets: ')))
        i,
  ];
  if (assetsIndexes.isEmpty) return const [];
  if (assetsIndexes.length > 1) {
    throw const FormatException('duplicate "flutter: assets:" key');
  }

  final assetsLine = flutterBlock[assetsIndexes.single];
  final inline = assetsLine.text.substring('assets:'.length).trim();
  if (inline.isNotEmpty) {
    return [
      for (final path in parseYamlFlowSequence(inline, line: assetsLine.number))
        PubspecAsset(line: assetsLine.number, path: path),
    ];
  }

  final block = <_Line>[];
  for (var i = assetsIndexes.single + 1; i < flutterBlock.length; i++) {
    final line = flutterBlock[i];
    if (line.indent < childIndent) break;
    if (line.indent == childIndent && !line.text.startsWith('-')) break;
    block.add(line);
  }
  if (block.isEmpty) return const [];

  final itemIndent = block.first.indent;
  final items = <List<_Line>>[];
  for (final line in block) {
    final isItemStart =
        line.indent == itemIndent &&
        (line.text == '-' || line.text.startsWith('- '));
    if (isItemStart) {
      items.add([line]);
    } else if (line.indent > itemIndent && items.isNotEmpty) {
      items.last.add(line);
    } else {
      throw FormatException(
        'line ${line.number}: unexpected line in assets: ${line.text}',
      );
    }
  }
  return items.map((item) => _parseAssetItem(item, itemIndent)).toList();
}

PubspecAsset _parseAssetItem(List<_Line> item, int itemIndent) {
  final first = item.first;
  final rest = first.text == '-' ? '' : first.text.substring(2).trim();

  // `- some/path` with nothing below: a string entry.
  if (rest.isNotEmpty && !_mapKeyPattern.hasMatch(rest)) {
    if (item.length > 1) {
      throw FormatException(
        'line ${item[1].number}: unexpected line below a string asset',
      );
    }
    if (rest.startsWith('{')) {
      throw FormatException(
        'line ${first.number}: flow mappings are not supported, use a block '
        'mapping',
      );
    }
    return PubspecAsset(
      line: first.number,
      path: parseYamlScalar(rest, line: first.number),
    );
  }

  // A map entry: its keys are `rest` (if any) plus the lines at the key
  // indent; deeper lines are the block sequence of the previous key.
  final entries = <({_Line line, String text, List<_Line> children})>[];
  final int keyIndent;
  if (rest.isNotEmpty) {
    keyIndent = itemIndent + (first.text.length - rest.length);
    entries.add((line: first, text: rest, children: []));
  } else {
    if (item.length < 2) {
      throw FormatException('line ${first.number}: empty asset entry');
    }
    keyIndent = item[1].indent;
  }
  for (final line in item.skip(1)) {
    if (line.indent == keyIndent) {
      entries.add((line: line, text: line.text, children: []));
    } else if (line.indent > keyIndent && entries.isNotEmpty) {
      entries.last.children.add(line);
    } else {
      throw FormatException(
        'line ${line.number}: unexpected indentation in asset entry',
      );
    }
  }

  final fields = <String, Object>{};
  for (final entry in entries) {
    final match = _mapKeyPattern.firstMatch(entry.text);
    if (match == null) {
      throw FormatException(
        'line ${entry.line.number}: expected "key: value": ${entry.text}',
      );
    }
    final key = match.group(1)!;
    if (fields.containsKey(key)) {
      throw FormatException('line ${entry.line.number}: duplicate key "$key"');
    }
    final value = (match.group(2) ?? '').trim();
    fields[key] = _parseFieldValue(value, entry.children, entry.line.number);
  }

  final path = fields['path'];
  return PubspecAsset(
    line: first.number,
    path: path is String ? path : null,
    fields: fields,
    isMap: true,
  );
}

Object _parseFieldValue(String value, List<_Line> children, int line) {
  if (value.isNotEmpty) {
    if (children.isNotEmpty) {
      throw FormatException(
        'line ${children.first.number}: unexpected line below a value',
      );
    }
    return value.startsWith('[')
        ? parseYamlFlowSequence(value, line: line)
        : parseYamlScalar(value, line: line);
  }
  if (children.isEmpty) {
    throw FormatException('line $line: empty value');
  }
  final indent = children.first.indent;
  final items = <String>[];
  for (final child in children) {
    if (child.indent != indent ||
        !(child.text == '-' || child.text.startsWith('- '))) {
      throw FormatException(
        'line ${child.number}: expected a "- item" sequence',
      );
    }
    items.add(parseYamlScalar(child.text.substring(1), line: child.number));
  }
  return items;
}

/// Whether the asset [path] is `partners/` or anything below it.
bool coversPartnersFolder(String path) {
  final normalized = p.posix.normalize(path.replaceAll(r'\', '/'));
  return normalized == partnersFolder ||
      normalized.startsWith('$partnersFolder/');
}

/// Whether [asset] is exactly `{path: partners/<id>/, flavors: [<id>]}`.
bool isFlavorOnlyPartnerAsset(PubspecAsset asset, String id) {
  final flavors = asset.flavors;
  return asset.isMap &&
      asset.path == '$partnersFolder/$id/' &&
      asset.fields.keys.toSet().containsAll(['path', 'flavors']) &&
      asset.fields.length == 2 &&
      flavors != null &&
      flavors.length == 1 &&
      flavors.single == id;
}

/// Returns the problems of [assets] for the partners [partnerIds]; an empty
/// list means each partner has exactly one entry
/// `{path: partners/<id>/, flavors: [<id>]}` and no other entry (string or
/// map) covers `partners/` or anything below it.
List<String> partnerAssetProblems(
  List<PubspecAsset> assets,
  Iterable<String> partnerIds,
) {
  final ids = partnerIds.toSet().toList()..sort();
  final problems = <String>[];
  for (final id in ids) {
    final count = assets
        .where((asset) => isFlavorOnlyPartnerAsset(asset, id))
        .length;
    if (count == 0) {
      problems.add(
        'missing asset entry {path: $partnersFolder/$id/, flavors: [$id]}',
      );
    } else if (count > 1) {
      problems.add(
        '$count asset entries {path: $partnersFolder/$id/, flavors: [$id]}',
      );
    }
  }
  for (final asset in assets) {
    final path = asset.path;
    if (path == null) {
      final raw = asset.fields['path'];
      if (raw is List<String> && raw.any(coversPartnersFolder)) {
        problems.add('$asset: "path" must be a single string');
      }
      continue;
    }
    if (!coversPartnersFolder(path)) continue;
    if (ids.any((id) => isFlavorOnlyPartnerAsset(asset, id))) continue;
    problems.add(
      '$asset covers $partnersFolder/ but is not '
      '{path: $partnersFolder/<id>/, flavors: [<id>]} for a partner',
    );
  }
  return problems;
}
