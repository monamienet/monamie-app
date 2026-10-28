/// Reads and writes single Firestore documents of any project.
///
/// Implementations throw a `PartnerToolException` on failure.
abstract interface class FirestoreDocuments {
  /// The document at [path] in [projectId], or `null` when it does not
  /// exist. Without [accessToken] the read is anonymous (it only works where
  /// the security rules allow public reads).
  Future<Map<String, Object?>?> get({
    required String projectId,
    required String path,
    String? accessToken,
  });

  /// Replaces the document at [path] in [projectId] with [data].
  Future<void> set({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required String accessToken,
  });

  /// Writes only the [fieldPaths] of the document at [path], creating it
  /// when missing. A path in [fieldPaths] that [data] leaves out (or sets to
  /// `null`) is deleted; every other field is kept.
  Future<void> update({
    required String projectId,
    required String path,
    required Map<String, Object?> data,
    required List<String> fieldPaths,
    required String accessToken,
  });
}
