import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_logo.dart' as app;

import '../../tool/src/partners.dart' as tool;
import 'support/partner_layout.dart';

const partnersRootPath = 'partners';
const sharedResPath = 'android/app/src/main/res';
const launchBackgroundPath =
    'android/app/src/main/res/drawable/launch_background.xml';
const launchBackgroundV21Path =
    'android/app/src/main/res/drawable-v21/launch_background.xml';
const webRootPath = 'web';
const webIndexPath = 'web/index.html';
const pubspecPath = 'pubspec.yaml';
const libRootPath = 'lib';

/// The folder of the login logo before it moved to `partners/<id>/`.
const legacyLogoFolder = 'assets/aquariustur';

/// Every Dart file below [root], sorted by path.
List<File> listDartFiles(Directory root) =>
    root
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Writes a minimal valid login logo into [partnerDirectory].
void writePartnerLogo(Directory partnerDirectory) {
  writeText(
    joinPath(partnerDirectory.path, requiredPartnerLogoFileName),
    '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"/>',
  );
}

/// Minimal partner-neutral `web/index.html`, mirroring the shared file.
const validWebIndexHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="apple-mobile-web-app-title" content="MonAmie">
  <link rel="apple-touch-icon" href="partner/icons/Icon-192.png">
  <link rel="icon" type="image/png" href="partner/favicon.png"/>
  <title>MonAmie</title>
  <link rel="manifest" href="partner/manifest.json">
