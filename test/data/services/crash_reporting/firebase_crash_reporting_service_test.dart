import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/crash_reporting/firebase_crash_reporting_service.dart';

@GenerateNiceMocks([MockSpec<FirebaseCrashlytics>()])
import 'firebase_crash_reporting_service_test.mocks.dart';

void main() {
  group('FirebaseCrashReportingService - Unit Test Suite', () {
    late MockFirebaseCrashlytics crashlytics;
    late FirebaseCrashReportingService service;

    setUp(() {
      crashlytics = MockFirebaseCrashlytics();
      when(
        crashlytics.setCrashlyticsCollectionEnabled(any),
      ).thenAnswer((_) => Future.value());
      when(
        crashlytics.recordFlutterFatalError(any),
      ).thenAnswer((_) => Future.value());
      when(
        crashlytics.recordError(any, any, fatal: anyNamed('fatal')),
      ).thenAnswer((_) => Future.value());
      service = FirebaseCrashReportingService(crashlytics: crashlytics);
    });

    test('Happy Path: start turns collection off in debug builds', () async {
      // Arrange: `flutter test` runs in debug mode, so kDebugMode is true
      // and the service must keep collection off.
      expect(kDebugMode, isTrue);

      // Act
      await service.start();

      // Assert
      verify(crashlytics.setCrashlyticsCollectionEnabled(false)).called(1);
      verifyNever(crashlytics.setCrashlyticsCollectionEnabled(true));
    });

    test(
      'Happy Path: recordFlutterFatalError forwards the details unchanged',
      () async {
        // Arrange
        final details = FlutterErrorDetails(
          exception: StateError('boom'),
          stack: StackTrace.current,
          library: 'test',
        );

        // Act
        await service.recordFlutterFatalError(details);

        // Assert
        final captured = verify(
          crashlytics.recordFlutterFatalError(captureAny),
        ).captured;
        expect(captured.single, same(details));
      },
    );

    test(
      'Happy Path: recordError forwards error, stack and fatal: true',
      () async {
        // Arrange
        final error = ArgumentError('bad');
        final stack = StackTrace.current;

        // Act
        await service.recordError(error, stack, fatal: true);

        // Assert
        verify(crashlytics.recordError(error, stack, fatal: true)).called(1);
      },
    );

    test('Edge Case: recordError is non-fatal by default', () async {
      // Arrange
      final error = Exception('handled');
      final stack = StackTrace.current;

      // Act
      await service.recordError(error, stack);

      // Assert
      verify(crashlytics.recordError(error, stack, fatal: false)).called(1);
      verifyNever(crashlytics.recordError(any, any, fatal: true));
    });

    test('Edge Case: recordError accepts a missing stack trace', () async {
      // Arrange
      const error = 'no stack';

      // Act
      await service.recordError(error, null);

      // Assert
      verify(crashlytics.recordError(error, null, fatal: false)).called(1);
    });

    test('Edge Case: a Crashlytics failure reaches the caller', () async {
      // Arrange
      when(
        crashlytics.setCrashlyticsCollectionEnabled(any),
      ).thenAnswer((_) => Future.error(StateError('plugin missing')));

      // Act & Assert
      await expectLater(service.start(), throwsStateError);
    });
  });
}
