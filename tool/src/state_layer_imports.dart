/// The layer rules run by `dart run tool/check_layers.dart`: Flutter's UI
/// libraries stay out of the state layer (view models and state contracts),
/// no file under `lib/` uses GetX, which the app no longer depends on, the
/// UI and the domain reach plugins only through the data layer's services,
/// and the domain imports no outer layer (its use cases only the data
/// layer's repositories, services and models).
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

/// The rules' names, printed with each violation.
const String stateImportsFlutterUi = 'state_imports_flutter_ui';
const String libImportsGet = 'lib_imports_get';
const String uiImportsPlugin = 'ui_imports_plugin';
const String domainImportsOuter = 'domain_imports_outer';

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

/// The plugin packages wrapped by the data layer's services, matched by
/// package name: these names exactly, and every package starting with one of
/// [pluginPackagePrefixes]. Other packages of the same family (the web
/// button of `google_sign_in_web`, say) are not plugins wrapped by a service.
const Set<String> pluginPackages = {
  'geolocator',
  'permission_handler',
  'flutter_background_service',
  'shared_preferences',
  'google_sign_in',
  'http',
};

/// Name prefixes of the plugin packages: Firebase (`firebase_core`,
/// `firebase_auth`…), its `cloud_*` packages and Hive (`hive`,
/// `hive_flutter`).
const List<String> pluginPackagePrefixes = ['firebase_', 'cloud_', 'hive'];

/// The app's own folders the domain must not import.
const List<String> _outerLayers = ['data', 'ui', 'routing', 'config'];

/// The folder of the use cases, the one part of the domain that reaches the
/// data layer: as in the official architecture guide, a use case combines
/// repositories (and the services and models they speak in).
const String useCasesFolder = 'lib/domain/use_cases/';

/// The data layer's folders a use case may import: never the UI, the
/// routing or the composition root.
const List<String> useCaseDataFolders = [
  'lib/data/repositories/',
  'lib/data/services/',
  'lib/data/model/',
];

const String _appPackage = 'package:monamie_app/';

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

  /// [stateImportsFlutterUi], [libImportsGet], [uiImportsPlugin] or
  /// [domainImportsOuter].
  final String rule;

  @override
  String toString() => switch (rule) {
    libImportsGet =>
      "$path:$line:$column - Files under lib/ must not import or export "
          "'$uri': the app no longer uses GetX. Use ChangeNotifier, go_router "
          'or provider. - $libImportsGet',
    uiImportsPlugin =>
      "$path:$line:$column - Files under lib/ui/ and lib/domain/ must not "
          "import or export '$uri'. Reach the plugin through a service or "
          'repository under lib/data/. - $uiImportsPlugin',
    domainImportsOuter =>
      "$path:$line:$column - Files under lib/domain/ must not import or "
          "export '$uri': the domain depends on no other layer, except its "
          'use cases (lib/domain/use_cases/), which may import the '
          "repositories, services and models of lib/data/. Move the "
          'conversion to lib/data/ or the shared piece to lib/domain/. - '
          '$domainImportsOuter',
    _ =>
      "$path:$line:$column - State files (view models and state contracts) "
          "must not import or export '$uri'. Try 'package:flutter/foundation.dart', "
          "'package:flutter/services.dart' or 'dart:ui', or move the UI piece to "
          'the screen. - $stateImportsFlutterUi',
  };
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

/// Whether [uri] imports one of the plugin packages ([pluginPackages],
/// [pluginPackagePrefixes]).
bool isPluginUri(String uri) {
  if (!uri.startsWith('package:')) return false;
  final name = uri.substring('package:'.length).split('/').first;
  return pluginPackages.contains(name) ||
      pluginPackagePrefixes.any(name.startsWith);
}

/// Whether [uri], imported by the file at [path] (relative to the package
/// root), reaches one of the app's outer layers ([_outerLayers]): by its
/// `package:` URI, or by a relative URI resolved against [path]. A use case
/// (under [useCasesFolder]) may reach [useCaseDataFolders].
bool _isOuterLayerUri(String path, String uri) {
  final String target;
  if (uri.startsWith(_appPackage)) {
    // Normalized too: `..` segments must not hide the folder reached.
    target = p.posix.normalize('lib/${uri.substring(_appPackage.length)}');
  } else if (!uri.contains(':')) {
    final from = p.posix.dirname(_segments(path).join('/'));
    target = p.posix.normalize(p.posix.join(from, uri));
  } else {
    return false;
  }
  final segments = target.split('/');
  final outer =
      segments.length > 2 &&
      segments.first == 'lib' &&
      _outerLayers.contains(segments[1]);
  if (!outer) return false;
  final useCase = _segments(path).join('/').startsWith(useCasesFolder);
  return !(useCase && useCaseDataFolders.any(target.startsWith));
}

/// The folder segments of [path] (`/` or `\` separated).
List<String> _segments(String path) => path.split(RegExp(r'[/\\]'));

/// Whether [path] is under `lib/<folder>/`.
bool _isUnder(String path, String folder) {
  final segments = _segments(path);
  return segments.length > 2 && segments[0] == 'lib' && segments[1] == folder;
}

/// Whether [path] is a hand-written Dart file under `lib/`.
bool _isLibSource(String path) {
  final segments = _segments(path);
  if (segments.first != 'lib') return false;
  final name = segments.last;
  return name.endsWith('.dart') && !_generatedSuffixes.any(name.endsWith);
}

/// The forbidden imports and exports of the file at [path] with [content]:
/// GetX in any hand-written file under `lib/`, Flutter's UI libraries in
/// state files, plugin packages under `lib/ui/` and `lib/domain/`, and the
/// app's outer layers (`data/`, `ui/`, `routing/`, `config/`) under
/// `lib/domain/`, where only the use cases may import [useCaseDataFolders].
/// Each URI reports its first broken rule.
List<LayerViolation> findLayerViolations(String path, String content) {
  if (!_isLibSource(path)) return const [];
  final stateFile = isStateFile(path, content);
  final domainFile = _isUnder(path, 'domain');
  final pluginFree = domainFile || _isUnder(path, 'ui');
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
      if (literal.stringValue case final uri?)
        if (uri.startsWith(_getPackage))
          at(literal, libImportsGet)
        else if (stateFile && forbiddenUris.contains(uri))
          at(literal, stateImportsFlutterUi)
        else if (pluginFree && isPluginUri(uri))
          at(literal, uiImportsPlugin)
        else if (domainFile && _isOuterLayerUri(path, uri))
          at(literal, domainImportsOuter),
  ];
}
