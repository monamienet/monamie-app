import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_backend.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_controller.dart';

@GenerateNiceMocks([MockSpec<AdministratorsBackend>()])
import 'administrators_controller_test.mocks.dart';

const _before = OrganizationAdministrators(
  administrators: [Administrator(email: 'olga@x.com', owner: true)],
  members: ['caio@x.com'],
);

const _after = OrganizationAdministrators(
  administrators: [
    Administrator(email: 'olga@x.com', owner: true),
    Administrator(email: 'caio@x.com'),
  ],
);

/// Makes `list` wait on [gate] before returning [people].
void listWaitsOn(
  Completer<void> gate, [
  OrganizationAdministrators people = _before,
]) {
  when(backend.list(any)).thenAnswer((_) async {
    await gate.future;
    return people;
  });
}

/// Makes `setAdministrator` wait on [gate].
void setWaitsOn(Completer<void> gate) {
  when(
    backend.setAdministrator(any, any, admin: anyNamed('admin')),
  ).thenAnswer((_) => gate.future);
}

late MockAdministratorsBackend backend;

AdministratorsController newController() =>
    AdministratorsController(organizationId: 'rotasul', backend: backend);

/// A started controller with [_before] loaded and the backend's
/// interactions cleared.
Future<AdministratorsController> loadedController() async {
  final controller = newController();
  controller.onStart();
  await pumpEventQueue();
  clearInteractions(backend);
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = MockAdministratorsBackend();
    when(backend.list(any)).thenAnswer((_) async => _before);
  });

  group('AdministratorsController.load - Unit Test Suite', () {
    test('Happy Path: starting reads the administrators and members', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      verify(backend.list('rotasul')).called(1);
      verifyNoMoreInteractions(backend);
      expect(controller.people.value, same(_before));
      expect(controller.isLoading.value, isFalse);
    });

    test('Edge Case: isLoading is true while the list is read', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      listWaitsOn(gate);

      // 2. Act
      final pending = controller.load();

      // 3. Assert
      expect(controller.isLoading.value, isTrue);
      gate.complete();
      await pending;
      expect(controller.isLoading.value, isFalse);
    });

    test('Edge Case: a second load while one runs reads nothing', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      listWaitsOn(gate);
      final first = controller.load();

      // 2. Act
      await controller.load();

      // 3. Assert
      verify(backend.list('rotasul')).called(1);
      verifyNoMoreInteractions(backend);
      gate.complete();
      await first;
    });

    test('Sad Path: an AdministratorsException shows its message and stops '
        'loading', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(backend.list(any)).thenAnswer(
        (_) async => throw const AdministratorsException('Sem permissão.'),
      );

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.errorMessage.value, 'Sem permissão.');
      expect(controller.isLoading.value, isFalse);
    });

    test('Sad Path: an unexpected error shows a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(
        backend.list(any),
      ).thenAnswer((_) async => throw StateError('offline'));

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(
        controller.errorMessage.value,
        'Não foi possível carregar os administradores.',
      );
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('AdministratorsController.setAdministrator - Unit Test Suite', () {
    test('Happy Path: the change is sent and the list read again', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(backend.list(any)).thenAnswer((_) async => _after);

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isTrue);
      verifyInOrder([
        backend.setAdministrator('rotasul', 'caio@x.com', admin: true),
        backend.list('rotasul'),
      ]);
      verifyNoMoreInteractions(backend);
      expect(controller.people.value, same(_after));
    });

    test('Edge Case: the row in flight is marked and then cleared', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      setWaitsOn(gate);

      // 2. Act
      final pending = controller.setAdministrator('ana@x.com', admin: false);

      // 3. Assert
      expect(controller.workingEmail.value, 'ana@x.com');
      gate.complete();
      await pending;
      expect(controller.workingEmail.value, isNull);
    });

    test('Edge Case: a second change while one runs returns false', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      setWaitsOn(gate);
      final first = controller.setAdministrator('ana@x.com', admin: false);

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      verify(backend.setAdministrator('rotasul', 'ana@x.com', admin: false));
      verifyNoMoreInteractions(backend);
      gate.complete();
      await first;
    });

    test('Edge Case: no change starts while the list is loading', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      listWaitsOn(gate);
      final loading = controller.load();

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      verify(backend.list('rotasul')).called(1);
      verifyNoMoreInteractions(backend);
      gate.complete();
      await loading;
    });

    test('Sad Path: an AdministratorsException returns false with its '
        'message and clears the row', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(
        backend.setAdministrator(any, any, admin: anyNamed('admin')),
      ).thenAnswer(
        (_) async => throw const AdministratorsException(
          'Essa pessoa não faz parte da organização.',
        ),
      );

      // 2. Act
      final ok = await controller.setAdministrator('rui@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      expect(
        controller.errorMessage.value,
        'Essa pessoa não faz parte da organização.',
      );
      expect(controller.workingEmail.value, isNull);
      expect(controller.people.value, same(_before));
    });

    test('Sad Path: an unexpected error gives a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      when(
        backend.setAdministrator(any, any, admin: anyNamed('admin')),
      ).thenAnswer((_) async => throw StateError('offline'));

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      expect(
        controller.errorMessage.value,
        'Não foi possível concluir agora. Verifique a conexão e tente de '
        'novo.',
      );
      expect(controller.workingEmail.value, isNull);
    });
  });
}
