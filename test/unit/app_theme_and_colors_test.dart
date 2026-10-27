import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_palette.dart';
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

/// The palette [AppColors] is expected to delegate to.
PartnerPalette currentPalette() => PartnerPalette.fromConfig(Partner.current);

void main() {
  group('AppColors (current partner palette) - Unit Test Suite', () {
    test('Happy Path: primary is the theme primary of the current partner '
        '(Grafite without a theme)', () {
      // 1. Arrange
      const expected = Color(0xFF3F4754);

      // 2. Act
      final color = AppColors.primary;

      // 3. Assert
      expect(color, expected);
    });

    test('Happy Path: primaryDark is the palette dark shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.primaryDark;

      // 3. Assert
      expect(color, palette.dark);
    });

    test('Happy Path: primaryLight is the palette light shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.primaryLight;

      // 3. Assert
      expect(color, palette.light);
    });

    test('Happy Path: secondary is the palette accent shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.secondary;

      // 3. Assert
      expect(color, palette.accent);
    });

    test('Happy Path: background is the palette background', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.background;

      // 3. Assert
      expect(color, palette.background);
    });

    test('Happy Path: background of the current partner is white', () {
      // 1. Arrange
      const expected = Color(0xFFFFFFFF);

      // 2. Act
      final color = AppColors.background;

      // 3. Assert
      expect(color, expected);
    });

    test('Happy Path: mediumBlue() is the palette primary', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.mediumBlue();

      // 3. Assert
      expect(color, palette.primary);
    });

    test('Happy Path: darkBlue() is the palette dark shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.darkBlue();

      // 3. Assert
      expect(color, palette.dark);
    });

    test('Happy Path: lightBlue() is the palette light shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.lightBlue();

      // 3. Assert
      expect(color, palette.light);
    });

    test('Happy Path: alternativeDarkBlue() is the palette accentDark '
        'shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.alternativeDarkBlue();

      // 3. Assert
      expect(color, palette.accentDark);
    });

    test('Happy Path: alternativeMediumBlue() is the palette accent shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.alternativeMediumBlue();

      // 3. Assert
      expect(color, palette.accent);
    });

    test('Happy Path: appBarTopGradient goes from primary to dark', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final gradient = AppColors.appBarTopGradient();

      // 3. Assert
      expect(gradient.colors, [palette.primary, palette.dark]);
    });

    test('Happy Path: appBarBottomGradient goes from accent to '
        'accentDark', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final gradient = AppColors.appBarBottomGradient();

      // 3. Assert
      expect(gradient.colors, [palette.accent, palette.accentDark]);
    });

    test('Happy Path: darkBlueToBlackGradient goes from dark to black', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final gradient = AppColors.darkBlueToBlackGradient();

      // 3. Assert
      expect(gradient.colors, [palette.dark, Colors.black]);
    });

    test('Edge Case: alpha sets only the alpha channel of darkBlue()', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.darkBlue(alpha: 100);

      // 3. Assert
      expect(color, palette.dark.withAlpha(100));
    });

    test('Edge Case: alpha 0 makes mediumBlue() fully transparent with the '
        'same RGB', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.mediumBlue(alpha: 0);

      // 3. Assert
      expect(
        [color.a, color.r, color.g, color.b],
        [0.0, palette.primary.r, palette.primary.g, palette.primary.b],
      );
    });

    test('Edge Case: alpha applies to lightBlue()', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.lightBlue(alpha: 128);

      // 3. Assert
      expect(color, palette.light.withAlpha(128));
    });

    test('Edge Case: alpha applies to alternativeDarkBlue()', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.alternativeDarkBlue(alpha: 64);

      // 3. Assert
      expect(color, palette.accentDark.withAlpha(64));
    });

    test('Edge Case: alpha applies to alternativeMediumBlue()', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final color = AppColors.alternativeMediumBlue(alpha: 200);

      // 3. Assert
      expect(color, palette.accent.withAlpha(200));
    });
  });

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

  group('AppTheme.lightTheme - Unit Test Suite', () {
    test('Happy Path: uses Material 3 and the partner primary', () {
      // 1. Arrange
      final primary = AppColors.primary;

      // 2. Act
      final theme = AppTheme.lightTheme;

      // 3. Assert
      expect(
        [theme.useMaterial3, theme.colorScheme.primary, theme.primaryColor],
        [true, primary, primary],
      );
    });

    test('Happy Path: the color scheme uses the palette shades', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final scheme = AppTheme.lightTheme.colorScheme;

      // 3. Assert
      expect(
        [
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          scheme.secondary,
          scheme.onSurface,
        ],
        [palette.light, palette.dark, palette.accent, palette.dark],
      );
    });

    test('Happy Path: app bar and floating button use the palette', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final theme = AppTheme.lightTheme;

      // 3. Assert
      expect(
        [
          theme.appBarTheme.backgroundColor,
          theme.floatingActionButtonTheme.backgroundColor,
          theme.floatingActionButtonTheme.foregroundColor,
        ],
        [palette.dark, palette.light, palette.dark],
      );
    });

    test('Edge Case: on-primary and on-secondary stay white', () {
      // 1. Arrange
      const white = Colors.white;

      // 2. Act
      final scheme = AppTheme.lightTheme.colorScheme;

      // 3. Assert
      expect([scheme.onPrimary, scheme.onSecondary], [white, white]);
    });

    test('Edge Case: the scaffold and surface stay white', () {
      // 1. Arrange
      const white = Colors.white;

      // 2. Act
      final theme = AppTheme.lightTheme;

      // 3. Assert
      expect(
        [theme.scaffoldBackgroundColor, theme.colorScheme.surface],
        [white, white],
      );
    });
  });

  group('AppTheme.darkTheme - Unit Test Suite', () {
    test('Happy Path: uses Material 3 and the partner primary', () {
      // 1. Arrange
      final primary = AppColors.primary;

      // 2. Act
      final theme = AppTheme.darkTheme;

      // 3. Assert
      expect(
        [theme.useMaterial3, theme.colorScheme.primary, theme.primaryColor],
        [true, primary, primary],
      );
    });

    test('Happy Path: the color scheme uses the palette shades', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final scheme = AppTheme.darkTheme.colorScheme;

      // 3. Assert
      expect(
        [
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          scheme.secondary,
          scheme.surface,
        ],
        [palette.accentDark, palette.light, palette.accent, palette.dark],
      );
    });

    test('Happy Path: scaffold and app bar use the accentDark shade', () {
      // 1. Arrange
      final palette = currentPalette();

      // 2. Act
      final theme = AppTheme.darkTheme;

      // 3. Assert
      expect(
        [theme.scaffoldBackgroundColor, theme.appBarTheme.backgroundColor],
        [palette.accentDark, palette.accentDark],
      );
    });

    test('Edge Case: on-primary, on-secondary and on-surface stay white', () {
      // 1. Arrange
      const white = Colors.white;

      // 2. Act
      final scheme = AppTheme.darkTheme.colorScheme;

      // 3. Assert
      expect(
        [scheme.onPrimary, scheme.onSecondary, scheme.onSurface],
        [white, white, white],
      );
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
