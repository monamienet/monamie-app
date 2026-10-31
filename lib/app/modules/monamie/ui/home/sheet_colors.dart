import 'package:flutter/painting.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

/// Colors of the sheet under the map, which continues the header on the
/// theme's dark shade. Every color is derived from `AppColors`, so the sheet
/// follows the bound organization's theme; the text is the readable color on
/// that shade, and the quieter tones are translucent layers of it.
abstract final class SheetColors {
  /// The sheet's background: the header's color.
  static Color get background => AppColors.darkBlue();

  /// Primary text.
  static Color get ink => AppColors.onPrimaryDark;

  /// Secondary text.
  static Color get muted => ink.withAlpha(196);

  /// Quiet card, selected row and off-avatar background.
  static Color get surface => ink.withAlpha(26);

  /// Hairline borders of buttons; the same as the header's chips.
  static Color get outline => ink.withAlpha(110);

  /// The grabber at the top of the sheet and the busy switch track.
  static Color get handle => ink.withAlpha(90);

  /// Accent on the dark background: live status, toggled icons, spinner.
  static Color get accent => AppColors.lightBlue();
}
