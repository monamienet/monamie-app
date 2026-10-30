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
      expect(palette.primary, const Color(0xFF315399));
    });

    test('Happy Path: no partner gives the MonAmie background', () {
      // 1. Arrange
      const PartnerConfig? config = null;

      // 2. Act
      final palette = PartnerPalette.fromConfig(config);

      // 3. Assert
      expect(palette.background, white);
    });
  });

  group('PartnerPalette on* colors - Unit Test Suite', () {
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
  });
}
