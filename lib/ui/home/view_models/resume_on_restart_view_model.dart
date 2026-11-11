import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/repositories/sharing_resume/sharing_resume_repository.dart';
import 'package:monamie_app/domain/models/sharing_resume.dart';
import 'package:monamie_app/ui/home/view_models/resume_on_restart_state.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';

export 'resume_on_restart_state.dart';

/// The choice to resume sharing by itself after the device restarts or the
/// app is updated (the menu's switch), what would keep it from resuming,
/// and the texts the device shows meanwhile.
class ResumeOnRestartViewModel extends ChangeNotifier {
  /// [available]: whether this device can resume sharing (Android only).
  ResumeOnRestartViewModel({
    required this._repository,
    required this._permissions,
    required this._available,
  }) {
    _state = _compute();
    _repository.resumeOnRestart.addListener(_refresh);
    _permissions.hasAlwaysLocationPermission.addListener(_refresh);
    _permissions.isBackgroundRestricted.addListener(_refresh);
  }

  final SharingResumeRepository _repository;
  final PermissionsRepository _permissions;
  final bool _available;

  late ResumeOnRestartState _state;
  bool _disposed = false;

  /// What the row shows; replaced whole, never changed in place.
  ResumeOnRestartState get state => _state;

  ResumeOnRestartState _compute() {
    final enabled = _repository.resumeOnRestart.value;
    return ResumeOnRestartState(
      available: _available,
      enabled: enabled,
      blocker: !_available || !enabled
          ? null
          : !_permissions.hasAlwaysLocationPermission.value
          ? ResumeBlocker.alwaysLocation
          : _permissions.isBackgroundRestricted.value
          ? ResumeBlocker.batteryRestricted
          : null,
    );
  }

  /// Replaces the state, notifying only when it differs.
  void _refresh() {
    final next = _compute();
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  /// Reads the stored choice.
  late final Command0<void> load = Command0(() async {
    if (_available) await _repository.restore();
    return const Ok(null);
  });

  /// Stores the choice; it applies at the next restart or update, and
  /// changes nothing in the sharing now. [Err] says why it could not be
  /// stored, and the choice stays.
  late final Command1<void, bool> setEnabled = Command1(
    _repository.setResumeOnRestart,
  );

  /// Opens what removes the [ResumeOnRestartState.blocker]: the request for
  /// location all the time, or the app's battery settings.
  late final Command0<void> resolveBlocker = Command0(() async {
    switch (_state.blocker) {
      case ResumeBlocker.alwaysLocation:
        await _permissions.requestAlwaysPermission();
      case ResumeBlocker.batteryRestricted:
        await _permissions.openBackgroundUsageSettings();
      case null:
        break;
    }
    return const Ok(null);
  });

  /// Texts given while others were being stored; only the last ones count.
  SharingResumeTexts? _pendingTexts;
  bool _storingTexts = false;

  /// Stores the texts the device shows without the screen, [texts] built
  /// by the screen in the app's language. Not a command: it is no action of
  /// the person's, and texts given while others are being stored (a second
  /// change of language) must not be dropped; the last ones win. A failure
  /// is only logged: the texts of the last language stay.
  Future<void> storeTexts(SharingResumeTexts texts) async {
    if (!_available) return;
    _pendingTexts = texts;
    if (_storingTexts) return;
    _storingTexts = true;
    try {
      for (var next = _pendingTexts; next != null; next = _pendingTexts) {
        _pendingTexts = null;
        try {
          await _repository.saveTexts(next);
        } catch (e) {
          debugPrint(
            '[ResumeOnRestartViewModel] Could not store the texts: $e',
          );
        }
      }
    } finally {
      _storingTexts = false;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _repository.resumeOnRestart.removeListener(_refresh);
    _permissions.hasAlwaysLocationPermission.removeListener(_refresh);
    _permissions.isBackgroundRestricted.removeListener(_refresh);
    load.dispose();
    setEnabled.dispose();
    resolveBlocker.dispose();
    super.dispose();
  }
}
