import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';

const white = Color(0xFFFFFFFF);

/// A complete `themes/{id}` document of the central catalog.
Map<String, Object?> fullThemeDoc() => {
  'name': 'Oceano',
  'primary': '#0B7F7B',
  'dark': '#0A3D3B',
  'light': '#D3EEEC',
  'onPrimary': '#FFFFFF',
  'onDark': '#F0F0F0',
  'order': 3,
  'active': true,
};

/// A catalog theme with only the fields the picker and resolver look at.
PartnerTheme themeOf(String id, {int order = 0, bool active = true}) =>
    PartnerTheme(
      id: id,
      name: id,
      primary: const Color(0xFF112233),
      dark: const Color(0xFF000000),
      light: const Color(0xFFEEEEEE),
      onPrimary: white,
      onDark: white,
      order: order,
      active: active,
    );

/// The fields of [theme], so two themes can be compared by value.
List<Object?> fieldsOf(PartnerTheme theme) => [
  theme.id,
  theme.name,
  theme.primary,
  theme.dark,
  theme.light,
  theme.onPrimary,
  theme.onDark,
  theme.order,
  theme.active,
];

void main() {
  group('PartnerTheme.fromJson - Unit Test Suite', () {
    test('Happy Path: a complete catalog document becomes the theme', () {
      // 1. Arrange
      final data = fullThemeDoc();

      // 2. Act
      final theme = PartnerTheme.fromJson('oceano', data);

      // 3. Assert
      expect(fieldsOf(theme!), [
        'oceano',
        'Oceano',
        const Color(0xFF0B7F7B),
        const Color(0xFF0A3D3B),
        const Color(0xFFD3EEEC),
        const Color(0xFFFFFFFF),
        const Color(0xFFF0F0F0),
        3,
        true,
      ]);
    });

    test('Happy Path: lower-case colors are accepted', () {
      // 1. Arrange
      final data = {
        ...fullThemeDoc(),
        'primary': '#0b7f7b',
        'dark': '#0a3d3b',
        'light': '#d3eeec',
      };

      // 2. Act
      final theme = PartnerTheme.fromJson('oceano', data);

      // 3. Assert
      expect(
        [theme?.primary, theme?.dark, theme?.light],
        [
          const Color(0xFF0B7F7B),
          const Color(0xFF0A3D3B),
          const Color(0xFFD3EEEC),
        ],
      );
    });

    test('Happy Path: active: false gives an inactive theme', () {
      // 1. Arrange
      final data = {...fullThemeDoc(), 'active': false};

      // 2. Act
      final theme = PartnerTheme.fromJson('oceano', data);

      // 3. Assert
      expect(theme?.active, isFalse);
    });

    test('Edge Case: a missing name falls back to the id', () {
      // 1. Arrange
      final data = fullThemeDoc()..remove('name');

      // 2. Act
      final theme = PartnerTheme.fromJson('oceano', data);

      // 3. Assert
      expect(theme?.name, 'oceano');
    });

    test('Edge Case: a blank name falls back to the id', () {
      // 1. Arrange
      final data = {...fullThemeDoc(), 'name': '   '};

      // 2. Act
      final theme = PartnerTheme.fromJson('oceano', data);

      // 3. Assert
      expect(theme?.name, 'oceano');
    });

    test('Edge Case: missing onPrimary and onDark fall back to white', () {
      // 1. Arrange
      final data = fullThemeDoc()
        ..remove('onPrimary')
        ..remove('onDark');

      // 2. Act
      final theme = PartnerTheme.fromJson('oceano', data);

      // 3. Assert
      expect([theme?.onPrimary, theme?.onDark], [white, white]);
    });

    test('Edge Case: malformed onPrimary and onDark fall back to white', () {
      // 1. Arrange
      final data = {...fullThemeDoc(), 'onPrimary': 'black', 'onDark': '#123'};

      // 2. Act
      final theme = PartnerTheme.fromJson('oceano', data);

      // 3. Assert
      expect([theme?.onPrimary, theme?.onDark], [white, white]);
    });

    const nonIntOrders = <String, Object?>{
      'missing': null,
      'a string': '3',
      'a double': 3.5,
    };
    for (final MapEntry(key: label, value: order) in nonIntOrders.entries) {
      test('Edge Case: an order that is $label falls back to 0', () {
        // 1. Arrange
        final data = {...fullThemeDoc(), 'order': order};

        // 2. Act
        final theme = PartnerTheme.fromJson('oceano', data);

        // 3. Assert
        expect(theme?.order, 0);
      });
    }

    const notExactlyFalse = <String, Object?>{
      'missing': null,
      'the string "false"': 'false',
      '0': 0,
    };
    for (final MapEntry(key: label, value: active) in notExactlyFalse.entries) {
      test('Edge Case: an active flag that is $label keeps the theme '
          'active', () {
        // 1. Arrange
        final data = {...fullThemeDoc(), 'active': active};

        // 2. Act
        final theme = PartnerTheme.fromJson('oceano', data);

        // 3. Assert
        expect(theme?.active, isTrue);
      });
    }

    const notMaps = <String, Object?>{
      'null': null,
      'a string': '#0B7F7B',
      'a list': ['#0B7F7B', '#0A3D3B', '#D3EEEC'],
    };
    for (final MapEntry(key: label, value: data) in notMaps.entries) {
      test('Sad Path: $label is not a theme', () {
        // 1. Arrange
        const id = 'oceano';

        // 2. Act
        final theme = PartnerTheme.fromJson(id, data);

        // 3. Assert
        expect(theme, isNull);
      });
    }

    const requiredColors = ['primary', 'dark', 'light'];
    for (final key in requiredColors) {
      test('Sad Path: a missing $key is not a theme', () {
        // 1. Arrange
        final data = fullThemeDoc()..remove(key);

        // 2. Act
        final theme = PartnerTheme.fromJson('oceano', data);

        // 3. Assert
        expect(theme, isNull);
      });

      test('Sad Path: a malformed $key is not a theme', () {
        // 1. Arrange
        final data = {...fullThemeDoc(), key: '#0B7F7'};

        // 2. Act
        final theme = PartnerTheme.fromJson('oceano', data);

        // 3. Assert
        expect(theme, isNull);
      });
    }
  });

  group('PartnerTheme.toJson - Unit Test Suite', () {
    test('Happy Path: fromJson reads back what toJson wrote', () {
      // 1. Arrange
      final theme = PartnerTheme.fromJson('oceano', {
        ...fullThemeDoc(),
        'active': false,
      })!;
      final json = theme.toJson();

      // 2. Act
      final copy = PartnerTheme.fromJson('oceano', json);

      // 3. Assert
      expect(fieldsOf(copy!), fieldsOf(theme));
    });

    test('Edge Case: colors are written as upper-case #RRGGBB', () {
      // 1. Arrange
      const theme = PartnerTheme(
        id: 'oceano',
        name: 'Oceano',
        primary: Color(0xFF0B7F7B),
        dark: Color(0xFF0A3D3B),
        light: Color(0xFFD3EEEC),
        onPrimary: Color(0xFFFFFFFF),
        onDark: Color(0xFF00000A),
      );

      // 2. Act
      final json = theme.toJson();

      // 3. Assert
      expect(
        [
          json['primary'],
          json['dark'],
          json['light'],
          json['onPrimary'],
          json['onDark'],
        ],
        ['#0B7F7B', '#0A3D3B', '#D3EEEC', '#FFFFFF', '#00000A'],
      );
    });

    test('Sad Path: the alpha channel is not written', () {
      // 1. Arrange
      const theme = PartnerTheme(
        id: 'oceano',
        name: 'Oceano',
        primary: Color(0x800B7F7B),
        dark: Color(0xFF0A3D3B),
        light: Color(0xFFD3EEEC),
        onPrimary: Color(0xFFFFFFFF),
        onDark: Color(0xFFFFFFFF),
      );

      // 2. Act
      final json = theme.toJson();

      // 3. Assert
      expect(json['primary'], '#0B7F7B');
    });
  });

  group('defaultPartnerTheme - Unit Test Suite', () {
    test('Happy Path: the default theme is Grafite with its catalog '
        'tones', () {
      // 1. Arrange
      const theme = defaultPartnerTheme;

      // 2. Act
      final values = [theme.id, theme.primary, theme.dark, theme.light];

      // 3. Assert
      expect(values, [
        'grafite',
        const Color(0xFF3F4754),
        const Color(0xFF1F2128),
        const Color(0xFFDCDEE2),
      ]);
    });
  });

  group('resolvePartnerTheme - Unit Test Suite', () {
    test('Happy Path: a themeId in the catalog resolves to that theme', () {
      // 1. Arrange
      final oceano = themeOf('oceano');
      final catalog = {'oceano': oceano, 'grafite': defaultPartnerTheme};

      // 2. Act
      final theme = resolvePartnerTheme('oceano', catalog);

      // 3. Assert
      expect(theme, same(oceano));
    });

    test('Edge Case: an inactive theme still resolves to itself', () {
      // 1. Arrange
      final retired = themeOf('retired', active: false);
      final catalog = {'retired': retired};

      // 2. Act
      final theme = resolvePartnerTheme('retired', catalog);

      // 3. Assert
      expect(theme, same(retired));
    });

    test('Edge Case: a null themeId resolves to Grafite', () {
      // 1. Arrange
      final catalog = {'oceano': themeOf('oceano')};

      // 2. Act
      final theme = resolvePartnerTheme(null, catalog);

      // 3. Assert
      expect(theme.id, 'grafite');
    });

    test('Sad Path: a themeId missing from the catalog resolves to '
        'Grafite', () {
      // 1. Arrange
      final catalog = {'oceano': themeOf('oceano')};

      // 2. Act
      final theme = resolvePartnerTheme('unknown', catalog);

      // 3. Assert
      expect(theme.id, 'grafite');
    });

    test('Sad Path: an empty catalog resolves to Grafite', () {
      // 1. Arrange
      const catalog = <String, PartnerTheme>{};

      // 2. Act
      final theme = resolvePartnerTheme('oceano', catalog);

      // 3. Assert
      expect(theme.id, 'grafite');
    });
  });

  group('pickableThemes - Unit Test Suite', () {
    test('Happy Path: active themes come sorted by order', () {
      // 1. Arrange
      final catalog = [
        themeOf('c', order: 3),
        themeOf('a', order: 1),
        themeOf('b', order: 2),
      ];

      // 2. Act
      final themes = pickableThemes(catalog);

      // 3. Assert
      expect(themes.map((theme) => theme.id), ['a', 'b', 'c']);
    });

    test('Edge Case: an empty catalog gives no themes', () {
      // 1. Arrange
      const catalog = <PartnerTheme>[];

      // 2. Act
      final themes = pickableThemes(catalog);

      // 3. Assert
      expect(themes, isEmpty);
    });

    test('Sad Path: inactive themes are left out', () {
      // 1. Arrange
      final catalog = [
        themeOf('a', order: 1),
        themeOf('retired', order: 0, active: false),
        themeOf('b', order: 2),
      ];

      // 2. Act
      final themes = pickableThemes(catalog);

      // 3. Assert
      expect(themes.map((theme) => theme.id), ['a', 'b']);
    });
  });

  group('parseHexColor - Unit Test Suite', () {
    test('Happy Path: upper-case #RRGGBB parses to an opaque color', () {
      // 1. Arrange
      const value = '#0B7F7B';

      // 2. Act
      final color = parseHexColor(value);

      // 3. Assert
      expect(color, const Color(0xFF0B7F7B));
    });

    test('Edge Case: lower-case #rrggbb parses to the same color', () {
      // 1. Arrange
      const value = '#0b7f7b';

      // 2. Act
      final color = parseHexColor(value);

      // 3. Assert
      expect(color, const Color(0xFF0B7F7B));
    });

    const malformed = <String, Object?>{
      'no leading #': '0B7F7B',
      'five digits': '#0B7F7',
      'non-hex digits': '#GGGGGG',
      'an int': 42,
      'null': null,
    };
    for (final MapEntry(key: label, value: value) in malformed.entries) {
      test('Sad Path: $label is not a color', () {
        // 1. Arrange
        final input = value;

        // 2. Act
        final color = parseHexColor(input);

        // 3. Assert
        expect(color, isNull);
      });
    }
  });

  group('formatHexColor - Unit Test Suite', () {
    test('Happy Path: a color is formatted as upper-case #RRGGBB', () {
      // 1. Arrange
      const color = Color(0xFF0B7F7B);

      // 2. Act
      final hex = formatHexColor(color);

      // 3. Assert
      expect(hex, '#0B7F7B');
    });

    test('Edge Case: leading zero channels are kept', () {
      // 1. Arrange
      const color = Color(0xFF00000A);

      // 2. Act
      final hex = formatHexColor(color);

      // 3. Assert
      expect(hex, '#00000A');
    });

    test('Sad Path: the alpha channel is dropped', () {
      // 1. Arrange
      const color = Color(0x400B7F7B);

      // 2. Act
      final hex = formatHexColor(color);

      // 3. Assert
      expect(hex, '#0B7F7B');
    });
  });
}
