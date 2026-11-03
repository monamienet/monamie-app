import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/foreground_service.dart';

@GenerateNiceMocks([MockSpec<FlutterBackgroundService>()])
import 'background_tracking_service_test.mocks.dart';

const _title = 'Sua localização está sendo compartilhada';
const _content = 'O compartilhamento está ligado.';

/// A fix at ([latitude], [longitude]) as the service's isolate sends it in
/// `updateLocationLocally` (a [Position] serialized across the isolates).
Map<String, dynamic> _located(double latitude, double longitude) => {
  'position': Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026, 11, 2, 9),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  ).toJson(),
};

/// A plugin mock whose `on(method)` answers the stream of [events]'s
/// controller for that method, created on first use.
class _Plugin {
  _Plugin() {
    when(plugin.on(any)).thenAnswer(
      (invocation) => events
          .putIfAbsent(
            invocation.positionalArguments[0] as String,
            StreamController<Map<String, dynamic>?>.new,
          )
          .stream,
    );
    when(
      plugin.configure(
        iosConfiguration: anyNamed('iosConfiguration'),
        androidConfiguration: anyNamed('androidConfiguration'),
      ),
    ).thenAnswer((_) async => true);
    when(plugin.startService()).thenAnswer((_) async => true);
  }

  final plugin = MockFlutterBackgroundService();
  final events = <String, StreamController<Map<String, dynamic>?>>{};

  late final service = BackgroundTrackingService(service: plugin);

  /// The controller of the service's isolate's [method] events.
  StreamController<Map<String, dynamic>?> of(String method) =>
      events.putIfAbsent(method, StreamController<Map<String, dynamic>?>.new);
}

