import 'package:flutter/painting.dart';
import 'package:monamie_app/ui/core/themes/monamie_brand.dart';
import 'package:monamie_app/ui/core/ui/admin_ui.dart';

/// The screen a language picker opens from, which gives it its colors: the
/// picker wears the colors of the screen under it.
enum LanguageScheme {
  /// Opened from the side menu: a white sheet, like the administration
  /// screens' sheets.
  menu,

  /// Opened from *Login*: navy ground, cream text.
  login,

  /// Opened from *Sem organização* and *Escolher organização*: cream ground,
  /// white cards, navy actions.
  organization,
}

/// The colors of a [LanguageScheme], from the design canvas's *Idioma*
/// boards.
class LanguageColors {
  const LanguageColors._({
    required this.sheet,
    required this.sheetBorder,
    required this.row,
    required this.ink,
    required this.muted,
    required this.rowRing,
    required this.selectedRing,
    required this.chip,
    required this.onChip,
    required this.mark,
    required this.onMark,
    required this.unselectedMark,
    required this.handle,
    required this.error,
    required this.buttonRing,
  });

  /// The colors of [scheme].
  factory LanguageColors.of(LanguageScheme scheme) => switch (scheme) {
    LanguageScheme.menu => const LanguageColors._(
      sheet: Color(0xFFFFFFFF),
      sheetBorder: null,
      row: Color(0x00000000),
      ink: MonAmieBrand.navy,
      muted: MonAmieBrand.mutedInk,
      rowRing: Color(0xFFDDD5C4),
      selectedRing: MonAmieBrand.navy,
      chip: Color(0xFFCDF0EF),
      onChip: Color(0xFF093A3E),
      mark: Color(0xFF0B7F7B),
      onMark: Color(0xFFFFFFFF),
      unselectedMark: Color(0xFFC9C3D6),
      handle: Color(0xFFC9C3D6),
      error: AdminColors.error,
      buttonRing: Color(0xFFDDD5C4),
    ),
    LanguageScheme.login => const LanguageColors._(
      sheet: MonAmieBrand.navy,
      sheetBorder: Color(0x29F6F1E7),
      row: Color(0x00000000),
      ink: MonAmieBrand.cream,
      muted: MonAmieBrand.mutedCream,
      rowRing: Color(0x47F6F1E7),
      selectedRing: MonAmieBrand.cream,
      chip: Color(0x1FF6F1E7),
      onChip: MonAmieBrand.cream,
      mark: MonAmieBrand.cream,
      onMark: MonAmieBrand.navy,
      unselectedMark: Color(0x73F6F1E7),
      handle: Color(0x59F6F1E7),
      error: Color(0xFFFF8A6B),
      buttonRing: Color(0x66F6F1E7),
    ),
    LanguageScheme.organization => const LanguageColors._(
      sheet: MonAmieBrand.cream,
      sheetBorder: null,
      row: Color(0xFFFFFFFF),
      ink: MonAmieBrand.navy,
      muted: MonAmieBrand.mutedInk,
      rowRing: Color(0xFFDDD5C4),
      selectedRing: MonAmieBrand.navy,
      chip: Color(0xFFECE6D9),
      onChip: MonAmieBrand.navy,
      mark: MonAmieBrand.navy,
      onMark: MonAmieBrand.cream,
      unselectedMark: Color(0xFFC9C3D6),
      handle: Color(0xFFC9C3D6),
      error: AdminColors.error,
      buttonRing: Color(0xFFDDD5C4),
    ),
  };

  /// The sheet's ground and its optional top border.
  final Color sheet;
  final Color? sheetBorder;

  /// A language row's background.
  final Color row;

  /// Text, and secondary text.
  final Color ink;
  final Color muted;

  /// A row's outline, and the one of the language in use.
  final Color rowRing;
  final Color selectedRing;

  /// The language's code chip, and the code on it.
  final Color chip;
  final Color onChip;

  /// The mark of the language in use, the check on it, and the ring of the
  /// others.
  final Color mark;
  final Color onMark;
  final Color unselectedMark;

  /// The grabber at the top of the sheet.
  final Color handle;

  /// The message when the choice could not be stored.
  final Color error;

  /// The outline of the globe button that opens the sheet.
  final Color buttonRing;
}
