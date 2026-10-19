import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Partner-neutral Kotlin package shared by every partner flavor (issue #30).
const neutralNamespace = 'org.monamienet.app';

/// Partner-specific namespace that must no longer appear in Android sources.
const legacyNamespace = 'org.monamienet.aquariustur';

const gradlePath = 'android/app/build.gradle.kts';
const mainActivityPath =
    'android/app/src/main/kotlin/org/monamienet/app/MainActivity.kt';
const androidSrcDir = 'android/app/src';

/// Returns the `namespace = "..."` value of a Gradle Kotlin DSL script, or
/// null when no uncommented declaration exists.
String? extractGradleNamespace(String gradleSource) {
  final match = RegExp(
    r'^\s*namespace\s*=\s*"([^"]+)"',
    multiLine: true,
  ).firstMatch(gradleSource);
  return match?.group(1);
}

/// Returns the `package` declared by a Kotlin source, or null when absent.
String? extractKotlinPackage(String kotlinSource) {
  final match = RegExp(
    r'^\s*package\s+([A-Za-z_][\w.]*)',
    multiLine: true,
  ).firstMatch(kotlinSource);
  return match?.group(1);
}

/// Derives the package implied by a file location under `src/main/kotlin/`,
/// or null when the path is outside that source root.
String? packageFromKotlinPath(String path) {
  const root = 'src/main/kotlin/';
  final normalized = path.replaceAll(r'\', '/');
  final index = normalized.indexOf(root);
  if (index < 0) return null;
  final segments = normalized.substring(index + root.length).split('/')
    ..removeLast();
  return segments.join('.');
}

/// Returns the sorted paths whose content contains [needle].
List<String> findFilesReferencing(Map<String, String> files, String needle) {
  return files.entries
      .where((entry) => entry.value.contains(needle))
      .map((entry) => entry.key)
      .toList()
    ..sort();
}

void main() {
  group('Android partner-neutral namespace - Contract Test Suite', () {
    // -------------------------------------------------------------
    // HAPPY PATH
    // -------------------------------------------------------------
    test('Happy Path: build.gradle.kts declares the neutral namespace', () {
      // 1. Arrange
      final gradleSource = File(gradlePath).readAsStringSync();

      // 2. Act
      final namespace = extractGradleNamespace(gradleSource);

      // 3. Assert
      expect(namespace, neutralNamespace);
    });

    test('Happy Path: MainActivity.kt package equals the Gradle namespace', () {
      // 1. Arrange
      final namespace = extractGradleNamespace(
        File(gradlePath).readAsStringSync(),
      );
      final kotlinSource = File(mainActivityPath).readAsStringSync();

      // 2. Act
      final package = extractKotlinPackage(kotlinSource);

      // 3. Assert
      expect(package, namespace);
    });

    test('Happy Path: MainActivity.kt folder matches its declared package', () {
      // 1. Arrange
      final declaredPackage = extractKotlinPackage(
        File(mainActivityPath).readAsStringSync(),
      );

      // 2. Act
      final folderPackage = packageFromKotlinPath(mainActivityPath);

      // 3. Assert
      expect(folderPackage, allOf(neutralNamespace, declaredPackage));
    });

    test('Happy Path: no file under android/app/src references the legacy '
        'partner namespace', () {
      // 1. Arrange
      final files = <String, String>{
        for (final file in Directory(
          androidSrcDir,
        ).listSync(recursive: true).whereType<File>())
          file.path: utf8.decode(file.readAsBytesSync(), allowMalformed: true),
      };

      // 2. Act
      final offenders = findFilesReferencing(files, legacyNamespace);

      // 3. Assert
      expect(offenders, isEmpty);
    });

    // -------------------------------------------------------------
    // EDGE CASES
    // -------------------------------------------------------------
    test('Edge Case: reads a namespace declared without spaces around "="', () {
      // 1. Arrange
      const gradleSource = 'android {\n    namespace="org.monamienet.app"\n}';

      // 2. Act
      final namespace = extractGradleNamespace(gradleSource);

      // 3. Assert
      expect(namespace, 'org.monamienet.app');
    });

    test('Edge Case: ignores a commented-out namespace line', () {
      // 1. Arrange
      const gradleSource = '''
android {
    // namespace = "org.monamienet.aquariustur"
    namespace = "org.monamienet.app"
}
''';

      // 2. Act
      final namespace = extractGradleNamespace(gradleSource);

      // 3. Assert
      expect(namespace, 'org.monamienet.app');
    });

    test('Edge Case: reads a Kotlin package after a header comment', () {
      // 1. Arrange
      const kotlinSource = '''
/*
 * Copyright MonAmieNet.
 */

package org.monamienet.app

class MainActivity
''';

      // 2. Act
      final package = extractKotlinPackage(kotlinSource);

      // 3. Assert
      expect(package, 'org.monamienet.app');
    });

    test('Edge Case: scanning an empty file set reports no references', () {
      // 1. Arrange
      final files = <String, String>{};

      // 2. Act
      final offenders = findFilesReferencing(files, legacyNamespace);

      // 3. Assert
      expect(offenders, isEmpty);
    });

    // -------------------------------------------------------------
    // SAD PATH
    // -------------------------------------------------------------
    test('Sad Path: returns null for a Gradle script without namespace', () {
      // 1. Arrange
      const gradleSource = 'android {\n    compileSdk = 35\n}';

      // 2. Act
      final namespace = extractGradleNamespace(gradleSource);

      // 3. Assert
      expect(namespace, isNull);
    });

    test('Sad Path: returns null for a Kotlin file without package', () {
      // 1. Arrange
      const kotlinSource = 'class MainActivity : FlutterActivity()';

      // 2. Act
      final package = extractKotlinPackage(kotlinSource);

      // 3. Assert
      expect(package, isNull);
    });

    test('Sad Path: detects a Kotlin package that does not match its folder '
        '(launch-time ClassNotFoundException)', () {
      // 1. Arrange
      const path =
          'android/app/src/main/kotlin/org/monamienet/app/MainActivity.kt';
      final declaredPackage = extractKotlinPackage(
        'package org.monamienet.aquariustur\n\nclass MainActivity',
      );

      // 2. Act
      final folderPackage = packageFromKotlinPath(path);

      // 3. Assert
      expect(folderPackage, isNot(declaredPackage));
    });

    test('Sad Path: returns null for a path outside src/main/kotlin', () {
      // 1. Arrange
      const path = 'android/app/src/main/java/io/flutter/plugins/X.java';

      // 2. Act
      final package = packageFromKotlinPath(path);

      // 3. Assert
      expect(package, isNull);
    });

    test('Sad Path: reports only the file that references the legacy '
        'namespace', () {
      // 1. Arrange
      final files = <String, String>{
        'a/MainActivity.kt': 'package org.monamienet.aquariustur',
        'b/AndroidManifest.xml': '<activity android:name=".MainActivity"/>',
      };

      // 2. Act
      final offenders = findFilesReferencing(files, legacyNamespace);

      // 3. Assert
      expect(offenders, ['a/MainActivity.kt']);
    });
  });
}
