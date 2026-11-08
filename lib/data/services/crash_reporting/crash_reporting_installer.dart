import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/services/crash_reporting/crash_reporting_service.dart';

/// The Flutter engines of the app, each with its own isolate: error handlers
/// are per isolate, so each one installs its own and tags its reports.
enum CrashIsolate {
  /// The screen's engine (`main`).
  ui('ui'),

  /// The tracking service's engine (`onStart` in `foreground_service.dart`).
  trackingService('tracking_service');

  const CrashIsolate(this.tag);

  /// The value of the custom key [isolateKey] in the reports.
  final String tag;
}

/// The custom key that tells which isolate a report came from.
const String isolateKey = 'isolate';

/// Starts [service] and makes it the destination of the errors nothing else
/// caught in this isolate: those the framework caught (build, layout,
/// gestures) and those of asynchronous code. Call it once the central
/// Firebase app is initialized.
Future<void> installCrashReporting(
  CrashReportingService service, {
  required CrashIsolate isolate,
}) async {
  await service.start();
  await service.setCustomKey(isolateKey, isolate.tag);
  FlutterError.onError = service.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    service.recordError(error, stackTrace, fatal: true);
    return true;
  };
}
