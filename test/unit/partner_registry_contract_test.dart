import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';

import 'support/partner_layout.dart';
import 'support/pubspec_assets.dart';

const pubspecPath = 'pubspec.yaml';

/// A pubspec whose `flutter: assets:` is [assets], indented as in the real
/// file.
String pubspecWithAssets(String assets) =>
    '''
name: app
dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
$assets
''';

/// The correct entry for partner [id], indented as in the real file.
String partnerEntry(String id) =>
    '''
    - path: partners/$id/
      flavors: [$id]''';

/// Returns `<folder>: <error>` for every partner under [partnersRoot] whose
/// `partner.json` is not accepted by [PartnerConfig.fromJson].
List<String> partnerConfigLoadProblems(Directory partnersRoot) {
  final problems = <String>[];
  for (final directory in listPartnerDirectories(partnersRoot)) {
    final id = directory.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    try {
      PartnerConfig.fromJson(
        id,
        jsonDecode(
          File(
            joinPath(directory.path, partnerConfigFileName),
          ).readAsStringSync(),
        ),
      );
    } on FormatException catch (error) {
      problems.add('$id: ${error.message}');
    }
  }
  return problems;
}

/// Ids of the real partners: the folders of `partners/` with a
/// `partner.json`.
List<String> realPartnerIds() => [
  for (final directory in listPartnerDirectories(Directory(partnersFolder)))
    directory.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
];

