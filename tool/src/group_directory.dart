/// A member of a Google group.
class GroupMember {
  const GroupMember({
    required this.email,
    required this.isGroup,
    this.role = 'MEMBER',
    this.isUser = true,
  });

  final String email;

  /// Whether the member is itself a group (a subgroup).
  final bool isGroup;

  /// Whether the member is a person's account (Cloud Identity type `USER`),
  /// not a group or another kind of member (`OTHER`).
  final bool isUser;

  /// The Google Groups role: `MEMBER`, `MANAGER` or `OWNER`. In the MonAmie
  /// group model everyone is a plain `MEMBER`; the others only appear in
  /// groups made before it.
  final String role;
}

/// Reads Google Workspace group memberships.
///
/// Implementations throw a `PartnerToolException` when the group does not
/// exist or cannot be read.
abstract interface class GroupDirectory {
  Future<List<GroupMember>> members(String groupEmail);
}
