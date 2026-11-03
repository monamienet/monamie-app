import 'package:monamie_app/domain/models/role_names.dart';

/// What the signed-in person may do in the bound organization, read from
/// their own membership documents (the same ones `firestore.rules` reads):
/// `organizationMemberships/{personKey}` (belongs, and whether as an
/// administrator) and `groups/{groupId}/groupMemberships/{personKey}`
/// (their roles in each group). The data layer reads them
/// (`capabilitiesFromMemberships` in `membership_service.dart`).
class Capabilities {
  const Capabilities({
    this.isMember = false,
    this.isAdmin = false,
    this.rolesByGroup = const {},
  });

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
