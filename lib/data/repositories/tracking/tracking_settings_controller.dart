// check_layers: state_contract

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'tracking_settings_repository.dart';

/// The bound organization's tracking settings in the UI isolate, kept current for
/// the *Ajustes de acompanhamento* screen.
///
/// Whoever creates it calls [start] once, to begin listening, and [dispose]
/// once, which stops listening.
class TrackingSettingsController {
  TrackingSettingsController({required this._repository});

  final TrackingSettingsRepository _repository;
  StreamSubscription<TrackingSettings>? _subscription;
  bool _started = false;
  bool _disposed = false;

  final _settings = ValueNotifier<TrackingSettings>(TrackingSettings.defaults);

  /// The saved settings; notifies only when they change.
  ValueListenable<TrackingSettings> get settings => _settings;

  /// Starts following the saved settings. Only the first call does
  /// anything.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _subscription = _repository.watch().listen((value) {
      if (!_disposed) _settings.value = value;
    }, onError: (_) {});
  }

  /// Stops listening and releases the value. Only the first call does
  /// anything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _settings.dispose();
  }
}
