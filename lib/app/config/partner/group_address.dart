/// Domain of every MonAmie group.
const groupDomain = 'monamienet.org';

/// Ids that can never be a partner: `app` is the central project and
/// `community` the shared Community project. Twin of `reservedPartnerIds` in
/// `tool/src/partners.dart` and `RESERVED_PARTNER_IDS` in
/// `functions/group_address.js`.
const reservedPartnerIds = {'app', 'community'};

final _partnerIdPattern = RegExp(r'^[a-z]{3,}$');
final _localPartPattern = RegExp(r'^([a-z]+)(\d{2})([rw])?$');

/// Returns why [id] is not a valid partner id, or `null` when it is valid.
///
/// Partner ids are lowercase letters only (at least three): that is what
/// lets a group address be split into partner, team and leaf.
String? partnerIdProblem(String id) {
  if (!_partnerIdPattern.hasMatch(id) || reservedPartnerIds.contains(id)) {
    return "invalid partner id '$id': it must match "
        "${_partnerIdPattern.pattern} and not be one of "
        '${reservedPartnerIds.join(', ')}';
  }
  return null;
}

/// The level of a MonAmie group in a partner's tree.
enum GroupLevel {
  /// `<id>00@`: the root group, whose only member is the owner.
  root,

  /// `<id>NN@` (01–99): a team. It has no direct members.
  team,

  /// `<id>NNr@` / `<id>NNw@`: who watches / who shares in the team.
  leaf,
}

/// A parsed MonAmie group address.
class GroupAddress {
  const GroupAddress({
    required this.partnerId,
    required this.team,
    required this.leaf,
  });

  /// The partner the group belongs to.
  final String partnerId;

  /// The two-digit team number; `00` is the root group.
  final String team;

  /// `r` (watch), `w` (share), or `null` for the root and team groups.
  final String? leaf;

  GroupLevel get level => team == '00'
      ? GroupLevel.root
      : leaf == null
      ? GroupLevel.team
      : GroupLevel.leaf;

  /// `<partner id><NN>`: the key of the team in the custom claims.
  String get teamKey => '$partnerId$team';

  /// The team group's e-mail, `<partner id><NN>@monamienet.org`.
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
  final partnerId = match[1]!;
  final team = match[2]!;
  final leaf = match[3];
  if (partnerIdProblem(partnerId) != null) return null;
  if (team == '00' && leaf != null) return null;
  return GroupAddress(partnerId: partnerId, team: team, leaf: leaf);
}

/// The partner a group gives access to, or `null`.
///
/// Only the root group and the team leaves grant anything; a direct member
/// of a team group (added by hand) gets nothing, as in `syncClaims`.
String? partnerIdFromGroupEmail(String email) {
  final address = parseGroupAddress(email);
  if (address == null || address.level == GroupLevel.team) return null;
  return address.partnerId;
}

/// The team e-mail for a team key: `rotasul01` → `rotasul01@monamienet.org`.
String teamEmailForKey(String teamKey) => '$teamKey@$groupDomain';
