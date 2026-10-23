/// The central MonAmie project is `monamienet-app`, so `app` can never be a
/// partner id. Kept in sync with `lib/app/config/partner/partner_config.dart`.
const reservedPartnerIds = {'app'};

final _partnerIdPattern = RegExp(r'^[a-z][a-z0-9]*$');
final _hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

/// The Firebase project of partner [id]: `monamienet-<id>`.
String firebaseProjectId(String id) => 'monamienet-$id';

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
/// groups (`<id>NN@monamienet.org`).
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
