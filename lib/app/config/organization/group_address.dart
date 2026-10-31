/// Domain of every MonAmie group.
const groupDomain = 'monamienet.org';

/// Ids that can never be an organization: `app` is the central project and
/// `community` the shared Community project. Twin of `reservedOrganizationIds` in
/// `tool/src/organizations.dart` and `RESERVED_ORGANIZATION_IDS` in
/// `functions/group_address.js`.
const reservedOrganizationIds = {'app', 'community'};

final _organizationIdPattern = RegExp(r'^[a-z]{3,}$');
final _localPartPattern = RegExp(r'^([a-z]+)(\d{2})([rw])?$');

/// Returns why [id] is not a valid organization id, or `null` when it is valid.
///
/// Organization ids are lowercase letters only (at least three): that is what
/// lets a group address be split into organization, team and leaf.
String? organizationIdProblem(String id) {
  if (!_organizationIdPattern.hasMatch(id) ||
      reservedOrganizationIds.contains(id)) {
    return "invalid organization id '$id': it must match "
        "${_organizationIdPattern.pattern} and not be one of "
        '${reservedOrganizationIds.join(', ')}';
  }
  return null;
}

/// The level of a MonAmie group in an organization's tree.
enum GroupLevel {
  /// `<id>00@`: the root group, whose members are the administrators.
  root,

  /// `<id>NN@` (01–99): a team. It has no direct members.
  team,

  /// `<id>NNr@` / `<id>NNw@`: who watches / who shares in the team.
  leaf,
}

/// A parsed MonAmie group address.
class GroupAddress {
  const GroupAddress({
    required this.organizationId,
    required this.team,
    required this.leaf,
  });

  /// The organization the group belongs to.
  final String organizationId;

  /// The two-digit team number; `00` is the root group.
  final String team;

  /// `r` (watch), `w` (share), or `null` for the root and team groups.
  final String? leaf;

  GroupLevel get level => team == '00'
      ? GroupLevel.root
      : leaf == null
      ? GroupLevel.team
      : GroupLevel.leaf;

  /// `<organization id><NN>`: the key of the team in the custom claims.
  String get teamKey => '$organizationId$team';

  /// The team group's e-mail, `<organization id><NN>@monamienet.org`.
  String get teamEmail => '$teamKey@$groupDomain';
}

/// Parses a group address with `^([a-z]+)(\d{2})([rw])?$` before
/// `@monamienet.org`. Returns `null` for anything else, including the
/// leaves of the root group (`<id>00r`, `<id>00w`), which never exist.
///
/// Twin of `parseGroupAddress` in `functions/group_address.js`.
GroupAddress? parseGroupAddress(String email) {
  final normalized = email.trim().toLowerCase();
  final at = normalized.lastIndexOf('@');
  if (at < 0 || normalized.substring(at + 1) != groupDomain) return null;
  final match = _localPartPattern.firstMatch(normalized.substring(0, at));
  if (match == null) return null;
  final organizationId = match[1]!;
  final team = match[2]!;
  final leaf = match[3];
  if (organizationIdProblem(organizationId) != null) return null;
  if (team == '00' && leaf != null) return null;
  return GroupAddress(organizationId: organizationId, team: team, leaf: leaf);
}

/// The organization a group gives access to, or `null`.
///
/// Only the root group and the team leaves grant anything; a direct member
/// of a team group (added by hand) gets nothing, as in `syncClaims`.
String? organizationIdFromGroupEmail(String email) {
  final address = parseGroupAddress(email);
  if (address == null || address.level == GroupLevel.team) return null;
  return address.organizationId;
}

/// The team e-mail for a team key: `rotasul01` → `rotasul01@monamienet.org`.
String teamEmailForKey(String teamKey) => '$teamKey@$groupDomain';
