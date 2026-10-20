import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_palette.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';
import 'package:monamie_app/app/utils/app_theme.dart';

import '../support/test_partner.dart';
import 'support/partner_layout.dart';

/// A partner with the AquariusTur colors, for the partner-switch tests.
const aquariusTurPartner = PartnerConfig(
  id: 'aquariustur',
  name: 'AquariusTur',
  primaryColor: Color(0xFF0ABAB5),
  secondaryColor: Color(0xFFFFFFFF),
);

/// A partner whose `colors.secondary` is dark, so [AppColors.background]
/// can be told apart from the white default.
const darkBackgroundPartner = PartnerConfig(
  id: 'nightly',
  name: 'Nightly',
  primaryColor: Color(0xFF112233),
  secondaryColor: Color(0xFF101820),
);

/// A partner with the background of [testPartner] but another primary.
const sameBackgroundOtherPrimaryPartner = PartnerConfig(
  id: 'other',
  name: 'Other',
  primaryColor: Color(0xFFAA0000),
  secondaryColor: Color(0xFFFFFFFF),
);

/// The palette [AppColors] is expected to delegate to.
PartnerPalette currentPalette() => PartnerPalette.fromConfig(Partner.current);

void main() {
  group('AppColors (current partner palette) - Unit Test Suite', () {
    test('Happy Path: primary is the colors.primary of the current '
        'partner', () {
      // 1. Arrange
      final expected = Partner.current.primaryColor;

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

    test('Happy Path: background is the colors.secondary of the current '
        'partner', () {
      // 1. Arrange
      final expected = Partner.current.secondaryColor;

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
      Partner.init(testPartner);
    });

    test('Happy Path: primary follows the partner set with Partner.init', () {
      // 1. Arrange
      Partner.init(aquariusTurPartner);

      // 2. Act
      final color = AppColors.primary;

      // 3. Assert
      expect(color, const Color(0xFF0ABAB5));
    });

    test('Happy Path: primaryDark of AquariusTur is #073B40', () {
      // 1. Arrange
      Partner.init(aquariusTurPartner);

      // 2. Act
      final color = AppColors.primaryDark;

      // 3. Assert
      expect(color, const Color(0xFF073B40));
    });

    test('Edge Case: the colors differ when the partner changes', () {
      // 1. Arrange
      Partner.init(testPartner);
      final acmeDark = AppColors.darkBlue();
      Partner.debugReset();
      Partner.init(aquariusTurPartner);

      // 2. Act
      final aquariusTurDark = AppColors.darkBlue();

      // 3. Assert
      expect(aquariusTurDark, isNot(acmeDark));
    });

    test('Happy Path: background follows the colors.secondary of the '
        'partner set with Partner.init', () {
      // 1. Arrange
      Partner.init(darkBackgroundPartner);

      // 2. Act
      final color = AppColors.background;

      // 3. Assert
      expect(color, const Color(0xFF101820));
    });

    test('Edge Case: background is not derived from colors.primary', () {
      // 1. Arrange
      Partner.init(sameBackgroundOtherPrimaryPartner);

      // 2. Act
      final color = AppColors.background;

      // 3. Assert
      expect(color, testPartner.secondaryColor);
    });

    test('Sad Path: reading background before Partner.init throws '
        'StateError', () {
      // 1. Arrange
      // setUp left Partner without a partner.

      // 2. Act
      Color action() => AppColors.background;

      // 3. Assert
      expect(action, throwsStateError);
    });

    test('Sad Path: reading a color before Partner.init throws '
        'StateError', () {
      // 1. Arrange
      // setUp left Partner without a partner.

      // 2. Act
      Color action() => AppColors.primary;

      // 3. Assert
      expect(action, throwsStateError);
    });

    test('Sad Path: building a gradient before Partner.init throws '
        'StateError', () {
      // 1. Arrange
      // setUp left Partner without a partner.

      // 2. Act
      LinearGradient action() => AppColors.appBarTopGradient();

      // 3. Assert
      expect(action, throwsStateError);
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
      Partner.init(testPartner);
    });

    test('Happy Path: lightTheme follows the partner set with '
        'Partner.init', () {
      // 1. Arrange
      Partner.init(aquariusTurPartner);

      // 2. Act
      final theme = AppTheme.lightTheme;

      // 3. Assert
      expect(theme.appBarTheme.backgroundColor, const Color(0xFF073B40));
    });

    test('Happy Path: darkTheme follows the partner set with '
        'Partner.init', () {
      // 1. Arrange
      Partner.init(aquariusTurPartner);

      // 2. Act
      final theme = AppTheme.darkTheme;

      // 3. Assert
      expect(theme.scaffoldBackgroundColor, const Color(0xFF052E32));
    });

    test('Sad Path: lightTheme before Partner.init throws StateError', () {
      // 1. Arrange
      // setUp left Partner without a partner.

      // 2. Act
      ThemeData action() => AppTheme.lightTheme;

      // 3. Assert
      expect(action, throwsStateError);
    });

    test('Sad Path: darkTheme before Partner.init throws StateError', () {
      // 1. Arrange
      // setUp left Partner without a partner.

      // 2. Act
      ThemeData action() => AppTheme.darkTheme;

      // 3. Assert
      expect(action, throwsStateError);
    });
  });

  group('AquariusTur Asset Integrity Tests', () {
    test('Happy Path: partners/aquariustur/logo-com-texto.svg exists and is '
        'not empty', () {
      // 1. Arrange
      final logo = File('partners/aquariustur/logo-com-texto.svg');

      // 2. Act
      final length = logo.existsSync() ? logo.lengthSync() : 0;

      // 3. Assert
      expect(length, greaterThan(0), reason: 'Missing or empty: ${logo.path}');
    });

    test(
      'Native splash launch_image e app icons devem existir e ser válidos',
      () {
        // 1. Arrange
        // Android brand resources now live in partners/<id>/android/res/.
        final nativeFiles = [
          for (final resource in requiredAndroidBrandResources)
            'partners/aquariustur/android/res/$resource',
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
          'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
          'partners/aquariustur/web/favicon.png',
          'partners/aquariustur/web/icons/Icon-192.png',
        ];

        // 2. Act
        final invalidFiles = nativeFiles.where((path) {
          final file = File(path);
          return !file.existsSync() || file.lengthSync() <= 100;
        }).toList();

        // 3. Assert
        expect(
          invalidFiles,
          isEmpty,
          reason: 'Arquivos nativos devem existir e conter bytes válidos',
        );
      },
    );
  });
}
