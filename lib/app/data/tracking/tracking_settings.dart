/// Periods an administrator may pick (*período*: the time asked between two
/// positions), in minutes. `firestore.rules` accepts the same values.
const trackingPeriods = [1, 2, 3, 5, 10, 15, 20, 30];

/// Radii an administrator may pick (*raio*: how far a person must move from the
/// last recorded position before another is recorded), in meters.
/// `firestore.rules` accepts the same values.
const trackingRadii = [5, 10, 20, 50, 100, 200, 300, 500];

/// The presets partners may use for now. Settings saved with any other
/// preset are applied as [TrackingPreset.economia] (see
/// [TrackingSettings.withinOffered]); the stored document is left as it is.
const offeredPresets = {TrackingPreset.economia};

/// A named choice on *Ajustes de acompanhamento*.
enum TrackingPreset {
  economia('Economia', 15, 100),
  equilibrio('Equilíbrio', 5, 10),
  precisao('Precisão', 1, 5),
  personalizado('Personalizado', null, null);

  const TrackingPreset(this.label, this.periodMinutes, this.radiusMeters);

  final String label;
  final int? periodMinutes;
  final int? radiusMeters;

  /// The settings this preset stands for (`null` for *Personalizado*).
  TrackingSettings? get settings => periodMinutes == null
      ? null
      : TrackingSettings(
          periodMinutes: periodMinutes!,
          radiusMeters: radiusMeters!,
        );
}

/// How often people in the field send their location: the partner's
/// `config/tracking`, chosen by an administrator.
class TrackingSettings {
  const TrackingSettings({
    required this.periodMinutes,
    required this.radiusMeters,
  });

  /// Reads `config/tracking`, whose stored fields keep their first names
  /// (`intervalMinutes` for the period, `distanceMeters` for the radius). A
  /// missing document, or a value that is not one of the allowed ones, falls
  /// back to [defaults] field by field. The plan's [minPeriodMinutes]
  /// (*período mínimo*, Community) raises a shorter period to the first
  /// allowed one at or above it.
  factory TrackingSettings.fromMap(
    Map<String, Object?>? data, {
    int minPeriodMinutes = 0,
  }) {
    final interval = data?['intervalMinutes'];
    final distance = data?['distanceMeters'];
    final settings = TrackingSettings(
      // `is int` first: a double such as 20.0 equals 20 in `contains`, but
      // is not an allowed value.
      periodMinutes: interval is int && trackingPeriods.contains(interval)
          ? interval
          : defaults.periodMinutes,
      radiusMeters: distance is int && trackingRadii.contains(distance)
          ? distance
          : defaults.radiusMeters,
    );
    return settings.withinPlan(minPeriodMinutes);
  }

  /// The values before any administrator choice, and for any stored value that is
  /// not allowed: *Economia* (15 min, 100 m), the only preset offered for now
  /// and the one every plan accepts.
  static const defaults = TrackingSettings(
    periodMinutes: 15,
    radiusMeters: 100,
  );

  final int periodMinutes;
  final int radiusMeters;

  /// These settings with the period raised to the plan's minimum period.
  TrackingSettings withinPlan(int minPeriodMinutes) {
    if (periodMinutes >= minPeriodMinutes) return this;
    final allowed = trackingPeriods.firstWhere(
      (minutes) => minutes >= minPeriodMinutes,
      orElse: () => trackingPeriods.last,
    );
    return TrackingSettings(periodMinutes: allowed, radiusMeters: radiusMeters);
  }

  /// These settings, or *Economia* when they match no preset in
  /// [offeredPresets] (custom values count as *Personalizado*).
  TrackingSettings withinOffered() => offeredPresets.contains(preset)
      ? this
      : TrackingPreset.economia.settings!;

  Duration get period => Duration(minutes: periodMinutes);

  /// At most this many positions per hour (only when the person moves
  /// [radiusMeters] or more).
  int get positionsPerHour => (60 / periodMinutes).round();

  /// A rough battery cost from 1 (low) to 3 (high), for the screen's hint.
  int get batteryLevel {
    final cost =
        (periodMinutes <= 1
            ? 3
            : periodMinutes <= 5
            ? 2
            : 1) +
        (radiusMeters <= 10 ? 1 : 0);
    return cost >= 4
        ? 3
        : cost >= 2
        ? 2
        : 1;
  }

  /// The preset these settings match, or *Personalizado*.
  TrackingPreset get preset => TrackingPreset.values.firstWhere(
    (preset) =>
        preset.periodMinutes == periodMinutes &&
        preset.radiusMeters == radiusMeters,
    orElse: () => TrackingPreset.personalizado,
  );

  Map<String, Object?> toMap() => {
    'intervalMinutes': periodMinutes,
    'distanceMeters': radiusMeters,
  };

  @override
  bool operator ==(Object other) =>
      other is TrackingSettings &&
      other.periodMinutes == periodMinutes &&
      other.radiusMeters == radiusMeters;

  @override
  int get hashCode => Object.hash(periodMinutes, radiusMeters);
}
