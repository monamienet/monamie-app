import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';

TrackingSettings settingsOf(int minutes, int meters) =>
    TrackingSettings(periodMinutes: minutes, radiusMeters: meters);

void main() {
  group('TrackingSettings.fromMap - Unit Test Suite', () {
    test('Happy Path: allowed values are read as they are', () {
      // 1. Arrange
      final data = <String, Object?>{
        'intervalMinutes': 20,
        'distanceMeters': 300,
      };

      // 2. Act
      final settings = TrackingSettings.fromMap(data);

      // 3. Assert
      expect(settings, settingsOf(20, 300));
    });

    test('Edge Case: a null map is 15 minutes and 100 meters', () {
      // 1. Arrange
      const Map<String, Object?>? data = null;

      // 2. Act
      final settings = TrackingSettings.fromMap(data);

      // 3. Assert
      expect(settings, settingsOf(15, 100));
    });

    test('Edge Case: a missing interval alone falls back to 15', () {
      // 1. Arrange
      final data = <String, Object?>{'distanceMeters': 10};

      // 2. Act
      final settings = TrackingSettings.fromMap(data);

      // 3. Assert
      expect(settings, settingsOf(15, 10));
    });

    test('Edge Case: a missing distance alone falls back to 100', () {
      // 1. Arrange
      final data = <String, Object?>{'intervalMinutes': 5};

      // 2. Act
      final settings = TrackingSettings.fromMap(data);

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
      final settings = TrackingSettings.fromMap(data);

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
      final settings = TrackingSettings.fromMap(data);

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
      final settings = TrackingSettings.fromMap(data);

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
      final settings = TrackingSettings.fromMap(data);

      // 3. Assert
      expect(settings, settingsOf(15, 100));
    });
  });

  group('TrackingSettings.fromMap with the plan minimum - Unit Test Suite', () {
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
        final settings = TrackingSettings.fromMap(data, minPeriodMinutes: min);

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
      final settings = TrackingSettings.fromMap(data, minPeriodMinutes: 20);

      // 3. Assert
      expect(settings, settingsOf(20, 50));
    });
  });

  group('TrackingSettings.withinPlan - Unit Test Suite', () {
    final cases = [
      ('Happy Path', 'minimum 15 raises 5 to 15', 5, 15, 15),
      ('Happy Path', 'minimum 15 keeps 20', 20, 15, 20),
      ('Edge Case', 'minimum 25 raises 5 to 30', 5, 25, 30),
      ('Edge Case', 'minimum 15 keeps 15', 15, 15, 15),
      ('Sad Path', 'minimum 0 keeps 1', 1, 0, 1),
    ];
    for (final (label, name, interval, min, expected) in cases) {
      test('$label: $name', () {
        // 1. Arrange
        final settings = settingsOf(interval, 100);

        // 2. Act
        final within = settings.withinPlan(min);

        // 3. Assert
        expect(within, settingsOf(expected, 100));
      });
    }
  });

  group('TrackingSettings.positionsPerHour - Unit Test Suite', () {
    final cases = [
      ('Happy Path', 5, 12),
      ('Happy Path', 15, 4),
      ('Edge Case', 1, 60),
      ('Edge Case', 30, 2),
    ];
    for (final (label, interval, expected) in cases) {
      test('$label: interval $interval min sends $expected per hour', () {
        // 1. Arrange
        final settings = settingsOf(interval, 10);

        // 2. Act
        final perHour = settings.positionsPerHour;

        // 3. Assert
        expect(perHour, expected);
      });
    }
  });

  group('TrackingSettings.batteryLevel - Unit Test Suite', () {
    final cases = [
      ('Happy Path', 'Precisão is high', 1, 5, 3),
      ('Happy Path', 'Equilíbrio is medium', 5, 10, 2),
      ('Happy Path', 'Economia is low', 15, 100, 1),
      (
        'Edge Case',
        'a long interval with a short distance is medium',
        30,
        10,
        2,
      ),
      (
        'Edge Case',
        'a short interval with a long distance is medium',
        3,
        50,
        2,
      ),
    ];
    for (final (label, name, interval, distance, expected) in cases) {
      test('$label: $name ($interval min, $distance m → $expected)', () {
        // 1. Arrange
        final settings = settingsOf(interval, distance);

        // 2. Act
        final level = settings.batteryLevel;

        // 3. Assert
        expect(level, expected);
      });
    }
  });

  group('TrackingSettings.preset - Unit Test Suite', () {
    final cases = [
      ('Happy Path', 15, 100, TrackingPreset.economia),
      ('Happy Path', 5, 10, TrackingPreset.equilibrio),
      ('Happy Path', 1, 5, TrackingPreset.precisao),
      ('Sad Path', 10, 20, TrackingPreset.personalizado),
      ('Edge Case', 15, 10, TrackingPreset.personalizado),
    ];
    for (final (label, interval, distance, expected) in cases) {
      test('$label: $interval min, $distance m is ${expected.name}', () {
        // 1. Arrange
        final settings = settingsOf(interval, distance);

        // 2. Act
        final preset = settings.preset;

        // 3. Assert
        expect(preset, expected);
      });
    }
  });

  group('TrackingSettings.withinOffered - Unit Test Suite', () {
    final cases = [
      ('Happy Path', 'Economia is kept', 15, 100, settingsOf(15, 100)),
      ('Sad Path', 'Equilíbrio becomes Economia', 5, 10, settingsOf(15, 100)),
      ('Sad Path', 'Precisão becomes Economia', 1, 5, settingsOf(15, 100)),
      (
        'Edge Case',
        'custom values (Personalizado) become Economia',
        20,
        50,
        settingsOf(15, 100),
      ),
      (
        'Edge Case',
        'Economia period with another radius becomes Economia',
        15,
        10,
        settingsOf(15, 100),
      ),
    ];
    for (final (label, name, interval, distance, expected) in cases) {
      test('$label: $name ($interval min, $distance m)', () {
        // 1. Arrange
        final settings = settingsOf(interval, distance);

        // 2. Act
        final within = settings.withinOffered();

        // 3. Assert
        expect(within, expected);
      });
    }
  });

  group('TrackingPreset.settings - Unit Test Suite', () {
    final cases = [
      ('Happy Path', TrackingPreset.economia, settingsOf(15, 100)),
      ('Happy Path', TrackingPreset.equilibrio, settingsOf(5, 10)),
      ('Happy Path', TrackingPreset.precisao, settingsOf(1, 5)),
      ('Edge Case', TrackingPreset.personalizado, null),
    ];
    for (final (label, preset, expected) in cases) {
      test('$label: ${preset.name} stands for $expected', () {
        // 1. Arrange
        final option = preset;

        // 2. Act
        final settings = option.settings;

        // 3. Assert
        expect(settings, expected);
      });
    }
  });

  group('TrackingSettings equality - Unit Test Suite', () {
    test('Happy Path: same values are equal with the same hashCode', () {
      // 1. Arrange
      final a = settingsOf(10, 200);
      final b = settingsOf(10, 200);

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect([equal, a.hashCode == b.hashCode], [true, true]);
    });

    test('Edge Case: a different distance is not equal', () {
      // 1. Arrange
      final a = settingsOf(10, 200);
      final b = settingsOf(10, 300);

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isFalse);
    });

    test('Sad Path: a different interval is not equal', () {
      // 1. Arrange
      final a = settingsOf(10, 200);
      final b = settingsOf(20, 200);

      // 2. Act
      final equal = a == b;

      // 3. Assert
      expect(equal, isFalse);
    });
  });
}
