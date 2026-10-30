import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_theme.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';
import 'package:monamie_app/app/utils/app_theme.dart';

import '../support/test_partner.dart';

/// A catalog theme with the AquariusTur tones, for the partner-switch tests.
const aquariusTurTheme = PartnerTheme(
  id: 'aquarius',
  name: 'Aquarius',
  primary: Color(0xFF0ABAB5),
  dark: Color(0xFF073B40),
  light: Color(0xFFCCF1F0),
  onPrimary: Color(0xFF000000),
  onDark: Color(0xFFFFFFFF),
);

/// A partner that picked [aquariusTurTheme].
const aquariusTurPartner = PartnerConfig(
  id: 'aquariustur',
  name: 'AquariusTur',
  themeId: 'aquarius',
  theme: aquariusTurTheme,
);

void main() {
  group('AppColors (partner switch) - Unit Test Suite', () {
    setUp(Partner.debugReset);

    tearDown(() {
      Partner.debugReset();
      Partner.bind(testPartner);
    });

    test('Happy Path: primary follows the partner set with Partner.init', () {
      // 1. Arrange
      Partner.bind(aquariusTurPartner);

      // 2. Act
      final color = AppColors.primary;

      // 3. Assert
      expect(color, const Color(0xFF0ABAB5));
    });

    test('Happy Path: primaryDark of AquariusTur is #073B40', () {
      // 1. Arrange
      Partner.bind(aquariusTurPartner);

      // 2. Act
      final color = AppColors.primaryDark;

      // 3. Assert
      expect(color, const Color(0xFF073B40));
    });

    test('Edge Case: the colors differ when the partner changes', () {
      // 1. Arrange
      Partner.bind(testPartner);
      final acmeDark = AppColors.darkBlue();
      Partner.debugReset();
      Partner.bind(aquariusTurPartner);

      // 2. Act
      final aquariusTurDark = AppColors.darkBlue();

      // 3. Assert
      expect(aquariusTurDark, isNot(acmeDark));
    });
  });

  group('AppTheme (partner switch) - Unit Test Suite', () {
    setUp(Partner.debugReset);

    tearDown(() {
      Partner.debugReset();
      Partner.bind(testPartner);
    });

    test('Happy Path: lightTheme follows the partner set with '
        'Partner.init', () {
      // 1. Arrange
      Partner.bind(aquariusTurPartner);

      // 2. Act
      final theme = AppTheme.lightTheme;

      // 3. Assert
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF073B40));
    });

    test('Happy Path: darkTheme follows the partner set with '
        'Partner.init', () {
      // 1. Arrange
      Partner.bind(aquariusTurPartner);

      // 2. Act
      final theme = AppTheme.darkTheme;

      // 3. Assert
      expect(theme.scaffoldBackgroundColor, const Color(0xFF052E32));
    });
  });
}
