import 'group.dart';

/// The administrators' group operations (central functions), kept apart so
/// the screens are tested with a fake. Every method throws
/// [GroupsException] with a message for an administrator.
abstract interface class GroupsBackend {
  Future<List<Group>> list(String organizationId);
  Future<Group> create(String organizationId, String name);
  Future<void> rename(String organizationId, String groupId, String name);

  /// Who would lose access to the organization if [groupId] were deleted
  /// (people in no other group who do not administer it), and who stays.
  Future<({List<String> loses, List<String> stays})> deletionImpact(
    String organizationId,
    String groupId,
  );

  Future<void> delete(String organizationId, String groupId);
  Future<void> setRoles(
    String organizationId,
    String groupId,
    String email,
    Set<GroupRole> roles,
  );
  Future<void> remove(String organizationId, String groupId, String email);
}

/// A group operation that failed, in words for an administrator.
class GroupsException implements Exception {
  const GroupsException(this.message);

  final String message;

  @override
  String toString() => message;
}
