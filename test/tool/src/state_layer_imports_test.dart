import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/src/state_layer_imports.dart';

const viewModelPath = 'lib/ui/x/view_models/x_view_model.dart';
const marker = '// check_layers: state_contract';

const getUris = [
  'package:get/get.dart',
  'package:get/route_manager.dart',
  'package:get/get_state_manager/get_state_manager.dart',
];

const uiLibraries = [
  'package:flutter/material.dart',
  'package:flutter/widgets.dart',
  'package:flutter/cupertino.dart',
  'package:flutter/painting.dart',
  'package:flutter/rendering.dart',
  'package:flutter/animation.dart',
  'package:flutter/gestures.dart',
  'package:flutter/semantics.dart',
];

void main() {
  group('isStateFile', () {
    test('a *_view_model.dart under lib/ is a state file', () {
      // 1. Arrange
      const content = "import 'package:flutter/foundation.dart';\n";

      // 2. Act
      final result = isStateFile(viewModelPath, content);

      // 3. Assert
      expect(result, isTrue);
    });

    test('a file with the marker on a line of its own is a state file', () {
      // 1. Arrange
      const content =
          "import 'dart:async';\n\n  $marker  \nabstract class S {}\n";

      // 2. Act
      final result = isStateFile('lib/ui/x/group_map_state.dart', content);

      // 3. Assert
      expect(result, isTrue);
    });

    test('Windows separators are accepted', () {
      // 1. Arrange
      const path = r'lib\ui\x\x_view_model.dart';

      // 2. Act
      final result = isStateFile(path, '');

      // 3. Assert
      expect(result, isTrue);
    });

    test('a file under lib/ with neither name nor marker is not', () {
      // 1. Arrange
      const content = "import 'package:flutter/material.dart';\n";

      // 2. Act
      final result = isStateFile('lib/ui/x/ui/x_screen.dart', content);

      // 3. Assert
      expect(result, isFalse);
    });

    test('the marker sharing a line with code does not count', () {
      // 1. Arrange
      const content = "abstract class S {} $marker\n";

      // 2. Act
      final result = isStateFile('lib/ui/x/s.dart', content);

      // 3. Assert
      expect(result, isFalse);
    });

    for (final path in [
      'test/ui/x/x_view_model.dart',
      'tool/x_view_model.dart',
      'mylib/x_view_model.dart',
    ]) {
      test('a view model outside lib/ is not a state file: $path', () {
        // 1. Arrange
        const content = marker;

        // 2. Act
        final result = isStateFile(path, content);

        // 3. Assert
        expect(result, isFalse);
      });
    }

    for (final name in [
      'x_view_model.mocks.dart',
      'x_view_model.freezed.dart',
      'x_view_model.g.dart',
    ]) {
      test('a generated file is skipped even with the marker: $name', () {
        // 1. Arrange
        const content = '$marker\n';

        // 2. Act
        final result = isStateFile('lib/ui/x/$name', content);

        // 3. Assert
        expect(result, isFalse);
      });
    }

    test('a non-Dart file is not a state file', () {
      // 1. Arrange
      const content = '$marker\n';

      // 2. Act
      final result = isStateFile('lib/ui/x/notes.txt', content);

      // 3. Assert
      expect(result, isFalse);
    });
  });

  group('findLayerViolations', () {
    test('allowed imports give no violation', () {
      // 1. Arrange
      const content = '''
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
export 'package:flutter/foundation.dart' show ChangeNotifier;
''';

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('a screen importing material is ignored', () {
      // 1. Arrange
      const content = "import 'package:flutter/material.dart';\n";

      // 2. Act
      final result = findLayerViolations('lib/ui/x/ui/x_screen.dart', content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('a generated view model importing material is ignored', () {
      // 1. Arrange
      const content = "import 'package:flutter/material.dart';\n";

      // 2. Act
      final result = findLayerViolations(
        'lib/ui/x/x_view_model.mocks.dart',
        content,
      );

      // 3. Assert
      expect(result, isEmpty);
    });

    for (final directive in ['import', 'export']) {
      for (final uri in uiLibraries) {
        test('$directive of $uri is a violation', () {
          // 1. Arrange
          final content = "$directive '$uri';\n";

          // 2. Act
          final result = findLayerViolations(viewModelPath, content);

          // 3. Assert
          expect(result.map((v) => (v.uri, v.rule)), [
            (uri, stateImportsFlutterUi),
          ]);
        });
      }
    }

    test('a marked state contract importing widgets is a violation', () {
      // 1. Arrange
      const content = "$marker\nimport 'package:flutter/widgets.dart';\n";

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x_state.dart', content);

      // 3. Assert
      expect(result.single.uri, 'package:flutter/widgets.dart');
    });

    test('the violation points at the opening quote, 1-based', () {
      // 1. Arrange
      const content =
          "import 'dart:async';\n\n  import \"package:flutter/material.dart\";\n";

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(
        (result.single.path, result.single.line, result.single.column),
        (viewModelPath, 3, 10),
      );
    });

    test('every forbidden directive is reported, in file order', () {
      // 1. Arrange
      const content = '''
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
export 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
''';

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result.map((v) => (v.line, v.uri)), [
        (1, 'package:flutter/material.dart'),
        (3, 'package:flutter/widgets.dart'),
        (4, 'package:flutter/gestures.dart'),
      ]);
    });

    for (final (label, content) in [
      ('show', "import 'package:flutter/material.dart' show Colors;\n"),
      ('hide', "import 'package:flutter/material.dart' hide Text;\n"),
      ('as', "import 'package:flutter/material.dart' as m;\n"),
      (
        'deferred as',
        "import 'package:flutter/material.dart' deferred as m;\n",
      ),
      ('double quotes', 'import "package:flutter/material.dart";\n'),
    ]) {
      test('an import with $label is a violation', () {
        // 1. Arrange (content from the table)

        // 2. Act
        final result = findLayerViolations(viewModelPath, content);

        // 3. Assert
        expect(result.single.uri, 'package:flutter/material.dart');
      });
    }

    test('a conditional import is checked on its default URI', () {
      // 1. Arrange
      const content = '''
import 'package:flutter/material.dart'
    if (dart.library.io) 'src/io_stub.dart';
''';

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result.single.uri, 'package:flutter/material.dart');
    });

    test('a forbidden URI in a conditional branch is reported there', () {
      // 1. Arrange
      const content = """
import 'src/stub.dart'
    if (dart.library.ui) 'package:flutter/material.dart';
""";

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(
        (result.single.uri, result.single.line, result.single.column),
        ('package:flutter/material.dart', 2, 26),
      );
    });

    test('an import line inside a block comment is not a violation', () {
      // 1. Arrange
      const content = """
/*
import 'package:flutter/material.dart';
*/
import 'package:flutter/foundation.dart';
""";

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('an import line inside a multi-line string is not a violation', () {
      // 1. Arrange
      const content = """
const example = '''
import 'package:flutter/material.dart';
''';
""";

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result, isEmpty);
    });

    for (final (label, content) in [
      ('// comment', "// import 'package:flutter/material.dart';\n"),
      ('/// doc comment', "/// import 'package:flutter/material.dart';\n"),
      (
        'trailing comment',
        "void f() {} // import 'package:flutter/material.dart';\n",
      ),
    ]) {
      test('an import in a $label is not a violation', () {
        // 1. Arrange (content from the table)

        // 2. Act
        final result = findLayerViolations(viewModelPath, content);

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    test('mismatched quotes are not read as a directive', () {
      // 1. Arrange
      const content = "import 'package:flutter/material.dart\";\n";

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('a relative file named like a UI library is not a violation', () {
      // 1. Arrange
      const content = "import 'material.dart';\n";

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('the message names the file, position, URI and rule', () {
      // 1. Arrange
      const content = "import 'package:flutter/material.dart';\n";

      // 2. Act
      final message = findLayerViolations(
        viewModelPath,
        content,
      ).single.toString();

      // 3. Assert
      expect(
        message,
        allOf(
          startsWith('$viewModelPath:1:8 '),
          contains("'package:flutter/material.dart'"),
          contains('State files (view models and state contracts)'),
          endsWith(' - $stateImportsFlutterUi'),
        ),
      );
    });
  });

  group('findLayerViolations: lib_imports_get', () {
    for (final directive in ['import', 'export']) {
      for (final uri in getUris) {
        test('$directive of $uri in a controller is a violation', () {
          // 1. Arrange
          final content = "$directive '$uri';\n";

          // 2. Act
          final result = findLayerViolations(viewModelPath, content);

          // 3. Assert
          expect(result.map((v) => (v.uri, v.rule)), [(uri, libImportsGet)]);
        });
      }
    }

    for (final path in [
      'lib/ui/x/ui/x_screen.dart',
      'lib/data/model/x.dart',
      'lib/main.dart',
      r'lib\ui\x\ui\x_screen.dart',
    ]) {
      test(
        'a non-state file under lib/ importing get is a violation: $path',
        () {
          // 1. Arrange
          const content = "import 'package:get/get.dart';\n";

          // 2. Act
          final result = findLayerViolations(path, content);

          // 3. Assert
          expect(result.map((v) => (v.path, v.rule)), [(path, libImportsGet)]);
        },
      );
    }

    for (final path in [
      'test/ui/x/x_page_test.dart',
      'tool/x.dart',
      'mylib/x.dart',
      'lib/ui/x/x.g.dart',
      'lib/ui/x/x.freezed.dart',
      'lib/ui/x/x_view_model.mocks.dart',
      'lib/ui/x/notes.txt',
    ]) {
      test('get is ignored outside hand-written lib/ Dart files: $path', () {
        // 1. Arrange
        const content = "import 'package:get/get.dart';\n";

        // 2. Act
        final result = findLayerViolations(path, content);

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    for (final (label, content) in [
      ('show', "import 'package:get/get.dart' show Get;\n"),
      ('hide', "import 'package:get/get.dart' hide Rx;\n"),
      ('as', "import 'package:get/get.dart' as getx;\n"),
      ('deferred as', "import 'package:get/get.dart' deferred as getx;\n"),
      ('export show', "export 'package:get/get.dart' show Get;\n"),
      ('double quotes', 'import "package:get/get.dart";\n'),
    ]) {
      test('a get directive with $label is a violation', () {
        // 1. Arrange (content from the table)

        // 2. Act
        final result = findLayerViolations('lib/ui/x/x.dart', content);

        // 3. Assert
        expect(result.single.rule, libImportsGet);
      });
    }

    test('get as the default URI of a conditional import is reported', () {
      // 1. Arrange
      const content = '''
import 'package:get/get.dart'
    if (dart.library.io) 'src/io_stub.dart';
''';

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x.dart', content);

      // 3. Assert
      expect(
        (result.single.uri, result.single.rule),
        ('package:get/get.dart', libImportsGet),
      );
    });

    test('get in a conditional branch is reported at the branch', () {
      // 1. Arrange
      const content = """
import 'src/stub.dart'
    if (dart.library.io) 'package:get/get.dart';
""";

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x.dart', content);

      // 3. Assert
      expect(
        (result.single.line, result.single.column, result.single.rule),
        (2, 26, libImportsGet),
      );
    });

    for (final uri in [
      'package:get_it/get_it.dart',
      'package:get_storage/get_storage.dart',
      'package:getx/getx.dart',
      'package:flutter_get/get.dart',
      'get/get.dart',
    ]) {
      test('a URI that only looks like get is allowed: $uri', () {
        // 1. Arrange
        final content = "import '$uri';\n";

        // 2. Act
        final result = findLayerViolations('lib/ui/x/x.dart', content);

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    test('a get import inside a comment is not a violation', () {
      // 1. Arrange
      const content = """
// import 'package:get/get.dart';
/*
export 'package:get/get.dart';
*/
""";

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x.dart', content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('a state file with material and get reports both, in file order', () {
      // 1. Arrange
      const content = '''
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
''';

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result.map((v) => (v.line, v.uri, v.rule)), [
        (1, 'package:get/get.dart', libImportsGet),
        (3, 'package:flutter/material.dart', stateImportsFlutterUi),
      ]);
    });

    test('a screen with material and get reports only get', () {
      // 1. Arrange
      const content = '''
import 'package:flutter/material.dart';
import 'package:get/get.dart';
''';

      // 2. Act
      final result = findLayerViolations('lib/ui/x/ui/x_screen.dart', content);

      // 3. Assert
      expect(result.map((v) => (v.line, v.rule)), [(2, libImportsGet)]);
    });

    test('the get message names the file, position, URI and rule', () {
      // 1. Arrange
      const path = 'lib/ui/x/ui/x_screen.dart';
      const content = "import 'dart:async';\nimport 'package:get/get.dart';\n";

      // 2. Act
      final message = findLayerViolations(path, content).single.toString();

      // 3. Assert
      expect(
        message,
        allOf(
          startsWith('$path:2:8 - Files under lib/ must not import or export '),
          contains("'package:get/get.dart'"),
          contains('no longer uses GetX'),
          endsWith(' - $libImportsGet'),
        ),
      );
    });
  });

  group('check_layers.dart', () {
    late Directory root;

    setUp(() {
      // A copy of the tool next to its own lib/, so Platform.script resolves
      // the fixture instead of the repository.
      root = Directory.systemTemp.createTempSync('check_layers_');
      for (final file in [
        'check_layers.dart',
        'src/state_layer_imports.dart',
      ]) {
        final target = File(p.join(root.path, 'tool', file))
          ..createSync(recursive: true);
        File(p.join('tool', file)).copySync(target.path);
      }
    });

    tearDown(() => root.deleteSync(recursive: true));

    // The tests run in flutter_tester, so the Dart VM comes from PATH.
    Future<ProcessResult> runTool() => Process.run('dart', [
      '--packages=${p.absolute('.dart_tool', 'package_config.json')}',
      p.join(root.path, 'tool', 'check_layers.dart'),
    ]);

    void writeLib(String relative, String content) {
      File(p.join(root.path, 'lib', relative))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    test('exits 0 and says so when no rule is broken', () async {
      // 1. Arrange
      writeLib(
        'a/a_view_model.dart',
        "import 'package:flutter/foundation.dart';\n",
      );
      writeLib('a/a_page.dart', "import 'package:flutter/material.dart';\n");

      // 2. Act
      final result = await runTool();

      // 3. Assert
      expect(
        (result.exitCode, (result.stdout as String).trim()),
        (0, 'No layer rule violations.'),
        reason: '${result.stderr}',
      );
    });

    test('exits 1 and lists every violation, nested files included', () async {
      // 1. Arrange
      writeLib(
        'a/b/c/c_view_model.dart',
        "import 'package:flutter/material.dart';\n",
      );
      writeLib(
        'z_state.dart',
        "$marker\nexport 'package:flutter/widgets.dart';\n",
      );
      writeLib('m/model.dart', "import 'package:get/get.dart';\n");
      writeLib('m/model.g.dart', "import 'package:get/get.dart';\n");

      // 2. Act
      final result = await runTool();

      // 3. Assert
      expect(result.exitCode, 1);
      expect(
        result.stderr,
        allOf(
          contains(p.join('lib', 'a', 'b', 'c', 'c_view_model.dart')),
          contains(p.join('lib', 'z_state.dart')),
          contains('${p.join('lib', 'm', 'model.dart')}:1:8'),
          isNot(contains('model.g.dart')),
          contains(libImportsGet),
          contains(stateImportsFlutterUi),
          contains('3 violation(s) found.'),
        ),
      );
    });
  });
}