</head>
<body></body>
</html>
''';

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

/// Populates [partnerDirectory] with every required web brand file, each
/// with distinct PNG bytes.
void writeAllWebBrandFiles(Directory partnerDirectory) {
  for (final path in requiredWebBrandFiles) {
    writeBytes(joinPath(partnerDirectory.path, 'web/$path'), [
      ...pngSignature,
      ...utf8.encode(path),
    ]);
  }
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

  group('missingWebBrandFiles - Unit Test Suite', () {
    test('Happy Path: reports nothing for a complete partner', () {
      // 1. Arrange
      writeAllWebBrandFiles(tempRoot);

      // 2. Act
      final missing = missingWebBrandFiles(tempRoot);

      // 3. Assert
      expect(missing, isEmpty);
    });

    test('Edge Case: ignores extra and unrelated files under web/', () {
      // 1. Arrange
      writeAllWebBrandFiles(tempRoot);
      writePng(joinPath(tempRoot.path, 'web/icons/Icon-1024.png'));
      writeText(joinPath(tempRoot.path, 'web/notes.txt'), 'x');

      // 2. Act
      final missing = missingWebBrandFiles(tempRoot);

      // 3. Assert
      expect(missing, isEmpty);
    });

    test('Sad Path: reports a missing maskable icon', () {
      // 1. Arrange
      writeAllWebBrandFiles(tempRoot);
      File(
        joinPath(tempRoot.path, 'web/icons/Icon-maskable-512.png'),
      ).deleteSync();

      // 2. Act
      final missing = missingWebBrandFiles(tempRoot);

      // 3. Assert
      expect(missing, ['icons/Icon-maskable-512.png']);
    });

    test('Sad Path: reports every file of a partner without web/', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"name": "X"}');

      // 2. Act
      final missing = missingWebBrandFiles(tempRoot);

      // 3. Assert
      expect(missing, requiredWebBrandFiles);
    });

    test('Sad Path: reports an empty favicon.png', () {
      // 1. Arrange
      writeAllWebBrandFiles(tempRoot);
      writeBytes(joinPath(tempRoot.path, 'web/favicon.png'), const []);

      // 2. Act
      final missing = missingWebBrandFiles(tempRoot);

      // 3. Assert
      expect(missing, ['favicon.png']);
    });

    test('Sad Path: reports a non-PNG file with a .png name', () {
      // 1. Arrange
      writeAllWebBrandFiles(tempRoot);
      writeText(
        joinPath(tempRoot.path, 'web/icons/Icon-192.png'),
        '<svg xmlns="http://www.w3.org/2000/svg"></svg>',
      );

      // 2. Act
      final missing = missingWebBrandFiles(tempRoot);

      // 3. Assert
      expect(missing, ['icons/Icon-192.png']);
    });

    test(
      'Sad Path: reports icons placed at the web/ root instead of web/icons/',
      () {
        // 1. Arrange
        writePng(joinPath(tempRoot.path, 'web/favicon.png'));
        for (final path in requiredWebBrandFiles.skip(1)) {
          writePng(joinPath(tempRoot.path, 'web/${path.split('/').last}'));
        }

        // 2. Act
        final missing = missingWebBrandFiles(tempRoot);

        // 3. Assert
        expect(missing, requiredWebBrandFiles.skip(1).toList());
      },
    );
  });

  group('partnerIdentityProblems - Unit Test Suite', () {
    test(
      'Happy Path: reports no problem for a valid name and primary color',
      () {
        // 1. Arrange
        writePartnerJson(
          tempRoot,
          '{"name": "AquariusTur", "colors": {"primary": "#0ABAB5", '
          '"secondary": "#FFFFFF"}}',
        );

        // 2. Act
        final problems = partnerIdentityProblems(tempRoot);

        // 3. Assert
        expect(problems, isEmpty);
      },
    );

    test(
      'Edge Case: accepts a lowercase primary color and a name with spaces',
      () {
        // 1. Arrange
        writePartnerJson(
          tempRoot,
          '{"name": "Rio Tur", "colors": {"primary": "#0abab5"}}',
        );

        // 2. Act
        final problems = partnerIdentityProblems(tempRoot);

        // 3. Assert
        expect(problems, isEmpty);
      },
    );

    test('Edge Case: does not require colors.secondary', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": "X", "colors": {"primary": "#000000"}}',
      );

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Sad Path: reports a missing name', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"colors": {"primary": "#0ABAB5"}}');

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('name')]);
    });

    test('Sad Path: reports a blank name', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": "   ", "colors": {"primary": "#0ABAB5"}}',
      );

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('name')]);
    });

    test('Sad Path: reports a non-string name', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": ["X"], "colors": {"primary": "#0ABAB5"}}',
      );

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('name')]);
    });

    test('Sad Path: reports a short #RGB primary color', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": "X", "colors": {"primary": "#0AB"}}',
      );

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('colors.primary')]);
    });

    test('Sad Path: reports a missing colors object', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"name": "X"}');

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('colors.primary')]);
    });

    test('Sad Path: reports both problems of an empty object', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{}');

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('name'), contains('colors.primary')]);
    });

    test('Sad Path: reports malformed JSON instead of throwing', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"name": ');

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('not valid JSON')]);
    });

    test('Sad Path: reports a JSON document that is not an object', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '["X"]');

      // 2. Act
      final problems = partnerIdentityProblems(tempRoot);

      // 3. Assert
      expect(problems, [contains('JSON object')]);
    });

    test('Sad Path: reports a missing partner.json', () {
      // 1. Arrange
      final emptyPartner = Directory(joinPath(tempRoot.path, 'empty'))
        ..createSync();

      // 2. Act
      final problems = partnerIdentityProblems(emptyPartner);

      // 3. Assert
      expect(problems, ['$partnerConfigFileName is missing']);
    });
  });

  group('partnerBrandTerms - Unit Test Suite', () {
    test('Happy Path: returns the name and the primary hex digits', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": "AquariusTur", "colors": {"primary": "#0ABAB5"}}',
      );

      // 2. Act
      final terms = partnerBrandTerms(tempRoot);

      // 3. Assert
      expect(terms, ['AquariusTur', '0ABAB5']);
    });

    test('Edge Case: trims spaces around the name', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": "  Rio Tur ", "colors": {"primary": "#112233"}}',
      );

      // 2. Act
      final terms = partnerBrandTerms(tempRoot);

      // 3. Assert
      expect(terms, ['Rio Tur', '112233']);
    });

    test('Edge Case: leaves out an invalid primary color', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": "X", "colors": {"primary": "teal"}}',
      );

      // 2. Act
      final terms = partnerBrandTerms(tempRoot);

      // 3. Assert
      expect(terms, ['X']);
    });

    test('Edge Case: leaves out a blank name', () {
      // 1. Arrange
      writePartnerJson(
        tempRoot,
        '{"name": " ", "colors": {"primary": "#112233"}}',
      );

      // 2. Act
      final terms = partnerBrandTerms(tempRoot);

      // 3. Assert
      expect(terms, ['112233']);
    });

    test('Sad Path: returns nothing for malformed JSON', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{');

      // 2. Act
      final terms = partnerBrandTerms(tempRoot);

      // 3. Assert
      expect(terms, isEmpty);
    });

    test('Sad Path: returns nothing for a missing partner.json', () {
      // 1. Arrange
      final emptyPartner = Directory(joinPath(tempRoot.path, 'empty'))
        ..createSync();

      // 2. Act
      final terms = partnerBrandTerms(emptyPartner);

      // 3. Assert
      expect(terms, isEmpty);
    });
  });

  group('brandMentions - Unit Test Suite', () {
    test('Happy Path: reports nothing for a partner-neutral source', () {
      // 1. Arrange
      const source = validWebIndexHtml;

      // 2. Act
      final mentions = brandMentions(source, ['AquariusTur', '0ABAB5']);

      // 3. Assert
      expect(mentions, isEmpty);
    });

    test('Happy Path: reports the line of a partner name', () {
      // 1. Arrange
      const source = '<html>\n<title>MonAmie AquariusTur</title>\n</html>';

      // 2. Act
      final mentions = brandMentions(source, ['AquariusTur']);

      // 3. Assert
      expect(mentions, ['line 2: aquariustur']);
    });

    test('Edge Case: matches ignoring case', () {
      // 1. Arrange
      const source = 'theme: #0abab5\nid: AQUARIUSTUR';

      // 2. Act
      final mentions = brandMentions(source, ['AquariusTur', '0ABAB5']);

      // 3. Assert
      expect(mentions, ['line 1: 0abab5', 'line 2: aquariustur']);
    });

    test('Edge Case: catches a color written as 0xFF + hex digits', () {
      // 1. Arrange
      const source = 'const color = Color(0xFF0ABAB5);';

      // 2. Act
      final mentions = brandMentions(source, ['0ABAB5']);

      // 3. Assert
      expect(mentions, ['line 1: 0abab5']);
    });

    test('Edge Case: skips the google-signin-client_id line', () {
      // 1. Arrange
      const source =
          '<meta name="google-signin-client_id" content="aquariustur-0ABAB5">';

      // 2. Act
      final mentions = brandMentions(source, ['AquariusTur', '0ABAB5']);

      // 3. Assert
      expect(mentions, isEmpty);
    });

    test('Edge Case: ignores blank terms', () {
      // 1. Arrange
      const source = 'anything at all';

      // 2. Act
      final mentions = brandMentions(source, ['', '   ']);

      // 3. Assert
      expect(mentions, isEmpty);
    });

    test(
      'Sad Path: reports a mention on a line next to the client id line',
      () {
        // 1. Arrange
        const source =
            '<meta name="google-signin-client_id" content="x">\n'
            '<title>MonAmie AquariusTur</title>';

        // 2. Act
        final mentions = brandMentions(source, ['AquariusTur']);

        // 3. Assert
        expect(mentions, ['line 2: aquariustur']);
      },
    );

    test('Sad Path: reports every term found on the same line', () {
      // 1. Arrange
      const source = '{"name": "AquariusTur", "theme_color": "#0ABAB5"}';

      // 2. Act
      final mentions = brandMentions(source, ['AquariusTur', '0ABAB5']);

      // 3. Assert
      expect(mentions, ['line 1: aquariustur', 'line 1: 0abab5']);
    });
  });

  group('listSharedWebFiles - Unit Test Suite', () {
    test('Happy Path: lists every file below web/, sorted', () {
      // 1. Arrange
      writeText(joinPath(tempRoot.path, 'index.html'), '<html/>');
      writeText(joinPath(tempRoot.path, 'splash/style.css'), 'x');

      // 2. Act
      final files = listSharedWebFiles(tempRoot);

      // 3. Assert
      expect(files, ['index.html', 'splash/style.css']);
    });

    test('Edge Case: leaves out the staged partner/ folder', () {
      // 1. Arrange
      writeText(joinPath(tempRoot.path, 'index.html'), '<html/>');
      writeText(joinPath(tempRoot.path, 'partner/partner.json'), '{}');
      writePng(joinPath(tempRoot.path, 'partner/icons/Icon-192.png'));

      // 2. Act
      final files = listSharedWebFiles(tempRoot);

      // 3. Assert
      expect(files, ['index.html']);
    });

    test('Edge Case: keeps files whose name only starts with "partner"', () {
      // 1. Arrange
      writeText(joinPath(tempRoot.path, 'partners.txt'), 'x');
      writeText(joinPath(tempRoot.path, 'partnerx/a.txt'), 'x');

      // 2. Act
      final files = listSharedWebFiles(tempRoot);

      // 3. Assert
      expect(files, ['partners.txt', 'partnerx/a.txt']);
    });

    test('Edge Case: returns nothing for an empty web/', () {
      // 1. Arrange
      final emptyWeb = tempRoot;

      // 2. Act
      final files = listSharedWebFiles(emptyWeb);

      // 3. Assert
      expect(files, isEmpty);
    });

    test('Sad Path: throws when web/ does not exist', () {
      // 1. Arrange
      final missingWeb = Directory(joinPath(tempRoot.path, 'missing'));

      // 2. Act
      action() => listSharedWebFiles(missingWeb);

      // 3. Assert
      expect(action, throwsA(isA<FileSystemException>()));
    });
  });

  group('findBrandFileCopies - Unit Test Suite', () {
    test('Happy Path: reports nothing when web/ holds no brand image', () {
      // 1. Arrange
      final partner = Directory(joinPath(tempRoot.path, 'partner_src'));
      writeAllWebBrandFiles(partner);
      final web = Directory(joinPath(tempRoot.path, 'web'));
      writeText(joinPath(web.path, 'index.html'), validWebIndexHtml);

      // 2. Act
      final copies = findBrandFileCopies(web, partner);

      // 3. Assert
      expect(copies, isEmpty);
    });

    test(
      'Edge Case: ignores brand copies inside the staged partner/ folder',
      () {
        // 1. Arrange
        final partner = Directory(joinPath(tempRoot.path, 'partner_src'));
        writeAllWebBrandFiles(partner);
        final web = Directory(joinPath(tempRoot.path, 'web'));
        Directory(joinPath(web.path, 'partner')).createSync(recursive: true);
        File(
          joinPath(partner.path, 'web/favicon.png'),
        ).copySync(joinPath(web.path, 'partner/favicon.png'));

        // 2. Act
        final copies = findBrandFileCopies(web, partner);

        // 3. Assert
        expect(copies, isEmpty);
      },
    );

    test('Edge Case: ignores a different PNG with the same name', () {
      // 1. Arrange
      final partner = Directory(joinPath(tempRoot.path, 'partner_src'));
      writeAllWebBrandFiles(partner);
      final web = Directory(joinPath(tempRoot.path, 'web'));
      writePng(joinPath(web.path, 'favicon.png'));

      // 2. Act
      final copies = findBrandFileCopies(web, partner);

      // 3. Assert
      expect(copies, isEmpty);
    });

    test('Sad Path: reports leftover brand images under any name', () {
      // 1. Arrange
      final partner = Directory(joinPath(tempRoot.path, 'partner_src'));
      writeAllWebBrandFiles(partner);
      final web = Directory(joinPath(tempRoot.path, 'web'));
      Directory(joinPath(web.path, 'icons')).createSync(recursive: true);
      File(
        joinPath(partner.path, 'web/favicon.png'),
      ).copySync(joinPath(web.path, 'favicon.png'));
      File(
        joinPath(partner.path, 'web/icons/Icon-512.png'),
      ).copySync(joinPath(web.path, 'icons/renamed.png'));

      // 2. Act
      final copies = findBrandFileCopies(web, partner);

      // 3. Assert
      expect(copies, ['favicon.png', 'icons/renamed.png']);
    });
  });

  group('webIndexProblems - Unit Test Suite', () {
    test('Happy Path: accepts a partner-neutral index linking to partner/', () {
      // 1. Arrange
      const html = validWebIndexHtml;

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: accepts attributes in any order and extra attributes', () {
      // 1. Arrange
      const html = '''
      <title>MonAmie</title>
      <meta content="MonAmie" name="apple-mobile-web-app-title">
      <link href="partner/manifest.json" rel="manifest" crossorigin="use-credentials">
      <link type="image/png" href="partner/favicon.png" rel="icon"/>
      <link href="partner/icons/Icon-192.png" rel="apple-touch-icon">
      ''';

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: ignores stale links that only appear in comments', () {
      // 1. Arrange
      final html = validWebIndexHtml.replaceFirst(
        '<title>',
        '<!-- <link rel="manifest" href="manifest.json"> -->\n  <title>',
      );

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Sad Path: rejects a partner name in the title', () {
      // 1. Arrange
      final html = validWebIndexHtml.replaceFirst(
        '<title>MonAmie</title>',
        '<title>MonAmie AquariusTur</title>',
      );

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, ['<title> must be MonAmie, got: MonAmie AquariusTur']);
    });

    test('Sad Path: rejects a partner name in apple-mobile-web-app-title', () {
      // 1. Arrange
      final html = validWebIndexHtml.replaceFirst(
        'content="MonAmie"',
        'content="MonAmie AquariusTur"',
      );

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, [
        'apple-mobile-web-app-title must be MonAmie, got: MonAmie AquariusTur',
      ]);
    });

    test('Sad Path: rejects the old root manifest link', () {
      // 1. Arrange
      final html = validWebIndexHtml.replaceFirst(
        'href="partner/manifest.json"',
        'href="manifest.json"',
      );

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, [
        'missing <link rel="manifest" href="partner/manifest.json">',
        '<link rel="manifest"> must point into partner/, got: manifest.json',
      ]);
    });

    test('Sad Path: rejects an extra icon link outside partner/', () {
      // 1. Arrange
      final html = validWebIndexHtml.replaceFirst(
        '<title>',
        '<link rel="icon" href="favicon.png">\n  <title>',
      );

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, [
        '<link rel="icon"> must point into partner/, got: favicon.png',
      ]);
    });

    test('Sad Path: reports every problem for an empty source', () {
      // 1. Arrange
      const html = '';

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, [
        '<title> is missing',
        'apple-mobile-web-app-title is missing',
        'missing <link rel="manifest" href="partner/manifest.json">',
        'missing <link rel="icon" href="partner/favicon.png">',
        'missing <link rel="apple-touch-icon" href="partner/icons/Icon-192.png">',
      ]);
    });
  });

  group('partnerLogoProblems - Unit Test Suite', () {
    test('Happy Path: reports nothing for a non-empty SVG logo', () {
      // 1. Arrange
      writePartnerLogo(tempRoot);

      // 2. Act
      final problems = partnerLogoProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: accepts an SVG with an XML declaration and Inkscape '
        'attributes', () {
      // 1. Arrange
      writeText(
        joinPath(tempRoot.path, requiredPartnerLogoFileName),
        '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
        '<svg\n   id="svg1"\n   inkscape:version="1.4"\n   width="200">'
        '</svg>\n',
      );

      // 2. Act
      final problems = partnerLogoProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: ignores a logo placed only under web/', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"name": "X"}');
      writePartnerLogo(Directory(joinPath(tempRoot.path, 'web')));

      // 2. Act
      final problems = partnerLogoProblems(tempRoot);

      // 3. Assert
      expect(problems, ['$requiredPartnerLogoFileName is missing']);
    });

    test('Sad Path: reports a missing logo', () {
      // 1. Arrange
      writePartnerJson(tempRoot, '{"name": "X"}');

      // 2. Act
      final problems = partnerLogoProblems(tempRoot);

      // 3. Assert
      expect(problems, ['$requiredPartnerLogoFileName is missing']);
    });

    test('Sad Path: reports an empty logo', () {
      // 1. Arrange
      writeBytes(joinPath(tempRoot.path, requiredPartnerLogoFileName), []);

      // 2. Act
      final problems = partnerLogoProblems(tempRoot);

      // 3. Assert
      expect(problems, ['$requiredPartnerLogoFileName is empty']);
    });

    test('Sad Path: reports a PNG saved with the .svg name', () {
      // 1. Arrange
      writePng(joinPath(tempRoot.path, requiredPartnerLogoFileName));

      // 2. Act
      final problems = partnerLogoProblems(tempRoot);

      // 3. Assert
      expect(problems, ['$requiredPartnerLogoFileName is not an SVG']);
    });
  });

  group('filesMentioning - Unit Test Suite', () {
    test('Happy Path: returns the files that contain the text', () {
      // 1. Arrange
      final hit = joinPath(tempRoot.path, 'a.dart');
      final miss = joinPath(tempRoot.path, 'b.dart');
      writeText(hit, "SvgPicture.asset('assets/aquariustur/Logo.svg')");
      writeText(miss, "SvgPicture.asset('partners/x/logo.svg')");

      // 2. Act
      final files = filesMentioning([File(hit), File(miss)], legacyLogoFolder);

      // 3. Assert
      expect(files, [hit]);
    });

    test('Edge Case: returns nothing for no files', () {
      // 1. Arrange
      final files = <File>[];

      // 2. Act
      final mentioning = filesMentioning(files, legacyLogoFolder);

      // 3. Assert
      expect(mentioning, isEmpty);
    });

    test('Edge Case: matches the text case-sensitively', () {
      // 1. Arrange
      final path = joinPath(tempRoot.path, 'a.dart');
      writeText(path, "'Assets/AquariusTur/Logo.svg'");

      // 2. Act
      final files = filesMentioning([File(path)], legacyLogoFolder);

      // 3. Assert
      expect(files, isEmpty);
    });

    test('Sad Path: skips a file that does not exist', () {
      // 1. Arrange
      final missing = File(joinPath(tempRoot.path, 'nope.dart'));

      // 2. Act
      final files = filesMentioning([missing], legacyLogoFolder);

      // 3. Assert
      expect(files, isEmpty);
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

    test('Happy Path: aquariustur is identified by "AquariusTur" and '
        '#0ABAB5', () {
      // 1. Arrange
      final partner = Directory('$partnersRootPath/aquariustur');

      // 2. Act
      final terms = partnerBrandTerms(partner);

      // 3. Assert
      expect(terms, ['AquariusTur', '0ABAB5']);
    });

    test('Happy Path: every partner.json declares a valid name and '
        'colors.primary (rule 5)', () {
      // 1. Arrange
      final partners = listPartnerDirectories(Directory(partnersRootPath));

      // 2. Act
      final problemsByPartner = {
        for (final partner in partners)
          partner.path: partnerIdentityProblems(partner),
      }..removeWhere((_, problems) => problems.isEmpty);

      // 3. Assert
      expect(problemsByPartner, isEmpty);
    });

    test('Happy Path: every partner provides all web brand files as real '
        'PNG files (rule 6)', () {
      // 1. Arrange
      final partners = listPartnerDirectories(Directory(partnersRootPath));

      // 2. Act
      final missingByPartner = {
        for (final partner in partners)
          partner.path: missingWebBrandFiles(partner),
      }..removeWhere((_, missing) => missing.isEmpty);

      // 3. Assert
      expect(missingByPartner, isEmpty);
    });

    test('Happy Path: web/ outside web/partner/ mentions no partner name or '
        'primary color (rule 7)', () {
      // 1. Arrange
      final terms = listPartnerDirectories(
        Directory(partnersRootPath),
      ).expand(partnerBrandTerms).toList();
      final webFiles = listSharedWebFiles(Directory(webRootPath));

      // 2. Act
      final mentionsByFile = {
        for (final path in webFiles)
          path: brandMentions(
            utf8.decode(
              File('$webRootPath/$path').readAsBytesSync(),
              allowMalformed: true,
            ),
            terms,
          ),
      }..removeWhere((_, mentions) => mentions.isEmpty);

      // 3. Assert
      expect(mentionsByFile, isEmpty);
    });

    test('Happy Path: web/ outside web/partner/ holds no partner brand '
        'image (rule 8)', () {
      // 1. Arrange
      final partners = listPartnerDirectories(Directory(partnersRootPath));
      final webRoot = Directory(webRootPath);

      // 2. Act
      final copiesByPartner = {
        for (final partner in partners)
          partner.path: findBrandFileCopies(webRoot, partner),
      }..removeWhere((_, copies) => copies.isEmpty);

      // 3. Assert
      expect(copiesByPartner, isEmpty);
    });

    test('Happy Path: web/index.html is partner-neutral and links to the '
        'staged partner/ files (rule 9)', () {
      // 1. Arrange
      final html = File(webIndexPath).readAsStringSync();

      // 2. Act
      final problems = webIndexProblems(html);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Happy Path: every partner provides a non-empty SVG login logo '
        'next to its partner.json (rule 10)', () {
      // 1. Arrange
      final partners = listPartnerDirectories(Directory(partnersRootPath));

      // 2. Act
      final problemsByPartner = {
        for (final partner in partners)
          partner.path: partnerLogoProblems(partner),
      }..removeWhere((_, problems) => problems.isEmpty);

      // 3. Assert
      expect(problemsByPartner, isEmpty);
    });

    test('Happy Path: the app and the partner tool agree on the logo file '
        'name', () {
      // 1. Arrange
      const toolName = tool.partnerLogoFileName;

      // 2. Act
      const appName = app.partnerLogoFileName;

      // 3. Assert
      expect(appName, toolName);
    });

    test('Happy Path: the logo file name is the onboarding upload name', () {
      // 1. Arrange
      const expected = requiredPartnerLogoFileName;

      // 2. Act
      const appName = app.partnerLogoFileName;

      // 3. Assert
      expect(appName, expected);
    });

    test('Happy Path: pubspec.yaml no longer bundles assets/aquariustur', () {
      // 1. Arrange
      final pubspec = File(pubspecPath);

      // 2. Act
      final files = filesMentioning([pubspec], legacyLogoFolder);

      // 3. Assert
      expect(files, isEmpty);
    });

    test('Happy Path: no file under lib/ refers to assets/aquariustur', () {
      // 1. Arrange
      final dartFiles = listDartFiles(Directory(libRootPath));

      // 2. Act
      final files = filesMentioning(dartFiles, legacyLogoFolder);

      // 3. Assert
      expect(files, isEmpty);
    });

    test('Happy Path: the assets/aquariustur folder is gone', () {
      // 1. Arrange
      final legacy = Directory(legacyLogoFolder);

      // 2. Act
      final exists = legacy.existsSync();

      // 3. Assert
      expect(exists, isFalse);
    });
  });
}
