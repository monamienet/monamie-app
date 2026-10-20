import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/partner_layout.dart';

const partnersRootPath = 'partners';
const sharedResPath = 'android/app/src/main/res';
const launchBackgroundPath =
    'android/app/src/main/res/drawable/launch_background.xml';
const launchBackgroundV21Path =
    'android/app/src/main/res/drawable-v21/launch_background.xml';

/// Minimal valid launch background, mirroring the shared Android resource.
const validLaunchBackgroundXml = '''
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
    <item>
        <bitmap android:gravity="center" android:src="@drawable/launch_image" />
    </item>
</layer-list>
''';

/// Creates [path] (and its parents) with [bytes].
void writeBytes(String path, List<int> bytes) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

/// Creates [path] (and its parents) with a PNG signature followed by data.
void writePng(String path) {
  writeBytes(path, [...pngSignature, 0x00, 0x00, 0x00, 0x0D]);
}

/// Creates [path] (and its parents) with the text [content].
void writeText(String path, String content) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(content);
}

/// Populates [partnerDirectory] with every required Android brand resource.
void writeAllBrandResources(Directory partnerDirectory) {
  for (final resource in requiredAndroidBrandResources) {
    writePng(joinPath(partnerDirectory.path, 'android/res/$resource'));
  }
}

/// Writes a `partner.json` whose body is [json] into [partnerDirectory].
void writePartnerJson(Directory partnerDirectory, String json) {
  writeText(joinPath(partnerDirectory.path, partnerConfigFileName), json);
}