void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('partner_registry_test_');
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('stripYamlComment - Unit Test Suite', () {
    test('Happy Path: removes a trailing comment', () {
      // 1. Arrange
      const line = '    - assets/monamie/  # brand';

      // 2. Act
      final stripped = stripYamlComment(line);

      // 3. Assert
      expect(stripped, '    - assets/monamie/');
    });

    test('Edge Case: removes a whole-line comment', () {
      // 1. Arrange
      const line = '# - path: partners/acme/';

      // 2. Act
      final stripped = stripYamlComment(line);

      // 3. Assert
      expect(stripped, isEmpty);
    });

    test('Edge Case: keeps a # glued to the text', () {
      // 1. Arrange
      const line = '- assets/a#b.png';

      // 2. Act
      final stripped = stripYamlComment(line);

      // 3. Assert
      expect(stripped, '- assets/a#b.png');
    });

    test('Sad Path: keeps a " #" inside quotes', () {
      // 1. Arrange
      const line = '- "assets/a #b.png" # note';

      // 2. Act
      final stripped = stripYamlComment(line);

      // 3. Assert
      expect(stripped, '- "assets/a #b.png"');
    });
  });

  group('parseYamlScalar - Unit Test Suite', () {
    test('Happy Path: returns a plain scalar trimmed', () {
      // 1. Arrange
      const text = ' partners/acme/ ';

      // 2. Act
      final value = parseYamlScalar(text);

      // 3. Assert
      expect(value, 'partners/acme/');
    });

    test('Edge Case: unquotes a double-quoted scalar', () {
      // 1. Arrange
      const text = '"partners/acme/"';

      // 2. Act
      final value = parseYamlScalar(text);

      // 3. Assert
      expect(value, 'partners/acme/');
    });

    test("Edge Case: unquotes a single-quoted scalar with ''", () {
      // 1. Arrange
      const text = "'it''s'";

      // 2. Act
      final value = parseYamlScalar(text);

      // 3. Assert
      expect(value, "it's");
    });

    test('Sad Path: rejects an alias', () {
      // 1. Arrange
      const text = '*partnerAssets';

      // 2. Act
      String action() => parseYamlScalar(text);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: rejects a flow mapping', () {
      // 1. Arrange
      const text = '{path: partners/acme/}';

      // 2. Act
      String action() => parseYamlScalar(text);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: rejects an empty scalar', () {
      // 1. Arrange
      const text = '  ';

      // 2. Act
      String action() => parseYamlScalar(text);

      // 3. Assert
      expect(action, throwsFormatException);
    });
  });

  group('parseYamlFlowSequence - Unit Test Suite', () {
    test('Happy Path: splits a flow sequence of scalars', () {
      // 1. Arrange
      const text = '[acme, "beta"]';

      // 2. Act
      final items = parseYamlFlowSequence(text);

      // 3. Assert
      expect(items, ['acme', 'beta']);
    });

    test('Edge Case: an empty flow sequence has no items', () {
      // 1. Arrange
      const text = '[ ]';

      // 2. Act
      final items = parseYamlFlowSequence(text);

      // 3. Assert
      expect(items, isEmpty);
    });

    test('Sad Path: rejects a scalar that is not a sequence', () {
      // 1. Arrange
      const text = 'acme';

      // 2. Act
      List<String> action() => parseYamlFlowSequence(text);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: rejects nested flow collections', () {
      // 1. Arrange
      const text = '[[acme]]';

      // 2. Act
      List<String> action() => parseYamlFlowSequence(text);

      // 3. Assert
      expect(action, throwsFormatException);
    });
  });

  group('parsePubspecAssets - Unit Test Suite', () {
    test('Happy Path: reads string entries in order', () {
      // 1. Arrange
      final source = pubspecWithAssets('''
    - assets/monamie/
    - assets/aquariustur/''');

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets.map((asset) => asset.path), [
        'assets/monamie/',
        'assets/aquariustur/',
      ]);
    });

    test('Happy Path: reads a map entry with a flow flavors list', () {
      // 1. Arrange
      final source = pubspecWithAssets(partnerEntry('acme'));

      // 2. Act
      final asset = parsePubspecAssets(source).single;

      // 3. Assert
      expect(
        [asset.isMap, asset.path, asset.flavors],
        [
          true,
          'partners/acme/',
          ['acme'],
        ],
      );
    });

    test('Happy Path: reads a map entry with a block flavors list', () {
      // 1. Arrange
      final source = pubspecWithAssets('''
    - path: partners/acme/
      flavors:
        - acme
        - beta''');

      // 2. Act
      final asset = parsePubspecAssets(source).single;

      // 3. Assert
      expect(asset.flavors, ['acme', 'beta']);
    });

    test('Happy Path: records the 1-based line of each entry', () {
      // 1. Arrange
      final source = pubspecWithAssets('''
    - assets/monamie/
${partnerEntry('acme')}''');

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets.map((asset) => asset.line), [9, 10]);
    });

    test('Edge Case: ignores comments and blank lines inside the list', () {
      // 1. Arrange
      final source = pubspecWithAssets('''
    # One entry per partner.

    - path: partners/acme/ # the acme partner
      # only its flavor
      flavors: [acme]''');

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets.single.flavors, ['acme']);
    });

    test('Edge Case: ignores commented-out sample assets after the list', () {
      // 1. Arrange
      final source =
          '''
${pubspecWithAssets('    - assets/monamie/')}
  # To add assets to your application, add an assets section:
  # assets:
  #   - images/a_dot_burr.jpeg
''';

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets.map((asset) => asset.path), ['assets/monamie/']);
    });

    test('Edge Case: accepts list items at the same indent as "assets:"', () {
      // 1. Arrange
      const source = '''
flutter:
  assets:
  - assets/monamie/
  - path: partners/acme/
    flavors: [acme]
  fonts: []
''';

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets.map((asset) => asset.path), [
        'assets/monamie/',
        'partners/acme/',
      ]);
    });

    test('Edge Case: stops at the next key of the flutter section', () {
      // 1. Arrange
      const source = '''
flutter:
  assets:
    - assets/monamie/
  fonts:
    - family: Acme
''';

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets, hasLength(1));
    });

    test('Edge Case: reads a flow sequence of assets', () {
      // 1. Arrange
      const source = '''
flutter:
  assets: [assets/monamie/, partners/]
''';

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets.map((asset) => asset.path), [
        'assets/monamie/',
        'partners/',
      ]);
    });

    test('Edge Case: keeps an unknown key such as the singular "flavor"', () {
      // 1. Arrange
      final source = pubspecWithAssets('''
    - path: partners/acme/
      flavor: [acme]''');

      // 2. Act
      final asset = parsePubspecAssets(source).single;

      // 3. Assert
      expect(
        [asset.fields.keys.toList(), asset.flavors],
        [
          ['path', 'flavor'],
          null,
        ],
      );
    });

    test('Edge Case: ignores an "assets:" key outside the flutter section', () {
      // 1. Arrange
      const source = '''
other:
  assets:
    - partners/
flutter:
  uses-material-design: true
''';

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets, isEmpty);
    });

    test('Edge Case: a pubspec without a flutter section has no assets', () {
      // 1. Arrange
      const source = 'name: app\n';

      // 2. Act
      final assets = parsePubspecAssets(source);

      // 3. Assert
      expect(assets, isEmpty);
    });

    test('Edge Case: reads CRLF line endings', () {
      // 1. Arrange
      final source = pubspecWithAssets(
        partnerEntry('acme'),
      ).replaceAll('\n', '\r\n');

      // 2. Act
      final asset = parsePubspecAssets(source).single;

      // 3. Assert
      expect(asset.flavors, ['acme']);
    });

    test('Sad Path: rejects a flow-mapping entry', () {
      // 1. Arrange
      final source = pubspecWithAssets(
        '    - {path: partners/acme/, flavors: [acme]}',
      );

      // 2. Act
      List<PubspecAsset> action() => parsePubspecAssets(source);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: rejects a duplicate key in an entry', () {
      // 1. Arrange
      final source = pubspecWithAssets('''
    - path: partners/acme/
      flavors: [acme]
      flavors: [beta]''');

      // 2. Act
      List<PubspecAsset> action() => parsePubspecAssets(source);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: rejects an alias entry', () {
      // 1. Arrange
      final source = pubspecWithAssets('    - *partnerAssets');

      // 2. Act
      List<PubspecAsset> action() => parsePubspecAssets(source);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: rejects a misindented line in the list', () {
      // 1. Arrange
      final source = pubspecWithAssets('''
      - assets/monamie/
    - assets/aquariustur/''');

      // 2. Act
      List<PubspecAsset> action() => parsePubspecAssets(source);

      // 3. Assert
      expect(action, throwsFormatException);
    });

    test('Sad Path: rejects tab indentation', () {
      // 1. Arrange
      final source = pubspecWithAssets('\t- partners/');

      // 2. Act
      List<PubspecAsset> action() => parsePubspecAssets(source);

      // 3. Assert
      expect(action, throwsFormatException);
    });
  });

  group('coversPartnersFolder - Unit Test Suite', () {
    test('Happy Path: a partner folder is under partners/', () {
      // 1. Arrange
      const path = 'partners/acme/';

      // 2. Act
      final covers = coversPartnersFolder(path);

      // 3. Assert
      expect(covers, isTrue);
    });

    test('Edge Case: partners/ itself is covered', () {
      // 1. Arrange
      const path = 'partners/';

      // 2. Act
      final covers = coversPartnersFolder(path);

      // 3. Assert
      expect(covers, isTrue);
    });

    test('Edge Case: a ./ prefix is still under partners/', () {
      // 1. Arrange
      const path = './partners/acme/android/';

      // 2. Act
      final covers = coversPartnersFolder(path);

      // 3. Assert
      expect(covers, isTrue);
    });

    test('Edge Case: a single file under partners/ is covered', () {
      // 1. Arrange
      const path = 'partners/acme/partner.json';

      // 2. Act
      final covers = coversPartnersFolder(path);

      // 3. Assert
      expect(covers, isTrue);
    });

    test('Edge Case: a path that escapes partners/ with .. is not under '
        'it', () {
      // 1. Arrange
      const path = 'partners/../assets/monamie/';

      // 2. Act
      final covers = coversPartnersFolder(path);

      // 3. Assert
      expect(covers, isFalse);
    });

    test('Sad Path: a folder that only starts with "partners" is not under '
        'it', () {
      // 1. Arrange
      const path = 'partners_old/acme/';

      // 2. Act
      final covers = coversPartnersFolder(path);

      // 3. Assert
      expect(covers, isFalse);
    });

    test('Sad Path: another asset folder is not under partners/', () {
      // 1. Arrange
      const path = 'assets/aquariustur/';

      // 2. Act
      final covers = coversPartnersFolder(path);

      // 3. Assert
      expect(covers, isFalse);
    });
  });

  group('partnerAssetProblems - Unit Test Suite', () {
    test('Happy Path: accepts one flavor-only entry per partner', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - assets/monamie/
${partnerEntry('acme')}
${partnerEntry('beta')}'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme', 'beta']);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: no partners and no partner entries has no problems', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('    - assets/monamie/'),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, const []);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: accepts quoted path and flavor values', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: "partners/acme/"
      flavors: ['acme']'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Sad Path: reports a partner without an entry', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets(partnerEntry('acme')),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme', 'beta']);

      // 3. Assert
      expect(problems, [contains('partners/beta/')]);
    });

    test('Sad Path: reports a partner with two entries', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('${partnerEntry('acme')}\n${partnerEntry('acme')}'),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, [contains('2 asset entries')]);
    });

    test('Sad Path: reports the singular "flavor" key, which Flutter ignores '
        'and bundles into every flavor', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: partners/acme/
      flavor: [acme]'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, hasLength(2));
    });

    test('Sad Path: reports a partner entry without flavors', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('    - path: partners/acme/'),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, contains(contains('covers partners/')));
    });

    test('Sad Path: reports a partner bundled into another flavor', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: partners/acme/
      flavors: [beta]
${partnerEntry('beta')}'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme', 'beta']);

      // 3. Assert
      expect(problems, hasLength(2));
    });

    test('Sad Path: reports a partner bundled into two flavors', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: partners/acme/
      flavors: [acme, beta]
${partnerEntry('beta')}'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme', 'beta']);

      // 3. Assert
      expect(problems, hasLength(2));
    });

    test('Sad Path: reports an empty flavors list', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: partners/acme/
      flavors: []'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, hasLength(2));
    });

    test('Sad Path: reports a scalar flavors value', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: partners/acme/
      flavors: acme'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, hasLength(2));
    });

    test('Sad Path: reports a partner entry with an extra key', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: partners/acme/
      flavors: [acme]
      flavor: [beta]'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, hasLength(2));
    });

    test('Sad Path: reports a string entry for a partner folder next to the '
        'correct entry', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
${partnerEntry('acme')}
    - partners/acme/'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, [contains('covers partners/')]);
    });

    test('Sad Path: reports a string entry for the whole partners/ folder', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
${partnerEntry('acme')}
    - partners/'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, [contains('covers partners/')]);
    });

    test('Sad Path: reports a subfolder of a partner, even flavor-only', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
${partnerEntry('acme')}
    - path: partners/acme/web/
      flavors: [acme]'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, [contains('partners/acme/web/')]);
    });

    test('Sad Path: reports a flavor-only entry for a folder that is not a '
        'partner', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
${partnerEntry('acme')}
${partnerEntry('ghost')}'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, [contains('partners/ghost/')]);
    });

    test('Sad Path: reports a partner path without the trailing slash', () {
      // 1. Arrange
      final assets = parsePubspecAssets(
        pubspecWithAssets('''
    - path: partners/acme
      flavors: [acme]'''),
      );

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, hasLength(2));
    });

    test('Sad Path: reports a partner entry inside a flow asset list', () {
      // 1. Arrange
      final assets = parsePubspecAssets('''
flutter:
  assets: [partners/acme/]
''');

      // 2. Act
      final problems = partnerAssetProblems(assets, ['acme']);

      // 3. Assert
      expect(problems, hasLength(2));
    });
  });

  group('partnerConfigLoadProblems - Unit Test Suite', () {
    test('Happy Path: accepts a partner.json the app can load', () {
      // 1. Arrange
      File(joinPath(tempRoot.path, 'acme/$partnerConfigFileName'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '{"name": "Acme", "colors": '
          '{"primary": "#112233", "secondary": "#FFFFFF"}}',
        );

      // 2. Act
      final problems = partnerConfigLoadProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Edge Case: ignores folders without partner.json', () {
      // 1. Arrange
      Directory(joinPath(tempRoot.path, 'notes')).createSync();

      // 2. Act
      final problems = partnerConfigLoadProblems(tempRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Sad Path: reports a partner.json missing colors.secondary', () {
      // 1. Arrange
      File(joinPath(tempRoot.path, 'acme/$partnerConfigFileName'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '{"name": "Acme", "colors": {"primary": "#112233"}}',
        );

      // 2. Act
      final problems = partnerConfigLoadProblems(tempRoot);

      // 3. Assert
      expect(problems, [allOf(startsWith('acme: '), contains('secondary'))]);
    });

    test('Sad Path: reports a folder name that is not a valid partner id', () {
      // 1. Arrange
      File(joinPath(tempRoot.path, 'testacme/$partnerConfigFileName'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '{"name": "Acme", "colors": '
          '{"primary": "#112233", "secondary": "#FFFFFF"}}',
        );

      // 2. Act
      final problems = partnerConfigLoadProblems(tempRoot);

      // 3. Assert
      expect(problems, [startsWith('testacme: ')]);
    });

    test('Sad Path: reports malformed JSON', () {
      // 1. Arrange
      File(joinPath(tempRoot.path, 'acme/$partnerConfigFileName'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('{"name": ');

      // 2. Act
      final problems = partnerConfigLoadProblems(tempRoot);

      // 3. Assert
      expect(problems, [startsWith('acme: ')]);
    });
  });

  group('Repository partner registry - Contract Test Suite', () {
    test('Happy Path: the repository declares at least one partner', () {
      // 1. Arrange
      final partnersRoot = Directory(partnersFolder);

      // 2. Act
      final partners = listPartnerDirectories(partnersRoot);

      // 3. Assert
      expect(partners, isNotEmpty);
    });

    test('Happy Path: every partners/*/partner.json loads with '
        'PartnerConfig.fromJson(<folder name>, ...)', () {
      // 1. Arrange
      final partnersRoot = Directory(partnersFolder);

      // 2. Act
      final problems = partnerConfigLoadProblems(partnersRoot);

      // 3. Assert
      expect(problems, isEmpty);
    });

    test('Happy Path: pubspec.yaml bundles each partner folder only into its '
        'own flavor and nothing else under partners/', () {
      // 1. Arrange
      final assets = parsePubspecAssets(File(pubspecPath).readAsStringSync());
      final ids = realPartnerIds();

      // 2. Act
      final problems = partnerAssetProblems(assets, ids);

      // 3. Assert
      expect(problems, isEmpty);
    });
  });
}
