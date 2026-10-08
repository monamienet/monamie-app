import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';
import 'package:monamie_app/app/utils/app_theme.dart';

void main() {
  group('AquariusTur Color Palette Tests', () {
    test('Primary brand color deve ser #0ABAB5', () {
      expect(AppColors.brandPrimary, const Color(0xFF0ABAB5));
      expect(AppColors.primary, const Color(0xFF0ABAB5));
      expect(AppColors.mediumBlue(), const Color(0xFF0ABAB5));
    });

    test('Dark shade deve ser o tom dark teal oceânico (#073B40)', () {
      expect(AppColors.brandDark, const Color(0xFF073B40));
      expect(AppColors.primaryDark, const Color(0xFF073B40));
      expect(AppColors.darkBlue(), const Color(0xFF073B40));
    });

    test('Light shade deve ser o tom aqua suave (#CCF1F0)', () {
      expect(AppColors.brandLight, const Color(0xFFCCF1F0));
      expect(AppColors.primaryLight, const Color(0xFFCCF1F0));
      expect(AppColors.lightBlue(), const Color(0xFFCCF1F0));
    });

    test('Transparência/alpha deve ser respeitada nas chamadas customizadas', () {
      final customAlphaColor = AppColors.darkBlue(alpha: 100);
      expect(customAlphaColor.a, closeTo(100 / 255.0, 0.01));
      expect(customAlphaColor.r, closeTo(7 / 255.0, 0.01));
      expect(customAlphaColor.g, closeTo(59 / 255.0, 0.01));
      expect(customAlphaColor.b, closeTo(64 / 255.0, 0.01));
    });

    test('Gradientes devem utilizar as cores da identidade AquariusTur', () {
      final topGradient = AppColors.appBarTopGradient();
      expect(topGradient.colors, [AppColors.mediumBlue(), AppColors.darkBlue()]);

      final bottomGradient = AppColors.appBarBottomGradient();
      expect(bottomGradient.colors, [
        AppColors.alternativeMediumBlue(),
        AppColors.alternativeDarkBlue(),
      ]);

      final toBlackGradient = AppColors.darkBlueToBlackGradient();
      expect(toBlackGradient.colors, [AppColors.darkBlue(), Colors.black]);
    });
  });

  group('AquariusTur AppTheme Tests', () {
    test('lightTheme deve ter useMaterial3 ativo e primary #0ABAB5', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.primaryColor, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, Colors.white);
      expect(theme.appBarTheme.backgroundColor, AppColors.darkBlue());
    });

    test('darkTheme deve ter useMaterial3 ativo e primary #0ABAB5', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.primaryColor, AppColors.primary);
      expect(theme.appBarTheme.backgroundColor, AppColors.alternativeDarkBlue());
    });
  });

  group('AquariusTur Asset Integrity Tests', () {
    test('Assets da pasta assets/aquariustur/ devem existir e não estar vazios', () {
      final requiredAssets = [
        'assets/aquariustur/AquariusTurLogo.svg',
        'assets/aquariustur/AquariusTurLogo.png',
        'assets/aquariustur/AquariusTurLogo320x132.svg',
        'assets/aquariustur/AquariusTurLogo320x132.png',
        'assets/aquariustur/AquariusTurSóLogo.svg',
        'assets/aquariustur/AquariusTurSóLogo.png',
        'assets/aquariustur/AquariusTurSóLogo64x64.png',
      ];

      for (final path in requiredAssets) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Arquivo deve existir: $path');
        expect(file.lengthSync(), greaterThan(0), reason: 'Arquivo não pode estar vazio: $path');
      }
    });

    test('Native splash launch_image e app icons devem existir e ser válidos', () {
      final nativeFiles = [
        'android/app/src/main/res/drawable/launch_image.png',
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
        'web/favicon.png',
        'web/icons/Icon-192.png',
      ];

      for (final path in nativeFiles) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Arquivo nativo deve existir: $path');
        expect(file.lengthSync(), greaterThan(100), reason: 'Arquivo deve conter bytes válidos: $path');
      }
    });
  });
}

