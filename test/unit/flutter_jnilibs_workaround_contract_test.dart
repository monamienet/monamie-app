import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Contract of the `merge<Variant>JniLibFolders` workaround in
/// `android/app/build.gradle.kts`.
///
/// Flutter < 3.47 stages `libapp.so` in
/// `build/app/intermediates/flutter/<variant>/jniLibs`, which AGP 9 merges
/// without tracking it as an input of `merge<Variant>JniLibFolders`. The
/// workaround adds that folder as an input; it must stay while the CI pins a
/// Flutter version below [flutterFixVersion] and be removed once the pin
/// reaches it (issue #57).

const gradlePath = 'android/app/build.gradle.kts';
const ciWorkflowPath = '.github/workflows/deploy-play-internal.yml';

/// First Flutter release that tracks the staged jniLibs folder itself
/// (flutter/flutter#188119).
const flutterFixVersion = '3.47.0';

/// Flutter plugin sources, relative to the Flutter SDK root.
const flutterPluginRelativePath =
    'packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt';
const flutterPluginConstantsRelativePath =
    'packages/flutter_tools/gradle/src/main/kotlin/FlutterPluginConstants.kt';

/// Placeholder used to compare staging paths written in different syntaxes.
const variantPlaceholder = '<variant>';

/// Code fragments that together make up the workaround in the Gradle script.
const jniLibsWorkaroundMarkers = <String>{
  r'Regex("^merge(\\w+)JniLibFolders$")',
  r'intermediates/flutter/$variant/jniLibs',
  'withPropertyName("flutterJniLibs")',
  'PathSensitivity.RELATIVE',
};

/// Mirrors the Gradle workaround: maps a `merge<Variant>JniLibFolders` task
/// name to its variant name with the first character lowercased, or returns
/// null when [taskName] is not such a task.
String? variantFromMergeJniLibFoldersTask(String taskName) {
  final match = RegExp(r'^merge(\w+)JniLibFolders$').firstMatch(taskName);
  if (match == null) return null;
  final capitalized = match.group(1)!;
  return capitalized[0].toLowerCase() + capitalized.substring(1);
}

/// Returns the first `flutter-version:` value of a GitHub workflow, without
/// quotes, or null when no uncommented declaration exists.
String? parseCiFlutterVersion(String workflowYaml) {
  final match = RegExp(
    r'''^\s*flutter-version:\s*['"]?([^'"\s#]+)['"]?''',
    multiLine: true,
  ).firstMatch(workflowYaml);
  return match?.group(1);
}

/// Compares two stable Flutter versions (`x.y.z`), returning a negative
/// number, zero or a positive number like [Comparable.compareTo].
///
/// Throws a [FormatException] for anything else (prereleases such as
/// `3.47.0-0.1.pre`, channel names, blanks): whether a prerelease already
/// carries the upstream fix is unknown, so the contract refuses to guess.
int compareFlutterVersions(String a, String b) {
  List<int> parse(String version) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(version);
    if (match == null) {
      throw FormatException('Not a stable Flutter version (x.y.z)', version);
    }
    return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
  }

  final left = parse(a);
  final right = parse(b);
  for (var i = 0; i < 3; i++) {
    final diff = left[i].compareTo(right[i]);
    if (diff != 0) return diff;
  }
  return 0;
}

/// Removes `//` line comments so commented-out code does not count.
String stripKotlinLineComments(String source) => source
    .split('\n')
    .map((line) {
      final index = line.indexOf('//');
      return index < 0 ? line : line.substring(0, index);
    })
    .join('\n');

/// Returns the [jniLibsWorkaroundMarkers] present in uncommented code of
/// [gradleSource].
Set<String> findJniLibsWorkaroundMarkers(String gradleSource) {
  final code = stripKotlinLineComments(gradleSource);
  return jniLibsWorkaroundMarkers.where(code.contains).toSet();
}

/// Returns the jniLibs folder the workaround tracks, relative to the build
/// directory, with the variant replaced by [variantPlaceholder]; null when
/// the script declares no such input.
String? workaroundStagingPath(String gradleSource) {
  final match = RegExp(
    r'layout\.buildDirectory\.dir\("([^"]*/jniLibs)"\)',
  ).firstMatch(stripKotlinLineComments(gradleSource));
  return match
      ?.group(1)!
      .replaceAll(RegExp(r'\$\{?variant\}?'), variantPlaceholder);
}

