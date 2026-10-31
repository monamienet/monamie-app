import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// The groups whose map the person sees: every group of the organization
/// ([allGroupIds]) for an administrator, the groups where they are a
/// `subscriber` for anyone else. Only groups whose name is known in [names]
/// are listed (a group still loading, or deleted, is left out), sorted by
/// name.
List<MapGroup> mapGroupsFor(
  Capabilities capabilities, {
  required Map<String, String> names,
  Iterable<String> allGroupIds = const [],
}) => namedGroups({
  if (capabilities.isAdmin) ...allGroupIds,
  ...capabilities.subscriberGroupIds,
}, names);

/// [groupIds] with their names from [names], sorted by name (ignoring case)
/// and then by id; ids without a name are skipped.
List<MapGroup> namedGroups(
  Iterable<String> groupIds,
  Map<String, String> names,
) {
  final groups = [
    for (final id in {...groupIds})
      if (names[id] case final name?)
        MapGroup(id: id, name: name.isEmpty ? 'Grupo sem nome' : name),
  ];
  groups.sort((a, b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.id.compareTo(b.id);
  });
  return groups;
}

/// The group to switch the map to once [groups] are known: the first one
/// when nothing is observed yet or the observed [current] is no longer among
/// them, `null` when the map should stay as it is (or [groups] is empty).
MapGroup? groupToObserve(List<MapGroup> groups, MapGroup? current) {
  if (groups.isEmpty) return null;
  if (current != null && groups.any((g) => g.id == current.id)) return null;
  return groups.first;
}

/// The observed [current] as it is now in [groups] when only its name
/// changed, so the app bar shows the new name; `null` otherwise.
MapGroup? renamedSelection(List<MapGroup> groups, MapGroup? current) {
  if (current == null) return null;
  for (final group in groups) {
    if (group.id == current.id) {
      return group.name != current.name ? group : null;
    }
  }
  return null;
}

/// The people of a group's positions, by name: the name they published
/// with, or the e-mail when it is blank.
List<GroupMember> membersOf(Iterable<UserModel> positions) {
  final members = [
    for (final user in positions)
      GroupMember(
        name: switch (user.name?.trim()) {
          final String name when name.isNotEmpty => name,
          _ => user.email,
        },
        email: user.email,
      ),
  ];
  members.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return members;
}
