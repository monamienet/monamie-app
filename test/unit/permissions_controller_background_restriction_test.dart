import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';

/// Implementação falsa do contrato, controlando a resposta de forma
/// determinística e contabilizando as consultas recebidas.
class FakeBackgroundRestrictionChecker implements BackgroundRestrictionChecker {
  FakeBackgroundRestrictionChecker({this.result = false, this.error});

  final bool result;
  final Object? error;
  int calls = 0;

  @override
  Future<bool> isRestricted() async {
    calls++;
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  group('PermissionsController - Restrição de Segundo Plano', () {
    test(
      'Happy Path: Deve retornar true e atualizar o estado quando o checker confirma a restrição',
      () async {
        // 1. Arrange
        final checker = FakeBackgroundRestrictionChecker(result: true);
        final controller = PermissionsController(
          backgroundRestrictionChecker: checker,
        );

        // 2. Act
        final resultado = await controller.refreshBackgroundRestriction();

        // 3. Assert
        expect(resultado, isTrue);
        expect(controller.isBackgroundRestricted.value, isTrue);
        expect(checker.calls, 1);
      },
    );

    test(
      'Happy Path: Deve retornar false e manter o estado quando o checker não detecta restrição',
      () async {
        // 1. Arrange
        final checker = FakeBackgroundRestrictionChecker(result: false);
        final controller = PermissionsController(
          backgroundRestrictionChecker: checker,
        );

        // 2. Act
        final resultado = await controller.refreshBackgroundRestriction();

        // 3. Assert
        expect(resultado, isFalse);
        expect(controller.isBackgroundRestricted.value, isFalse);
      },
    );

    test(
      'Edge Case: Deve limpar a restrição previamente registrada quando o usuário a remove nas configurações',
      () async {
        // 1. Arrange
        final checker = FakeBackgroundRestrictionChecker(result: false);
        final controller = PermissionsController(
          backgroundRestrictionChecker: checker,
        );
        controller.isBackgroundRestricted.value = true;

        // 2. Act
        final resultado = await controller.refreshBackgroundRestriction();

        // 3. Assert
        expect(resultado, isFalse);
        expect(controller.isBackgroundRestricted.value, isFalse);
      },
    );

    test(
      'Sad Path: Deve propagar a exceção do checker e preservar o estado anterior',
      () async {
        // 1. Arrange
        final checker = FakeBackgroundRestrictionChecker(
          error: StateError('falha nativa'),
        );
        final controller = PermissionsController(
          backgroundRestrictionChecker: checker,
        );
        controller.isBackgroundRestricted.value = true;

        // 2. Act
        final future = controller.refreshBackgroundRestriction();

        // 3. Assert
        await expectLater(future, throwsA(isA<StateError>()));
        expect(controller.isBackgroundRestricted.value, isTrue);
      },
    );
  });

  group('PermissionsController - arePermissionsGranted', () {
    PermissionsController buildController({
      required bool always,
      required bool notification,
      required bool restricted,
    }) {
      final controller = PermissionsController(
        backgroundRestrictionChecker: FakeBackgroundRestrictionChecker(),
      );
      controller.hasAlwaysLocationPermission.value = always;
      controller.hasNotificationPermission.value = notification;
      controller.isBackgroundRestricted.value = restricted;
      return controller;
    }

    test(
      'Happy Path: Deve retornar true com localização sempre, notificação concedida e sem restrição',
      () {
        // 1. Arrange
        final controller = buildController(
          always: true,
          notification: true,
          restricted: false,
        );

        // 2. Act
        final concedidas = controller.arePermissionsGranted();

        // 3. Assert
        expect(concedidas, isTrue);
      },
    );

    test(
      'Edge Case: Deve retornar false no estado inicial do controller (nada concedido)',
      () {
        // 1. Arrange
        final controller = PermissionsController(
          backgroundRestrictionChecker: FakeBackgroundRestrictionChecker(),
        );

        // 2. Act
        final concedidas = controller.arePermissionsGranted();

        // 3. Assert
        expect(concedidas, isFalse);
      },
    );

    test(
      'Sad Path: Deve retornar false quando o app está restrito em segundo plano mesmo com permissões concedidas',
      () {
        // 1. Arrange
        final controller = buildController(
          always: true,
          notification: true,
          restricted: true,
        );

        // 2. Act
        final concedidas = controller.arePermissionsGranted();

        // 3. Assert
        expect(concedidas, isFalse);
      },
    );

    test(
      'Sad Path: Deve retornar false quando falta a permissão de localização "sempre"',
      () {
        // 1. Arrange
        final controller = buildController(
          always: false,
          notification: true,
          restricted: false,
        );

        // 2. Act
        final concedidas = controller.arePermissionsGranted();

        // 3. Assert
        expect(concedidas, isFalse);
      },
    );

    test(
      'Sad Path: Deve retornar false quando falta a permissão de notificação',
      () {
        // 1. Arrange
        final controller = buildController(
          always: true,
          notification: false,
          restricted: false,
        );

        // 2. Act
        final concedidas = controller.arePermissionsGranted();

        // 3. Assert
        expect(concedidas, isFalse);
      },
    );
  });
}
