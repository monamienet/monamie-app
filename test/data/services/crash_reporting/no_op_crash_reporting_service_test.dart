import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/services/crash_reporting/no_op_crash_reporting_service.dart';

void main() {
  group('NoOpCrashReportingService - Unit Test Suite', () {
    const service = NoOpCrashReportingService();

    test('Happy Path: start completes without doing anything', () async {
      // Act & Assert
      await expectLater(service.start(), completes);
    });

    test('Happy Path: setCustomKey completes without doing anything', () async {
      // Act & Assert
      await expectLater(service.setCustomKey('isolate', 'ui'), completes);
    });

    test(
      'Happy Path: recordFlutterFatalError presents the error on the console',
      () async {
        // Arrange
        final presented = <FlutterErrorDetails>[];
        final originalPresentError = FlutterError.presentError;
        addTearDown(() => FlutterError.presentError = originalPresentError);
        FlutterError.presentError = presented.add;
        final details = FlutterErrorDetails(exception: StateError('boom'));

        // Act
        await service.recordFlutterFatalError(details);

        // Assert
        expect(presented, hasLength(1));
        expect(presented.single, same(details));
      },
    );

    test('Happy Path: a fatal recordError prints error and stack', () async {
      // Arrange
      final printed = <String?>[];
      final originalDebugPrint = debugPrint;
      addTearDown(() => debugPrint = originalDebugPrint);
      debugPrint = (message, {wrapWidth}) => printed.add(message);
      final stack = StackTrace.fromString('#0 main');

      // Act
      await service.recordError('fatal boom', stack, fatal: true);

      // Assert
      expect(printed, hasLength(1));
      expect(printed.single, contains('fatal boom'));
      expect(printed.single, contains('#0 main'));
    });

    test('Edge Case: a non-fatal recordError completes silently', () async {
      // Arrange
      final printed = <String?>[];
      final originalDebugPrint = debugPrint;
      addTearDown(() => debugPrint = originalDebugPrint);
      debugPrint = (message, {wrapWidth}) => printed.add(message);

      // Act
      await expectLater(
        service.recordError(Exception('handled'), StackTrace.current),
        completes,
      );

      // Assert
      expect(printed, isEmpty);
    });
  });
}
