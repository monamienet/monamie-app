import 'dart:io';

import 'package:path/path.dart' as p;

import 'src/state_layer_imports.dart';

/// Fails (exit code 1) when a controller or state contract under `lib/`
/// imports one of Flutter's UI libraries (see `src/state_layer_imports.dart`).
/// Run from anywhere in the repo: `dart run tool/check_layers.dart`.
void main() {
  // tool/check_layers.dart -> repository root, independent of the working
  // directory.
  final repoRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final lib = Directory(p.join(repoRoot, 'lib'));

  final violations = <LayerViolation>[];
  final files = lib.listSync(recursive: true).whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final path = p.relative(file.path, from: repoRoot);
    violations.addAll(findLayerViolations(path, file.readAsStringSync()));
  }

  if (violations.isEmpty) {
    stdout.writeln('No state file imports Flutter UI libraries.');
    return;
  }
  violations.forEach(stderr.writeln);
  stderr.writeln('${violations.length} violation(s) found.');
  exitCode = 1;
}
