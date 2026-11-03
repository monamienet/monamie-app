import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';

part 'tracking_settings_edit_state.freezed.dart';

/// What *Ajustes de acompanhamento* shows, replaced whole by
/// `TrackingSettingsEditViewModel`.
@freezed
abstract class TrackingSettingsEditState with _$TrackingSettingsEditState {
  const factory TrackingSettingsEditState({
    /// What is saved now.
    required TrackingSettings savedSettings,

    /// What an administrator is choosing.
    required TrackingSettings draft,
    required TrackingPreset preset,

    /// The plan's minimum period (Community: 15 min); presets below it are
    /// not offered.
    @Default(0) int minPeriodMinutes,
    @Default(false) bool justSaved,

    /// Why the last save failed; empty when it did not.
    @Default('') String errorMessage,
  }) = _TrackingSettingsEditState;
}
