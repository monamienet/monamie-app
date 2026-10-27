import 'dart:async';

import 'package:get/get.dart';

import 'firestore_tracking_settings_repository.dart';
import 'tracking_settings.dart';
import 'tracking_settings_repository.dart';

/// The bound partner's tracking settings in the UI isolate, kept current, so
/// every freshness threshold on the map follows the owner's choice.
class TrackingSettingsController extends GetxController {
  TrackingSettingsController({TrackingSettingsRepository? repository})
    : _repository = repository ?? const FirestoreTrackingSettingsRepository();

  final TrackingSettingsRepository _repository;
  StreamSubscription<TrackingSettings>? _subscription;

  final Rx<TrackingSettings> settings = TrackingSettings.defaults.obs;

  /// After this long without an update a person fades on the map.
  Duration get staleAfter => settings.value.staleAfter;

  @override
  void onInit() {
    super.onInit();
    _subscription = _repository.watch().listen(
      (value) => settings.value = value,
      onError: (_) {},
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
