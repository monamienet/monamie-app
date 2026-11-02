import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';

@GenerateNiceMocks([MockSpec<TrackingSettingsRepository>()])
import 'tracking_settings_controller_test.mocks.dart';

const _kFrequent = TrackingSettings(periodMinutes: 5, radiusMeters: 50);

/// A [TrackingSettingsController] whose repository emits what [settings]
/// receives.
TrackingSettingsController _controller(
  StreamController<TrackingSettings> settings,
) {
  final repository = MockTrackingSettingsRepository();
  when(repository.watch()).thenAnswer((_) => settings.stream);
  return TrackingSettingsController(repository: repository);
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  group('TrackingSettingsController', () {
    test(
      'Happy Path: Deve guardar cada valor salvo que o repositório emite',
      () async {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings)..onInit();

        // 2. Act
        settings.add(_kFrequent);
        await pumpEventQueue();

        // 3. Assert
        expect(controller.settings.value.periodMinutes, 5);
        expect(controller.settings.value.radiusMeters, 50);
        controller.onClose();
      },
    );

    test(
      'Edge Case: Deve começar com os valores padrão antes da primeira leitura',
      () {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings);

        // 2. Act
        controller.onInit();

        // 3. Assert
        expect(
          controller.settings.value.periodMinutes,
          TrackingSettings.defaults.periodMinutes,
        );
        controller.onClose();
      },
    );

    test(
      'Sad Path: Deve ignorar um erro do repositório e continuar recebendo valores',
      () async {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings)..onInit();

        // 2. Act
        settings.addError(StateError('permissão negada'));
        settings.add(_kFrequent);
        await pumpEventQueue();

        // 3. Assert
        expect(controller.settings.value.periodMinutes, 5);
        controller.onClose();
      },
    );

    test('Happy Path: Deve parar de ouvir o repositório ao fechar', () {
      // 1. Arrange
      final settings = StreamController<TrackingSettings>();
      final controller = _controller(settings)..onInit();

      // 2. Act
      controller.onClose();

      // 3. Assert
      expect(settings.hasListener, isFalse);
    });
  });
}
