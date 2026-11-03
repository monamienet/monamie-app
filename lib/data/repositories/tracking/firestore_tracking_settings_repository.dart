import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';

import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'tracking_settings_repository.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';

/// [TrackingSettingsRepository] over `organizations/{id}/config/tracking` and
/// `config/plan` in the bound organization's project.
///
/// In the UI isolate it is organization-scoped: whoever creates it calls
/// [start] once, which keeps [settings] current, and [dispose] once, which
/// stops listening. The tracking service's isolate only calls [watch].
class FirestoreTrackingSettingsRepository
    implements TrackingSettingsRepository {
  FirestoreTrackingSettingsRepository();

  StreamSubscription<TrackingSettings>? _subscription;
  bool _started = false;
  bool _disposed = false;

  final _settings = ValueNotifier<TrackingSettings>(TrackingSettings.defaults);

  @override
  ValueListenable<TrackingSettings> get settings => _settings;

  /// Starts following the saved settings into [settings]. Only the first
  /// call does anything.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _subscription = watch().listen((value) {
      if (!_disposed) _settings.value = value;
    }, onError: (_) {});
  }

  /// Stops listening and releases [settings]. Only the first call does
  /// anything.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _settings.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _config =>
      CurrentOrganizationFirebase.instance.organizationData.collection(
        FirestorePaths.config,
      );

  @override
  Future<int> minPeriodMinutes() async {
    try {
      final plan = await _config.doc(FirestorePaths.plan).get();
      final minutes = plan.data()?['minIntervalMinutes'];
      return minutes is int ? minutes : 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Stream<TrackingSettings> watch() async* {
    final min = await minPeriodMinutes();
    yield* _config
        .doc(FirestorePaths.tracking)
        .snapshots()
        .map(
          (doc) => trackingSettingsFromFirestore(
            doc.data(),
            minPeriodMinutes: min,
          ).withinOffered(),
        );
  }

  @override
  Future<void> save(TrackingSettings settings) =>
      _config.doc(FirestorePaths.tracking).set({
        ...trackingSettingsToFirestore(settings),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy':
            CurrentOrganizationFirebase.instance.auth.currentUser?.email,
      });
}

/// Reads `config/tracking`, whose stored fields keep their first names
/// (`intervalMinutes` for the period, `distanceMeters` for the radius). A
/// missing document or a value that is not allowed falls back field by field
/// (see [TrackingSettings.validated]).
TrackingSettings trackingSettingsFromFirestore(
  Map<String, Object?>? data, {
  int minPeriodMinutes = 0,
}) => TrackingSettings.validated(
  periodMinutes: data?['intervalMinutes'],
  radiusMeters: data?['distanceMeters'],
  minPeriodMinutes: minPeriodMinutes,
);

/// The stored fields of [settings] in `config/tracking`.
Map<String, Object?> trackingSettingsToFirestore(TrackingSettings settings) => {
  'intervalMinutes': settings.periodMinutes,
  'distanceMeters': settings.radiusMeters,
};
