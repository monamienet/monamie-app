import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';

import 'capabilities.dart';

/// Syncs and reads the MonAmie custom claims (`share`, `watch`, `admin`) of
/// the person signed in to the bound partner's project.
class MonAmieClaimsService {
  MonAmieClaimsService._();

  /// Calls the partner's `syncClaims`, which recomputes the claims from the
  /// person's Google Groups, then refreshes the ID token so the rules see
  /// them.
  ///
  /// Returns the new capabilities, or `null` when the sync failed (which is
  /// not evidence of removal).
  static Future<Capabilities?> syncClaims() async {
    try {
      final user = CurrentPartnerFirebase.instance.auth.currentUser;
      if (user == null) {
        debugPrint('[MonAmieClaimsService] Not signed in.');
        return null;
      }
      // A fresh token for the function to forward to the groups gateway.
      final rawToken = await user.getIdToken(true);
      if (rawToken == null) return null;

      final result = await CurrentPartnerFirebase.instance.functions
          .httpsCallable('syncClaims')
          .call({'idToken': rawToken});
      await user.getIdToken(true);

      final data = result.data;
      final capabilities = Capabilities.fromClaims(
        data is Map ? Map<String, Object?>.from(data) : const {},
      );
      debugPrint(
        '[MonAmieClaimsService] Synced: share=${capabilities.share} '
        'watch=${capabilities.watch} admin=${capabilities.admin}',
      );
      return capabilities;
    } catch (e) {
      debugPrint('[MonAmieClaimsService] Could not sync the claims: $e');
      return null;
    }
  }

  /// The capabilities in the current ID token, without syncing. `null` when
  /// not signed in or the token cannot be read.
  static Future<Capabilities?> readClaims() async {
    try {
      final user = CurrentPartnerFirebase.instance.auth.currentUser;
      if (user == null) return null;
      final result = await user.getIdTokenResult(true);
      return Capabilities.fromClaims(result.claims ?? const {});
    } catch (e) {
      debugPrint('[MonAmieClaimsService] Could not read the claims: $e');
      return null;
    }
  }

  /// Whether the person may share their location, syncing the claims first
  /// when the token has none that allow it.
  static Future<bool> ensureCanShare() async {
    final current = await readClaims();
    if (current != null && current.canShare) return true;
    return (await syncClaims())?.canShare ?? false;
  }
}
