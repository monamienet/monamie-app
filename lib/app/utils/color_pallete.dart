import 'package:flutter/material.dart';

import '../config/organization/organization.dart';
import '../config/organization/organization_palette.dart';

/// App colors, derived from the bound organization ([OrganizationPalette]), or the
/// MonAmie colors when no organization is bound.
///
/// The `*Blue` names come from the first brand; they now mean shades of the
/// organization's primary color, whatever its hue.
class AppColors {
  static OrganizationPalette get _palette =>
      OrganizationPalette.fromConfig(Organization.current);

  // Semantic Getters
  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.dark;
  static Color get primaryLight => _palette.light;
  static Color get secondary => _palette.accent;

  /// `colors.secondary` of `organization.json`: the brand background.
  static Color get background => _palette.background;

  /// Readable text color on [primary] / [mediumBlue].
  static Color get onPrimary => _palette.onPrimary;

  /// Readable text color on [primaryDark] / [darkBlue].
  static Color get onPrimaryDark => _palette.onDark;

  /// Readable text color on [secondary] / [alternativeMediumBlue].
  static Color get onSecondary => _palette.onAccent;

  /// Readable text color on [alternativeDarkBlue].
  static Color get onAlternativeDark => _palette.onAccentDark;

  static Color darkBlue({int alpha = 255}) => _palette.dark.withAlpha(alpha);

  static Color lightBlue({int alpha = 255}) => _palette.light.withAlpha(alpha);

  static Color mediumBlue({int alpha = 255}) =>
      _palette.primary.withAlpha(alpha);

  static Color alternativeDarkBlue({int alpha = 255}) =>
      _palette.accentDark.withAlpha(alpha);

  static Color alternativeMediumBlue({int alpha = 255}) =>
      _palette.accent.withAlpha(alpha);

  static LinearGradient darkBlueToBlackGradient({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [darkBlue(), Colors.black],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient appBarTopGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: [mediumBlue(), darkBlue()],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient appBarBottomGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: [alternativeMediumBlue(), alternativeDarkBlue()],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient darkTransparentGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.2),
        Colors.black.withValues(alpha: 0.2),
      ],
    );
  }
}
