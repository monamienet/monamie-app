import 'package:flutter/foundation.dart';

/// Sends crashes and unhandled errors to the central project's crash
/// reports (`monamienet-app`), where MonAmie sees them for every
/// organization.
///
/// Reports carry no personal data: no e-mail, name or person key.
abstract interface class CrashReportingService {
  /// Turns collection on, or off in debug builds. Call it once the central
  /// Firebase app is initialized, before the first report.
  Future<void> start();

  /// Marks every later report of this isolate with [key] = [value] (a
  /// non-personal tag, such as which isolate it came from).
  Future<void> setCustomKey(String key, String value);

  /// Records an error the Flutter framework caught (`FlutterError.onError`)
  /// as a crash.
  Future<void> recordFlutterFatalError(FlutterErrorDetails details);

  /// Records [error], an unhandled error when [fatal]
  /// (`PlatformDispatcher.onError`).
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  });
}
