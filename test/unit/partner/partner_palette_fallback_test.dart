import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_palette.dart';

const black = Color(0xFF000000);
const white = Color(0xFFFFFFFF);

void main() {
  group('readableOn - Unit Test Suite', () {
    test('Happy Path: the light AquariusTur teal #0ABAB5 gets black text', () {
      // 1. Arrange
      const background = Color(0xFF0ABAB5);

      // 2. Act
      final text = readableOn(background);

      // 3. Assert
      expect(text, black);
    });

    test('Happy Path: a dark teal #073B40 gets white text', () {
      // 1. Arrange
      const background = Color(0xFF073B40);

      // 2. Act
      final text = readableOn(background);

      // 3. Assert
      expect(text, white);
    });

    test('Happy Path: the MonAmie blue gets white text', () {
      // 1. Arrange
      const background = MonAmieBrand.primary;

      // 2. Act
      final text = readableOn(background);

      // 3. Assert
      expect(text, white);
    });

    test('Edge Case: pure white gets black text', () {
      // 1. Arrange
      const background = white;

      // 2. Act
      final text = readableOn(background);

      // 3. Assert
      expect(text, black);
    });

    test('Edge Case: pure black gets white text', () {
      // 1. Arrange
      const background = black;

      // 2. Act
      final text = readableOn(background);

      // 3. Assert
      expect(text, white);
    });

    test('Sad Path: a saturated yellow is not given white text', () {
      // 1. Arrange
      // Yellow is bright, so white text on it would be unreadable.
      const background = Color(0xFFFFEB3B);

      // 2. Act
      final text = readableOn(background);

      // 3. Assert
      expect(text, isNot(white));
    });
  });

  group('PartnerPalette.fromConfig (fallbacks) - Unit Test Suite', () {
    test('Happy Path: no partner gives the MonAmie primary color', () {
      // 1. Arrange
      const PartnerConfig? config = null;

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.primary, MonAmieBrand.primary);
    });

    test('Happy Path: no partner gives the MonAmie background', () {
      // 1. Arrange
      const PartnerConfig? config = null;

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.background, MonAmieBrand.background);
    });

    test('Happy Path: no partner gives the same shades as the MonAmie '
        'colors', () {
      // 1. Arrange
      final monAmie = PartnerPalette.fromColors(
        primary: MonAmieBrand.primary,
        background: MonAmieBrand.background,
      );

      // 2. Act
      final palette = PartnerPalette.fromConfig(null);

      // 3. Assert
      expect(
        [palette.dark, palette.light, palette.accentDark, palette.accent],
        [monAmie.dark, monAmie.light, monAmie.accentDark, monAmie.accent],
      );
    });

    test('Edge Case: a missing primary falls back to MonAmie blue', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        secondaryColor: Color(0xFF101010),
      );

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.primary, MonAmieBrand.primary);
    });

    test('Edge Case: a missing primary keeps the partner background', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        secondaryColor: Color(0xFF101010),
      );

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.background, const Color(0xFF101010));
    });

    test('Edge Case: a missing background falls back to white', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        primaryColor: Color(0xFF0ABAB5),
      );

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.background, white);
    });

    test('Edge Case: a missing background keeps the partner primary', () {
      // 1. Arrange
      const config = PartnerConfig(
        id: 'acme',
        name: 'Acme',
        primaryColor: Color(0xFF0ABAB5),
      );

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.primary, const Color(0xFF0ABAB5));
    });

    test('Sad Path: a partner with no colors at all looks like MonAmie', () {
      // 1. Arrange
      const config = PartnerConfig(id: 'acme', name: 'Acme');

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(
        [palette.primary, palette.background],
        [MonAmieBrand.primary, MonAmieBrand.background],
      );
    });
  });

  group('PartnerPalette on* colors - Unit Test Suite', () {
    test('Happy Path: onPrimary is readable on the primary color', () {
      // 1. Arrange
      final palette = PartnerPalette.fromColors(
        primary: const Color(0xFF0ABAB5),
        background: white,
      );

      // 2. Act
      final onPrimary = palette.onPrimary;

      // 3. Assert
      expect(onPrimary, readableOn(palette.primary));
    });

    test('Edge Case: the dark shade of a light primary still gets white '
        'text', () {
      // 1. Arrange
      final palette = PartnerPalette.fromColors(
        primary: const Color(0xFFFFEB3B),
        background: white,
      );

      // 2. Act
      final onDark = palette.onDark;

      // 3. Assert
      expect(onDark, white);
    });

    test('Sad Path: onPrimary differs from onDark for a light primary', () {
      // 1. Arrange
      final palette = PartnerPalette.fromColors(
        primary: const Color(0xFF0ABAB5),
        background: white,
      );

      // 2. Act
      final pair = [palette.onPrimary, palette.onDark];

      // 3. Assert
      expect(pair, [black, white]);
    });
  });
}
