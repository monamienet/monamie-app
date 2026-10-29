import 'package:firebase_core/firebase_core.dart';

/// A partner the signed-in user belongs to, with its Firebase options.
class PartnerCandidate {
  const PartnerCandidate({
    required this.id,
    required this.options,
    this.owner = false,
  });

  final String id;
  final FirebaseOptions options;

  /// Whether the signed-in user is the partner's owner (*titular*, who
  /// created it). It grants no powers: those come from the root group. It
  /// only means that deleting their account deletes the organization.
  final bool owner;
}

/// Finds the partners of the user signed in to the central project.
abstract interface class PartnerDirectory {
  /// The user's partners whose status is `active`, sorted by id; empty
  /// when none.
  ///
  /// [fresh] skips the server's short groups cache (right after accepting
  /// an invite, when the new membership must show at once).
  Future<List<PartnerCandidate>> partnersOfSignedInUser({bool fresh = false});
}
