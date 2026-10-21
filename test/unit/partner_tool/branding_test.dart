import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/src/branding.dart';
import '../../../tool/src/partners.dart';

const logoSource =
    '<svg xmlns="http://www.w3.org/2000/svg"><rect width="1" height="1"/></svg>';
const iconSource =
    '<svg xmlns="http://www.w3.org/2000/svg"><circle r="1"/></svg>';

/// Returns the message of the [PartnerToolException] thrown by [action], or
/// fails the test when it does not throw one.
String messageOf(void Function() action) {
  try {
    action();
  } on PartnerToolException catch (error) {
    return error.message;
  }
  fail('Expected a PartnerToolException.');
}

/// An SVG of exactly [bytes] ASCII bytes.
String svgOfSize(int bytes) {
  const open = '<svg>';
  const close = '</svg>';
  return '$open${' ' * (bytes - open.length - close.length)}$close';
}

void main() {
  late Directory temp;

  File fileWith(String name, String contents) =>
      File(p.join(temp.path, name))..writeAsStringSync(contents);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('branding_test_');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  group('buildBrandingDocument - Unit Test Suite', () {
    test('Happy Path: a name only gives a name and empty colors', () {
      // 1. Arrange
      const name = 'AquariusTur';

      // 2. Act
      final document = buildBrandingDocument(name: name);

      // 3. Assert
      expect(document, {'name': 'AquariusTur', 'colors': <String, Object?>{}});
    });

    test('Happy Path: every field is put in the document', () {
      // 1. Arrange
      final logo = fileWith('logo.svg', logoSource);
      final icon = fileWith('icon.svg', iconSource);

      // 2. Act
      final document = buildBrandingDocument(
        name: 'AquariusTur',
        primary: '#0ABAB5',
        secondary: '#FFFFFF',
        logo: logo,
        icon: icon,
      );

      // 3. Assert
      expect(document, {
        'name': 'AquariusTur',
        'colors': {'primary': '#0ABAB5', 'secondary': '#FFFFFF'},
        'logoSvg': logoSource,
        'iconSvg': iconSource,
      });
    });

    test('Edge Case: the name is trimmed', () {
      // 1. Arrange
      const name = '  AquariusTur \n';

      // 2. Act
      final document = buildBrandingDocument(name: name);

      // 3. Assert
      expect(document['name'], 'AquariusTur');
    });

    test('Edge Case: colors are written in upper case', () {
      // 1. Arrange
      const primary = '#0abab5';

      // 2. Act
      final document = buildBrandingDocument(name: 'Acme', primary: primary);

      // 3. Assert
      expect(document['colors'], {'primary': '#0ABAB5'});
    });

    test('Edge Case: a name that only starts with "MonAmie" is accepted', () {
      // 1. Arrange
      const name = 'MonAmieTur';

      // 2. Act
      final document = buildBrandingDocument(name: name);

      // 3. Assert
      expect(document['name'], 'MonAmieTur');
    });

    test('Edge Case: an SVG of exactly 200 KiB is accepted', () {
      // 1. Arrange
      final logo = fileWith('logo.svg', svgOfSize(maxSvgBytes));

      // 2. Act
      final document = buildBrandingDocument(name: 'Acme', logo: logo);

      // 3. Assert
      expect((document['logoSvg'] as String).length, maxSvgBytes);
    });

    test('Edge Case: an SVG with a <scripted> element is not a script', () {
      // 1. Arrange
      final logo = fileWith(
        'logo.svg',
        '<svg><metadata><scripted/></metadata></svg>',
      );

      // 2. Act
      final document = buildBrandingDocument(name: 'Acme', logo: logo);

      // 3. Assert
      expect(
        document['logoSvg'],
        '<svg><metadata><scripted/></metadata></svg>',
      );
    });

    test('Sad Path: a blank name is rejected', () {
      // 1. Arrange
      const name = '   ';

      // 2. Act
      final message = messageOf(() => buildBrandingDocument(name: name));

      // 3. Assert
      expect(message, contains('blank'));
    });

    test('Sad Path: a name with the "MonAmie " prefix is rejected', () {
      // 1. Arrange
      const name = 'MonAmie AquariusTur';

      // 2. Act
      final message = messageOf(() => buildBrandingDocument(name: name));

      // 3. Assert
      expect(message, contains("'MonAmie '"));
    });

    test('Sad Path: the "MonAmie " prefix is rejected in any case', () {
      // 1. Arrange
      const name = '  monamie AquariusTur';

      // 2. Act
      final message = messageOf(() => buildBrandingDocument(name: name));

      // 3. Assert
      expect(message, contains("'MonAmie '"));
    });

    const badColors = ['teal', '0ABAB5', '#0AB', '#FF0ABAB5', '#GGGGGG', ''];
    for (final color in badColors) {
      test('Sad Path: the primary color "$color" is rejected naming '
          '--primary', () {
        // 1. Arrange
        final primary = color;

        // 2. Act
        final message = messageOf(
          () => buildBrandingDocument(name: 'Acme', primary: primary),
        );

        // 3. Assert
        expect(message, contains('--primary'));
      });
    }

    test('Sad Path: a bad secondary color is rejected naming --secondary', () {
      // 1. Arrange
      const secondary = 'white';

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', secondary: secondary),
      );

      // 3. Assert
      expect(message, contains('--secondary'));
    });

    test('Sad Path: a missing logo file is rejected', () {
      // 1. Arrange
      final logo = File(p.join(temp.path, 'missing.svg'));

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', logo: logo),
      );

      // 3. Assert
      expect(message, allOf(contains('--logo'), contains('does not exist')));
    });

    test('Sad Path: a file that is not an SVG is rejected', () {
      // 1. Arrange
      final icon = fileWith('icon.png', 'PNG-ish bytes, no markup');

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', icon: icon),
      );

      // 3. Assert
      expect(message, allOf(contains('--icon'), contains('not an SVG')));
    });

    test('Sad Path: an SVG without a closing tag is rejected', () {
      // 1. Arrange
      final logo = fileWith(
        'logo.svg',
        '<svg xmlns="http://www.w3.org/2000/svg">',
      );

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', logo: logo),
      );

      // 3. Assert
      expect(message, contains('not an SVG'));
    });

    test('Sad Path: an SVG with a <script> is rejected', () {
      // 1. Arrange
      final logo = fileWith(
        'logo.svg',
        '<svg><script>alert(1)</script><rect/></svg>',
      );

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', logo: logo),
      );

      // 3. Assert
      expect(message, contains('<script>'));
    });

    test('Sad Path: an upper case <SCRIPT> is rejected too', () {
      // 1. Arrange
      final icon = fileWith(
        'icon.svg',
        '<svg><SCRIPT type="text/javascript">x()</SCRIPT></svg>',
      );

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', icon: icon),
      );

      // 3. Assert
      expect(message, contains('<script>'));
    });

    test('Sad Path: an SVG over 200 KiB is rejected', () {
      // 1. Arrange
      final logo = fileWith('logo.svg', svgOfSize(maxSvgBytes + 1));

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', logo: logo),
      );

      // 3. Assert
      expect(message, contains('200 KiB'));
    });

    test('Sad Path: a file that is not UTF-8 is rejected', () {
      // 1. Arrange
      final logo = File(p.join(temp.path, 'logo.svg'))
        ..writeAsBytesSync([0x3C, 0x73, 0x76, 0x67, 0x3E, 0xFF, 0xFE, 0xC3]);

      // 2. Act
      final message = messageOf(
        () => buildBrandingDocument(name: 'Acme', logo: logo),
      );

      // 3. Assert
      expect(message, contains('not UTF-8'));
    });
  });

  group('svgWarnings - Unit Test Suite', () {
    test('Happy Path: an SVG without live text has no warnings', () {
      // 1. Arrange
      const svg = '<svg><path d="M0 0h1v1z"/></svg>';

      // 2. Act
      final warnings = svgWarnings('--logo', svg);

      // 3. Assert
      expect(warnings, isEmpty);
    });

    test('Edge Case: a <textPath> alone is not live <text>', () {
      // 1. Arrange
      const svg = '<svg><textPath href="#p"/></svg>';

      // 2. Act
      final warnings = svgWarnings('--logo', svg);

      // 3. Assert
      expect(warnings, isEmpty);
    });

    test('Sad Path: live <text> gives one warning naming the option', () {
      // 1. Arrange
      const svg = '<svg><text x="0" y="10">AquariusTur</text></svg>';

      // 2. Act
      final warnings = svgWarnings('--logo', svg);

      // 3. Assert
      expect(warnings, [allOf(contains('--logo'), contains('<text>'))]);
    });

    test('Sad Path: several <text> elements still give a single warning', () {
      // 1. Arrange
      const svg = '<svg><text>Aquarius</text><text>Tur</text></svg>';

      // 2. Act
      final warnings = svgWarnings('--icon', svg);

      // 3. Assert
      expect(warnings, hasLength(1));
    });
  });
}
