import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/app/modules/admin/tracking_settings_edit_controller.dart';

@GenerateNiceMocks([MockSpec<TrackingSettingsRepository>()])
import 'tracking_settings_edit_controller_test.mocks.dart';

const equilibrio = TrackingSettings(periodMinutes: 5, radiusMeters: 10);
const economia = TrackingSettings(periodMinutes: 15, radiusMeters: 100);
const custom = TrackingSettings(periodMinutes: 10, radiusMeters: 20);

/// A [MockTrackingSettingsRepository] with the plan's minimum [minimum]
/// and no settings stream.
MockTrackingSettingsRepository mockRepository({int minimum = 0}) {
  final repository = MockTrackingSettingsRepository();
  when(repository.minPeriodMinutes()).thenAnswer((_) async => minimum);
  when(repository.watch()).thenAnswer((_) => const Stream.empty());
  return repository;
}

/// Makes [repository]'s `save` wait on [gate].
void saveWaitsOn(Completer<void> gate) {
  when(repository.save(any)).thenAnswer((_) => gate.future);
}

late MockTrackingSettingsRepository repository;

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

/// A controller saved on Equilíbrio with Economia picked: a draft with
/// changes, ready to save.
Future<TrackingSettingsEditController> changedController() async {
  final controller = await controllerFor(equilibrio);
  controller.pickPreset(TrackingPreset.economia);
  return controller;
}

/// The presets shown on screen that cannot be picked for now.
const notOffered = [
  TrackingPreset.equilibrio,
  TrackingPreset.precisao,
  TrackingPreset.personalizado,
];

