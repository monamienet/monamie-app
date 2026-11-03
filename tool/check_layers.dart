import 'dart:io';

import 'package:path/path.dart' as p;

import 'src/state_layer_imports.dart';
import 'src/ui_text_literals.dart';

/// Fails (exit code 1) when a view model or state contract under `lib/`
/// imports one of Flutter's UI libraries, any file under `lib/` imports
/// GetX, a file under `lib/ui/` or `lib/domain/` imports a plugin, or a file
/// under `lib/domain/` imports another layer of the app (see
/// `src/state_layer_imports.dart`), or a screen under `lib/ui/` holds a
/// hard-coded text instead of reading the ARB files (see
/// `src/ui_text_literals.dart`).
/// Run from anywhere in the repo: `dart run tool/check_layers.dart`.
void main() {
  // tool/check_layers.dart -> repository root, independent of the working
  // directory.
  final repoRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final lib = Directory(p.join(repoRoot, 'lib'));

  final violations = <Object>[];
  final files = lib.listSync(recursive: true).whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final path = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    violations
      ..addAll(findLayerViolations(path, content))
      ..addAll(findHardCodedTexts(path, content));
  }

  if (violations.isEmpty) {
    stdout.writeln('No layer or text rule violations.');
    return;
  }
  violations.forEach(stderr.writeln);
  stderr.writeln('${violations.length} violation(s) found.');
  exitCode = 1;
}