/// Returns the value of `const val <name> = "..."` in a Kotlin source, or
/// null when absent.
String? parseKotlinStringConst(String kotlinSource, String name) {
  final match = RegExp(
    'const\\s+val\\s+${RegExp.escape(name)}\\s*=\\s*"([^"]*)"',
  ).firstMatch(kotlinSource);
  return match?.group(1);
}

/// Returns the per-variant jniLibs staging folder written by the Flutter
/// Gradle plugin, relative to the build directory, with the variant replaced
/// by [variantPlaceholder]; null when the plugin has no such path.
String? pluginStagingPath(
  String pluginSource, {
  required String intermediatesDir,
}) {
  final match = RegExp(
    r'"\$\{FlutterPluginConstants\.INTERMEDIATES_DIR\}/flutter/\$\{variant\.name\}/jniLibs"',
  ).firstMatch(pluginSource);
  if (match == null) return null;
  return '$intermediatesDir/flutter/$variantPlaceholder/jniLibs';
}

/// Returns the first ancestor (inclusive) of any of [startPaths] that
/// contains [flutterPluginRelativePath] according to [fileExists], or null.
String? findFlutterRoot(
  List<String> startPaths,
  bool Function(String path) fileExists,
) {
  for (final start in startPaths) {
    var current = p.normalize(start);
    while (true) {
      if (fileExists(p.join(current, flutterPluginRelativePath))) {
        return current;
      }
      final parent = p.dirname(current);
      if (parent == current) break;
      current = parent;
    }
  }
  return null;
}

/// Flutter SDK running the tests: `FLUTTER_ROOT` when set, otherwise the
/// ancestors of the test VM executable (under `<root>/bin/cache/`).
String? installedFlutterRoot() => findFlutterRoot([
  ?Platform.environment['FLUTTER_ROOT'],
  Platform.resolvedExecutable,
], (path) => File(path).existsSync());

