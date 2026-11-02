import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
  group('TrackingSettingsController', () {
    test(
      'Happy Path: Deve guardar cada valor salvo que o repositório emite',
      () async {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings)..start();

        // 2. Act
        settings.add(_kFrequent);
        await pumpEventQueue();

        // 3. Assert
        expect(controller.settings.value.periodMinutes, 5);
        expect(controller.settings.value.radiusMeters, 50);
        controller.dispose();
      },
    );

    test(
      'Edge Case: Deve começar com os valores padrão antes da primeira leitura',
      () {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings);

        // 2. Act
        controller.start();

        // 3. Assert
        expect(
          controller.settings.value.periodMinutes,
          TrackingSettings.defaults.periodMinutes,
        );
        controller.dispose();
      },
    );

    test(
      'Sad Path: Deve ignorar um erro do repositório e continuar recebendo valores',
      () async {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings)..start();

        // 2. Act
        settings.addError(StateError('permissão negada'));
        settings.add(_kFrequent);
        await pumpEventQueue();

        // 3. Assert
        expect(controller.settings.value.periodMinutes, 5);
        controller.dispose();
      },
    );

    test('Happy Path: Deve parar de ouvir o repositório ao fechar', () {
      // 1. Arrange
      final settings = StreamController<TrackingSettings>();
      final controller = _controller(settings)..start();

      // 2. Act
      controller.dispose();

      // 3. Assert
      expect(settings.hasListener, isFalse);
    });

    test(
      'Happy Path: Deve avisar uma vez quando chega um valor salvo diferente',
      () async {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings)..start();
        var notified = 0;
        controller.settings.addListener(() => notified++);

        // 2. Act
        settings.add(_kFrequent);
        await pumpEventQueue();

        // 3. Assert
        expect(notified, 1);
        controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve avisar quando o repositório emite de novo o mesmo valor',
      () async {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings)..start();
        settings.add(_kFrequent);
        await pumpEventQueue();
        var notified = 0;
        controller.settings.addListener(() => notified++);

        // 2. Act
        settings.add(
          const TrackingSettings(periodMinutes: 5, radiusMeters: 50),
        );
        await pumpEventQueue();

        // 3. Assert
        expect(notified, 0);
        controller.dispose();
      },
    );

    test(
      'Edge Case: Deve ouvir o repositório uma vez só quando start() é chamado duas vezes',
      () {
        // 1. Arrange
        final repository = MockTrackingSettingsRepository();
        when(
          repository.watch(),
        ).thenAnswer((_) => const Stream<TrackingSettings>.empty());
        final controller = TrackingSettingsController(repository: repository)
          ..start();

        // 2. Act
        controller.start();

        // 3. Assert
        verify(repository.watch()).called(1);
        controller.dispose();
      },
    );

    test('Edge Case: Deve aceitar um segundo dispose() sem lançar', () {
      // 1. Arrange
      final settings = StreamController<TrackingSettings>();
      final controller = _controller(settings)..start();
      controller.dispose();

      // 2. Act
      void act() => controller.dispose();

      // 3. Assert
      expect(act, returnsNormally);
    });

    test('Edge Case: Deve aceitar dispose() sem start() sem lançar', () {
      // 1. Arrange
      final settings = StreamController<TrackingSettings>();
      final controller = _controller(settings);

      // 2. Act
      void act() => controller.dispose();

      // 3. Assert
      expect(act, returnsNormally);
    });

    test(
      'Sad Path: Não deve ouvir o repositório com start() depois de dispose()',
      () {
        // 1. Arrange
        final settings = StreamController<TrackingSettings>();
        final controller = _controller(settings)..dispose();

        // 2. Act
        controller.start();

        // 3. Assert
        expect(settings.hasListener, isFalse);
      },
    );
  });
}
