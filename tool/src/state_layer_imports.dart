/// The rule that keeps Flutter's UI libraries out of the state layer
/// (controllers and state contracts), run by `dart run tool/check_layers.dart`.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// The rule's name, printed with each violation.
const String stateImportsFlutterUi = 'state_imports_flutter_ui';

/// The line that marks a file as a state contract, for the contracts whose
/// names follow no pattern. It must be a line of its own.
const String stateContractMarker = '// check_layers: state_contract';

/// Flutter's UI libraries. `foundation.dart` (ChangeNotifier, debugPrint),
/// `services.dart` (platform channels) and `dart:ui` stay allowed.
const Set<String> forbiddenUris = {
  'package:flutter/animation.dart',
  'package:flutter/cupertino.dart',
  'package:flutter/gestures.dart',
  'package:flutter/material.dart',
  'package:flutter/painting.dart',
  'package:flutter/rendering.dart',
  'package:flutter/semantics.dart',
  'package:flutter/widgets.dart',
};

const List<String> _generatedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.mocks.dart',
];

/// A forbidden import or export found in a state file.
class LayerViolation {
  const LayerViolation({
    required this.path,
    required this.line,
    required this.column,
    required this.uri,
  });

  final String path;

  /// 1-based line and column of the URI's opening quote.
  final int line;
  final int column;
  final String uri;

  @override
  String toString() =>
      "$path:$line:$column - State files (controllers and state contracts) "
      "must not import or export '$uri'. Try 'package:flutter/foundation.dart', "
      "'package:flutter/services.dart' or 'dart:ui', or move the UI piece to "
      'the screen. - $stateImportsFlutterUi';
}

/// Whether the Dart file at [path] (relative to the package root, `/` or `\`
/// separated) with [content] belongs to the state layer: under `lib/`, not
/// generated, and either named `*_controller.dart` or carrying
/// [stateContractMarker].
bool isStateFile(String path, String content) {
  final segments = path.split(RegExp(r'[/\\]'));
  if (segments.first != 'lib') return false;
  final name = segments.last;
  if (!name.endsWith('.dart')) return false;
  if (_generatedSuffixes.any(name.endsWith)) return false;
  if (name.endsWith('_controller.dart')) return true;
  return content.split('\n').any((line) => line.trim() == stateContractMarker);
}

/// The forbidden imports and exports of the file at [path] with [content];
/// empty when the file is not in the state layer.
List<LayerViolation> findLayerViolations(String path, String content) {
  if (!isStateFile(path, content)) return const [];
  // Dart's own parser: comments and strings are never directives, and the
  // `if (...)` branches of conditional imports are checked too.
  final unit = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
  ).unit;
  final uris = <StringLiteral>[
    for (final directive in unit.directives)
      if (directive is NamespaceDirective) ...[
        directive.uri,
        for (final configuration in directive.configurations) configuration.uri,
      ],
  ];
  return [
    for (final literal in uris)
      if (forbiddenUris.contains(literal.stringValue))
        LayerViolation(
          path: path,
          line: unit.lineInfo.getLocation(literal.offset).lineNumber,
          column: unit.lineInfo.getLocation(literal.offset).columnNumber,
          uri: literal.stringValue!,
        ),
  ];
}
