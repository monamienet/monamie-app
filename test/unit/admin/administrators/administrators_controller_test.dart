import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_backend.dart';
import 'package:monamie_app/app/modules/admin/administrators/administrators_controller.dart';

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

/// [AdministratorsBackend] that records every call, returns [people] from
/// `list`, optionally waits on [listGate] / [setGate] and fails with
/// [listFailure] / [setFailure].
class FakeAdministratorsBackend implements AdministratorsBackend {
  final calls = <String>[];
  OrganizationAdministrators people = _before;
  Completer<void>? listGate;
  Completer<void>? setGate;
  Object? listFailure;
  Object? setFailure;

  @override
  Future<OrganizationAdministrators> list(String organizationId) async {
    calls.add('list:$organizationId');
    await listGate?.future;
    if (listFailure case final failure?) throw failure;
    return people;
  }

  @override
  Future<void> setAdministrator(
    String organizationId,
    String email, {
    required bool admin,
  }) async {
    calls.add('set:$organizationId:$email:$admin');
    await setGate?.future;
    if (setFailure case final failure?) throw failure;
  }
}

late FakeAdministratorsBackend backend;

AdministratorsController newController() =>
    AdministratorsController(organizationId: 'rotasul', backend: backend);

/// A started controller with [_before] loaded and the call log cleared.
Future<AdministratorsController> loadedController() async {
  final controller = newController();
  controller.onStart();
  await pumpEventQueue();
  backend.calls.clear();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeAdministratorsBackend();
  });

  group('AdministratorsController.load - Unit Test Suite', () {
    test('Happy Path: starting reads the administrators and members', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(backend.calls, ['list:rotasul']);
      expect(controller.people.value, same(_before));
      expect(controller.isLoading.value, isFalse);
    });

    test('Edge Case: isLoading is true while the list is read', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.listGate = Completer<void>();

      // 2. Act
      final pending = controller.load();

      // 3. Assert
      expect(controller.isLoading.value, isTrue);
      backend.listGate!.complete();
      await pending;
      expect(controller.isLoading.value, isFalse);
    });

    test('Edge Case: a second load while one runs reads nothing', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.listGate = Completer<void>();
      final first = controller.load();

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(backend.calls, ['list:rotasul']);
      backend.listGate!.complete();
      await first;
    });

    test('Sad Path: an AdministratorsException shows its message and stops '
        'loading', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.listFailure = const AdministratorsException('Sem permissão.');

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.errorMessage.value, 'Sem permissão.');
      expect(controller.isLoading.value, isFalse);
    });

    test('Sad Path: an unexpected error shows a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.listFailure = StateError('offline');

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
      backend.people = _after;

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isTrue);
      expect(backend.calls, ['set:rotasul:caio@x.com:true', 'list:rotasul']);
      expect(controller.people.value, same(_after));
    });

    test('Edge Case: the row in flight is marked and then cleared', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.setGate = Completer<void>();

      // 2. Act
      final pending = controller.setAdministrator('ana@x.com', admin: false);

      // 3. Assert
      expect(controller.workingEmail.value, 'ana@x.com');
      backend.setGate!.complete();
      await pending;
      expect(controller.workingEmail.value, isNull);
    });

    test('Edge Case: a second change while one runs returns false', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.setGate = Completer<void>();
      final first = controller.setAdministrator('ana@x.com', admin: false);

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      expect(backend.calls, ['set:rotasul:ana@x.com:false']);
      backend.setGate!.complete();
      await first;
    });

    test('Edge Case: no change starts while the list is loading', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.listGate = Completer<void>();
      final loading = controller.load();

      // 2. Act
      final ok = await controller.setAdministrator('caio@x.com', admin: true);

      // 3. Assert
      expect(ok, isFalse);
      expect(backend.calls, ['list:rotasul']);
      backend.listGate!.complete();
      await loading;
    });

    test('Sad Path: an AdministratorsException returns false with its '
        'message and clears the row', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.setFailure = const AdministratorsException(
        'Essa pessoa não faz parte da organização.',
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
      backend.setFailure = StateError('offline');

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
