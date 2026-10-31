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
  /// created it). It grants no powers: those come from the root group. It
  /// only means that deleting their account deletes the organization.
  final bool owner;
}

/// Finds the organizations of the user signed in to the central project.
abstract interface class OrganizationDirectory {
  /// The user's organizations whose status is `active`, sorted by id; empty
  /// when none.
  ///
  /// [fresh] skips the server's short groups cache (right after accepting
  /// an invite, when the new membership must show at once).
  Future<List<OrganizationCandidate>> organizationsOfSignedInUser({
    bool fresh = false,
  });
}
