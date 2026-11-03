import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [GroupsRepository] over [groups], one list per organization id: creating
/// a group adds it (ids `g1`, `g2`… in creation order), renaming, setting
/// roles and removing people change it, deleting removes it.
class FakeGroupsRepository with FakeOutcomes implements GroupsRepository {
  /// Starts with [groups] by organization id.
  FakeGroupsRepository({Map<String, List<Group>>? groups})
    : groups = {
        for (final MapEntry(:key, :value) in (groups ?? const {}).entries)
          key: [...value],
      };

  /// The groups of each organization, in the server's order.
  final Map<String, List<Group>> groups;

  int _nextId = 1;

  List<Group> _of(String organizationId) =>
      groups.putIfAbsent(organizationId, () => []);

  /// Replaces group [groupId] of [organizationId] with [change] of it.
  void _change(
    String organizationId,
    String groupId,
    Group Function(Group group) change,
  ) {
    final list = _of(organizationId);
    final index = list.indexWhere((g) => g.id == groupId);
    if (index < 0) throw StateError('No group $groupId in $organizationId.');
    list[index] = change(list[index]);
  }

  @override
  Future<Result<List<Group>>> list(String organizationId) =>
      answer('list', [organizationId], () => [..._of(organizationId)]);

  @override
  Future<Result<Group>> create(String organizationId, String name) =>
      answer('create', [organizationId, name], () {
        final group = Group(id: 'g${_nextId++}', name: name, people: const []);
        _of(organizationId).add(group);
        return group;
      });

  @override
  Future<Result<void>> rename(
    String organizationId,
    String groupId,
    String name,
  ) => answer('rename', [
    organizationId,
    groupId,
    name,
  ], () => _change(organizationId, groupId, (g) => g.copyWith(name: name)));

  /// Whoever is in [groupId] and in no other group of the organization
  /// loses access; the others stay. (The fake does not know who
  /// administers the organization.)
  @override
  Future<Result<({List<String> loses, List<String> stays})>> deletionImpact(
    String organizationId,
    String groupId,
  ) => answer('deletionImpact', [organizationId, groupId], () {
    final list = _of(organizationId);
    final elsewhere = {
      for (final g in list)
        if (g.id != groupId) ...g.people.map((p) => p.email),
    };
    final people = [
      for (final g in list)
        if (g.id == groupId) ...g.people.map((p) => p.email),
    ];
    return (
      loses: [...people.where((e) => !elsewhere.contains(e))],
      stays: [...people.where(elsewhere.contains)],
    );
  });

  @override
  Future<Result<void>> delete(String organizationId, String groupId) => answer(
    'delete',
    [organizationId, groupId],
    () => _of(organizationId).removeWhere((g) => g.id == groupId),
  );

  /// Gives [email] exactly [roles] in [groupId], adding them when absent.
  @override
  Future<Result<void>> setRoles(
    String organizationId,
    String groupId,
    String email,
    Set<GroupRole> roles,
  ) => answer(
    'setRoles',
    [organizationId, groupId, email, roles],
    () => _change(organizationId, groupId, (g) {
      final person = GroupPerson(email: email, roles: roles);
      final found = g.people.any((p) => p.email == email);
      return g.copyWith(
        people: found
            ? [for (final p in g.people) p.email == email ? person : p]
            : [...g.people, person],
      );
    }),
  );

  @override
  Future<Result<void>> remove(
    String organizationId,
    String groupId,
    String email,
  ) => answer(
    'remove',
    [organizationId, groupId, email],
    () => _change(
      organizationId,
      groupId,
      (g) => g.copyWith(people: [...g.people.where((p) => p.email != email)]),
    ),
  );
}
