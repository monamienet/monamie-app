import 'package:flutter/material.dart';

import '../config/partner/partner.dart';
import '../config/partner/partner_palette.dart';

/// App colors, derived from the partner of this build ([PartnerPalette]).
///
/// The `*Blue` names come from the first brand; they now mean shades of the
/// partner's primary color, whatever its hue.
class AppColors {
  static PartnerPalette get _palette =>
      PartnerPalette.fromConfig(Partner.current);

  // Semantic Getters
  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.dark;
  static Color get primaryLight => _palette.light;
  static Color get secondary => _palette.accent;

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
