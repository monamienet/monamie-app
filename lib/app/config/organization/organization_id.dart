/// Ids that can never be an organization: `app` is the central project and
/// `community` the shared Community project. Twin of
/// `reservedOrganizationIds` in `tool/src/organizations.dart` and of
/// `isValidOrganizationId` in `central/functions/organization_id.js`.
const reservedOrganizationIds = {'app', 'community'};

final _organizationIdPattern = RegExp(r'^[a-z]{3,}$');

/// Returns why [id] is not a valid organization id, or `null` when it is
/// valid: lowercase letters only (at least three), and not reserved.
String? organizationIdProblem(String id) {
  if (!_organizationIdPattern.hasMatch(id) ||
      reservedOrganizationIds.contains(id)) {
    return "invalid organization id '$id': it must match "
        "${_organizationIdPattern.pattern} and not be one of "
        '${reservedOrganizationIds.join(', ')}';
  }
  return null;
}