void main() {
  group('BackgroundTrackingService.start - Unit Test Suite', () {
    test('Happy Path: configures the service, then starts it', () async {
      // 1. Arrange
      final harness = _Plugin();

      // 2. Act
      final started = await harness.service.start(
        notificationTitle: _title,
        notificationContent: _content,
      );

      // 3. Assert
      expect(started, isTrue);
      verifyInOrder([
        harness.plugin.configure(
          iosConfiguration: anyNamed('iosConfiguration'),
          androidConfiguration: anyNamed('androidConfiguration'),
        ),
        harness.plugin.startService(),
      ]);
    });

    test('Edge Case: the service runs in the foreground with the '
        'notification, never by itself or on boot', () async {
      // 1. Arrange
      final harness = _Plugin();

      // 2. Act
      await harness.service.start(
        notificationTitle: _title,
        notificationContent: _content,
      );

      // 3. Assert
      final captured = verify(
        harness.plugin.configure(
          iosConfiguration: captureAnyNamed('iosConfiguration'),
          androidConfiguration: captureAnyNamed('androidConfiguration'),
        ),
      ).captured;
      final ios = captured[0] as IosConfiguration;
      final android = captured[1] as AndroidConfiguration;
      expect(android.isForegroundMode, isTrue);
      expect(android.autoStart, isFalse);
      expect(android.autoStartOnBoot, isFalse);
      expect(android.initialNotificationTitle, _title);
      expect(android.initialNotificationContent, _content);
      expect(android.onStart, onStart);
      expect(ios.autoStart, isFalse);
      expect(ios.onForeground, onStart);
      expect(ios.onBackground, onIosBackground);
    });

    test('Sad Path: answers false when the plugin could not start', () async {
      // 1. Arrange
      final harness = _Plugin();
      when(harness.plugin.startService()).thenAnswer((_) async => false);

      // 2. Act
      final started = await harness.service.start(
        notificationTitle: _title,
        notificationContent: _content,
      );

      // 3. Assert
      expect(started, isFalse);
    });

    test(
      'Sad Path: a failed configuration does not start the service',
      () async {
        // 1. Arrange
        final harness = _Plugin();
        when(
          harness.plugin.configure(
            iosConfiguration: anyNamed('iosConfiguration'),
            androidConfiguration: anyNamed('androidConfiguration'),
          ),
        ).thenAnswer((_) async => throw StateError('no plugin'));

        // 2. Act
        final start = harness.service.start(
          notificationTitle: _title,
          notificationContent: _content,
        );

        // 3. Assert
        await expectLater(start, throwsStateError);
        verifyNever(harness.plugin.startService());
      },
    );
  });

  group('BackgroundTrackingService.isRunning - Unit Test Suite', () {
    for (final running in [true, false]) {
      test('Happy Path: answers what the plugin says ($running)', () async {
        // 1. Arrange
        final harness = _Plugin();
        when(harness.plugin.isRunning()).thenAnswer((_) async => running);

        // 2. Act
        final answer = await harness.service.isRunning();

        // 3. Assert
        expect(answer, running);
      });
    }
  });

  group('BackgroundTrackingService events sent - Unit Test Suite', () {
    test('Happy Path: stop sends stopService', () {
      // 1. Arrange
      final harness = _Plugin();

      // 2. Act
      harness.service.stop();

      // 3. Assert
      verify(harness.plugin.invoke('stopService')).called(1);
    });

    test('Happy Path: sendUser sends setUserInfo with e-mail and name', () {
      // 1. Arrange
      final harness = _Plugin();

      // 2. Act
      harness.service.sendUser(email: 'ana@example.com', name: 'Ana');

      // 3. Assert
      verify(
        harness.plugin.invoke('setUserInfo', {
          'email': 'ana@example.com',
          'name': 'Ana',
        }),
      ).called(1);
    });

    test('Edge Case: sendUser keeps an empty name as it is', () {
      // 1. Arrange
      final harness = _Plugin();

      // 2. Act
      harness.service.sendUser(email: 'ana@example.com', name: '');

      // 3. Assert
      verify(
        harness.plugin.invoke('setUserInfo', {
          'email': 'ana@example.com',
          'name': '',
        }),
      ).called(1);
    });
  });

  group('BackgroundTrackingService.ready - Unit Test Suite', () {
    test('Happy Path: each ready event of the isolate is one event', () async {
      // 1. Arrange
      final harness = _Plugin();
      var count = 0;
      harness.service.ready.listen((_) => count++);

      // 2. Act
      harness.of('ready')
        ..add(null)
        ..add(const {'extra': 1});
      await pumpEventQueue();

      // 3. Assert
      expect(count, 2);
      verify(harness.plugin.on('ready')).called(1);
    });

    test('Edge Case: no event, no ready', () async {
      // 1. Arrange
      final harness = _Plugin();
      var count = 0;
      harness.service.ready.listen((_) => count++);

      // 2. Act
      harness.of('updateLocationLocally').add(_located(-22.9, -43.1));
      await pumpEventQueue();

      // 3. Assert
      expect(count, 0);
    });

    test('Sad Path: cancelling stops listening to the plugin', () async {
      // 1. Arrange
      final harness = _Plugin();
      final subscription = harness.service.ready.listen((_) {});

      // 2. Act
      await subscription.cancel();

      // 3. Assert
      expect(harness.of('ready').hasListener, isFalse);
    });
  });

  group('BackgroundTrackingService.localPositions - Unit Test Suite', () {
    test('Happy Path: each fix becomes its latitude and longitude', () async {
      // 1. Arrange
      final harness = _Plugin();
      final positions = <LatLng>[];
      harness.service.localPositions.listen(positions.add);

      // 2. Act
      harness.of('updateLocationLocally')
        ..add(_located(-22.9, -43.1))
        ..add(_located(-22.8, -43.0));
      await pumpEventQueue();

      // 3. Assert
      expect(positions, const [LatLng(-22.9, -43.1), LatLng(-22.8, -43.0)]);
      verify(harness.plugin.on('updateLocationLocally')).called(1);
    });

    test('Edge Case: an event without data is skipped', () async {
      // 1. Arrange
      final harness = _Plugin();
      final positions = <LatLng>[];
      harness.service.localPositions.listen(positions.add);

      // 2. Act
      harness.of('updateLocationLocally')
        ..add(null)
        ..add(_located(-22.9, -43.1));
      await pumpEventQueue();

      // 3. Assert
      expect(positions, const [LatLng(-22.9, -43.1)]);
    });

    test(
      'Sad Path: a fix without latitude is an error on the stream',
      () async {
        // 1. Arrange
        final harness = _Plugin();
        final errors = <Object>[];
        harness.service.localPositions.listen((_) {}, onError: errors.add);

        // 2. Act
        harness.of('updateLocationLocally').add({
          'position': {'longitude': -43.1},
        });
        await pumpEventQueue();

        // 3. Assert
        expect(errors.single, isA<ArgumentError>());
      },
    );
  });
}
