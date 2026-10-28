import 'tracking_settings.dart';

/// Reads and saves the bound partner's tracking settings.
abstract interface class TrackingSettingsRepository {
  /// The current settings and every later change, already limited by the
  /// plan's minimum interval.
  Stream<TrackingSettings> watch();

  /// The plan's minimum interval in minutes (Community: 15; Standard: 0).
  Future<int> minPeriodMinutes();

  /// Saves [settings] (owner only, enforced by the rules).
  Future<void> save(TrackingSettings settings);
}
