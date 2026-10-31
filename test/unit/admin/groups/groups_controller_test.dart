import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_backend.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_controller.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);
const leste = Group(id: '03', name: 'Equipe Léste', people: []);
const serra = Group(id: '02', name: 'Equipe Serra', people: []);

/// [GroupsBackend] that records every call, returns [groups] from `list`,
/// optionally waits on [gate] and fails with [failure] in the writes.
class FakeGroupsBackend implements GroupsBackend {
  final calls = <String>[];
  List<Group> groups = [norte, leste];
  Completer<void>? gate;
  Object? failure;

  Future<void> _write(String call) async {
    calls.add(call);
    await gate?.future;
    if (failure case final failure?) throw failure;
  }

  @override
  Future<List<Group>> list(String organizationId) async {
    calls.add('list:$organizationId');
    return groups;
  }

  @override
  Future<Group> create(String organizationId, String name) async {
    await _write('create:$organizationId:$name');
    return serra;
  }

  @override
  Future<void> rename(String organizationId, String team, String name) =>
      _write('rename:$organizationId:$team:$name');

  @override
  Future<({List<String> loses, List<String> stays})> deletionImpact(
    String organizationId,
    String team,
  ) async {
    await _write('deletionImpact:$organizationId:$team');
    return (loses: ['ana@x.com'], stays: <String>[]);
  }

  @override
  Future<void> delete(String organizationId, String team) =>
      _write('delete:$organizationId:$team');

  @override
  Future<void> setRoles(
    String organizationId,
    String team,
    String email,
    Set<GroupRole> roles,
  ) => _write(
    'setRoles:$organizationId:$team:$email:${(roles.map((r) => r.name).toList()..sort()).join(',')}',
  );

  @override
  Future<void> remove(String organizationId, String team, String email) =>
      _write('remove:$organizationId:$team:$email');
}

late FakeGroupsBackend backend;