void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('partner_layout_test_');
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('isValidHexColor - Unit Test Suite', () {
    test('Happy Path: accepts an uppercase #RRGGBB color', () {
      // 1. Arrange
      const color = '#FFFFFF';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isTrue);
    });

    test('Edge Case: accepts a lowercase #rrggbb color', () {
      // 1. Arrange
      const color = '#0abab5';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isTrue);
    });

    test('Edge Case: rejects a color with surrounding whitespace', () {
      // 1. Arrange
      const color = ' #FFFFFF ';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects a color name such as "white"', () {
      // 1. Arrange
      const color = 'white';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects the short #RGB form "#FFF"', () {
      // 1. Arrange
      const color = '#FFF';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects non-hex digits "#GGGGGG"', () {
      // 1. Arrange
      const color = '#GGGGGG';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects the #AARRGGBB form "#FFFFFFFF"', () {
      // 1. Arrange
      const color = '#FFFFFFFF';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects a color without the leading "#"', () {
      // 1. Arrange
      const color = 'FFFFFF';

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects a non-string value', () {
      // 1. Arrange
      const color = 0xFFFFFF;

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });

    test('Sad Path: rejects null', () {
      // 1. Arrange
      const Object? color = null;

      // 2. Act
      final isValid = isValidHexColor(color);

      // 3. Assert
      expect(isValid, isFalse);
    });
  });

  group('partnerConfigProblems - Unit Test Suite', () {
    test('Happy Path: reports no problem for a valid secondary color', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": "X", "colors": {"primary": "#0ABAB5", '
        '"secondary": "#FFFFFF"}}',
      );

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: accepts a lowercase secondary color', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"secondary": "#a1b2c3"}}');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: ignores unrelated extra keys', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"colors": {"secondary": "#000000", "tertiary": "red"}, '
        '"extra": [1, 2, 3]}',
      );

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Sad Path: rejects the color name "white"', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"secondary": "white"}}');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('colors.secondary')]);
    });

    test('Sad Path: rejects the short form "#FFF"', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"secondary": "#FFF"}}');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('colors.secondary')]);
    });

    test('Sad Path: rejects non-hex digits "#GGGGGG"', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"secondary": "#GGGGGG"}}');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('colors.secondary')]);
    });

    test('Sad Path: rejects a config without the "colors" key', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"name": "X"}');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('colors')]);
    });

    test('Sad Path: rejects "colors" without "secondary"', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"primary": "#0ABAB5"}}');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('colors.secondary')]);
    });

    test('Sad Path: rejects a JSON document that is not an object', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '["#FFFFFF"]');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('JSON object')]);
    });

    test('Sad Path: reports malformed JSON instead of throwing', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"secondary": "#FFFFFF"');

      // 2. Act
      final problems = partnerConfigProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('not valid JSON')]);
    });

    test('Sad Path: reports a missing partner.json', () {
      // 1. Arrange
      final emptyPartner = Directory(joinPath(tempRoot.path, 'empty'))
        ..createSync();

      // 2. Act
      final problems = partnerConfigProblems(emptyPartner);

      // 3. Assert
      expect(problems, ['$partnerConfigFileName is missing']);
    });
  });

  group('missingAndroidBrandResources - Unit Test Suite', () {
    test('Happy Path: reports nothing for a complete partner', () {
      // 1. Arrange
      writeAllBrandResources(tempRoot);

      // 2. Act
      final missing = missingAndroidBrandResources(tempRoot);

      // 3. Assert
      expect(missing, isEmpty);
    });

    test('Edge Case: ignores extra and unrelated files', () {
      // 1. Arrange
      writeAllBrandResources(tempRoot);
      writePng(
        joinPath(tempRoot.path, 'android/res/mipmap-ldpi/ic_launcher.png'),
      );
      writeText(joinPath(tempRoot.path, 'android/res/values/notes.txt'), 'x');
      writeText(joinPath(tempRoot.path, 'README.md'), '# partner');

      // 2. Act
      final missing = missingAndroidBrandResources(tempRoot);

      // 3. Assert
      expect(missing, isEmpty);
    });

    test('Sad Path: reports a missing density', () {
      // 1. Arrange
      writeAllBrandResources(tempRoot);
      File(
        joinPath(tempRoot.path, 'android/res/mipmap-xxhdpi/ic_launcher.png'),
      ).deleteSync();

      // 2. Act
      final missing = missingAndroidBrandResources(tempRoot);

      // 3. Assert
      expect(missing, ['mipmap-xxhdpi/ic_launcher.png']);
    });

    test('Sad Path: reports every resource of a partner without android/', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"secondary": "#FFFFFF"}}');

      // 2. Act
      final missing = missingAndroidBrandResources(tempRoot);

      // 3. Assert
      expect(missing, requiredAndroidBrandResources);
    });

    test('Sad Path: reports an empty launch_image.png', () {
      // 1. Arrange
      writeAllBrandResources(tempRoot);
      writeBytes(
        joinPath(tempRoot.path, 'android/res/drawable/launch_image.png'),
        const [],
      );

      // 2. Act
      final missing = missingAndroidBrandResources(tempRoot);

      // 3. Assert
      expect(missing, ['drawable/launch_image.png']);
    });

    test('Sad Path: reports a non-PNG file with a .png name', () {
      // 1. Arrange
      writeAllBrandResources(tempRoot);
      writeText(
        joinPath(tempRoot.path, 'android/res/mipmap-mdpi/ic_launcher.png'),
        '<svg xmlns="http://www.w3.org/2000/svg"></svg>',
      );

      // 2. Act
      final missing = missingAndroidBrandResources(tempRoot);

      // 3. Assert
      expect(missing, ['mipmap-mdpi/ic_launcher.png']);
    });

    test('Sad Path: reports a directory named like a required resource', () {
      // 1. Arrange
      writeAllBrandResources(tempRoot);
      final iconPath = joinPath(
        tempRoot.path,
        'android/res/mipmap-hdpi/ic_launcher.png',
      );
      File(iconPath).deleteSync();
      Directory(iconPath).createSync();

      // 2. Act
      final missing = missingAndroidBrandResources(tempRoot);

      // 3. Assert
      expect(missing, ['mipmap-hdpi/ic_launcher.png']);
    });
  });

  group('listPartnerDirectories - Unit Test Suite', () {
    test('Happy Path: lists folders that contain partner.json, sorted', () {
      // 1. Arrange
      for (final id in ['zeta', 'alpha']) {
        writePartnerJson(
          Directory(joinPath(tempRoot.path, id)),
          '{"colors": {"secondary": "#FFFFFF"}}',
        );
      }

      // 2. Act
      final partners = listPartnerDirectories(tempRoot);

      // 3. Assert
      expect(partners.map((dir) => dir.path.split('/').last), [
        'alpha',
        'zeta',
      ]);
    });

    test('Edge Case: ignores a folder without partner.json', () {
      // 1. Arrange
      writePartnerJson(
        Directory(joinPath(tempRoot.path, 'real')),
        '{"colors": {"secondary": "#FFFFFF"}}',
      );
      writeAllBrandResources(Directory(joinPath(tempRoot.path, 'drafts')));

      // 2. Act
      final partners = listPartnerDirectories(tempRoot);

      // 3. Assert
      expect(partners.map((dir) => dir.path.split('/').last), ['real']);
    });

    test('Edge Case: ignores loose files at the partners root', () {
      // 1. Arrange
      writeText(joinPath(tempRoot.path, partnerConfigFileName), '{}');
      writeText(joinPath(tempRoot.path, 'README.md'), '# partners');

      // 2. Act
      final partners = listPartnerDirectories(tempRoot);

      // 3. Assert
      expect(partners, isEmpty);
    });

    test('Sad Path: throws when the partners root does not exist', () {
      // 1. Arrange
      final missingRoot = Directory(joinPath(tempRoot.path, 'missing'));

      // 2. Act
      action() => listPartnerDirectories(missingRoot);

      // 3. Assert
      expect(action, throwsA(isA<FileSystemException>()));
    });
  });

  group('findForbiddenSharedBrandFiles - Unit Test Suite', () {
    test('Happy Path: reports nothing for resources without brand images', () {
      // 1. Arrange
      writeText(joinPath(tempRoot.path, 'values/styles.xml'), '<resources/>');
      writeText(
        joinPath(tempRoot.path, 'drawable/launch_background.xml'),
        validLaunchBackgroundXml,
      );

      // 2. Act
      final offenders = findForbiddenSharedBrandFiles(tempRoot);

      // 3. Assert
      expect(offenders, isEmpty);
    });

    test('Edge Case: ignores similarly named files', () {
      // 1. Arrange
      writePng(joinPath(tempRoot.path, 'mipmap-hdpi/ic_launcher_round.png'));
      writePng(joinPath(tempRoot.path, 'drawable/launch_image.webp'));
      writeText(joinPath(tempRoot.path, 'drawable/ic_launcher.xml'), '<x/>');

      // 2. Act
      final offenders = findForbiddenSharedBrandFiles(tempRoot);

      // 3. Assert
      expect(offenders, isEmpty);
    });

    test('Edge Case: reports nothing for an empty res folder', () {
      // 1. Arrange
      final emptyRes = tempRoot;

      // 2. Act
      final offenders = findForbiddenSharedBrandFiles(emptyRes);

      // 3. Assert
      expect(offenders, isEmpty);
    });

    test('Sad Path: reports leftover icons and splash image anywhere', () {
      // 1. Arrange
      writePng(joinPath(tempRoot.path, 'mipmap-xxxhdpi/ic_launcher.png'));
      writePng(joinPath(tempRoot.path, 'drawable/launch_image.png'));
      writePng(joinPath(tempRoot.path, 'nested/deeper/ic_launcher.png'));

      // 2. Act
      final offenders = findForbiddenSharedBrandFiles(tempRoot);

      // 3. Assert
      expect(offenders, [
        'drawable/launch_image.png',
        'mipmap-xxxhdpi/ic_launcher.png',
        'nested/deeper/ic_launcher.png',
      ]);
    });
  });

  group('launchBackgroundProblems - Unit Test Suite', () {
    test('Happy Path: accepts the partner color and partner image', () {
      // 1. Arrange
      const xml = validLaunchBackgroundXml;

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: accepts attributes spread over several lines', () {
      // 1. Arrange
      const xml = '''
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:drawable="@color/splash_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/launch_image" />
    </item>
</layer-list>
''';

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: ignores references that only appear in comments', () {
      // 1. Arrange
      const xml = '''
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- <item android:drawable="@color/splash_background" /> -->
    <item android:drawable="@android:color/white" />
    <!-- <bitmap android:src="@drawable/launch_image" /> -->
</layer-list>
''';

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, [
        'background must be @color/splash_background',
        'unexpected background drawable: @android:color/white',
        'image must be @drawable/launch_image',
      ]);
    });

    test('Sad Path: rejects a hardcoded framework background color', () {
      // 1. Arrange
      final xml = validLaunchBackgroundXml.replaceFirst(
        '@color/splash_background',
        '@android:color/white',
      );

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, [
        'background must be @color/splash_background',
        'unexpected background drawable: @android:color/white',
      ]);
    });

    test('Sad Path: rejects an extra hardcoded hex background layer', () {
      // 1. Arrange
      final xml = validLaunchBackgroundXml.replaceFirst(
        '<item>',
        '<item android:drawable="#FFFFFF" />\n    <item>',
      );

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, ['unexpected background drawable: #FFFFFF']);
    });

    test('Sad Path: rejects a layer list without the launch image', () {
      // 1. Arrange
      const xml = '''
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
</layer-list>
''';

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, ['image must be @drawable/launch_image']);
    });

    test('Sad Path: reports every problem for an empty source', () {
      // 1. Arrange
      const xml = '';

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, [
        'background must be @color/splash_background',
        'image must be @drawable/launch_image',
      ]);
    });
  });

  group('Repository partner layout - Contract Test Suite', () {
    test('Happy Path: the repository declares at least one partner', () {
      // 1. Arrange
      final partnersRoot = Directory(partnersRootPath);

      // 2. Act
      final partners = listPartnerDirectories(partnersRoot);

      // 3. Assert
      expect(partners, isNotEmpty);
    });

    test('Happy Path: aquariustur uses #FFFFFF as splash background', () {
      // 1. Arrange
      final configSource = File(
        '$partnersRootPath/aquariustur/$partnerConfigFileName',
      ).readAsStringSync();

      // 2. Act
      final config = jsonDecode(configSource) as Map<String, dynamic>;

      // 3. Assert
      expect(config['colors'], containsPair('secondary', '#FFFFFF'));
    });

    test('Happy Path: every partner.json declares a valid colors.secondary '
        '(rule 1)', () {
      // 1. Arrange
      final partners = listPartnerDirectories(Directory(partnersRootPath));

      // 2. Act
      final problemsByPartner = {
        for (final partner in partners)
          partner.path: partnerConfigProblems(partner),
      }..removeWhere((_, problems) => problems.isEmpty);

      // 3. Assert
      expect(problemsByPartner, isEmpty);
    });

    test('Happy Path: every partner provides all Android brand resources as '
        'real PNG files (rule 2)', () {
      // 1. Arrange
      final partners = listPartnerDirectories(Directory(partnersRootPath));

      // 2. Act
      final missingByPartner = {
        for (final partner in partners)
          partner.path: missingAndroidBrandResources(partner),
      }..removeWhere((_, missing) => missing.isEmpty);

      // 3. Assert
      expect(missingByPartner, isEmpty);
    });

    test('Happy Path: shared android res holds no ic_launcher.png or '
        'launch_image.png (rule 3)', () {
      // 1. Arrange
      final sharedRes = Directory(sharedResPath);

      // 2. Act
      final offenders = findForbiddenSharedBrandFiles(sharedRes);

      // 3. Assert
      expect(offenders, isEmpty);
    });

    test('Happy Path: drawable/launch_background.xml uses the partner color '
        'and image (rule 4)', () {
      // 1. Arrange
      final xml = File(launchBackgroundPath).readAsStringSync();

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Happy Path: drawable-v21/launch_background.xml uses the partner '
        'color and image (rule 4)', () {
      // 1. Arrange
      final xml = File(launchBackgroundV21Path).readAsStringSync();

      // 2. Act
      final problems = launchBackgroundProblems(xml);

      // 3. Assert
      expect(problems, isEmpty);
    });
  });
}
