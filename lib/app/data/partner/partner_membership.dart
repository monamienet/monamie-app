import 'package:monamie_app/app/config/partner/partner_config.dart';

/// Whether any of the user's groups (as the gateway's `/groups` returns
/// them) belongs to partner [partnerId] by name (`<id>NN@monamienet.org`).
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
/// user has no role left in any of the partner's groups.
///
/// `null` means the sync failed, which is not evidence of removal.
bool claimsShowNoAccess(Map<String, dynamic>? groupRoles) =>
    groupRoles != null && groupRoles.isEmpty;
