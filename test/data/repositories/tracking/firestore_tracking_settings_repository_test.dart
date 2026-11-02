import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/repositories/tracking/firestore_tracking_settings_repository.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';

TrackingSettings settingsOf(int minutes, int meters) =>
    TrackingSettings(periodMinutes: minutes, radiusMeters: meters);

void main() {
  group('trackingSettingsFromFirestore - Unit Test Suite', () {
    test('Happy Path: allowed values are read as they are', () {
      // 1. Arrange
      final data = <String, Object?>{
        'intervalMinutes': 20,
        'distanceMeters': 300,
      };

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(20, 300));
    });

    test('Edge Case: a null map is 15 minutes and 100 meters', () {
      // 1. Arrange
      const Map<String, Object?>? data = null;

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(15, 100));
    });

    test('Edge Case: a missing interval alone falls back to 15', () {
      // 1. Arrange
      final data = <String, Object?>{'distanceMeters': 10};

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(15, 10));
    });

    test('Edge Case: a missing distance alone falls back to 100', () {
      // 1. Arrange
      final data = <String, Object?>{'intervalMinutes': 5};

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(5, 100));
    });

    test('Sad Path: interval 4 is not allowed and falls back to 15', () {
      // 1. Arrange
      final data = <String, Object?>{
        'intervalMinutes': 4,
        'distanceMeters': 200,
      };

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(15, 200));
    });

    test('Sad Path: distance 15 is not allowed and falls back to 100', () {
      // 1. Arrange
      final data = <String, Object?>{
        'intervalMinutes': 30,
        'distanceMeters': 15,
      };

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(30, 100));
    });

    test('Sad Path: values that are strings fall back to 15 and 100', () {
      // 1. Arrange
      final data = <String, Object?>{
        'intervalMinutes': '20',
        'distanceMeters': '300',
      };

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(15, 100));
    });

    // Firestore may hand back a number as a double; it is not an int.
    test('Sad Path: values that are doubles fall back to 15 and 100', () {
      // 1. Arrange
      final data = <String, Object?>{
        'intervalMinutes': 20.0,
        'distanceMeters': 300.0,
      };

      // 2. Act
      final settings = trackingSettingsFromFirestore(data);

      // 3. Assert
      expect(settings, settingsOf(15, 100));
    });
  });

  group(
    'trackingSettingsFromFirestore with the plan minimum - Unit Test Suite',
    () {
      final cases = [
        ('Happy Path', 'Community 15 raises interval 5 to 15', 5, 15, 15),
        ('Happy Path', 'Community 15 keeps interval 20', 20, 15, 20),
        ('Edge Case', 'minimum 25 raises interval 5 to 30', 5, 25, 30),
        ('Edge Case', 'minimum 0 keeps interval 1', 1, 0, 1),
      ];
      for (final (label, name, interval, min, expected) in cases) {
        test('$label: $name', () {
          // 1. Arrange
          final data = <String, Object?>{
            'intervalMinutes': interval,
            'distanceMeters': 50,
          };

          // 2. Act
          final settings = trackingSettingsFromFirestore(
            data,
            minPeriodMinutes: min,
          );

          // 3. Assert
          expect(settings, settingsOf(expected, 50));
        });
      }

      test('Sad Path: a not-allowed interval falls back to 15, then is raised '
          'to the minimum 20', () {
        // 1. Arrange
        final data = <String, Object?>{
          'intervalMinutes': 4,
          'distanceMeters': 50,
        };

        // 2. Act
        final settings = trackingSettingsFromFirestore(
          data,
          minPeriodMinutes: 20,
        );

        // 3. Assert
        expect(settings, settingsOf(20, 50));
      });
    },
  );

  group('trackingSettingsToFirestore - Unit Test Suite', () {
    test('Happy Path: the period and the radius keep their stored names', () {
      // 1. Arrange
      final settings = settingsOf(20, 300);

      // 2. Act
      final data = trackingSettingsToFirestore(settings);

      // 3. Assert
      expect(data, {'intervalMinutes': 20, 'distanceMeters': 300});
    });

    test('Edge Case: what it writes reads back as the same settings', () {
      // 1. Arrange
      final settings = settingsOf(5, 10);

      // 2. Act
      final read = trackingSettingsFromFirestore(
        trackingSettingsToFirestore(settings),
      );

      // 3. Assert
      expect(read, settings);
    });

    test('Sad Path: it writes only the two stored fields', () {
      // 1. Arrange
      const settings = TrackingSettings.defaults;

      // 2. Act
      final data = trackingSettingsToFirestore(settings);

      // 3. Assert
      expect(data.keys, unorderedEquals(['intervalMinutes', 'distanceMeters']));
    });
  });
}
