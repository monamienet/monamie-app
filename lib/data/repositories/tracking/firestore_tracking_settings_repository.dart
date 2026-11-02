import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';

import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'tracking_settings_repository.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';

/// [TrackingSettingsRepository] over `organizations/{id}/config/tracking` and
/// `config/plan` in the bound organization's project.
class FirestoreTrackingSettingsRepository
    implements TrackingSettingsRepository {
  const FirestoreTrackingSettingsRepository();

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
