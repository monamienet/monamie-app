import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';

/// Reads and saves the bound organization's tracking settings.
abstract interface class TrackingSettingsRepository {
  /// The saved settings, kept current while the organization is bound (the
  /// defaults until they are first read); notifies only when they change.
  /// *Ajustes de acompanhamento* opens with this value.
  ValueListenable<TrackingSettings> get settings;

  /// The current settings and every later change, already limited by the
  /// plan's minimum period and applied as *Economia* when saved with a
  /// preset not in `offeredPresets`.
  Stream<TrackingSettings> watch();

  /// The plan's minimum interval in minutes (Community: 15; Standard: 0).
  Future<int> minPeriodMinutes();

  /// Saves [settings] (administrators only, enforced by the rules).
  Future<void> save(TrackingSettings settings);
}