void main() {
  group('variantFromMergeJniLibFoldersTask - Unit Test Suite', () {
    test('Happy Path: maps a flavored release merge task to its variant', () {
      // 1. Arrange
      const taskName = 'mergeAquariusturReleaseJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, 'aquariusturRelease');
    });

    test('Happy Path: maps a flavored debug merge task to its variant', () {
      // 1. Arrange
      const taskName = 'mergeAquariusturDebugJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, 'aquariusturDebug');
    });

    test('Edge Case: maps an unflavored merge task to the build type', () {
      // 1. Arrange
      const taskName = 'mergeReleaseJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, 'release');
    });

    test('Edge Case: maps an androidTest merge task to its test variant', () {
      // 1. Arrange
      const taskName = 'mergeAquariusturDebugAndroidTestJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, 'aquariusturDebugAndroidTest');
    });

    test('Edge Case: lowercases only the first character of the variant', () {
      // 1. Arrange
      const taskName = 'mergeAcmeProfileJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, 'acmeProfile');
    });

    test('Edge Case: maps a single-character variant', () {
      // 1. Arrange
      const taskName = 'mergeXJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, 'x');
    });

    test('Sad Path: ignores the native-libs merge task', () {
      // 1. Arrange
      const taskName = 'mergeAquariusturReleaseNativeLibs';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, isNull);
    });

    test('Sad Path: ignores a merge task without a variant', () {
      // 1. Arrange
      const taskName = 'mergeJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, isNull);
    });

    test('Sad Path: ignores a lowercase task name (match is case '
        'sensitive)', () {
      // 1. Arrange
      const taskName = 'mergeaquariusturreleasejnilibfolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, isNull);
    });

    test('Sad Path: ignores a name with a prefix before "merge"', () {
      // 1. Arrange
      const taskName = 'premergeAquariusturReleaseJniLibFolders';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, isNull);
    });

    test('Sad Path: ignores an empty task name', () {
      // 1. Arrange
      const taskName = '';

      // 2. Act
      final variant = variantFromMergeJniLibFoldersTask(taskName);

      // 3. Assert
      expect(variant, isNull);
    });
  });

  group('parseCiFlutterVersion - Unit Test Suite', () {
    test('Happy Path: reads a single-quoted version', () {
      // 1. Arrange
      const yaml = '''
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.4'
          channel: stable
''';

      // 2. Act
      final version = parseCiFlutterVersion(yaml);

      // 3. Assert
      expect(version, '3.44.4');
    });

    test('Edge Case: reads a double-quoted version', () {
      // 1. Arrange
      const yaml = '        with:\n          flutter-version: "3.47.0"\n';

      // 2. Act
      final version = parseCiFlutterVersion(yaml);

      // 3. Assert
      expect(version, '3.47.0');
    });

    test('Edge Case: reads an unquoted version followed by a comment', () {
      // 1. Arrange
      const yaml = '          flutter-version: 3.44.4 # pinned\n';

      // 2. Act
      final version = parseCiFlutterVersion(yaml);

      // 3. Assert
      expect(version, '3.44.4');
    });

    test('Edge Case: ignores a commented-out declaration', () {
      // 1. Arrange
      const yaml = '''
          # flutter-version: '3.47.0'
          flutter-version: '3.44.4'
''';

      // 2. Act
      final version = parseCiFlutterVersion(yaml);

      // 3. Assert
      expect(version, '3.44.4');
    });

    test('Sad Path: returns null for a workflow without flutter-version', () {
      // 1. Arrange
      const yaml = '''
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
''';

      // 2. Act
      final version = parseCiFlutterVersion(yaml);

      // 3. Assert
      expect(version, isNull);
    });
  });

  group('compareFlutterVersions - Unit Test Suite', () {
    test('Happy Path: 3.44.4 is older than 3.47.0', () {
      // 1. Arrange
      const pinned = '3.44.4';

      // 2. Act
      final result = compareFlutterVersions(pinned, flutterFixVersion);

      // 3. Assert
      expect(result, isNegative);
    });

    test('Happy Path: 3.48.1 is newer than 3.47.0', () {
      // 1. Arrange
      const pinned = '3.48.1';

      // 2. Act
      final result = compareFlutterVersions(pinned, flutterFixVersion);

      // 3. Assert
      expect(result, isPositive);
    });

    test('Edge Case: equal versions compare as zero', () {
      // 1. Arrange
      const pinned = '3.47.0';

      // 2. Act
      final result = compareFlutterVersions(pinned, flutterFixVersion);

      // 3. Assert
      expect(result, 0);
    });

    test('Edge Case: compares components numerically, not as text', () {
      // 1. Arrange
      const pinned = '3.100.0';

      // 2. Act
      final result = compareFlutterVersions(pinned, flutterFixVersion);

      // 3. Assert
      expect(result, isPositive);
    });

    test('Edge Case: a higher major wins over lower minor and patch', () {
      // 1. Arrange
      const pinned = '4.0.0';

      // 2. Act
      final result = compareFlutterVersions(pinned, '3.99.99');

      // 3. Assert
      expect(result, isPositive);
    });

    test('Sad Path: rejects a prerelease version', () {
      // 1. Arrange
      const pinned = '3.47.0-0.1.pre';

      // 2. Act
      int action() => compareFlutterVersions(pinned, flutterFixVersion);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: rejects a version with missing components', () {
      // 1. Arrange
      const pinned = '3.47';

      // 2. Act
      int action() => compareFlutterVersions(pinned, flutterFixVersion);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: rejects a channel name', () {
      // 1. Arrange
      const pinned = 'stable';

      // 2. Act
      int action() => compareFlutterVersions(pinned, flutterFixVersion);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });

    test('Sad Path: rejects an empty version', () {
      // 1. Arrange
      const pinned = '';

      // 2. Act
      int action() => compareFlutterVersions(flutterFixVersion, pinned);

      // 3. Assert
      expect(action, throwsA(isA<FormatException>()));
    });
  });

  group('Gradle source helpers - Unit Test Suite', () {
    const workaroundFixture = r'''
val mergeJniLibFoldersTask = Regex("^merge(\\w+)JniLibFolders$")

tasks.configureEach {
    val variant = mergeJniLibFoldersTask.matchEntire(name)?.groupValues?.get(1)
        ?.replaceFirstChar { it.lowercase() }
        ?: return@configureEach
    inputs.files(layout.buildDirectory.dir("intermediates/flutter/$variant/jniLibs"))
        .withPropertyName("flutterJniLibs")
        .withPathSensitivity(PathSensitivity.RELATIVE)
}
''';

    test('Happy Path: finds every marker of the workaround', () {
      // 1. Arrange
      const gradleSource = workaroundFixture;

      // 2. Act
      final markers = findJniLibsWorkaroundMarkers(gradleSource);

      // 3. Assert
      expect(markers, jniLibsWorkaroundMarkers);
    });

    test('Happy Path: reads the tracked staging path with a placeholder', () {
      // 1. Arrange
      const gradleSource = workaroundFixture;

      // 2. Act
      final path = workaroundStagingPath(gradleSource);

      // 3. Assert
      expect(path, 'intermediates/flutter/<variant>/jniLibs');
    });

    test(r'Edge Case: reads a staging path written as ${variant}', () {
      // 1. Arrange
      const gradleSource =
          r'inputs.files(layout.buildDirectory.dir("intermediates/flutter/${variant}/jniLibs"))';

      // 2. Act
      final path = workaroundStagingPath(gradleSource);

      // 3. Assert
      expect(path, 'intermediates/flutter/<variant>/jniLibs');
    });

    test('Edge Case: finds no marker in a fully commented-out workaround', () {
      // 1. Arrange
      final gradleSource = workaroundFixture
          .split('\n')
          .map((line) => '// $line')
          .join('\n');

      // 2. Act
      final markers = findJniLibsWorkaroundMarkers(gradleSource);

      // 3. Assert
      expect(markers, isEmpty);
    });

    test('Sad Path: reports a partial workaround as missing markers', () {
      // 1. Arrange
      final gradleSource = workaroundFixture.replaceAll(
        '.withPropertyName("flutterJniLibs")',
        '',
      );

      // 2. Act
      final markers = findJniLibsWorkaroundMarkers(gradleSource);

      // 3. Assert
      expect(markers, isNot(contains('withPropertyName("flutterJniLibs")')));
    });

    test('Sad Path: returns null for a script without the input', () {
      // 1. Arrange
      const gradleSource = 'android {\n    compileSdk = 36\n}';

      // 2. Act
      final path = workaroundStagingPath(gradleSource);

      // 3. Assert
      expect(path, isNull);
    });
  });

  group('Flutter plugin source helpers - Unit Test Suite', () {
    test('Happy Path: reads the per-variant staging path of the plugin', () {
      // 1. Arrange
      const pluginSource = r'''
            val jniLibsDir =
                project.layout.buildDirectory.dir(
                    "${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter/${variant.name}/jniLibs"
                )
''';

      // 2. Act
      final path = pluginStagingPath(
        pluginSource,
        intermediatesDir: 'intermediates',
      );

      // 3. Assert
      expect(path, 'intermediates/flutter/<variant>/jniLibs');
    });

    test('Happy Path: reads a Kotlin string constant', () {
      // 1. Arrange
      const constantsSource =
          'object FlutterPluginConstants {\n'
          '    const val INTERMEDIATES_DIR = "intermediates"\n}';

      // 2. Act
      final value = parseKotlinStringConst(
        constantsSource,
        'INTERMEDIATES_DIR',
      );

      // 3. Assert
      expect(value, 'intermediates');
    });

    test('Edge Case: ignores the per-source-set path of the plugin', () {
      // 1. Arrange
      const pluginSource = r'''
                    "${FlutterPluginConstants.INTERMEDIATES_DIR}/flutter/${sourceSet.name}/jniLibs"
''';

      // 2. Act
      final path = pluginStagingPath(
        pluginSource,
        intermediatesDir: 'intermediates',
      );

      // 3. Assert
      expect(path, isNull);
    });

    test('Edge Case: finds the Flutter root from the test VM executable', () {
      // 1. Arrange
      const root = '/sdk/flutter';
      const executable =
          '$root/bin/cache/artifacts/engine/linux-x64/flutter_tester';
      bool exists(String path) => path == '$root/$flutterPluginRelativePath';

      // 2. Act
      final found = findFlutterRoot([executable], exists);

      // 3. Assert
      expect(found, root);
    });

    test('Edge Case: prefers the first start path that has the plugin', () {
      // 1. Arrange
      bool exists(String path) =>
          path == '/a/flutter/$flutterPluginRelativePath' ||
          path == '/b/flutter/$flutterPluginRelativePath';

      // 2. Act
      final found = findFlutterRoot([
        '/a/flutter',
        '/b/flutter/bin/cache/dart-sdk/bin/dart',
      ], exists);

      // 3. Assert
      expect(found, '/a/flutter');
    });

    test('Sad Path: returns null when no ancestor has the plugin', () {
      // 1. Arrange
      bool exists(String path) => false;

      // 2. Act
      final found = findFlutterRoot(['/usr/lib/dart/bin/dart'], exists);

      // 3. Assert
      expect(found, isNull);
    });

    test('Sad Path: returns null for a missing Kotlin constant', () {
      // 1. Arrange
      const constantsSource = 'object FlutterPluginConstants {}';

      // 2. Act
      final value = parseKotlinStringConst(
        constantsSource,
        'INTERMEDIATES_DIR',
      );

      // 3. Assert
      expect(value, isNull);
    });
  });

  group('Flutter jniLibs workaround - Repo Contract Test Suite', () {
    late String gradleSource;
    late String ciFlutterVersion;

    setUp(() {
      gradleSource = File(gradlePath).readAsStringSync();
      ciFlutterVersion = parseCiFlutterVersion(
        File(ciWorkflowPath).readAsStringSync(),
      )!;
    });

    test('Happy Path: the CI pins a stable Flutter version', () {
      // 1. Arrange
      final workflow = File(ciWorkflowPath).readAsStringSync();

      // 2. Act
      final version = parseCiFlutterVersion(workflow);

      // 3. Assert
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('Happy Path: build.gradle.kts keeps the workaround while the CI '
        'Flutter is older than $flutterFixVersion', () {
      // 1. Arrange
      final needsWorkaround =
          compareFlutterVersions(ciFlutterVersion, flutterFixVersion) < 0;

      // 2. Act
      final markers = findJniLibsWorkaroundMarkers(gradleSource);

      // 3. Assert
      expect(
        markers,
        needsWorkaround ? jniLibsWorkaroundMarkers : anything,
        reason:
            'CI Flutter $ciFlutterVersion stages libapp.so without AGP '
            'tracking it; keep the merge<Variant>JniLibFolders workaround',
      );
    });

    test('Sad Path: build.gradle.kts drops the workaround once the CI '
        'Flutter reaches $flutterFixVersion (issue #57)', () {
      // 1. Arrange
      final fixedUpstream =
          compareFlutterVersions(ciFlutterVersion, flutterFixVersion) >= 0;

      // 2. Act
      final markers = findJniLibsWorkaroundMarkers(gradleSource);

      // 3. Assert
      expect(
        markers,
        fixedUpstream ? isEmpty : anything,
        reason:
            'CI Flutter $ciFlutterVersion already tracks the staged jniLibs '
            '(flutter/flutter#188119); remove the workaround (issue #57)',
      );
    });

    test('Happy Path: the tracked folder is the one the installed Flutter '
        'plugin stages libapp.so in', () {
      // 1. Arrange
      if (compareFlutterVersions(ciFlutterVersion, flutterFixVersion) >= 0) {
        markTestSkipped(
          'CI Flutter $ciFlutterVersion no longer needs the workaround',
        );
        return;
      }
      final flutterRoot = installedFlutterRoot();
      if (flutterRoot == null) {
        markTestSkipped(
          'Flutter SDK sources not found from FLUTTER_ROOT or '
          '${Platform.resolvedExecutable}',
        );
        return;
      }
      final pluginSource = File(
        p.join(flutterRoot, flutterPluginRelativePath),
      ).readAsStringSync();
      final constantsFile = File(
        p.join(flutterRoot, flutterPluginConstantsRelativePath),
      );
      final intermediatesDir = constantsFile.existsSync()
          ? parseKotlinStringConst(
              constantsFile.readAsStringSync(),
              'INTERMEDIATES_DIR',
            )
          : null;
      if (intermediatesDir == null) {
        markTestSkipped('INTERMEDIATES_DIR not found in ${constantsFile.path}');
        return;
      }
      final expected = pluginStagingPath(
        pluginSource,
        intermediatesDir: intermediatesDir,
      );

      // 2. Act
      final tracked = workaroundStagingPath(gradleSource);

      // 3. Assert
      expect(tracked, allOf(isNotNull, expected));
    });

    test('Edge Case: the installed Flutter plugin names the merge task as '
        'the workaround expects', () {
      // 1. Arrange
      final flutterRoot = installedFlutterRoot();
      if (flutterRoot == null) {
        markTestSkipped(
          'Flutter SDK sources not found from FLUTTER_ROOT or '
          '${Platform.resolvedExecutable}',
        );
        return;
      }
      final pluginSource = File(
        p.join(flutterRoot, flutterPluginRelativePath),
      ).readAsStringSync();

      // 2. Act
      final declaresTaskName = pluginSource.contains(
        r'"merge${FlutterPluginUtils.capitalize(variant.name)}JniLibFolders"',
      );

      // 3. Assert
      expect(declaresTaskName, isTrue);
    });
  });
}
