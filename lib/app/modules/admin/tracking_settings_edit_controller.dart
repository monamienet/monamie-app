import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';

/// State of *Ajustes de acompanhamento*: the owner picks a preset or custom
/// values and saves them for everyone in the field.
class TrackingSettingsEditController extends GetxController {
  TrackingSettingsEditController({
    required TrackingSettingsRepository repository,
    required TrackingSettings saved,
  }) : _repository = repository,
       savedSettings = saved.obs,
       draft = saved.obs,
       preset = saved.preset.obs;

  final TrackingSettingsRepository _repository;

  /// What is saved now.
  final Rx<TrackingSettings> savedSettings;

  /// What the owner is choosing.
  final Rx<TrackingSettings> draft;
  final Rx<TrackingPreset> preset;

  /// The plan's minimum interval (Community: 15 min); presets below it are
  /// not offered.
  final RxInt minIntervalMinutes = 0.obs;
  final RxBool isSaving = false.obs;
  final RxBool justSaved = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      minIntervalMinutes.value = await _repository.minIntervalMinutes();
    } catch (e) {
      debugPrint('[TrackingSettings] Could not read the plan: $e');
    }
  }

  bool get hasChanges => draft.value != savedSettings.value;

  /// Whether [option] is allowed by the plan.
  bool allows(TrackingPreset option) =>
      option.intervalMinutes == null ||
      option.intervalMinutes! >= minIntervalMinutes.value;

  void pickPreset(TrackingPreset option) {
    if (isSaving.value || !allows(option)) return;
    preset.value = option;
    justSaved.value = false;
    final settings = option.settings;
    if (settings != null) draft.value = settings;
  }

  void setInterval(int minutes) {
    if (isSaving.value || minutes < minIntervalMinutes.value) return;
    justSaved.value = false;
    draft.value = TrackingSettings(
      intervalMinutes: minutes,
      distanceMeters: draft.value.distanceMeters,
    );
  }

  void setDistance(int meters) {
    if (isSaving.value) return;
    justSaved.value = false;
    draft.value = TrackingSettings(
      intervalMinutes: draft.value.intervalMinutes,
      distanceMeters: meters,
    );
  }

  /// Saves the draft. Returns whether it worked.
  Future<bool> save() async {
    if (isSaving.value || !hasChanges) return false;
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _repository.save(draft.value);
      savedSettings.value = draft.value;
      justSaved.value = true;
      return true;
    } catch (e) {
      debugPrint('[TrackingSettings] Save failed: $e');
      errorMessage.value =
          'Não foi possível salvar agora. Verifique a conexão e tente de novo.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
