import 'package:firebase_core/firebase_core.dart';

/// A partner the signed-in user belongs to, with its Firebase options.
class PartnerCandidate {
  const PartnerCandidate({required this.id, required this.options});

  final String id;
  final FirebaseOptions options;
}

/// Finds the partners of the user signed in to the central project.
abstract interface class PartnerDirectory {
  /// The user's partners whose status is `active`, sorted by id; empty
  /// when none.
  Future<List<PartnerCandidate>> partnersOfSignedInUser();
}
