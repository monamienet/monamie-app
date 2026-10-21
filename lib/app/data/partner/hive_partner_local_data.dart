import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'partner_local_data.dart';

/// Hive boxes that hold partner data: the gateway groups cache
/// (`GoogleGroupsProvider`) and the user's data (`UserDataProvider`).
/// `user_google_data` is deleted by the sign-out itself.
const partnerHiveBoxes = ['google_groups_data', 'user_data'];

/// [PartnerLocalData] stored in Hive.
class HivePartnerLocalData implements PartnerLocalData {
  const HivePartnerLocalData();

  @override
  Future<void> clear() async {
    for (final box in partnerHiveBoxes) {
      try {
        await Hive.deleteBoxFromDisk(box);
      } catch (error) {
        // A box that cannot be deleted must not block the sign-out.
        debugPrint('Could not delete the Hive box $box: $error');
      }
    }
  }
}
