import 'package:monamie_app/app/config/organization/group_address.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';

/// Whether any of the user's groups (as the gateway's `/groups` returns
/// them) gives access to organization [organizationId]: its root group, or a watch
/// or share leaf of one of its teams.
///
/// When it becomes false, the user was removed from all the organization's
/// groups and the app forgets the organization.
bool belongsToOrganization(
  String organizationId,
  Iterable<Map<String, dynamic>> userGroups,
) => userGroups.any((group) {
  final email = group['email'];
  return email is String &&
      organizationIdFromGroupEmail(email) == organizationId;
});

/// Whether the claims synced by the organization's `syncClaims` show that the
/// user has no capability left in the organization.
///
/// `null` means the sync failed, which is not evidence of removal.
bool claimsShowNoAccess(Capabilities? capabilities) =>
    capabilities != null && capabilities.isEmpty;
