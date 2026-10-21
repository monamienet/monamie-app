import 'dart:ui' show Color;

/// The MonAmie brand: shown before a partner is bound, and the fallback for
/// partner branding that leaves something out.
///
/// The color and the artwork come from the MonAmie site
/// (`monamienet/monamie-site`, `home.html`).
abstract final class MonAmieBrand {
  static const name = 'MonAmie';

  /// Brand blue, the `brand-700` tone of the site.
  static const primary = Color(0xFF315399);

  static const background = Color(0xFFFFFFFF);

  /// Radar mark with the "MonAmie" name below it.
  static const logoAsset = 'assets/monamie/monamie-logo.svg';

  /// Radar mark alone.
  static const iconAsset = 'assets/monamie/monamie-icon.svg';
}
