/// The layer rules run by `dart run tool/check_layers.dart`: Flutter's UI
/// libraries stay out of the state layer (view models and state contracts),
/// and no file under `lib/` uses GetX, which the app no longer depends on.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// The rules' names, printed with each violation.
const String stateImportsFlutterUi = 'state_imports_flutter_ui';
const String libImportsGet = 'lib_imports_get';

/// GetX, replaced by ChangeNotifier, go_router and provider.
const String _getPackage = 'package:get/';

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
    this.rule = stateImportsFlutterUi,
  });

  final String path;

  /// 1-based line and column of the URI's opening quote.
  final int line;
  final int column;
  final String uri;

  /// [stateImportsFlutterUi] or [libImportsGet].
  final String rule;

  @override
  String toString() => rule == libImportsGet
      ? "$path:$line:$column - Files under lib/ must not import or export "
            "'$uri': the app no longer uses GetX. Use ChangeNotifier, go_router "
            'or provider. - $libImportsGet'
      : "$path:$line:$column - State files (view models and state contracts) "
            "must not import or export '$uri'. Try 'package:flutter/foundation.dart', "
            "'package:flutter/services.dart' or 'dart:ui', or move the UI piece to "
            'the screen. - $stateImportsFlutterUi';
}

/// Whether the Dart file at [path] (relative to the package root, `/` or `\`
/// separated) with [content] belongs to the state layer: under `lib/`, not
/// generated, and either named `*_view_model.dart` or carrying
/// [stateContractMarker].
bool isStateFile(String path, String content) {
  if (!_isLibSource(path)) return false;
  if (path.endsWith('_view_model.dart')) return true;
  return content.split('\n').any((line) => line.trim() == stateContractMarker);
}

/// Whether [path] is a hand-written Dart file under `lib/`.
bool _isLibSource(String path) {
  final segments = path.split(RegExp(r'[/\\]'));
  if (segments.first != 'lib') return false;
  final name = segments.last;
  return name.endsWith('.dart') && !_generatedSuffixes.any(name.endsWith);
}

/// The forbidden imports and exports of the file at [path] with [content]:
/// GetX in any hand-written file under `lib/`, and Flutter's UI libraries in
/// state files.
List<LayerViolation> findLayerViolations(String path, String content) {
  if (!_isLibSource(path)) return const [];
  final stateFile = isStateFile(path, content);
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
  LayerViolation at(StringLiteral literal, String rule) {
    final location = unit.lineInfo.getLocation(literal.offset);
    return LayerViolation(
      path: path,
      line: location.lineNumber,
      column: location.columnNumber,
      uri: literal.stringValue!,
      rule: rule,
    );
  }

  return [
    for (final literal in uris)
      if (literal.stringValue?.startsWith(_getPackage) ?? false)
        at(literal, libImportsGet)
      else if (stateFile && forbiddenUris.contains(literal.stringValue))
        at(literal, stateImportsFlutterUi),
  ];
}