void main() {
  setUp(() {
    Get.testMode = true;
    repository = mockRepository();
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
        saved: custom,
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(controller.preset.value, TrackingPreset.personalizado);
    });

    test('Edge Case: the plan minimum is loaded on start', () async {
      // 1. Arrange
      repository = mockRepository(minimum: 15);
      final controller = TrackingSettingsEditController(
        repository: repository,
        saved: economia,
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(controller.minPeriodMinutes.value, 15);
    });
  });

  group('TrackingSettingsEditController.allows - Unit Test Suite', () {
    test('Happy Path: without a plan minimum Economia is allowed', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);

      // 2. Act
      final allowed = controller.allows(TrackingPreset.economia);

      // 3. Assert
      expect(allowed, isTrue);
    });

    test('Edge Case: with the plan minimum 15, Economia (15 min) is '
        'allowed', () async {
      // 1. Arrange
      repository = mockRepository(minimum: 15);
      final controller = await controllerFor(economia);

      // 2. Act
      final allowed = controller.allows(TrackingPreset.economia);

      // 3. Assert
      expect(allowed, isTrue);
    });

    test('Sad Path: with the plan minimum 20, Economia (15 min) is not '
        'allowed', () async {
      // 1. Arrange
      repository = mockRepository(minimum: 20);
      final controller = await controllerFor(economia);

      // 2. Act
      final allowed = controller.allows(TrackingPreset.economia);

      // 3. Assert
      expect(allowed, isFalse);
    });

    for (final option in notOffered) {
      test('Sad Path: without a plan minimum ${option.name} is not '
          'allowed', () async {
        // 1. Arrange
        final controller = await controllerFor(equilibrio);

        // 2. Act
        final allowed = controller.allows(option);

        // 3. Assert
        expect(allowed, isFalse);
      });
    }
  });

  group('TrackingSettingsEditController.pickPreset - Unit Test Suite', () {
    test('Happy Path: Economia sets the draft to 15 min and 100 m', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);

      // 2. Act
      controller.pickPreset(TrackingPreset.economia);

      // 3. Assert
      expect(
        [
          controller.draft.value,
          controller.preset.value,
          controller.hasChanges,
        ],
        [economia, TrackingPreset.economia, true],
      );
    });

    test('Edge Case: with the plan minimum 15, Economia is picked', () async {
      // 1. Arrange
      repository = mockRepository(minimum: 15);
      final controller = await controllerFor(
        const TrackingSettings(periodMinutes: 30, radiusMeters: 100),
      );

      // 2. Act
      controller.pickPreset(TrackingPreset.economia);

      // 3. Assert
      expect(
        [controller.draft.value, controller.preset.value],
        [economia, TrackingPreset.economia],
      );
    });

    for (final option in notOffered) {
      test('Sad Path: ${option.name} changes nothing', () async {
        // 1. Arrange
        final controller = await controllerFor(economia);

        // 2. Act
        controller.pickPreset(option);

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
    }
  });

  group('TrackingSettingsEditController.setPeriod - Unit Test Suite', () {
    test('Sad Path: 20 minutes changes nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(economia);

      // 2. Act
      controller.setPeriod(20);

      // 3. Assert
      expect(
        [controller.draft.value, controller.hasChanges],
        [economia, false],
      );
    });

    test('Edge Case: starting on Personalizado, 20 minutes changes '
        'nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(custom);

      // 2. Act
      controller.setPeriod(20);

      // 3. Assert
      expect([controller.draft.value, controller.hasChanges], [custom, false]);
    });
  });

  group('TrackingSettingsEditController.setRadius - Unit Test Suite', () {
    test('Sad Path: 50 m changes nothing', () async {
      // 1. Arrange
      final controller = await controllerFor(economia);

      // 2. Act
      controller.setRadius(50);

      // 3. Assert
      expect(
        [controller.draft.value, controller.hasChanges],
        [economia, false],
      );
    });

    test(
      'Edge Case: starting on Personalizado, 50 m changes nothing',
      () async {
        // 1. Arrange
        final controller = await controllerFor(custom);

        // 2. Act
        controller.setRadius(50);

        // 3. Assert
        expect(
          [controller.draft.value, controller.hasChanges],
          [custom, false],
        );
      },
    );
  });

  group('TrackingSettingsEditController.save - Unit Test Suite', () {
    test('Happy Path: a change is saved once through the repository', () async {
      // 1. Arrange
      final controller = await changedController();

      // 2. Act
      await controller.save();

      // 3. Assert
      verify(repository.save(economia)).called(1);
    });

    test('Happy Path: after a save the draft is the saved settings, '
        'justSaved is true and it returns true', () async {
      // 1. Arrange
      final controller = await changedController();

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
      final controller = await changedController();

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
      expect(ok, isFalse);
      verifyNever(repository.save(any));
    });

    test('Sad Path: a failing repository sets errorMessage and save '
        'returns false', () async {
      // 1. Arrange
      final controller = await changedController();
      when(
        repository.save(any),
      ).thenAnswer((_) async => throw Exception('offline'));

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
      final controller = await changedController();
      when(
        repository.save(any),
      ).thenAnswer((_) async => throw Exception('offline'));

      // 2. Act
      await controller.save();

      // 3. Assert
      expect(controller.isSaving.value, isFalse);
    });
  });

  group('TrackingSettingsEditController.save reentrancy - Unit Test Suite', () {
    test('Happy Path: isSaving is true while the save is in flight', () async {
      // 1. Arrange
      final controller = await changedController();
      final gate = Completer<void>();
      saveWaitsOn(gate);

      // 2. Act
      final pending = controller.save();

      // 3. Assert
      expect(controller.isSaving.value, isTrue);
      gate.complete();
      await pending;
    });

    test('Edge Case: a second save while the first is in flight returns '
        'false and does not call the repository again', () async {
      // 1. Arrange
      final controller = await changedController();
      final gate = Completer<void>();
      saveWaitsOn(gate);
      final first = controller.save();
      await pumpEventQueue();

      // 2. Act
      final second = await controller.save();

      // 3. Assert
      gate.complete();
      await first;
      expect(second, isFalse);
      verify(repository.save(any)).called(1);
    });

    test('Sad Path: picking Economia does nothing while saving', () async {
      // 1. Arrange
      final controller = await controllerFor(equilibrio);
      // A draft only Economia would change, set directly since no other
      // preset can be picked.
      controller.draft.value = custom;
      final gate = Completer<void>();
      saveWaitsOn(gate);
      final pending = controller.save();

      // 2. Act
      controller.pickPreset(TrackingPreset.economia);

      // 3. Assert
      expect(controller.draft.value, custom);
      gate.complete();
      await pending;
    });
  });
}
