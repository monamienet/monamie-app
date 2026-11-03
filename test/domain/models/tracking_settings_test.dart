import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';

TrackingSettings settingsOf(int minutes, int meters) =>
    TrackingSettings(periodMinutes: minutes, radiusMeters: meters);

void main() {
  group('TrackingSettings.defaults - Unit Test Suite', () {
    test(
      'Happy Path: the defaults are Economia, 15 minutes and 100 meters',
      () {
        // 1. Arrange
        const defaults = TrackingSettings.defaults;

        // 2. Act
        final values = [defaults.periodMinutes, defaults.radiusMeters];

        // 3. Assert
        expect(values, [15, 100]);
      },
    );
  });

  group('TrackingSettings.validated - Unit Test Suite', () {
    test('Happy Path: allowed values are kept as they are', () {
      // 1. Arrange
      const period = 20;
      const radius = 300;

      // 2. Act
      final settings = TrackingSettings.validated(
        periodMinutes: period,
        radiusMeters: radius,
      );

      // 3. Assert
      expect(settings, settingsOf(20, 300));
    });

    test('Edge Case: missing values are 15 minutes and 100 meters', () {
      // 1. Arrange
      const Object? missing = null;

      // 2. Act
      final settings = TrackingSettings.validated(
        periodMinutes: missing,
        radiusMeters: missing,
      );

      // 3. Assert
      expect(settings, settingsOf(15, 100));
    });

    test('Edge Case: each value falls back on its own', () {
      // 1. Arrange
      const period = 4;
      const radius = 200;

      // 2. Act
      final settings = TrackingSettings.validated(
        periodMinutes: period,
        radiusMeters: radius,
      );

      // 3. Assert
      expect(settings, settingsOf(15, 200));
    });

    final wrongTypes = <(String, Object?, Object?)>[
      ('strings', '20', '300'),
      // Firestore may hand back a number as a double; it is not an int.
      ('doubles', 20.0, 300.0),
      ('booleans', true, false),
    ];
    for (final (label, period, radius) in wrongTypes) {
      test('Sad Path: values that are $label fall back to 15 and 100', () {
        // 1. Arrange
        final values = (period, radius);

        // 2. Act
        final settings = TrackingSettings.validated(
          periodMinutes: values.$1,
          radiusMeters: values.$2,
        );

        // 3. Assert
        expect(settings, settingsOf(15, 100));
      });
    }

    final minimums = [
      ('Happy Path', 'minimum 15 raises period 5 to 15', 5, 15, 15),
      ('Happy Path', 'minimum 15 keeps period 20', 20, 15, 20),
      ('Edge Case', 'minimum 25 raises period 5 to 30', 5, 25, 30),
      (
        'Sad Path',
        'a not-allowed period falls back to 15, then rises to '
            'the minimum 20',
        4,
        20,
        20,
      ),
    ];
    for (final (label, name, period, min, expected) in minimums) {
      test('$label: $name', () {
        // 1. Arrange
        final value = period;

        // 2. Act
        final settings = TrackingSettings.validated(
          periodMinutes: value,
          radiusMeters: 50,
          minPeriodMinutes: min,
        );

        // 3. Assert
        expect(settings, settingsOf(expected, 50));
      });
    }
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
