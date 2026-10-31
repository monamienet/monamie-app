/// Ids that can never be an organization: `app` is the central project
/// (`monamienet-app`) and `community` the shared Community project. Kept in
/// sync with `central/functions/organization_id.js` and the app.
const reservedOrganizationIds = {'app', 'community'};

/// Lowercase letters only, at least three: the id names the organization's
/// project (`monamienet-<id>`).
final _organizationIdPattern = RegExp(r'^[a-z]{3,}$');

/// The shared Firebase project of every Community organization.
const communityProjectId = 'monamienet-community';

/// The Firebase project where organization [id]'s data lives: the shared
/// Community project when [plan] is `community`, else its own
/// `monamienet-<id>` (Standard, and entries written before plans existed).
String firebaseProjectId(String id, {String? plan}) =>
    plan == 'community' ? communityProjectId : 'monamienet-$id';

/// A failure the organization tool reports to the user as a plain message.
class OrganizationToolException implements Exception {
  OrganizationToolException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Returns why [id] is not a valid organization id, or `null` when it is valid.
///
/// The id names the organization's Firebase project (`monamienet-<id>`) and
/// its data root `organizations/<id>`.
String? organizationIdProblem(String id) {
  if (!_organizationIdPattern.hasMatch(id)) {
    return "Invalid organization id '$id': it must match ${_organizationIdPattern.pattern}.";
  }
  if (reservedOrganizationIds.contains(id)) {
    return "Invalid organization id '$id': it must not be one of "
        '${reservedOrganizationIds.join(', ')}.';
  }
  return null;
}

/// Throws a [OrganizationToolException] when [id] is not a valid organization id.
void checkOrganizationId(String id) {
  final problem = organizationIdProblem(id);
  if (problem != null) throw OrganizationToolException(problem);
}

/// The central MonAmie Firebase project: sign-in and the organization registry.
const centralProjectId = 'monamienet-app';

/// The single Android application id of the MonAmie app.
const appPackageName = 'org.monamienet.app';
