import 'package:flutter/foundation.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';

import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'tracking_settings_edit_state.dart';

export 'tracking_settings_edit_state.dart';

/// State of *Ajustes de acompanhamento*: an administrator picks a preset or custom
/// values and saves them for everyone in the field. The screen runs [load]
/// when it opens.
class TrackingSettingsEditViewModel extends ChangeNotifier {
  TrackingSettingsEditViewModel({
    required this._repository,
    required TrackingSettings saved,
  }) : _state = TrackingSettingsEditState(
         savedSettings: saved,
         draft: saved,
         preset: saved.preset,
       );

  final TrackingSettingsRepository _repository;

  TrackingSettingsEditState _state;
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  TrackingSettingsEditState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(TrackingSettingsEditState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    load.dispose();
    save.dispose();
    super.dispose();
  }

  /// Reads the plan's minimum period; nothing is restricted when it cannot
  /// be read (so it always ends [Ok]).
  late final Command0<void> load = Command0(_load);

  /// Saves the draft. The failure is also kept in
  /// [TrackingSettingsEditState.failure]. Ignored without changes.
  late final Command0<void> save = Command0(_save, blocked: () => !hasChanges);

  Future<Result<void>> _load() async {
    try {
      final minutes = await _repository.minPeriodMinutes();
      _emit(_state.copyWith(minPeriodMinutes: minutes));
    } catch (e) {
      debugPrint('[TrackingSettings] Could not read the plan: $e');
    }
    return const Ok(null);
  }

  bool get hasChanges => _state.draft != _state.savedSettings;

  /// Whether [option] can be picked: in [offeredPresets] and allowed by the
  /// plan's minimum period.
  bool allows(TrackingPreset option) =>
      offeredPresets.contains(option) &&
      (option.periodMinutes == null ||
          option.periodMinutes! >= _state.minPeriodMinutes);

  void pickPreset(TrackingPreset option) {
    if (save.running || !allows(option)) return;
    final settings = option.settings;
    _emit(
      _state.copyWith(
        preset: option,
        justSaved: false,
        draft: settings ?? _state.draft,
      ),
    );
  }

  void setPeriod(int minutes) {
    if (save.running ||
        !allows(TrackingPreset.personalizado) ||
        minutes < _state.minPeriodMinutes) {
      return;
    }
    _emit(
      _state.copyWith(
        justSaved: false,
        draft: TrackingSettings(
          periodMinutes: minutes,
          radiusMeters: _state.draft.radiusMeters,
        ),
      ),
    );
  }

  void setRadius(int meters) {
    if (save.running || !allows(TrackingPreset.personalizado)) return;
    _emit(
      _state.copyWith(
        justSaved: false,
        draft: TrackingSettings(
          periodMinutes: _state.draft.periodMinutes,
          radiusMeters: meters,
        ),
      ),
    );
  }

  Future<Result<void>> _save() async {
    _emit(_state.copyWith(failure: null));
    try {
      await _repository.save(_state.draft);
      _emit(_state.copyWith(savedSettings: _state.draft, justSaved: true));
      return const Ok(null);
    } catch (e, stackTrace) {
      debugPrint('[TrackingSettings] Save failed: $e');
      const failure = Failure.connection(FailedAction.save);
      _emit(_state.copyWith(failure: failure));
      return Err(failure, error: e, stackTrace: stackTrace);
    }
  }
}
