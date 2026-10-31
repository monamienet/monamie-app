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

  /// A person's last position, keyed by e-mail ([PositionFields]).
  static const positions = 'positions';

  /// Under a position: one point per position sent ([TrailPointFields]).
  static const trail = 'trail';

  /// Under a position: one summary per day, keyed `yyyy-mm-dd`
  /// ([TrailDayFields]).
  static const trailDays = 'trailDays';

  /// The theme catalog, in the central project.
  static const themes = 'themes';

  /// `organizations/{id}`: an organization's data in its project, or its
  /// entry in the central registry.
  static String organization(String id) => '$organizations/$id';

  /// `organizations/{id}/config/branding`.
  static String brandingDocument(String id) =>
      '${organization(id)}/$config/$branding';

  /// Cloud Storage path of an organization's logo (not Firestore, but under
  /// the same name).
  static String logo(String id) => '${organization(id)}/logo.png';
}

/// Fields of `organizations/{id}/positions/{email}`.
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

  /// The team the person shares with: the team group's e-mail.
  static const groupId = 'groupId';
}

/// Fields of `positions/{email}/trail/{pointId}`.
abstract final class TrailPointFields {
  static const lat = 'lat';
  static const lng = 'lng';

  /// When the server received the point (server clock).
  static const receivedAt = 'receivedAt';
  static const groupId = 'groupId';
}

/// Fields of `positions/{email}/trailDays/{yyyy-mm-dd}`.
abstract final class TrailDayFields {
  static const lastAt = 'lastAt';
  static const pointCount = 'pointCount';
  static const groupId = 'groupId';
}
