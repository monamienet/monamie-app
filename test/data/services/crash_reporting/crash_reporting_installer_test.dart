import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/crash_reporting/crash_reporting_installer.dart';
import 'package:monamie_app/data/services/crash_reporting/crash_reporting_service.dart';

@GenerateNiceMocks([MockSpec<CrashReportingService>()])
import 'crash_reporting_installer_test.mocks.dart';

void main() {
  group('installCrashReporting - Unit Test Suite', () {
    late MockCrashReportingService service;
    late FlutterExceptionHandler? originalFlutterOnError;
    late ErrorCallback? originalPlatformOnError;

    setUp(() {
      originalFlutterOnError = FlutterError.onError;
      originalPlatformOnError = PlatformDispatcher.instance.onError;
      service = MockCrashReportingService();
      when(service.start()).thenAnswer((_) => Future.value());
      when(service.setCustomKey(any, any)).thenAnswer((_) => Future.value());
      when(
        service.recordFlutterFatalError(any),
      ).thenAnswer((_) => Future.value());
      when(
        service.recordError(any, any, fatal: anyNamed('fatal')),
      ).thenAnswer((_) => Future.value());
    });

    tearDown(() {
      FlutterError.onError = originalFlutterOnError;
      PlatformDispatcher.instance.onError = originalPlatformOnError;
    });

    test('Happy Path: the enum tags are the report values', () {
      expect(CrashIsolate.ui.tag, 'ui');
      expect(CrashIsolate.trackingService.tag, 'tracking_service');
      expect(isolateKey, 'isolate');
    });

    for (final isolate in CrashIsolate.values) {
      test(
        'Happy Path: starts, then tags the reports as ${isolate.tag}',
        () async {
          // Act
          await installCrashReporting(service, isolate: isolate);

          // Assert
          verifyInOrder([
            service.start(),
            service.setCustomKey('isolate', isolate.tag),
          ]);
        },
      );
    }

    test('Happy Path: FlutterError.onError forwards the details', () async {
      // Arrange
      await installCrashReporting(service, isolate: CrashIsolate.ui);
      final details = FlutterErrorDetails(exception: StateError('boom'));

      // Act
      FlutterError.onError!(details);

      // Assert
      final captured = verify(
        service.recordFlutterFatalError(captureAny),
      ).captured;
      expect(captured.single, same(details));
    });

    test('Happy Path: PlatformDispatcher.onError records a fatal error and '
        'reports it handled', () async {
      // Arrange
      await installCrashReporting(service, isolate: CrashIsolate.ui);
      final error = StateError('async boom');
      final stack = StackTrace.current;

      // Act
      final handled = PlatformDispatcher.instance.onError!(error, stack);

      // Assert
      expect(handled, isTrue);
      verify(service.recordError(error, stack, fatal: true)).called(1);
    });

    test('Edge Case: nothing is recorded until an error happens', () async {
      // Act
      await installCrashReporting(service, isolate: CrashIsolate.ui);

      // Assert
      verifyNever(service.recordFlutterFatalError(any));
      verifyNever(service.recordError(any, any, fatal: anyNamed('fatal')));
    });

    test('Sad Path: a failing start leaves the handlers untouched', () async {
      // Arrange
      when(service.start()).thenAnswer((_) => Future.error(StateError('x')));
      final before = FlutterError.onError;

      // Act & Assert
      await expectLater(
        installCrashReporting(service, isolate: CrashIsolate.ui),
        throwsStateError,
      );
      expect(FlutterError.onError, same(before));
      verifyNever(service.setCustomKey(any, any));
    });
  });
}
