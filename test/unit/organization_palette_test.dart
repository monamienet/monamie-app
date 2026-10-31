import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/config/organization/organization_palette.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart';

/// The AquariusTur brand color, the calibration point of issue #35.
const aquariusTurPrimary = Color(0xFF0ABAB5);

/// The shades the app used for [aquariusTurPrimary] before it became
/// white-label (issue #35).
const aquariusTurDark = Color(0xFF073B40);
const aquariusTurLight = Color(0xFFCCF1F0);
const aquariusTurAccentDark = Color(0xFF052E32);
const aquariusTurAccent = Color(0xFF088F8B);

/// One row of the shade table of issue #35.
typedef ShadeSpec = ({
  double hueShift,
  double saturationFactor,
  double lightness,
});

const darkSpec = (hueShift: 6.97, saturationFactor: 0.894, lightness: 0.139);
const lightSpec = (hueShift: 0.08, saturationFactor: 0.634, lightness: 0.873);
const accentDarkSpec = (
  hueShift: 7.04,
  saturationFactor: 0.911,
  lightness: 0.108,
);
const accentSpec = (hueShift: -0.07, saturationFactor: 0.996, lightness: 0.296);

/// One 8-bit step of a color channel, the precision a [Color] keeps.
const channelStep = 1 / 255;

/// The shade [spec] of [primary], derived straight from the issue's rule:
/// hue shifted (wrapping into [0, 360)), saturation scaled (clamped to
/// [0, 1]) and lightness replaced.
Color expectedShade(Color primary, ShadeSpec spec) {
  final hsl = HSLColor.fromColor(primary);
  return HSLColor.fromAHSL(
    hsl.alpha,
    (hsl.hue + spec.hueShift) % 360,
    (hsl.saturation * spec.saturationFactor).clamp(0.0, 1.0),
    spec.lightness,
  ).toColor();
}

/// Whether the red, green and blue channels of [color] are equal.
bool isGrey(Color color) => color.r == color.g && color.g == color.b;

/// A catalog theme whose dark and light tones are not the shades the
/// AquariusTur primary would derive, so a derived palette is told apart.
const oceanoTheme = OrganizationTheme(
  id: 'oceano',
  name: 'Oceano',
  primary: aquariusTurPrimary,
  dark: Color(0xFF102030),
  light: Color(0xFFF0E0D0),
  onPrimary: Color(0xFFFFFFFF),
  onDark: Color(0xFFFFFFFF),
);

