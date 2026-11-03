import 'package:monamie_app/data/repositories/functions_result.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/utils/result.dart';

import 'groups_repository.dart';

const _failed = Failure.connection(FailedAction.conclude);

/// [GroupsRepository] over the central project's group functions, called
/// with the MonAmie (central) session.
class GroupsRepositoryRemote implements GroupsRepository {
  const GroupsRepositoryRemote({required this._functions});

  final CentralFunctionsService _functions;

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function() operation, {
    Failure unexpected = _failed,
  }) => functionsResult(
    operation,
    refusal: functionsRefusal,
    unexpected: unexpected,
    logTag: 'Groups',
  );

  /// Calls [name] for an operation whose answer does not matter.
  Future<Result<void>> _void(String name, Map<String, Object?> data) =>
      _run(() async {
        await _functions.call(name, data);
        return const Ok(null);
      });

  @override
  Future<Result<List<Group>>> list(String organizationId) => _run(() async {
    final data = await _functions.call('listGroups', {
      'organizationId': organizationId,
    });
    final groups = data is Map ? data['groups'] : null;
    return Ok([
      for (final entry in groups is List ? groups : const [])
        ?Group.fromJson(entry),
    ]);
  }, unexpected: const Failure.load(LoadTarget.groups));

  @override
  Future<Result<Group>> create(String organizationId, String name) =>
      _run(() async {
        final data = await _functions.call('createGroup', {
          'organizationId': organizationId,
          'name': name,
        });
        final group = Group.fromJson({
          ...?(data as Map?),
          'people': const <Object?>[],
        });
        return group == null
            ? const Err(Failure.unexpectedResponse(creatingGroup: true))
            : Ok(group);
      });

  @override
  Future<Result<void>> rename(
    String organizationId,
    String groupId,
    String name,
  ) => _void('renameGroup', {
    'organizationId': organizationId,
    'groupId': groupId,
    'name': name,
  });

  @override
  Future<Result<({List<String> loses, List<String> stays})>> deletionImpact(
    String organizationId,
    String groupId,
  ) => _run(() async {
    final data = await _functions.call('groupDeletionImpact', {
      'organizationId': organizationId,
      'groupId': groupId,
    });
    List<String> list(String key) => [
      for (final e in (data is Map ? data[key] : null) as List? ?? const [])
        if (e is String) e,
    ];
    return Ok((loses: list('loses'), stays: list('stays')));
  });

  @override
  Future<Result<void>> delete(String organizationId, String groupId) => _void(
    'deleteGroup',
    {'organizationId': organizationId, 'groupId': groupId},
  );

  @override
  Future<Result<void>> setRoles(
    String organizationId,
    String groupId,
    String email,
    Set<GroupRole> roles,
  ) => _void('setMemberRoles', {
    'organizationId': organizationId,
    'groupId': groupId,
    'email': email,
    'roles': [for (final r in roles) r.id],
  });

  @override
  Future<Result<void>> remove(
    String organizationId,
    String groupId,
    String email,
  ) => _void('removeMember', {
    'organizationId': organizationId,
    'groupId': groupId,
    'email': email,
  });
}
