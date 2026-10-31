import 'package:flutter/material.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// Colors of the sheet under the map, drawn on the theme's light shade.
/// Every color is derived from `AppColors`, so the sheet follows the bound
/// organization's theme: the text is the theme's dark shade, and the quieter
/// tones are translucent layers of it.
abstract final class SheetColors {
  /// The sheet's background.
  static Color get background => AppColors.lightBlue();

  /// Primary text.
  static Color get ink => AppColors.darkBlue();

  /// Secondary text.
  static Color get muted => ink.withAlpha(200);

  /// Quiet card, selected row and off-avatar background.
  static Color get surface => ink.withAlpha(18);

  /// The card that stands out from the sheet: sharing turned on.
  static Color get raised => Colors.white;

  /// Hairline borders of buttons.
  static Color get outline => ink.withAlpha(70);

  /// The grabber at the top of the sheet and the busy switch track.
  static Color get handle => ink.withAlpha(80);
}
