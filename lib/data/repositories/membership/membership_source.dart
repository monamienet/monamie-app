/// The signed-in person's membership documents in an organization's
/// project, and the names of the groups they may read, as live streams.
///
/// Kept behind a contract so the controllers (in the UI isolate and in the
/// background tracking isolate) are tested with a fake.
abstract interface class MembershipSource {
  /// The data of `organizationMemberships/{personKey(email)}`, then every
  /// change. `null` means the server says it does not exist: the person was
  /// removed (a missing document seen only in the local cache is not
  /// emitted).
  Stream<Map<String, Object?>?> organizationMembership(
    String organizationId,
    String email,
  );

  /// The raw `roles` of each of the person's group memberships in
  /// [organizationId], by group id, then every change (a collection-group
  /// query on `groupMemberships` filtered by `email` and `organizationId`).
  Stream<Map<String, Object?>> groupRoles(String organizationId, String email);

  /// Every group of [organizationId], name by id. Only administrators may
  /// list them.
  Stream<Map<String, String>> allGroupNames(String organizationId);

  /// The name of group [groupId], `null` when the group does not exist.
  /// Its members (any role) and the administrators may read it.
  Stream<String?> groupName(String organizationId, String groupId);
}
