import 'package:monamie_app/app/config/partner/group_address.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';

/// Whether any of the user's groups (as the gateway's `/groups` returns
/// them) gives access to partner [partnerId]: its root group, or a watch
/// or share leaf of one of its teams.
///
/// When it becomes false, the user was removed from all the partner's
/// groups and the app forgets the partner.
bool belongsToPartner(
  String partnerId,
  Iterable<Map<String, dynamic>> userGroups,
) => userGroups.any((group) {
  final email = group['email'];
  return email is String && partnerIdFromGroupEmail(email) == partnerId;
});

/// Whether the claims synced by the partner's `syncClaims` show that the
/// user has no capability left in the partner.
///
/// `null` means the sync failed, which is not evidence of removal.
bool claimsShowNoAccess(Capabilities? capabilities) =>
    capabilities != null && capabilities.isEmpty;
