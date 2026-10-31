import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

/// What the signed-in person may do in the bound organization, read from
/// their own membership documents (the same ones `firestore.rules` reads):
/// `organizationMemberships/{personKey}` (belongs, and whether as an
/// administrator) and `groups/{groupId}/groupMemberships/{personKey}`
/// (their roles in each group).
class Capabilities {
  const Capabilities({
    this.isMember = false,
    this.isAdmin = false,
    this.rolesByGroup = const {},
  });

  /// Reads the documents. [organizationMembership] is the data of
  /// `organizationMemberships/{personKey}`, `null` when it does not exist;
  /// [groupRoles] the raw `roles` of each of the person's group memberships,
  /// by group id. Without an organization membership the person belongs to
  /// nothing there, whatever group memberships are left. A malformed field
  /// counts as absent, never as an error; unknown roles are kept but grant
  /// nothing.
  factory Capabilities.fromMemberships({
    required Map<String, Object?>? organizationMembership,
    required Map<String, Object?> groupRoles,
  }) {
    if (organizationMembership == null) return const Capabilities();
    return Capabilities(
      isMember: true,
      isAdmin:
          organizationMembership[OrganizationMembershipFields.role] ==
          OrganizationRoles.admin,
      rolesByGroup: {
        for (final MapEntry(:key, :value) in groupRoles.entries)
          if (rolesOf(value) case final roles when roles.isNotEmpty) key: roles,
      },
    );
  }

  /// Whether the person belongs to the organization at all.
  final bool isMember;

  /// Whether the person administers the organization (the *administrador*):
  /// they manage it and see every group.
  final bool isAdmin;

  /// The person's roles ([GroupRoles]) in each of their groups, by group id.
  final Map<String, Set<String>> rolesByGroup;

  /// The groups where the person publishes their location, sorted.
  List<String> get publisherGroupIds => _groupsWith(GroupRoles.publisher);

  /// The groups whose map the person receives as a subscriber, sorted
  /// (administrators see every group besides these).
  List<String> get subscriberGroupIds => _groupsWith(GroupRoles.subscriber);

  /// The groups the person manages as their *Gestor do grupo*, sorted
  /// (administrators manage every group besides these).
  List<String> get maintainerGroupIds => _groupsWith(GroupRoles.maintainer);

  /// Whether the person manages some group: as an administrator, or as
  /// the maintainer of one.
  bool get canManageGroups => isAdmin || maintainerGroupIds.isNotEmpty;

  /// Whether the person shares their location in some group.
  bool get canPublish => publisherGroupIds.isNotEmpty;

  /// Whether the person sees some group's map. A person who only publishes
  /// sees just their own position.
  bool get canWatch => isAdmin || subscriberGroupIds.isNotEmpty;

  /// Whether the person sees the map of group [groupId].
  bool canWatchGroup(String groupId) =>
      isAdmin ||
      (rolesByGroup[groupId]?.contains(GroupRoles.subscriber) ?? false);

  List<String> _groupsWith(String role) => [
    for (final MapEntry(:key, :value) in rolesByGroup.entries)
      if (value.contains(role)) key,
  ]..sort();

  @override
  bool operator ==(Object other) =>
      other is Capabilities &&
      other.isMember == isMember &&
      other.isAdmin == isAdmin &&
      other.rolesByGroup.length == rolesByGroup.length &&
      rolesByGroup.entries.every(
        (e) =>
            other.rolesByGroup[e.key]?.length == e.value.length &&
            other.rolesByGroup[e.key]!.containsAll(e.value),
      );

  @override
  int get hashCode => Object.hash(isMember, isAdmin, rolesByGroup.length);
}

/// The role names in a raw `roles` field: the strings of a list, anything
/// else none.
Set<String> rolesOf(Object? raw) => {
  if (raw is List)
    for (final role in raw)
      if (role is String && role.isNotEmpty) role,
};

/// The ids in [groupRoles] (raw `roles` by group id) whose roles include
/// [role], sorted. The background service uses it for the groups it
/// publishes to.
List<String> groupsWithRole(Map<String, Object?> groupRoles, String role) => [
  for (final MapEntry(:key, :value) in groupRoles.entries)
    if (rolesOf(value).contains(role)) key,
]..sort();
