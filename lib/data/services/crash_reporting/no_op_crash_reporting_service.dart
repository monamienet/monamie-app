import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/services/crash_reporting/crash_reporting_service.dart';

/// [CrashReportingService] that sends nothing, for the web (Crashlytics has
/// no web implementation) and tests. Errors are still printed to the
/// console, as without a crash reporter.
class NoOpCrashReportingService implements CrashReportingService {
  const NoOpCrashReportingService();

  @override
  Future<void> start() async {}

  @override
  Future<void> setCustomKey(String key, String value) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async =>
      FlutterError.presentError(details);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    if (fatal) debugPrint('$error\n$stackTrace');
  }
}
