import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'organization_local_data.dart';

/// Hive boxes that hold organization data: the gateway groups cache
/// (`GoogleGroupsProvider`) and the user's data (`UserDataProvider`).
/// `user_google_data` is deleted by the sign-out itself.
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
