import 'package:flutter/material.dart';

/// MonAmie AquariusTur Color Palette.
/// Brand primary color is `#0ABAB5` with harmonized oceanic teal shades.
class AppColors {
  // Brand Base Constants
  static const Color brandPrimary = Color(0xFF0ABAB5); // AquariusTur Cyan/Teal
  static const Color brandDark = Color(0xFF073B40);    // Oceanic Dark Teal
  static const Color brandLight = Color(0xFFCCF1F0);   // Soft Aqua Accent
  static const Color brandAltDark = Color(0xFF052E32); // Deep Abyss Teal
  static const Color brandAltMedium = Color(0xFF088F8B);// Vibrant Medium Teal

  // Semantic Getters
  static Color get primary => brandPrimary;
  static Color get primaryDark => brandDark;
  static Color get primaryLight => brandLight;
  static Color get secondary => brandAltMedium;

  // Backwards-compatible methods mapped to AquariusTur palette
  static Color darkBlue({int alpha = 255}) =>
      Color.fromARGB(alpha, 7, 59, 64);

  static Color lightBlue({int alpha = 255}) =>
      Color.fromARGB(alpha, 204, 241, 240);

  static Color mediumBlue({int alpha = 255}) =>
      Color.fromARGB(alpha, 10, 186, 181);

  static Color alternativeDarkBlue({int alpha = 255}) =>
      Color.fromARGB(alpha, 5, 46, 50);

  static Color alternativeMediumBlue({int alpha = 255}) =>
      Color.fromARGB(alpha, 8, 143, 139);

  static LinearGradient darkBlueToBlackGradient({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [
        darkBlue(),
        Colors.black,
      ],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient appBarTopGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: [
        mediumBlue(),
        darkBlue(),
      ],
      begin: begin,
      end: end,
    );
  }

  static LinearGradient appBarBottomGradient({
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: [
        alternativeMediumBlue(),
        alternativeDarkBlue(),
      ],
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