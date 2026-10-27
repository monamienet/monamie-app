/// Ids that can never be a partner: `app` is the central project
/// (`monamienet-app`) and `community` the shared Community project. Kept in
/// sync with `lib/app/config/partner/group_address.dart` and
/// `functions/group_address.js`.
const reservedPartnerIds = {'app', 'community'};

/// Lowercase letters only, at least three: what lets a group address be
/// split into partner, team and leaf (`rotasul01w`).
final _partnerIdPattern = RegExp(r'^[a-z]{3,}$');
final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// The shared Firebase project of every Community partner.
const communityProjectId = 'monamienet-community';

/// The Firebase project where partner [id]'s data lives: the shared
/// Community project when [plan] is `community`, else its own
/// `monamienet-<id>` (Standard, and entries written before plans existed).
String firebaseProjectId(String id, {String? plan}) =>
    plan == 'community' ? communityProjectId : 'monamienet-$id';

/// Path of partner [id]'s data root in its project. Every partner, on any
/// plan, keeps its data under it.
String partnerDataPath(String id) => 'partners/$id';

/// Whether [value] is a color in the `#RRGGBB` format (either case).
bool isHexColor(Object? value) =>
    value is String && _hexColorPattern.hasMatch(value);

/// A failure the partner tool reports to the user as a plain message.
class PartnerToolException implements Exception {
  PartnerToolException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Returns why [id] is not a valid partner id, or `null` when it is valid.
///
/// The id names the partner's Firebase project (`monamienet-<id>`) and its
/// groups (`<id>00@`, `<id>NN@`, `<id>NNr@`, `<id>NNw@monamienet.org`).
String? partnerIdProblem(String id) {
  if (!_partnerIdPattern.hasMatch(id)) {
    return "Invalid partner id '$id': it must match ${_partnerIdPattern.pattern}.";
  }
  if (reservedPartnerIds.contains(id)) {
    return "Invalid partner id '$id': it must not be one of "
        '${reservedPartnerIds.join(', ')}.';
  }
  return null;
}

/// Throws a [PartnerToolException] when [id] is not a valid partner id.
void checkPartnerId(String id) {
  final problem = partnerIdProblem(id);
  if (problem != null) throw PartnerToolException(problem);
}

/// The central MonAmie Firebase project: sign-in and the partner registry.
const centralProjectId = 'monamienet-app';

/// The single Android application id of the MonAmie app.
const appPackageName = 'org.monamienet.app';

/// The root group of partner [id]: `<id>00@monamienet.org`.
String rootGroupEmail(String id) => '${id}00@monamienet.org';
