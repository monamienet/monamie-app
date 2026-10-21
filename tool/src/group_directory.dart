/// A member of a Google group.
class GroupMember {
  const GroupMember({required this.email, required this.isGroup});

  final String email;

  /// Whether the member is itself a group (a subgroup).
  final bool isGroup;
}

/// Reads Google Workspace group memberships.
///
/// Implementations throw a `PartnerToolException` when the group does not
/// exist or cannot be read.
abstract interface class GroupDirectory {
  Future<List<GroupMember>> members(String groupEmail);
}
