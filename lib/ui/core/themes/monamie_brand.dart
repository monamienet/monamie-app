import 'dart:ui' show Color;

/// The MonAmie brand: shown before an organization is bound, and the fallback for
/// organization branding that leaves something out.
///
/// The color and the artwork come from the MonAmie site
/// (`monamienet/monamie-site`, `home.html`).
abstract final class MonAmieBrand {
  static const name = 'MonAmie';

  /// Brand blue, the `brand-700` tone of the site.
  static const primary = Color(0xFF315399);

  static const background = Color(0xFFFFFFFF);

  /// The "Encontro" identity of MonAmie's own screens (sign-in, organization
  /// picker, creation): navy ink on cream, with a coral meeting point.
  static const navy = Color(0xFF1B1838);
  static const cream = Color(0xFFF6F1E7);
  static const coral = Color(0xFFF2542D);

  /// Secondary text on cream.
  static const mutedInk = Color(0xFF4A4858);

  /// Secondary text on navy.
  static const mutedCream = Color(0xFFD8D3E4);

  /// MonAmie's tagline on the sign-in screen.
  static const tagline = 'Sua equipe, no mesmo ponto.';

  /// Radar mark with the "MonAmie" name below it.
  static const logoAsset = 'assets/monamie/monamie-logo.svg';

  /// Radar mark alone.
  static const iconAsset = 'assets/monamie/monamie-icon.svg';
}
