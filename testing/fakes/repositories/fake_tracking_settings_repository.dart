import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';

import 'fake_outcomes.dart';

/// [TrackingSettingsRepository] over [settings]: saving replaces it and
/// [watch] follows it. [minPeriod] is the plan's minimum. A failure asked
/// for with `fail` throws, as the Firestore-backed repository does.
class FakeTrackingSettingsRepository
    with FakeOutcomes
    implements TrackingSettingsRepository {
  FakeTrackingSettingsRepository({
    TrackingSettings initial = TrackingSettings.defaults,
    this.minPeriod = 0,
  }) : settings = ValueNotifier(initial);

  @override
  final ValueNotifier<TrackingSettings> settings;

  /// What [minPeriodMinutes] answers (Community: 15; Standard: 0).
  int minPeriod;

  @override
  Stream<TrackingSettings> watch() {
    late final StreamController<TrackingSettings> controller;
    void push() => controller.add(settings.value);
    controller = StreamController(
      onListen: () {
        push();
        settings.addListener(push);
      },
      onCancel: () => settings.removeListener(push),
    );
    return controller.stream;
  }

  @override
  Future<int> minPeriodMinutes() =>
      run('minPeriodMinutes', const [], () => minPeriod);

  @override
  Future<void> save(TrackingSettings next) =>
      run('save', [next], () => settings.value = next);

  /// Releases [settings].
  void dispose() => settings.dispose();
}
