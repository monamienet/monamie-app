import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';

import 'tracking_settings.dart';
import 'tracking_settings_repository.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

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
          (doc) => TrackingSettings.fromMap(
            doc.data(),
            minPeriodMinutes: min,
          ).withinOffered(),
        );
  }

  @override
  Future<void> save(TrackingSettings settings) =>
      _config.doc(FirestorePaths.tracking).set({
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy':
            CurrentOrganizationFirebase.instance.auth.currentUser?.email,
      });
}
