import 'tracking_settings.dart';

/// Reads and saves the bound partner's tracking settings.
abstract interface class TrackingSettingsRepository {
  /// The current settings and every later change, already limited by the
  /// plan's minimum period and applied as *Economia* when saved with a
  /// preset not in `offeredPresets`.
  Stream<TrackingSettings> watch();

  /// The plan's minimum interval in minutes (Community: 15; Standard: 0).
  Future<int> minPeriodMinutes();

  /// Saves [settings] (administrators only, enforced by the rules).
  Future<void> save(TrackingSettings settings);
}
