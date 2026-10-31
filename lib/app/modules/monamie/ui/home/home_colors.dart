import 'package:flutter/painting.dart';

/// Neutral colors of the home screen, the same for every organization. The brand
/// colors (header, accents) come from `AppColors`, which follows the theme.
abstract final class HomeColors {
  /// Primary text.
  static const ink = Color(0xFF1B1838);

  /// Secondary text; 7:1 against white.
  static const muted = Color(0xFF4A4858);

  /// Quiet card and chip background.
  static const surface = Color(0xFFF1F0F4);

  /// Hairline borders of cards and buttons.
  static const outline = Color(0xFFDDD9E4);

  /// Separators between rows.
  static const divider = Color(0xFFECEAF0);

  /// The grabber at the top of the sheet.
  static const handle = Color(0xFFC9C3D6);

  /// A person who is not sharing now.
  static const offline = Color(0xFF8A90A0);
}
