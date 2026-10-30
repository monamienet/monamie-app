import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_palette.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';

/// The AquariusTur brand color, the calibration point of issue #35.
const aquariusTurPrimary = Color(0xFF0ABAB5);

/// The shades the app used for [aquariusTurPrimary] before it became
/// white-label (issue #35).
const aquariusTurDark = Color(0xFF073B40);
const aquariusTurLight = Color(0xFFCCF1F0);
const aquariusTurAccentDark = Color(0xFF052E32);
const aquariusTurAccent = Color(0xFF088F8B);

/// The shade table of issue #35: the lightness each shade gets.
const darkLightness = 0.139;
const lightLightness = 0.873;
const accentDarkLightness = 0.108;
const accentLightness = 0.296;

/// One 8-bit step of a color channel, the precision a [Color] keeps.
const channelStep = 1 / 255;

/// Whether the red, green and blue channels of [color] are equal.
bool isGrey(Color color) => color.r == color.g && color.g == color.b;

/// A catalog theme whose dark and light tones are not the shades the
/// AquariusTur primary would derive, so a derived palette is told apart.
const oceanoTheme = PartnerTheme(
  id: 'oceano',
  name: 'Oceano',
  primary: aquariusTurPrimary,
  dark: Color(0xFF102030),
  light: Color(0xFFF0E0D0),
  onPrimary: Color(0xFFFFFFFF),
  onDark: Color(0xFFFFFFFF),
);

void main() {
  group('PartnerPalette.fromColors (AquariusTur calibration) - '
      'Unit Test Suite', () {
    test('Happy Path: primary is the input brand color, unchanged', () {
      // 1. Arrange
      const background = Color(0xFFFFFFFF);

      // 2. Act
      final palette = PartnerPalette.fromColors(
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
      final palette = PartnerPalette.fromColors(
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
      final palette = PartnerPalette.fromColors(
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
      final palette = PartnerPalette.fromColors(
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
      final palette = PartnerPalette.fromColors(
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
      final palette = PartnerPalette.fromColors(
        primary: aquariusTurPrimary,
        background: background,
      );

      // 3. Assert
      expect(palette.background, background);
    });
  });

  group('PartnerPalette.fromColors (shade rule) - Unit Test Suite', () {
    test(
      'Edge Case: a grey primary gives grey shades (saturation stays 0)',
      () {
        // 1. Arrange
        const greyPrimary = Color(0xFF808080);

        // 2. Act
        final palette = PartnerPalette.fromColors(
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
      final palette = PartnerPalette.fromColors(
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
          closeTo(darkLightness, channelStep),
          closeTo(lightLightness, channelStep),
          closeTo(accentDarkLightness, channelStep),
          closeTo(accentLightness, channelStep),
        ],
      );
    });

    test('Edge Case: a white primary still gives the fixed lightness of '
        'every shade', () {
      // 1. Arrange
      const whitePrimary = Color(0xFFFFFFFF);

      // 2. Act
      final palette = PartnerPalette.fromColors(
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
          closeTo(darkLightness, channelStep),
          closeTo(lightLightness, channelStep),
          closeTo(accentDarkLightness, channelStep),
          closeTo(accentLightness, channelStep),
        ],
      );
    });

    test('Edge Case: a wrapped hue lands in [0, 360)', () {
      // 1. Arrange
      const redPrimary = Color(0xFFFF0004);

      // 2. Act
      final palette = PartnerPalette.fromColors(
        primary: redPrimary,
        background: const Color(0xFFFFFFFF),
      );

      // 3. Assert
      expect(
        HSLColor.fromColor(palette.accentDark).hue,
        allOf(greaterThanOrEqualTo(0), lessThan(360)),
      );
    });

    test('Sad Path: the shades of a different primary are not the '
        'AquariusTur shades', () {
      // 1. Arrange
      const otherPrimary = Color(0xFFE53935);

      // 2. Act
      final palette = PartnerPalette.fromColors(
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

  group('PartnerPalette.fromTheme - Unit Test Suite', () {
    test('Happy Path: primary, dark and light are the theme tones', () {
      // 1. Arrange
      const theme = oceanoTheme;

      // 2. Act
      final palette = PartnerPalette.fromTheme(theme);

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
      final palette = PartnerPalette.fromTheme(theme);

      // 3. Assert
      expect(palette.background, const Color(0xFFFFFFFF));
    });

    test('Sad Path: dark and light are not derived from the primary', () {
      // 1. Arrange
      const theme = oceanoTheme;

      // 2. Act
      final palette = PartnerPalette.fromTheme(theme);

      // 3. Assert
      expect([
        palette.dark,
        palette.light,
      ], isNot([aquariusTurDark, aquariusTurLight]));
    });
  });

  group('PartnerPalette.fromConfig (catalog theme) - Unit Test Suite', () {
    test('Happy Path: a config with a theme uses the theme tones', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        themeId: 'oceano',
        theme: oceanoTheme,
      );

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(
        [palette.primary, palette.dark, palette.light],
        [aquariusTurPrimary, const Color(0xFF102030), const Color(0xFFF0E0D0)],
      );
    });

    test('Edge Case: a config without a theme uses the Grafite tones', () {
      // 1. Arrange
      const config = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

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
      const config = PartnerConfig(id: 'acme', name: 'Acme', themeId: 'neon');

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.primary, const Color(0xFF3F4754));
    });
  });
}
