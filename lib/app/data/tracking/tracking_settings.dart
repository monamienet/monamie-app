/// Intervals the owner may pick, in minutes. `firestore.rules` accepts the
/// same values.
const trackingIntervals = [1, 2, 3, 5, 10, 15, 20, 30];

/// Distance filters the owner may pick, in meters. `firestore.rules`
/// accepts the same values.
const trackingDistances = [5, 10, 20, 50, 100, 200, 300, 500];

/// A named choice on *Ajustes de acompanhamento*.
enum TrackingPreset {
  economia('Economia', 15, 100),
  equilibrio('Equilíbrio', 5, 10),
  precisao('Precisão', 1, 5),
  personalizado('Personalizado', null, null);

  const TrackingPreset(this.label, this.intervalMinutes, this.distanceMeters);

  final String label;
  final int? intervalMinutes;
  final int? distanceMeters;

  /// The settings this preset stands for (`null` for *Personalizado*).
  TrackingSettings? get settings => intervalMinutes == null
      ? null
      : TrackingSettings(
          intervalMinutes: intervalMinutes!,
          distanceMeters: distanceMeters!,
        );
}

/// How often people in the field send their location: the partner's
/// `config/tracking`, chosen by the owner.
class TrackingSettings {
  const TrackingSettings({
    required this.intervalMinutes,
    required this.distanceMeters,
  });

  /// Reads `config/tracking`. A missing document, or a value that is not one
  /// of the allowed ones, falls back to [defaults] field by field. The
  /// plan's [minIntervalMinutes] (Community) raises a shorter interval to
  /// the first allowed one at or above it.
  factory TrackingSettings.fromMap(
    Map<String, Object?>? data, {
    int minIntervalMinutes = 0,
  }) {
    final interval = data?['intervalMinutes'];
    final distance = data?['distanceMeters'];
    final settings = TrackingSettings(
      // `is int` first: a double such as 20.0 equals 20 in `contains`, but
      // is not an allowed value.
      intervalMinutes: interval is int && trackingIntervals.contains(interval)
          ? interval
          : defaults.intervalMinutes,
      distanceMeters: distance is int && trackingDistances.contains(distance)
          ? distance
          : defaults.distanceMeters,
    );
    return settings.withinPlan(minIntervalMinutes);
  }

  /// The values before any owner choice: *Equilíbrio* (5 min, 10 m).
  static const defaults = TrackingSettings(
    intervalMinutes: 5,
    distanceMeters: 10,
  );

  final int intervalMinutes;
  final int distanceMeters;

  /// These settings with the interval raised to the plan's minimum.
  TrackingSettings withinPlan(int minIntervalMinutes) {
    if (intervalMinutes >= minIntervalMinutes) return this;
    final allowed = trackingIntervals.firstWhere(
      (minutes) => minutes >= minIntervalMinutes,
      orElse: () => trackingIntervals.last,
    );
    return TrackingSettings(
      intervalMinutes: allowed,
      distanceMeters: distanceMeters,
    );
  }

  Duration get interval => Duration(minutes: intervalMinutes);

  /// After this long without an update a person fades on the map and leaves
  /// the "sharing now" lists: two missed intervals. The one freshness
  /// threshold of the app.
  Duration get staleAfter => Duration(minutes: intervalMinutes * 2);

  /// At most this many positions per hour (only when the person moves
  /// [distanceMeters] or more).
  int get positionsPerHour => (60 / intervalMinutes).round();

  /// A rough battery cost from 1 (low) to 3 (high), for the screen's hint.
  int get batteryLevel {
    final cost =
        (intervalMinutes <= 1
            ? 3
            : intervalMinutes <= 5
            ? 2
            : 1) +
        (distanceMeters <= 10 ? 1 : 0);
    return cost >= 4
        ? 3
        : cost >= 2
        ? 2
        : 1;
  }

  /// The preset these settings match, or *Personalizado*.
  TrackingPreset get preset => TrackingPreset.values.firstWhere(
    (preset) =>
        preset.intervalMinutes == intervalMinutes &&
        preset.distanceMeters == distanceMeters,
    orElse: () => TrackingPreset.personalizado,
  );

  Map<String, Object?> toMap() => {
    'intervalMinutes': intervalMinutes,
    'distanceMeters': distanceMeters,
  };

  @override
  bool operator ==(Object other) =>
      other is TrackingSettings &&
      other.intervalMinutes == intervalMinutes &&
      other.distanceMeters == distanceMeters;

  @override
  int get hashCode => Object.hash(intervalMinutes, distanceMeters);
}
