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

  /// The plan's minimum period (Community: 15 min); presets below it are
  /// not offered.
  final RxInt minPeriodMinutes = 0.obs;
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
      minPeriodMinutes.value = await _repository.minPeriodMinutes();
    } catch (e) {
      debugPrint('[TrackingSettings] Could not read the plan: $e');
    }
  }

  bool get hasChanges => draft.value != savedSettings.value;

  /// The presets that can be picked for now. The others stay on screen,
  /// greyed out, until they are opened to partners.
  static const offered = {TrackingPreset.economia};

  /// Whether [option] can be picked: offered for now and allowed by the
  /// plan's minimum period.
  bool allows(TrackingPreset option) =>
      offered.contains(option) &&
      (option.periodMinutes == null ||
          option.periodMinutes! >= minPeriodMinutes.value);

  void pickPreset(TrackingPreset option) {
    if (isSaving.value || !allows(option)) return;
    preset.value = option;
    justSaved.value = false;
    final settings = option.settings;
    if (settings != null) draft.value = settings;
  }

  void setPeriod(int minutes) {
    if (isSaving.value ||
        !allows(TrackingPreset.personalizado) ||
        minutes < minPeriodMinutes.value) {
      return;
    }
    justSaved.value = false;
    draft.value = TrackingSettings(
      periodMinutes: minutes,
      radiusMeters: draft.value.radiusMeters,
    );
  }

  void setRadius(int meters) {
    if (isSaving.value || !allows(TrackingPreset.personalizado)) return;
    justSaved.value = false;
    draft.value = TrackingSettings(
      periodMinutes: draft.value.periodMinutes,
      radiusMeters: meters,
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
