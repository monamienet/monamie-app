import 'dart:async';

import 'package:get/get.dart';

import 'firestore_tracking_settings_repository.dart';
import 'tracking_settings.dart';
import 'tracking_settings_repository.dart';

/// The bound organization's tracking settings in the UI isolate, kept current for
/// the *Ajustes de acompanhamento* screen.
class TrackingSettingsController extends GetxController {
  TrackingSettingsController({TrackingSettingsRepository? repository})
    : _repository = repository ?? const FirestoreTrackingSettingsRepository();

  final TrackingSettingsRepository _repository;
  StreamSubscription<TrackingSettings>? _subscription;

  final Rx<TrackingSettings> settings = TrackingSettings.defaults.obs;

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
