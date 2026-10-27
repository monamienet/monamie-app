import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_edit_controller.dart';

const equilibrio = TrackingSettings(intervalMinutes: 5, distanceMeters: 10);
const economia = TrackingSettings(intervalMinutes: 15, distanceMeters: 100);
const precisao = TrackingSettings(intervalMinutes: 1, distanceMeters: 5);

/// [TrackingSettingsRepository] that records every save, with the plan's
/// minimum [minimum], optionally waiting on [gate] or failing with
/// [failure] in `save`.
class FakeTrackingSettingsRepository implements TrackingSettingsRepository {
  FakeTrackingSettingsRepository({this.minimum = 0});

  final int minimum;
  final saved = <TrackingSettings>[];
  Completer<void>? gate;
  Object? failure;

  @override
  Future<int> minIntervalMinutes() async => minimum;

  @override
  Stream<TrackingSettings> watch() => const Stream.empty();

  @override
  Future<void> save(TrackingSettings settings) async {
    saved.add(settings);
    await gate?.future;
    if (failure case final failure?) throw failure;
  }
}

late FakeTrackingSettingsRepository repository;

/// A controller started over [repository] with [saved] as the saved
/// settings, once the plan's minimum has loaded.
Future<TrackingSettingsEditController> controllerFor(
  TrackingSettings saved,
) async {
  final controller = TrackingSettingsEditController(
    repository: repository,
    saved: saved,
  );
  controller.onStart();
  await pumpEventQueue();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    repository = FakeTrackingSettingsRepository();
  });

  group('TrackingSettingsEditController initial state - Unit Test Suite', () {
    test('Happy Path: a fresh controller has no changes', () async {
      // 1. Arrange
      final controller = TrackingSettingsEditController(
        repository: repository,
        saved: equilibrio,
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(controller.hasChanges, isFalse);
    });

    test('Happy Path: the preset matches the saved preset', () async {
      // 1. Arrange
      final controller = TrackingSettingsEditController(
        repository: repository,
        saved: economia,
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(controller.preset.value, TrackingPreset.economia);
    });

    test('Edge Case: custom saved settings start on Personalizado', () async {
      // 1. Arrange
      final controller = TrackingSettingsEditController(
        repository: repository,
        saved: const TrackingSettings(intervalMinutes: 10, distanceMeters: 20),
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(controller.preset.value, TrackingPreset.personalizado);
    });

    test('Edge Case: the plan minimum is loaded on start', () async {
      // 1. Arrange
      repository = FakeTrackingSettingsRepository(minimum: 15);
      final controller = TrackingSettingsEditController(
        repository: repository,
        saved: economia,
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(controller.minIntervalMinutes.value, 15);
    });
  });

  group('TrackingSettingsEditController.pickPreset - Unit Test Suite', () {
    test('Happy Path: Precisão sets the draft to 1 min and 5 m', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);

      // 2. Act
      controller.pickPreset(TrackingPreset.precisao);

      // 3. Assert
      expect(
        [
          controller.draft.value,
          controller.preset.value,
          controller.hasChanges,
        ],
        [precisao, TrackingPreset.precisao, true],
      );
    });

    test('Edge Case: Personalizado keeps the draft values', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);

      // 2. Act
      controller.pickPreset(TrackingPreset.personalizado);

      // 3. Assert
      expect(
        [controller.draft.value, controller.preset.value],
        [equilibrio, TrackingPreset.personalizado],
      );
    });

    test('Sad Path: with the plan minimum 15, Precisão does nothing', () async {
      // 1. Arrange
      repository = FakeTrackingSettingsRepository(minimum: 15);
      final controller = await controllerFor(economia);

      // 2. Act
      controller.pickPreset(TrackingPreset.precisao);

      // 3. Assert
      expect(
        [
          controller.draft.value,
          controller.preset.value,
          controller.hasChanges,
        ],
        [economia, TrackingPreset.economia, false],
      );
    });
  });

  group('TrackingSettingsEditController.allows - Unit Test Suite', () {
    final cases = [
      ('Happy Path', TrackingPreset.economia, true),
      ('Edge Case', TrackingPreset.personalizado, true),
      ('Sad Path', TrackingPreset.precisao, false),
      ('Sad Path', TrackingPreset.equilibrio, false),
    ];
    for (final (label, option, expected) in cases) {
      test('$label: with the plan minimum 15, ${option.name} is '
          '${expected ? 'allowed' : 'not allowed'}', () async {
        // 1. Arrange
        repository = FakeTrackingSettingsRepository(minimum: 15);
        final controller = await controllerFor(economia);

        // 2. Act
        final allowed = controller.allows(option);

        // 3. Assert
        expect(allowed, expected);
      });
    }

    test('Edge Case: without a plan minimum Precisão is allowed', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);

      // 2. Act
      final allowed = controller.allows(TrackingPreset.precisao);

      // 3. Assert
      expect(allowed, isTrue);
    });
  });

  group('TrackingSettingsEditController.setInterval - Unit Test Suite', () {
    test('Happy Path: with the plan minimum 15, 20 minutes is set', () async {
      // 1. Arrange
      repository = FakeTrackingSettingsRepository(minimum: 15);
      final controller = await controllerFor(economia);

      // 2. Act
      controller.setInterval(20);

      // 3. Assert
      expect(
        controller.draft.value,
        const TrackingSettings(intervalMinutes: 20, distanceMeters: 100),
      );
    });

    test('Edge Case: with the plan minimum 15, 15 minutes is set', () async {
      // 1. Arrange
      repository = FakeTrackingSettingsRepository(minimum: 15);
      final controller = await controllerFor(
        const TrackingSettings(intervalMinutes: 30, distanceMeters: 100),
      );

      // 2. Act
      controller.setInterval(15);

      // 3. Assert
      expect(controller.draft.value, economia);
    });

    test(
      'Sad Path: with the plan minimum 15, 5 minutes does nothing',
      () async {
        // 1. Arrange
        repository = FakeTrackingSettingsRepository(minimum: 15);
        final controller = await controllerFor(economia);

        // 2. Act
        controller.setInterval(5);

        // 3. Assert
        expect(
          [controller.draft.value, controller.hasChanges],
          [economia, false],
        );
      },
    );
  });

  group('TrackingSettingsEditController.setDistance - Unit Test Suite', () {
    test('Happy Path: 100 m changes only the distance', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);

      // 2. Act
      controller.setDistance(100);

      // 3. Assert
      expect(
        [controller.draft.value, controller.hasChanges],
        [const TrackingSettings(intervalMinutes: 5, distanceMeters: 100), true],
      );
    });

    test('Edge Case: setting the saved distance back is no change', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.setDistance(100);

      // 2. Act
      controller.setDistance(10);

      // 3. Assert
      expect(controller.hasChanges, isFalse);
    });
  });

  group('TrackingSettingsEditController.save - Unit Test Suite', () {
    test('Happy Path: a change is saved once through the repository', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.pickPreset(TrackingPreset.economia);

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(repository.saved, [economia]);
    });

    test('Happy Path: after a save the draft is the saved settings, '
        'justSaved is true and it returns true', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.pickPreset(TrackingPreset.economia);

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect(
        [ok, controller.savedSettings.value, controller.justSaved.value],
        [true, economia, true],
      );
    });

    test('Happy Path: isSaving is false after the save', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.setDistance(50);

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(controller.isSaving.value, isFalse);
    });

    test('Sad Path: no changes returns false and calls nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect([ok, repository.saved], [false, isEmpty]);
    });

    test('Sad Path: a failing repository sets errorMessage and save '
        'returns false', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.setDistance(50);
      repository.failure = Exception('offline');

      // 2. Act
      final ok = await controller.save();

      // 3. Assert
      expect(
        [ok, controller.errorMessage.value, controller.savedSettings.value],
        [false, isNotEmpty, equilibrio],
      );
    });

    test('Sad Path: isSaving is false after the repository throws', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.setDistance(50);
      repository.failure = Exception('offline');

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(controller.isSaving.value, isFalse);
    });
  });

  group('TrackingSettingsEditController.save reentrancy - Unit Test Suite', () {
    test('Happy Path: isSaving is true while the save is in flight', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.setDistance(50);
      repository.gate = Completer<void>();

      // 2. Act
      final pending = controller.save();

      // 3. Assert
      expect(controller.isSaving.value, isTrue);
      repository.gate!.complete();
      await pending;
    });

    test('Edge Case: a second save while the first is in flight returns '
        'false and does not call the repository again', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      controller.setDistance(50);
      repository.gate = Completer<void>();
      final first = controller.save();
      await pumpEventQueue();

      // 2. Act
      final second = await controller.save();

      // 3. Assert
      repository.gate!.complete();
      await first;
      expect([second, repository.saved.length], [false, 1]);
    });

    final whileSaving =
        <(String, void Function(TrackingSettingsEditController))>[
          ('pickPreset', (c) => c.pickPreset(TrackingPreset.precisao)),
          ('setInterval', (c) => c.setInterval(30)),
          ('setDistance', (c) => c.setDistance(500)),
        ];
    for (final (name, change) in whileSaving) {
      test('Sad Path: $name does nothing while saving', () async {
        // 1. Arrange
        final controller = await controllerFor(equilibrio);
        controller.setDistance(50);
        repository.gate = Completer<void>();
        final pending = controller.save();

        // 2. Act
        change(controller);

        // 3. Assert
        expect(
          controller.draft.value,
          const TrackingSettings(intervalMinutes: 5, distanceMeters: 50),
        );
        repository.gate!.complete();
        await pending;
      });
    }
  });
}