/// A started controller for Rota Sul with [norte] and [leste] loaded and
/// the backend's call log cleared.
Future<GroupsController> loadedController() async {
  final controller = GroupsController(
    organizationId: 'rotasul',
    backend: backend,
  );
  controller.onStart();
  await pumpEventQueue();
  backend.calls.clear();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeGroupsBackend();
  });

  group('GroupsController.onInit - Unit Test Suite', () {
    test('Happy Path: starting loads the organization groups', () async {
      // 1. Arrange
      final controller = GroupsController(
        organizationId: 'rotasul',
        backend: backend,
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(backend.calls, ['list:rotasul']);
      expect(controller.groups, [norte, leste]);
      expect(controller.isLoading.value, isFalse);
    });

    test('Edge Case: no groups read "0 de 99"', () async {
      // 1. Arrange
      backend.groups = [];

      // 2. Act
      final controller = await loadedController();

      // 3. Assert
      expect(controller.countLabel, '0 de 99');
    });

    test(
      'Sad Path: a failed load shows the message and leaves no team',
      () async {
        // 1. Arrange
        backend = _FailingListBackend();
        final controller = GroupsController(
          organizationId: 'rotasul',
          backend: backend,
        );

        // 2. Act
        controller.onStart();
        await pumpEventQueue();

        // 3. Assert
        expect(controller.errorMessage.value, 'Sem permissão.');
        expect(controller.groups, isEmpty);
        expect(controller.isLoading.value, isFalse);
      },
    );
  });

  group('GroupsController.countLabel - Unit Test Suite', () {
    test('Happy Path: two groups read "2 de 99"', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final label = controller.countLabel;

      // 3. Assert
      expect(label, '2 de 99');
    });
  });

  group('GroupsController.nameProblem - Unit Test Suite', () {
    test('Happy Path: a new name has no problem', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final problem = controller.nameProblem('Equipe Serra');

      // 3. Assert
      expect(problem, isNull);
    });

    test('Edge Case: renaming a team to its own name has no problem', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final problem = controller.nameProblem('equipe norte', renaming: '01');

      // 3. Assert
      expect(problem, isNull);
    });

    test(
      'Sad Path: renaming a team to another team\'s name is a duplicate',
      () async {
        // 1. Arrange
        final controller = await loadedController();

        // 2. Act
        final problem = controller.nameProblem('Equipe Leste', renaming: '01');

        // 3. Assert
        expect(problem, 'Já existe o grupo Equipe Léste.');
      },
    );
  });

  group('GroupsController.create - Unit Test Suite', () {
    test('Happy Path: the created team is returned and added', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final created = await controller.create('Equipe Serra');

      // 3. Assert
      expect(created, serra);
      expect(controller.groups, [norte, leste, serra]);
      expect(backend.calls, ['create:rotasul:Equipe Serra']);
      expect(controller.isWorking.value, isFalse);
    });

    test(
      'Edge Case: a second operation while one runs calls nothing',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        backend.gate = Completer<void>();
        final first = controller.create('Equipe Serra');

        // 2. Act
        final second = await controller.create('Equipe Mar');

        // 3. Assert
        expect(second, isNull);
        expect(backend.calls, ['create:rotasul:Equipe Serra']);
        backend.gate!.complete();
        await first;
      },
    );

    test('Edge Case: isWorking is true while the backend works', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.gate = Completer<void>();

      // 2. Act
      final pending = controller.create('Equipe Serra');

      // 3. Assert
      expect(controller.isWorking.value, isTrue);
      backend.gate!.complete();
      await pending;
    });

    test('Sad Path: a GroupsException returns null with its message', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.failure = const GroupsException(
        'Já existe a equipe Equipe Serra.',
      );

      // 2. Act
      final created = await controller.create('Equipe Serra');

      // 3. Assert
      expect(created, isNull);
      expect(controller.errorMessage.value, 'Já existe a equipe Equipe Serra.');
      expect(controller.groups, [norte, leste]);
      expect(controller.isWorking.value, isFalse);
    });
  });

  group('GroupsController.setRoles - Unit Test Suite', () {
    test('Happy Path: roles are sent and the groups reloaded', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final ok = await controller.setRoles('01', 'ana@x.com', {
        GroupRole.publisher,
        GroupRole.subscriber,
      });

      // 3. Assert
      expect(ok, isTrue);
      expect(backend.calls, [
        'setRoles:rotasul:01:ana@x.com:publisher,subscriber',
        'list:rotasul',
      ]);
    });

    test(
      'Edge Case: a second operation while one runs returns false',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        backend.gate = Completer<void>();
        final first = controller.delete('03');

        // 2. Act
        final ok = await controller.setRoles('01', 'ana@x.com', {
          GroupRole.subscriber,
        });

        // 3. Assert
        expect(ok, isFalse);
        expect(backend.calls, ['delete:rotasul:03']);
        backend.gate!.complete();
        await first;
      },
    );

    test('Sad Path: no roles returns false and calls nothing', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final ok = await controller.setRoles('01', 'ana@x.com', {});

      // 3. Assert
      expect(ok, isFalse);
      expect(backend.calls, isEmpty);
    });
  });

  group('GroupsController.delete - Unit Test Suite', () {
    test('Happy Path: the deleted team leaves the list', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final ok = await controller.delete('01');

      // 3. Assert
      expect(ok, isTrue);
      expect(controller.groups, [leste]);
      expect(backend.calls, ['delete:rotasul:01']);
    });

    test('Edge Case: an unexpected error gives a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.failure = StateError('network down');

      // 2. Act
      final ok = await controller.delete('01');

      // 3. Assert
      expect(ok, isFalse);
      expect(controller.errorMessage.value, isNotEmpty);
      expect(controller.isWorking.value, isFalse);
    });

    test('Sad Path: a failed delete keeps the team', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.failure = const GroupsException('Equipe não encontrada.');

      // 2. Act
      final ok = await controller.delete('01');

      // 3. Assert
      expect(ok, isFalse);
      expect(controller.groups, [norte, leste]);
      expect(controller.errorMessage.value, 'Equipe não encontrada.');
      expect(controller.isWorking.value, isFalse);
    });
  });

  group('GroupsController.rename - Unit Test Suite', () {
    test(
      'Happy Path: the trimmed name is sent and the groups reloaded',
      () async {
        // 1. Arrange
        final controller = await loadedController();

        // 2. Act
        final ok = await controller.rename('01', '  Guias Norte ');

        // 3. Assert
        expect(ok, isTrue);
        expect(backend.calls, [
          'rename:rotasul:01:Guias Norte',
          'list:rotasul',
        ]);
      },
    );

    test('Edge Case: isWorking is true while the backend works', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.gate = Completer<void>();

      // 2. Act
      final pending = controller.rename('01', 'Guias');

      // 3. Assert
      expect(controller.isWorking.value, isTrue);
      backend.gate!.complete();
      await pending;
      expect(controller.isWorking.value, isFalse);
    });

    test(
      'Sad Path: a refused name returns false with the server message',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        backend.failure = const GroupsException(
          'Já existe o grupo Equipe Léste.',
        );

        // 2. Act
        final ok = await controller.rename('01', 'equipe leste');

        // 3. Assert
        expect(ok, isFalse);
        expect(
          controller.errorMessage.value,
          'Já existe o grupo Equipe Léste.',
        );
        expect(backend.calls, ['rename:rotasul:01:equipe leste']);
      },
    );
  });

  group('GroupsController.deletionImpact - Unit Test Suite', () {
    test('Happy Path: returns who would leave the organization', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final impact = await controller.deletionImpact('01');

      // 3. Assert
      expect(impact?.loses, ['ana@x.com']);
      expect(backend.calls, ['deletionImpact:rotasul:01']);
    });

    test('Edge Case: while another operation runs it returns null', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.gate = Completer<void>();
      final first = controller.delete('03');

      // 2. Act
      final impact = await controller.deletionImpact('01');

      // 3. Assert
      expect(impact, isNull);
      backend.gate!.complete();
      await first;
    });

    test('Sad Path: a failure returns null with its message', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.failure = const GroupsException('Grupo não encontrado.');

      // 2. Act
      final impact = await controller.deletionImpact('01');

      // 3. Assert
      expect(impact, isNull);
      expect(controller.errorMessage.value, 'Grupo não encontrado.');
    });
  });

  group('GroupsController.remove - Unit Test Suite', () {
    test('Happy Path: the person is removed and the groups reloaded', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final ok = await controller.remove('01', 'ana@x.com');

      // 3. Assert
      expect(ok, isTrue);
      expect(backend.calls, ['remove:rotasul:01:ana@x.com', 'list:rotasul']);
    });

    test('Edge Case: an unexpected error gives a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.failure = StateError('network down');

      // 2. Act
      final ok = await controller.remove('01', 'ana@x.com');

      // 3. Assert
      expect(ok, isFalse);
      expect(controller.errorMessage.value, contains('tente de novo'));
    });

    test('Sad Path: a refused removal does not reload the groups', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.failure = const GroupsException('Essa pessoa não está no grupo.');

      // 2. Act
      final ok = await controller.remove('01', 'vera@x.com');

      // 3. Assert
      expect(ok, isFalse);
      expect(backend.calls, ['remove:rotasul:01:vera@x.com']);
      expect(controller.errorMessage.value, 'Essa pessoa não está no grupo.');
    });
  });
}

/// A backend whose `list` fails with a [GroupsException].
class _FailingListBackend extends FakeGroupsBackend {
  @override
  Future<List<Group>> list(String organizationId) async {
    calls.add('list:$organizationId');
    throw const GroupsException('Sem permissão.');
  }
}