void main() {
  group('OrganizationPalette.fromColors (AquariusTur calibration) - '
      'Unit Test Suite', () {
    test('Happy Path: primary is the input brand color, unchanged', () {
      // 1. Arrange
      const background = Color(0xFFFFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: aquariusTurPrimary,
        background: background,
      );

      // 3. Assert
      expect(palette.primary, aquariusTurPrimary);
    });

    test('Happy Path: #0ABAB5 gives the dark shade #073B40', () {
      // 1. Arrange
      const background = Color(0xFFFFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: aquariusTurPrimary,
        background: background,
      );

      // 3. Assert
      expect(palette.dark, aquariusTurDark);
    });

    test('Happy Path: #0ABAB5 gives the light shade #CCF1F0', () {
      // 1. Arrange
      const background = Color(0xFFFFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: aquariusTurPrimary,
        background: background,
      );

      // 3. Assert
      expect(palette.light, aquariusTurLight);
    });

    test('Happy Path: #0ABAB5 gives the accentDark shade #052E32', () {
      // 1. Arrange
      const background = Color(0xFFFFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: aquariusTurPrimary,
        background: background,
      );

      // 3. Assert
      expect(palette.accentDark, aquariusTurAccentDark);
    });

    test('Happy Path: #0ABAB5 gives the accent shade #088F8B', () {
      // 1. Arrange
      const background = Color(0xFFFFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: aquariusTurPrimary,
        background: background,
      );

      // 3. Assert
      expect(palette.accent, aquariusTurAccent);
    });

    test('Happy Path: background is the input background, unchanged', () {
      // 1. Arrange
      const background = Color(0xFFFFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: aquariusTurPrimary,
        background: background,
      );

      // 3. Assert
      expect(palette.background, background);
    });
  });

  group('OrganizationPalette.fromColors (shade rule) - Unit Test Suite', () {
    test('Happy Path: a non-AquariusTur primary follows the shade table', () {
      // 1. Arrange
      const primary = Color(0xFF8E24AA);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: primary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        [palette.dark, palette.light, palette.accentDark, palette.accent],
        [
          expectedShade(primary, darkSpec),
          expectedShade(primary, lightSpec),
          expectedShade(primary, accentDarkSpec),
          expectedShade(primary, accentSpec),
        ],
      );
    });

    test('Happy Path: background is not derived from primary', () {
      // 1. Arrange
      const background = Color(0xFF123456);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: const Color(0xFFFF5722),
        background: background,
      );

      // 3. Assert
      expect(palette.background, background);
    });

    test(
      'Edge Case: a grey primary gives grey shades (saturation stays 0)',
      () {
        // 1. Arrange
        const greyPrimary = Color(0xFF808080);

        // 2. Act
        final palette = OrganizationPalette.fromColors(
          primary: greyPrimary,
          background: const Color(0xFFFFFFFF),
        );

        // 3. Assert
        expect(
          [
            palette.dark,
            palette.light,
            palette.accentDark,
            palette.accent,
          ].map(isGrey).toList(),
          [true, true, true, true],
        );
      },
    );

    test('Edge Case: a black primary still gives the fixed lightness of '
        'every shade', () {
      // 1. Arrange
      const blackPrimary = Color(0xFF000000);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: blackPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        [
          palette.dark,
          palette.light,
          palette.accentDark,
          palette.accent,
        ].map((shade) => HSLColor.fromColor(shade).lightness).toList(),
        [
          closeTo(darkSpec.lightness, channelStep),
          closeTo(lightSpec.lightness, channelStep),
          closeTo(accentDarkSpec.lightness, channelStep),
          closeTo(accentSpec.lightness, channelStep),
        ],
      );
    });

    test('Edge Case: a white primary still gives the fixed lightness of '
        'every shade', () {
      // 1. Arrange
      const whitePrimary = Color(0xFFFFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: whitePrimary,
        background: const Color(0xFF000000),
      );

      // 3. Assert
      expect(
        [
          palette.dark,
          palette.light,
          palette.accentDark,
          palette.accent,
        ].map((shade) => HSLColor.fromColor(shade).lightness).toList(),
        [
          closeTo(darkSpec.lightness, channelStep),
          closeTo(lightSpec.lightness, channelStep),
          closeTo(accentDarkSpec.lightness, channelStep),
          closeTo(accentSpec.lightness, channelStep),
        ],
      );
    });

    test('Edge Case: the shades do not depend on the primary lightness', () {
      // 1. Arrange
      // Same hue and saturation as #0ABAB5, much lighter.
      final lighterPrimary = HSLColor.fromColor(
        aquariusTurPrimary,
      ).withLightness(0.8).toColor();

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: lighterPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        [palette.dark, palette.light, palette.accentDark, palette.accent],
        [
          expectedShade(lighterPrimary, darkSpec),
          expectedShade(lighterPrimary, lightSpec),
          expectedShade(lighterPrimary, accentDarkSpec),
          expectedShade(lighterPrimary, accentSpec),
        ],
      );
    });

    test('Edge Case: a hue near 360 wraps around for the dark shade', () {
      // 1. Arrange
      // Hue ~359.06 degrees: +6.97 must wrap to ~6.03, not exceed 360.
      const redPrimary = Color(0xFFFF0004);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: redPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(palette.dark, expectedShade(redPrimary, darkSpec));
    });

    test('Edge Case: a wrapped hue lands in [0, 360)', () {
      // 1. Arrange
      const redPrimary = Color(0xFFFF0004);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: redPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        HSLColor.fromColor(palette.accentDark).hue,
        allOf(greaterThanOrEqualTo(0), lessThan(360)),
      );
    });

    test('Edge Case: a hue of 0 wraps backwards for the accent shade', () {
      // 1. Arrange
      // Hue 0 degrees: -0.07 must wrap to 359.93, not go negative.
      const pureRed = Color(0xFFFF0000);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: pureRed,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(palette.accent, expectedShade(pureRed, accentSpec));
    });

    test('Edge Case: an opaque primary gives opaque shades', () {
      // 1. Arrange
      const opaquePrimary = aquariusTurPrimary;

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: opaquePrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        [
          palette.dark,
          palette.light,
          palette.accentDark,
          palette.accent,
        ].map((shade) => shade.a).toList(),
        [1.0, 1.0, 1.0, 1.0],
      );
    });

    test('Edge Case: a translucent primary is kept as is, alpha included', () {
      // 1. Arrange
      const translucentPrimary = Color(0x800ABAB5);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: translucentPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(palette.primary, translucentPrimary);
    });

    test('Edge Case: a translucent background is kept as is, alpha '
        'included', () {
      // 1. Arrange
      const translucentBackground = Color(0x40FFFFFF);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: aquariusTurPrimary,
        background: translucentBackground,
      );

      // 3. Assert
      expect(palette.background, translucentBackground);
    });

    test('Edge Case: shades only change hue, saturation and lightness, so '
        'they carry the primary alpha', () {
      // 1. Arrange
      const translucentPrimary = Color(0x800ABAB5);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: translucentPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        [
          palette.dark,
          palette.light,
          palette.accentDark,
          palette.accent,
        ].map((shade) => shade.a).toList(),
        List.filled(4, translucentPrimary.a),
      );
    });

    test('Sad Path: the shades of a different primary are not the '
        'AquariusTur shades', () {
      // 1. Arrange
      const otherPrimary = Color(0xFFE53935);

      // 2. Act
      final palette = OrganizationPalette.fromColors(
        primary: otherPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        [palette.dark, palette.light, palette.accentDark, palette.accent],
        isNot(
          anyElement(
            isIn([
              aquariusTurDark,
              aquariusTurLight,
              aquariusTurAccentDark,
              aquariusTurAccent,
            ]),
          ),
        ),
      );
    });
  });

  group('OrganizationPalette.fromTheme - Unit Test Suite', () {
    test('Happy Path: primary, dark and light are the theme tones', () {
      // 1. Arrange
      const theme = oceanoTheme;

      // 2. Act
      final palette = OrganizationPalette.fromTheme(theme);

      // 3. Assert
      expect(
        [palette.primary, palette.dark, palette.light],
        [aquariusTurPrimary, const Color(0xFF102030), const Color(0xFFF0E0D0)],
      );
    });

    test('Edge Case: the background is white', () {
      // 1. Arrange
      const theme = oceanoTheme;

      // 2. Act
      final palette = OrganizationPalette.fromTheme(theme);

      // 3. Assert
      expect(palette.background, const Color(0xFFFFFFFF));
    });

    test('Sad Path: dark and light are not derived from the primary', () {
      // 1. Arrange
      const theme = oceanoTheme;

      // 2. Act
      final palette = OrganizationPalette.fromTheme(theme);

      // 3. Assert
      expect([
        palette.dark,
        palette.light,
      ], isNot([aquariusTurDark, aquariusTurLight]));
    });
  });

  group('OrganizationPalette.fromConfig (catalog theme) - Unit Test Suite', () {
    test('Happy Path: a config with a theme uses the theme tones', () {
      // 1. Arrange
      const config = OrganizationConfig(
        id: 'acme',
        name: 'Acme',
        themeId: 'oceano',
        theme: oceanoTheme,
      );

      // 2. Act
      final palette = OrganizationPalette.fromConfig(config);

      // 3. Assert
      expect(
        [palette.primary, palette.dark, palette.light],
        [aquariusTurPrimary, const Color(0xFF102030), const Color(0xFFF0E0D0)],
      );
    });

    test('Edge Case: a config without a theme uses the Grafite tones', () {
      // 1. Arrange
      const config = OrganizationConfig(id: 'acme', name: 'Acme');

      // 2. Act
      final palette = OrganizationPalette.fromConfig(config);

      // 3. Assert
      expect(
        [palette.primary, palette.dark, palette.light],
        [
          const Color(0xFF3F4754),
          const Color(0xFF1F2128),
          const Color(0xFFDCDEE2),
        ],
      );
    });

    test('Sad Path: a themeId without a resolved theme uses Grafite, not '
        'the MonAmie blue', () {
      // 1. Arrange
      const config = OrganizationConfig(
        id: 'acme',
        name: 'Acme',
        themeId: 'neon',
      );

      // 2. Act
      final palette = OrganizationPalette.fromConfig(config);

      // 3. Assert
      expect(palette.primary, const Color(0xFF3F4754));
    });
  });
}
