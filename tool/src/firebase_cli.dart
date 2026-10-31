/// An Android app registered in a Firebase project.
class FirebaseAndroidApp {
  const FirebaseAndroidApp({required this.appId, required this.packageName});

  /// Firebase app id, e.g. `1:123:android:abc`.
  final String appId;

  /// Android package name the app was registered with.
  final String packageName;

  @override
  bool operator ==(Object other) =>
      other is FirebaseAndroidApp &&
      other.appId == appId &&
      other.packageName == packageName;

  @override
  int get hashCode => Object.hash(appId, packageName);

  @override
  String toString() => '$appId ($packageName)';
}

/// A web app registered in a Firebase project.
class FirebaseWebApp {
  const FirebaseWebApp({required this.appId, required this.displayName});

  final String appId;
  final String displayName;

  @override
  String toString() => '$appId ($displayName)';
}

/// The Firebase CLI calls the organization tool needs.
///
/// Implementations throw a `OrganizationToolException` on failure, and their
/// messages never include config contents (they hold API keys).
abstract interface class FirebaseCli {
  /// Lists the Android apps of Firebase project [projectId].
  Future<List<FirebaseAndroidApp>> listAndroidApps(String projectId);

  /// Returns the `google-services.json` contents of Android app [appId] in
  /// Firebase project [projectId].
  Future<String> androidConfig({
    required String projectId,
    required String appId,
  });

  /// Lists the web apps of Firebase project [projectId].
  Future<List<FirebaseWebApp>> listWebApps(String projectId);

  /// Returns the web SDK config (`apiKey`, `appId`, `authDomain`, ...) of web
  /// app [appId] in Firebase project [projectId].
  Future<Map<String, Object?>> webConfig({
    required String projectId,
    required String appId,
  });
}
