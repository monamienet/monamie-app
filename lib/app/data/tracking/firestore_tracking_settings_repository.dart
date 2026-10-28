import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';

import 'tracking_settings.dart';
import 'tracking_settings_repository.dart';

/// [TrackingSettingsRepository] over `partners/{id}/config/tracking` and
/// `config/plan` in the bound partner's project.
class FirestoreTrackingSettingsRepository
    implements TrackingSettingsRepository {
  const FirestoreTrackingSettingsRepository();

  CollectionReference<Map<String, dynamic>> get _config =>
      CurrentPartnerFirebase.instance.partnerData.collection('config');

  @override
  Future<int> minPeriodMinutes() async {
    try {
      final plan = await _config.doc('plan').get();
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
        .doc('tracking')
        .snapshots()
        .map(
          (doc) => TrackingSettings.fromMap(
            doc.data(),
            minPeriodMinutes: min,
          ).withinOffered(),
        );
  }

  @override
  Future<void> save(TrackingSettings settings) => _config.doc('tracking').set({
    ...settings.toMap(),
    'updatedAt': FieldValue.serverTimestamp(),
    'updatedBy': CurrentPartnerFirebase.instance.auth.currentUser?.email,
  });
}
