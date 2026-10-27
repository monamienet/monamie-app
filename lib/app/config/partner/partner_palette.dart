import 'package:flutter/painting.dart';

import 'monamie_brand.dart';
import 'partner_config.dart';
import 'partner_theme.dart';

/// How a shade is derived from the brand color in HSL.
///
/// The hue is shifted by [hueShift] degrees, the saturation is multiplied by
/// [saturationFactor] and the lightness is replaced by [lightness], so every
/// partner gets shades with the same contrast against white text.
class _ShadeRule {
  const _ShadeRule({
    required this.hueShift,
    required this.saturationFactor,
    required this.lightness,
  });

  final double hueShift;
  final double saturationFactor;
  final double lightness;

  Color applyTo(HSLColor brand) => brand
      .withHue((brand.hue + hueShift) % 360)
      .withSaturation((brand.saturation * saturationFactor).clamp(0.0, 1.0))
      .withLightness(lightness)
      .toColor();
}

// Calibrated so the AquariusTur brand color `#0ABAB5` gives exactly the
// shades the app used before it became white-label (see issue #35).
const _dark = _ShadeRule(
  hueShift: 6.97,
  saturationFactor: 0.894,
  lightness: 0.139,
);
const _light = _ShadeRule(
  hueShift: 0.08,
  saturationFactor: 0.634,
  lightness: 0.873,
);
const _accentDark = _ShadeRule(
  hueShift: 7.04,
  saturationFactor: 0.911,
  lightness: 0.108,
);
const _accent = _ShadeRule(
  hueShift: -0.07,
  saturationFactor: 0.996,
  lightness: 0.296,
);

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

/// Black or white, whichever has the higher WCAG contrast ratio against
/// [background], so text stays readable on any partner color.
Color readableOn(Color background) {
  final luminance = background.computeLuminance();
  final contrastWithWhite = 1.05 / (luminance + 0.05);
  final contrastWithBlack = (luminance + 0.05) / 0.05;
  return contrastWithBlack > contrastWithWhite ? _black : _white;
}

/// The partner's colors: the two it chose in `partner.json` plus the shades
/// derived from its primary color.
class PartnerPalette {
  const PartnerPalette._({
    required this.primary,
    required this.dark,
    required this.light,
    required this.accentDark,
    required this.accent,
    required this.background,
  });

  /// Derives the shades from [primary]; [background] is used as is.
  factory PartnerPalette.fromColors({
    required Color primary,
    required Color background,
  }) {
    final brand = HSLColor.fromColor(primary);
    return PartnerPalette._(
      primary: primary,
      dark: _dark.applyTo(brand),
      light: _light.applyTo(brand),
      accentDark: _accentDark.applyTo(brand),
      accent: _accent.applyTo(brand),
      background: background,
    );
  }

  /// The palette of [config].
  ///
  /// A partner with a resolved catalog theme uses its primary, dark and light
  /// tones as they are, on a white background. A legacy partner without one
  /// derives the shades from `colors.primary` and `colors.secondary`, each
  /// falling back on its own (MonAmie blue, white). No partner ([config]
  /// `null`) gives the MonAmie palette.
  factory PartnerPalette.fromConfig(PartnerConfig? config) {
    final theme = config?.theme;
    if (theme != null) return PartnerPalette.fromTheme(theme);
    return PartnerPalette.fromColors(
      primary: config?.primaryColor ?? MonAmieBrand.primary,
      background: config?.secondaryColor ?? MonAmieBrand.background,
    );
  }

  /// The palette of a catalog [theme]. Only the two accents are derived.
  factory PartnerPalette.fromTheme(PartnerTheme theme) {
    final derived = PartnerPalette.fromColors(
      primary: theme.primary,
      background: MonAmieBrand.background,
    );
    return PartnerPalette._(
      primary: theme.primary,
      dark: theme.dark,
      light: theme.light,
      accentDark: derived.accentDark,
      accent: derived.accent,
      background: MonAmieBrand.background,
    );
  }

  /// `colors.primary`: the brand color.
  final Color primary;

  /// A dark shade of [primary], for app bars and text on light surfaces.
  final Color dark;

  /// A pale shade of [primary], for containers and floating buttons.
  final Color light;

  /// A darker shade than [dark], for the dark theme background.
  final Color accentDark;

  /// A medium shade of [primary]: `ColorScheme.secondary`.
  final Color accent;

  /// `colors.secondary`: the brand background (the login background).
  final Color background;

  /// Text and icon color on [primary].
  Color get onPrimary => readableOn(primary);

  /// Text and icon color on [dark].
  Color get onDark => readableOn(dark);

  /// Text and icon color on [accent].
  Color get onAccent => readableOn(accent);

  /// Text and icon color on [accentDark].
  Color get onAccentDark => readableOn(accentDark);
}
