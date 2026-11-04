import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/services/crash_reporting/crash_reporting_service.dart';

/// [CrashReportingService] over Firebase Crashlytics, on the `[DEFAULT]`
/// app (the central project). Android only: the plugin has no web
/// implementation.
class FirebaseCrashReportingService implements CrashReportingService {
  FirebaseCrashReportingService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> start() =>
      // Crashes while developing are not MonAmie's users' crashes.
      _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) =>
      // Also prints the error to the console, as Flutter's default handler.
      _crashlytics.recordFlutterFatalError(details);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) => _crashlytics.recordError(error, stackTrace, fatal: fatal);
}
