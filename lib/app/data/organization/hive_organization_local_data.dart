import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'organization_local_data.dart';

/// Hive boxes earlier versions filled with organization data (the groups
/// gateway's cache and the user's groups), still deleted at sign-out so
/// nothing of them stays on an updated device. `user_google_data` is
/// deleted by the sign-out itself.
const organizationHiveBoxes = ['google_groups_data', 'user_data'];

/// [OrganizationLocalData] stored in Hive.
class HiveOrganizationLocalData implements OrganizationLocalData {
  const HiveOrganizationLocalData();

  @override
  Future<void> clear() async {
    for (final box in organizationHiveBoxes) {
      try {
        await Hive.deleteBoxFromDisk(box);
      } catch (error) {
        // A box that cannot be deleted must not block the sign-out.
        debugPrint('Could not delete the Hive box $box: $error');
      }
    }
  }
}
