import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';

part 'appearance_state.freezed.dart';

/// Where the logo sheet is: closed, converting the picked file, showing the
/// converted logo, or explaining why the file cannot be used.
enum LogoSheet { closed, processing, preview, error }

/// What *Aparência* shows, replaced whole by `AppearanceViewModel`.
@freezed
abstract class AppearanceState with _$AppearanceState {
  const factory AppearanceState({
    /// The name being edited.
    required String name,

    /// The id of the theme picked.
    required String themeId,

    /// The logo to save; `null` shows the name's initial. Compared by
    /// identity with the saved one to know whether it changed.
    Uint8List? logoPng,

    /// The themes that can be picked.
    @Default([]) List<OrganizationTheme> themes,
    @Default(LogoSheet.closed) LogoSheet sheet,

    /// Why the picked file cannot be used (with [LogoSheet.error]).
    @Default('') String sheetError,

    /// The converted logo waiting for "Usar este logo".
    Uint8List? candidate,

    /// Why the last save failed; empty when it did not.
    @Default('') String errorMessage,
  }) = _AppearanceState;
}
