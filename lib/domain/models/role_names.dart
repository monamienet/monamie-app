/// The role names of the organization and of its groups, as stored in the
/// membership documents and sent to the central functions. They are the
/// domain's vocabulary, so they live here; `firestore_paths.dart` exports
/// them next to the field names that hold them.
library;

/// The two values of `organizationMemberships/{personKey}.role`.
abstract final class OrganizationRoles {
  /// Manages the organization and sees every group.
  static const admin = 'admin';
  static const member = 'member';
}

/// The values of `groupMemberships/{personKey}.roles`.
abstract final class GroupRoles {
  /// Shares their own location in the group.
  static const publisher = 'publisher';

  /// Sees the group's map and history.
  static const subscriber = 'subscriber';

  /// Manages the group's people, invites and name through the central
  /// functions (*Gestor do grupo*); given only by administrators.
  static const maintainer = 'maintainer';
}
