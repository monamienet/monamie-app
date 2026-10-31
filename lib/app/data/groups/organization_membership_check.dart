/// Asks whether the person signed in to an organization's project still
/// belongs to it, right after entering, before anything of the organization
/// is shown.
abstract interface class OrganizationMembershipCheck {
  /// Whether the signed-in person has an `organizationMemberships` document
  /// in [organizationId]; `null` when it could not be read, which is not
  /// evidence of removal.
  Future<bool?> isMemberOf(String organizationId);
}
