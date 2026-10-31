/// The Firestore collection and document names the app and `tool/` use, in
/// one place, so a rename cannot miss one. `firestore.rules` and the
/// functions (`firestore_paths.js` in `functions/` and `central/functions/`)
/// use the same names.
abstract final class FirestorePaths {
  /// Root of every organization's data in its project, and of the central
  /// registry in the central project.
  static const organizations = 'organizations';

  /// `config/branding`, `config/tracking` and `config/plan` of an
  /// organization.
  static const config = 'config';
  static const branding = 'branding';
  static const tracking = 'tracking';
  static const plan = 'plan';

  /// Under a group: a person's last position published there, keyed by
  /// `personKey(email)` ([PositionFields]).
  static const positions = 'positions';

  /// Under a position: one point per position sent ([TrailPointFields]).
  static const trail = 'trail';

  /// Under a position: one summary per day, keyed `yyyy-mm-dd`
  /// ([TrailDayFields]).
  static const trailDays = 'trailDays';

  /// The theme catalog, in the central project.
  static const themes = 'themes';

  /// Who belongs to an organization, keyed by `personKey(email)`:
  /// `{email, role, addedAt}` ([OrganizationMembershipFields]).
  static const organizationMemberships = 'organizationMemberships';

  /// An organization's groups (`{name, createdAt}`, auto ids;
  /// [GroupFields]).
  static const groups = 'groups';

  /// Under a group: who belongs to it, keyed by `personKey(email)`
  /// ([GroupMembershipFields]).
  static const groupMemberships = 'groupMemberships';

  /// Each person's organizations, keyed by `personKey(email)`, in the
  /// central project (`{email, organizationIds}`). Only the central
  /// functions and `tool/` read it.
  static const accounts = 'accounts';

  /// `organizations/{id}`: an organization's data in its project, or its
  /// entry in the central registry.
  static String organization(String id) => '$organizations/$id';

  /// `organizations/{id}/config/branding`.
  static String brandingDocument(String id) =>
      '${organization(id)}/$config/$branding';

  /// `organizations/{id}/organizationMemberships/{personKey}`.
  static String organizationMembership(String id, String key) =>
      '${organization(id)}/$organizationMemberships/$key';

  /// `accounts/{personKey}` (central project).
  static String account(String key) => '$accounts/$key';

  /// `organizations/{id}/groups/{groupId}`.
  static String group(String id, String groupId) =>
      '${organization(id)}/$groups/$groupId';

  /// `organizations/{id}/groups/{groupId}/positions`.
  static String groupPositions(String id, String groupId) =>
      '${group(id, groupId)}/$positions';

  /// `organizations/{id}/groups/{groupId}/positions/{personKey}`.
  static String position(String id, String groupId, String key) =>
      '${groupPositions(id, groupId)}/$key';

  /// Cloud Storage path of an organization's logo (not Firestore, but under
  /// the same name).
  static String logo(String id) => '${organization(id)}/logo.png';
}

/// Fields of `organizations/{id}/organizationMemberships/{personKey}`.
abstract final class OrganizationMembershipFields {
  static const email = 'email';

  /// `admin` or `member`.
  static const role = 'role';
  static const addedAt = 'addedAt';
}

/// The two values of [OrganizationMembershipFields.role].
abstract final class OrganizationRoles {
  /// Manages the organization and sees every group.
  static const admin = 'admin';
  static const member = 'member';
}

/// Fields of `organizations/{id}/groups/{groupId}`.
abstract final class GroupFields {
  static const name = 'name';
  static const createdAt = 'createdAt';
}

/// Fields of `groups/{groupId}/groupMemberships/{personKey}`.
abstract final class GroupMembershipFields {
  static const email = 'email';

  /// Repeated so the person finds their own memberships with one
  /// collection-group query filtered by organization.
  static const organizationId = 'organizationId';

  /// A sorted, non-empty subset of [GroupRoles].
  static const roles = 'roles';
  static const addedAt = 'addedAt';
}

/// The values of [GroupMembershipFields.roles].
abstract final class GroupRoles {
  /// Shares their own location in the group.
  static const publisher = 'publisher';

  /// Sees the group's map and history.
  static const subscriber = 'subscriber';

  /// Manages the group's people, invites and name through the central
  /// functions (*Gestor do grupo*); given only by administrators.
  static const maintainer = 'maintainer';
}

/// Fields of `accounts/{personKey}` (central project).
abstract final class AccountFields {
  static const email = 'email';
  static const organizationIds = 'organizationIds';
}

/// Fields of `groups/{groupId}/positions/{personKey}`.
abstract final class PositionFields {
  static const email = 'email';
  static const name = 'name';
  static const lat = 'lat';
  static const lng = 'lng';

  /// When the device captured the position (device clock).
  static const capturedAt = 'capturedAt';

  /// When the server received the position (server clock).
  static const receivedAt = 'receivedAt';
  static const isPublishing = 'isPublishing';

  /// `null` while the person publishes here; set only by the central
  /// functions when they lose `publisher` or leave the group, which takes
  /// them off the map. Always written, since a `null` filter finds only
  /// documents that have the field.
  static const removedAt = 'removedAt';
}

/// Fields of `positions/{personKey}/trail/{pointId}`.
abstract final class TrailPointFields {
  static const lat = 'lat';
  static const lng = 'lng';

  /// When the server received the point (server clock).
  static const receivedAt = 'receivedAt';
}

/// Fields of `positions/{personKey}/trailDays/{yyyy-mm-dd}`.
abstract final class TrailDayFields {
  static const lastAt = 'lastAt';
  static const pointCount = 'pointCount';
}
