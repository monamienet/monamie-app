import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

/// File and keys of what lets sharing resume without the screen. The
/// native side reads them (`ResumeSharingReceiver.kt`, `ResumeFailures.kt`),
/// so keep both in sync.
const sharingResumePreferencesFile = 'monamie_sharing_resume';

/// Whether sharing resumes after a restart or an update (bool).
const sharingResumeOptionKey = 'resumeOnRestart';

/// Who was sharing (JSON `{email, name}`), absent while sharing is off.
const sharingResumeIntentKey = 'intent';

/// The texts the device shows without the screen (JSON, see
/// [SharingResumePreferencesService.writeTexts]).
const sharingResumeTextsKey = 'texts';

/// Set by the native receiver right before it starts the tracking service
/// after a restart or an update (bool); the service takes it.
const sharingResumeResumingKey = 'resuming';

/// A failure of the tracking service to resume (a `ResumeFailure` name),
/// which the native side shows as a notification and then removes.
const sharingResumeFailureKey = 'failure';

/// What lets sharing resume without the screen, kept in a classic
/// SharedPreferences file.
///
/// Classic, not DataStore: the native receiver that resumes sharing after a
/// restart reads it without Flutter, and both the UI and the tracking
/// service's isolates use it at the same time (DataStore allows one instance
/// per file in a process). Every method may throw when the storage fails.
class SharingResumePreferencesService {
  SharingResumePreferencesService({SharedPreferencesAsync? preferences})
    : _preferences =
          preferences ??
          SharedPreferencesAsync(
            options: const SharedPreferencesAsyncAndroidOptions(
              backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
              originalSharedPreferencesOptions:
                  AndroidSharedPreferencesStoreOptions(
                    fileName: sharingResumePreferencesFile,
                  ),
            ),
          );

  final SharedPreferencesAsync _preferences;

  /// Whether the person chose to resume sharing; `false` until they choose.
  Future<bool> readOption() async =>
      await _preferences.getBool(sharingResumeOptionKey) ?? false;

  Future<void> writeOption(bool resume) =>
      _preferences.setBool(sharingResumeOptionKey, resume);

  /// The person sharing, or `null` when sharing is off or what is stored
  /// cannot be read.
  Future<({String email, String name})?> readIntent() async {
    final source = await _preferences.getString(sharingResumeIntentKey);
    if (source == null) return null;
    try {
      if (jsonDecode(source) case {
        'email': final String email,
        'name': final String name,
      }) {
        return (email: email, name: name);
      }
    } on FormatException {
      // Unreadable: as if sharing were off.
    }
    return null;
  }

  Future<void> writeIntent({required String email, required String name}) =>
      _preferences.setString(
        sharingResumeIntentKey,
        jsonEncode({'email': email, 'name': name}),
      );

  Future<void> clearIntent() => _preferences.remove(sharingResumeIntentKey);

  /// Stores the texts, as JSON with the keys `notificationTitle`,
  /// `notificationContent`, `failureChannel`, `failureTitle` and
  /// `failures` (one text per `ResumeFailure` name).
  Future<void> writeTexts(Map<String, Object> texts) =>
      _preferences.setString(sharingResumeTextsKey, jsonEncode(texts));

  /// The texts [writeTexts] stored, or `null` when none can be read.
  Future<Map<String, Object?>?> readTexts() async {
    final source = await _preferences.getString(sharingResumeTextsKey);
    if (source == null) return null;
    try {
      final texts = jsonDecode(source);
      return texts is Map<String, Object?> ? texts : null;
    } on FormatException {
      return null;
    }
  }

  /// Whether the native receiver started the service, after a restart or
  /// an update; removes the mark, so a later start is not taken for one.
  Future<bool> takeResuming() async {
    final resuming = await _preferences.getBool(sharingResumeResumingKey);
    if (resuming == null) return false;
    await _preferences.remove(sharingResumeResumingKey);
    return resuming;
  }

  /// Asks the native side to show the notification of [failure] (a
  /// `ResumeFailure` name).
  Future<void> writeFailure(String failure) =>
      _preferences.setString(sharingResumeFailureKey, failure);
}
