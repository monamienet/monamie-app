import 'package:freezed_annotation/freezed_annotation.dart';

part 'resume_on_restart_state.freezed.dart';

/// What keeps sharing from resuming after a restart, though the person
/// chose so.
enum ResumeBlocker {
  /// Location is not allowed all the time.
  alwaysLocation,

  /// The app's battery use is "Restricted".
  batteryRestricted,
}

/// What the menu's "resume after restart" row shows, replaced whole by
/// `ResumeOnRestartViewModel`.
@freezed
abstract class ResumeOnRestartState with _$ResumeOnRestartState {
  const factory ResumeOnRestartState({
    /// Whether the device can resume sharing by itself (Android only); the
    /// row is hidden otherwise.
    required bool available,

    /// Whether the person chose to resume sharing.
    required bool enabled,

    /// What would keep it from resuming, `null` for nothing (or while the
    /// option is off).
    ResumeBlocker? blocker,
  }) = _ResumeOnRestartState;
}
