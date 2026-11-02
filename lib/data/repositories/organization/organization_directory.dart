import 'package:firebase_core/firebase_core.dart';

/// An organization the signed-in user belongs to, with its Firebase options.
class OrganizationCandidate {
  const OrganizationCandidate({
    required this.id,
    required this.options,
    this.owner = false,
  });

  final String id;
  final FirebaseOptions options;

  /// Whether the signed-in user is the organization's owner (*titular*, who
  /// created it). It grants no powers: those come from the person's
  /// `organizationMemberships` document. It only means that deleting their
  /// account deletes the organization.
  final bool owner;
}

/// Finds the organizations of the user signed in to the central project.
abstract interface class OrganizationDirectory {
  /// The user's organizations whose status is `active`, sorted by id; empty
  /// when none. An accepted invite or a new organization is listed at once.
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser();
}

/// Whether the signed-in user owns an organization, read from the directory.
extension OrganizationOwnership on OrganizationDirectory {
  /// Whether the signed-in user owns organization [organizationId]
  /// (*titular*), as the server says now. Throws when it cannot be read.
  Future<bool> ownsOrganization(String organizationId) async {
    final candidates = await organizationsOfSignedInUser();
    return candidates.any((c) => c.id == organizationId && c.owner);
  }
}
