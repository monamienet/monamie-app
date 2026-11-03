import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/src/state_layer_imports.dart';
import '../../../tool/src/ui_text_literals.dart' show uiHardCodedText;

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

  group('findLayerViolations: ui_imports_plugin', () {
    const pluginUris = [
      'package:geolocator/geolocator.dart',
      'package:permission_handler/permission_handler.dart',
      'package:flutter_background_service/flutter_background_service.dart',
      'package:shared_preferences/shared_preferences.dart',
      'package:google_sign_in/google_sign_in.dart',
      'package:http/http.dart',
      'package:firebase_core/firebase_core.dart',
      'package:firebase_auth/firebase_auth.dart',
      'package:cloud_firestore/cloud_firestore.dart',
      'package:cloud_functions/cloud_functions.dart',
      'package:hive/hive.dart',
      'package:hive_flutter/hive_flutter.dart',
    ];

    for (final path in [
      'lib/ui/x/widgets/x_screen.dart',
      'lib/domain/models/x.dart',
      r'lib\ui\x\widgets\x_screen.dart',
    ]) {
      for (final uri in pluginUris) {
        test('$uri under $path is a violation', () {
          // 1. Arrange
          final content = "import '$uri';\n";

          // 2. Act
          final result = findLayerViolations(path, content);

          // 3. Assert
          expect(result.map((v) => (v.uri, v.rule)), [(uri, uiImportsPlugin)]);
        });
      }
    }

    test('an export of a plugin under lib/ui/ is a violation', () {
      // 1. Arrange
      const content =
          "export 'package:geolocator/geolocator.dart' show Position;\n";

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x.dart', content);

      // 3. Assert
      expect(result.single.rule, uiImportsPlugin);
    });

    for (final path in [
      'lib/data/services/x_service.dart',
      'lib/routing/router.dart',
      'lib/config/dependencies.dart',
      'lib/main.dart',
      'lib/ui/x/x.g.dart',
      'lib/domain/models/x.freezed.dart',
      'lib/ui/x/x_view_model.mocks.dart',
      'test/ui/x/x_test.dart',
      'tool/x.dart',
    ]) {
      test('a plugin is allowed outside lib/ui/ and lib/domain/ sources: '
          '$path', () {
        // 1. Arrange
        const content =
            "import 'package:cloud_firestore/cloud_firestore.dart';\n";

        // 2. Act
        final result = findLayerViolations(path, content);

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    for (final uri in [
      'package:google_sign_in_web/web_only.dart',
      'package:http_parser/http_parser.dart',
      'package:geolocator_android/geolocator_android.dart',
      'package:firebase/firebase.dart',
      'package:latlong2/latlong.dart',
      'package:flutter_map/flutter_map.dart',
      'package:monamie_app/data/services/firestore/membership_service.dart',
      'cloud_firestore/cloud_firestore.dart',
    ]) {
      test('a URI that is not one of the wrapped plugins is allowed: $uri', () {
        // 1. Arrange
        final content = "import '$uri';\n";

        // 2. Act
        final result = findLayerViolations(
          'lib/ui/x/widgets/x_screen.dart',
          content,
        );

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    test('a plugin as the default URI of a conditional import is reported', () {
      // 1. Arrange
      const content = '''
import 'package:shared_preferences/shared_preferences.dart'
    if (dart.library.js_interop) 'src/web_stub.dart';
''';

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x.dart', content);

      // 3. Assert
      expect(
        (result.single.uri, result.single.rule),
        ('package:shared_preferences/shared_preferences.dart', uiImportsPlugin),
      );
    });

    test('a plugin in a conditional branch is reported at the branch', () {
      // 1. Arrange
      const content = """
import 'src/stub.dart'
    if (dart.library.io) 'package:hive/hive.dart';
""";

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x.dart', content);

      // 3. Assert
      expect(
        (result.single.line, result.single.column, result.single.rule),
        (2, 26, uiImportsPlugin),
      );
    });

    test('a plugin import inside a comment is not a violation', () {
      // 1. Arrange
      const content = """
// import 'package:geolocator/geolocator.dart';
/* import 'package:hive/hive.dart'; */
""";

      // 2. Act
      final result = findLayerViolations('lib/ui/x/x.dart', content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('a view model importing material and a plugin reports both', () {
      // 1. Arrange
      const content = '''
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
''';

      // 2. Act
      final result = findLayerViolations(viewModelPath, content);

      // 3. Assert
      expect(result.map((v) => (v.line, v.rule)), [
        (1, stateImportsFlutterUi),
        (2, uiImportsPlugin),
      ]);
    });

    test('the plugin message names the file, position, URI and rule', () {
      // 1. Arrange
      const path = 'lib/ui/x/widgets/x_screen.dart';
      const content =
          "import 'dart:async';\nimport 'package:hive/hive.dart';\n";

      // 2. Act
      final message = findLayerViolations(path, content).single.toString();

      // 3. Assert
      expect(
        message,
        allOf(
          startsWith('$path:2:8 - Files under lib/ui/ and lib/domain/ must '),
          contains("'package:hive/hive.dart'"),
          contains('lib/data/'),
          endsWith(' - $uiImportsPlugin'),
        ),
      );
    });
  });

  group('isPluginUri', () {
    test('a wrapped plugin package is a plugin', () {
      // 1. Arrange
      const uri = 'package:permission_handler/permission_handler.dart';

      // 2. Act
      final result = isPluginUri(uri);

      // 3. Assert
      expect(result, isTrue);
    });

    test('a package starting with a plugin prefix is a plugin', () {
      // 1. Arrange
      const uri = 'package:firebase_storage/firebase_storage.dart';

      // 2. Act
      final result = isPluginUri(uri);

      // 3. Assert
      expect(result, isTrue);
    });

    for (final uri in [
      'dart:io',
      'src/hive.dart',
      'package:geolocatorx/x.dart',
    ]) {
      test('$uri is not a plugin', () {
        // 1. Arrange (uri from the table)

        // 2. Act
        final result = isPluginUri(uri);

        // 3. Assert
        expect(result, isFalse);
      });
    }
  });

  group('findLayerViolations: domain_imports_outer', () {
    const domainPath = 'lib/domain/models/x.dart';

    for (final uri in [
      'package:monamie_app/data/services/firebase/firestore_paths.dart',
      'package:monamie_app/ui/core/ui/notice_presenter.dart',
      'package:monamie_app/routing/routes.dart',
      'package:monamie_app/config/dependencies.dart',
    ]) {
      test('$uri in the domain is a violation', () {
        // 1. Arrange
        final content = "import '$uri';\n";

        // 2. Act
        final result = findLayerViolations(domainPath, content);

        // 3. Assert
        expect(result.map((v) => (v.uri, v.rule)), [(uri, domainImportsOuter)]);
      });
    }

    for (final (uri, label) in [
      ('../../data/model/organization_binding.dart', 'up to lib/data/'),
      ('../../ui/x/x.dart', 'up to lib/ui/'),
      ('../../../lib/routing/routes.dart', 'out of lib/ and back'),
      ('./../../config/dependencies.dart', 'starting with ./'),
    ]) {
      test('a relative import $label is a violation: $uri', () {
        // 1. Arrange
        final content = "import '$uri';\n";

        // 2. Act
        final result = findLayerViolations(domainPath, content);

        // 3. Assert
        expect(result.single.rule, domainImportsOuter);
      });
    }

    test('a package URI with `..` that leaves lib/domain/ is a violation', () {
      // 1. Arrange
      const uri = 'package:monamie_app/domain/../data/x.dart';
      const content = "import '$uri';\n";

      // 2. Act
      final result = findLayerViolations(domainPath, content);

      // 3. Assert
      expect(result.map((v) => (v.uri, v.rule)), [(uri, domainImportsOuter)]);
    });

    test(
      'a package URI with `..` that stays inside lib/domain/ is allowed',
      () {
        // 1. Arrange
        const content =
            "import 'package:monamie_app/domain/models/../models/x.dart';\n";

        // 2. Act
        final result = findLayerViolations(domainPath, content);

        // 3. Assert
        expect(result, isEmpty);
      },
    );

    test('a relative import resolves from a Windows path', () {
      // 1. Arrange
      const content = "import '../../data/x.dart';\n";

      // 2. Act
      final result = findLayerViolations(r'lib\domain\models\x.dart', content);

      // 3. Assert
      expect(result.single.rule, domainImportsOuter);
    });

    for (final uri in [
      'package:monamie_app/domain/models/role_names.dart',
      'package:monamie_app/utils/result.dart',
      'package:monamie_app/main.dart',
      'role_names.dart',
      '../models/role_names.dart',
      '../../utils/result.dart',
      'package:freezed_annotation/freezed_annotation.dart',
      'package:flutter/foundation.dart',
      'package:monamie_app_extra/data/x.dart',
      'dart:ui',
    ]) {
      test('$uri is allowed in the domain', () {
        // 1. Arrange
        final content = "import '$uri';\n";

        // 2. Act
        final result = findLayerViolations(domainPath, content);

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    test('an outer layer as the default URI of a conditional import is '
        'reported', () {
      // 1. Arrange
      const content = '''
import 'package:monamie_app/data/x.dart'
    if (dart.library.io) 'x_io.dart';
''';

      // 2. Act
      final result = findLayerViolations(domainPath, content);

      // 3. Assert
      expect(result.single.rule, domainImportsOuter);
    });

    test('an outer layer in a conditional branch is reported there', () {
      // 1. Arrange
      const content = """
import 'x_stub.dart'
    if (dart.library.io) '../../data/x_io.dart';
""";

      // 2. Act
      final result = findLayerViolations(domainPath, content);

      // 3. Assert
      expect(
        (result.single.line, result.single.uri, result.single.rule),
        (2, '../../data/x_io.dart', domainImportsOuter),
      );
    });

    for (final path in [
      'lib/domain/models/x.freezed.dart',
      'lib/domain/models/x.g.dart',
      'lib/data/model/x.dart',
      'lib/ui/x/x.dart',
      'test/domain/models/x_test.dart',
    ]) {
      test('outer layers are allowed outside hand-written domain files: '
          '$path', () {
        // 1. Arrange
        const content =
            "import 'package:monamie_app/data/services/firebase/firestore_paths.dart';\n";

        // 2. Act
        final result = findLayerViolations(path, content);

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    test('a domain file importing a plugin reports the plugin rule only', () {
      // 1. Arrange
      const content = '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/data/x.dart';
''';

      // 2. Act
      final result = findLayerViolations(domainPath, content);

      // 3. Assert
      expect(result.map((v) => (v.line, v.rule)), [
        (1, uiImportsPlugin),
        (2, domainImportsOuter),
      ]);
    });

    test('the domain message names the file, position, URI and rule', () {
      // 1. Arrange
      const content = "import 'dart:async';\nexport '../../ui/x.dart';\n";

      // 2. Act
      final message = findLayerViolations(
        domainPath,
        content,
      ).single.toString();

      // 3. Assert
      expect(
        message,
        allOf(
          startsWith('$domainPath:2:8 - Files under lib/domain/ must not '),
          contains("'../../ui/x.dart'"),
          contains('depends on no other layer'),
          endsWith(' - $domainImportsOuter'),
        ),
      );
    });
  });

  group('findLayerViolations: domain_imports_outer (use cases)', () {
    const useCasePath = 'lib/domain/use_cases/x.dart';

    test('the use cases folder and its data folders are the documented '
        'ones', () {
      // 1. Arrange
      // 2. Act
      // 3. Assert
      expect(useCasesFolder, 'lib/domain/use_cases/');
      expect(useCaseDataFolders, [
        'lib/data/repositories/',
        'lib/data/services/',
        'lib/data/model/',
      ]);
    });

    for (final uri in [
      'package:monamie_app/data/repositories/session/session_repository.dart',
      'package:monamie_app/data/services/background_tracking_stopper.dart',
      'package:monamie_app/data/model/organization_binding.dart',
      '../../data/repositories/invites/invites_repository.dart',
      '../../data/services/firestore/membership_service.dart',
      '../../data/model/user_google_model.dart',
      './../../data/model/x.dart',
      '../models/invite.dart',
      'package:monamie_app/utils/result.dart',
    ]) {
      test('Happy Path: $uri is allowed in a use case', () {
        // 1. Arrange
        final content = "import '$uri';\n";

        // 2. Act
        final result = findLayerViolations(useCasePath, content);

        // 3. Assert
        expect(result, isEmpty);
      });
    }

    test('Happy Path: an export of a repository from a use case is '
        'allowed', () {
      // 1. Arrange
      const content =
          "export 'package:monamie_app/data/repositories/x/x.dart';\n";

      // 2. Act
      final result = findLayerViolations(useCasePath, content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Sad Path: a `..` package URI from a use case reaching the UI is a '
        'violation', () {
      // 1. Arrange
      const uri = 'package:monamie_app/data/repositories/../../ui/x.dart';
      const content = "import '$uri';\n";

      // 2. Act
      final result = findLayerViolations(useCasePath, content);

      // 3. Assert
      expect(result.map((v) => (v.uri, v.rule)), [(uri, domainImportsOuter)]);
    });

    test('Edge Case: a `..` package URI between data folders is allowed in a '
        'use case', () {
      // 1. Arrange
      const content =
          "import 'package:monamie_app/data/services/../repositories/x.dart';\n";

      // 2. Act
      final result = findLayerViolations(useCasePath, content);

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Edge Case: a use case in a subfolder may import the data layer', () {
      // 1. Arrange
      const content = "import '../../../data/model/x.dart';\n";

      // 2. Act
      final result = findLayerViolations(
        'lib/domain/use_cases/session/x.dart',
        content,
      );

      // 3. Assert
      expect(result, isEmpty);
    });

    test('Edge Case: a relative import resolves from a Windows path', () {
      // 1. Arrange
      const content = "import '../../data/repositories/x.dart';\n";

      // 2. Act
      final result = findLayerViolations(
        r'lib\domain\use_cases\x.dart',
        content,
      );

      // 3. Assert
      expect(result, isEmpty);
    });

    for (final uri in [
      'package:monamie_app/ui/core/ui/app_messenger.dart',
      'package:monamie_app/routing/routes.dart',
      'package:monamie_app/config/dependencies.dart',
      'package:monamie_app/data/x.dart',
      'package:monamie_app/data/repositories_extra/x.dart',
      'package:monamie_app/data/models/x.dart',
      '../../ui/x/x.dart',
      '../../routing/routes.dart',
      '../../data/repositories/../../ui/x.dart',
      '../../data/x.dart',
    ]) {
      test('Sad Path: $uri in a use case is a violation', () {
        // 1. Arrange
        final content = "import '$uri';\n";

        // 2. Act
        final result = findLayerViolations(useCasePath, content);

        // 3. Assert
        expect(result.map((v) => (v.uri, v.rule)), [(uri, domainImportsOuter)]);
      });
    }

    for (final path in [
      'lib/domain/models/x.dart',
      'lib/domain/x.dart',
      'lib/domain/use_cases_extra/x.dart',
      'lib/domain/models/use_cases/x.dart',
    ]) {
      test('Sad Path: the data layer stays forbidden outside the use cases: '
          '$path', () {
        // 1. Arrange
        const content =
            "import 'package:monamie_app/data/repositories/x/x.dart';\n";

        // 2. Act
        final result = findLayerViolations(path, content);

        // 3. Assert
        expect(result.single.rule, domainImportsOuter);
      });
    }

    test('Sad Path: a use case importing a plugin still breaks the plugin '
        'rule', () {
      // 1. Arrange
      const content = """
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/data/repositories/x/x.dart';
""";

      // 2. Act
      final result = findLayerViolations(useCasePath, content);

      // 3. Assert
      expect(result.map((v) => (v.line, v.rule)), [(1, uiImportsPlugin)]);
    });

    test('Sad Path: a use case importing the UI is reported with the use '
        'case exception in the message', () {
      // 1. Arrange
      const content = "import '../../ui/x.dart';\n";

      // 2. Act
      final message = findLayerViolations(
        useCasePath,
        content,
      ).single.toString();

      // 3. Assert
      expect(
        message,
        allOf(
          startsWith('$useCasePath:1:8 - Files under lib/domain/ must not '),
          contains('lib/domain/use_cases/'),
          endsWith(' - $domainImportsOuter'),
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
        'src/ui_text_literals.dart',
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
        (0, 'No layer or text rule violations.'),
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

    test(
      'exits 1 for a plugin in the UI and an outer layer in the domain',
      () async {
        // 1. Arrange
        writeLib('ui/a/a_screen.dart', "import 'package:hive/hive.dart';\n");
        writeLib('domain/b.dart', "import '../data/c.dart';\n");
        writeLib('data/c.dart', "import 'package:hive/hive.dart';\n");

        // 2. Act
        final result = await runTool();

        // 3. Assert
        expect(result.exitCode, 1);
        expect(
          result.stderr,
          allOf(
            contains('${p.join('lib', 'ui', 'a', 'a_screen.dart')}:1:8'),
            contains('${p.join('lib', 'domain', 'b.dart')}:1:8'),
            isNot(contains(p.join('lib', 'data', 'c.dart'))),
            contains(uiImportsPlugin),
            contains(domainImportsOuter),
            contains('2 violation(s) found.'),
          ),
        );
      },
    );
    test('exits 1 for a hard-coded text in a screen under lib/ui/', () async {
      // 1. Arrange
      writeLib(
        'ui/a/a_screen.dart',
        "import 'package:flutter/widgets.dart';\n"
            "Widget f() => const Text('Olá');\n",
      );
      writeLib('ui/a/a_view_model.dart', "const String m = 'Olá';\n");

      // 2. Act
      final result = await runTool();

      // 3. Assert
      expect(result.exitCode, 1);
      expect(
        result.stderr,
        allOf(
          contains('${p.join('lib', 'ui', 'a', 'a_screen.dart')}:2:26'),
          isNot(contains('a_view_model.dart')),
          contains(uiHardCodedText),
          contains('1 violation(s) found.'),
        ),
      );
    });
  });
}
