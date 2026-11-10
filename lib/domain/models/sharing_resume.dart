/// Who was sharing on this device when sharing was last turned on: what the
/// tracking service publishes as when it resumes without the screen (after
/// the device restarts, the app is updated or Android restarts the
/// service).
///
/// It exists while the person means to share: written when they turn
/// sharing on, removed when they turn it off, sign out, switch organization
/// or lose access, so it always belongs to the bound organization.
class SharingIntent {
  const SharingIntent({required this.email, required this.name});

  final String email;

  /// The name published with the positions (`UserModel.publishedName`).
  final String name;

  @override
  bool operator ==(Object other) =>
      other is SharingIntent && other.email == email && other.name == name;

  @override
  int get hashCode => Object.hash(email, name);

  @override
  String toString() => 'SharingIntent($email)';
}

/// Why sharing could not resume without the screen; each one is a
/// notification telling the person.
enum ResumeFailure {
  /// Location is not allowed "all the time" (checked natively, before the
  /// service starts).
  backgroundLocation,

  /// The app's battery use is "Restricted" (checked natively).
  batteryRestricted,

  /// The device's location is off (checked natively): Android refuses the
  /// tracking service then, so sharing cannot resume and wait for it.
  locationOff,

  /// No account is signed in, or another one than the one that was sharing.
  signedOut,

  /// The person publishes in no group of the organization any more (or was
  /// removed from it).
  noGroup,
}

/// The texts the device shows when sharing resumes without the screen, in
/// the app's language. The screen builds them from `AppLocalizations` and
/// stores them, since neither the tracking service nor the native side
/// that starts it after a restart has a `BuildContext`.
class SharingResumeTexts {
  const SharingResumeTexts({
    required this.notificationTitle,
    required this.notificationContent,
    required this.failureChannel,
    required this.failureTitle,
    required this.failures,
  });

  /// The sharing notification, as `SharingNotification` has it.
  final String notificationTitle;
  final String notificationContent;

  /// The name of the notification channel of the failures, shown in the
  /// system's notification settings.
  final String failureChannel;

  /// The failure notification's title and its text for each reason.
  final String failureTitle;
  final Map<ResumeFailure, String> failures;

  @override
  bool operator ==(Object other) =>
      other is SharingResumeTexts &&
      other.notificationTitle == notificationTitle &&
      other.notificationContent == notificationContent &&
      other.failureChannel == failureChannel &&
      other.failureTitle == failureTitle &&
      _sameFailures(other.failures, failures);

  @override
  int get hashCode => Object.hash(
    notificationTitle,
    notificationContent,
    failureChannel,
    failureTitle,
    Object.hashAll([
      for (final reason in ResumeFailure.values) failures[reason],
    ]),
  );

  static bool _sameFailures(
    Map<ResumeFailure, String> a,
    Map<ResumeFailure, String> b,
  ) => ResumeFailure.values.every((reason) => a[reason] == b[reason]);
}
