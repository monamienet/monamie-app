import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/admin/groups/group.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_backend.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_controller.dart';

@GenerateNiceMocks([MockSpec<GroupsBackend>()])
import 'groups_controller_test.mocks.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);
const leste = Group(id: '03', name: 'Equipe Léste', people: []);
const serra = Group(id: '02', name: 'Equipe Serra', people: []);

/// Stubs every write of [backend] to run [answer] before its result:
/// `create` returns [serra] and `deletionImpact` says only ana@x.com
/// leaves the organization.
void stubWrites(Future<void> Function() answer) {
  when(backend.create(any, any)).thenAnswer((_) async {
    await answer();
    return serra;
  });
  when(backend.rename(any, any, any)).thenAnswer((_) => answer());
  when(backend.deletionImpact(any, any)).thenAnswer((_) async {
    await answer();
    return (loses: ['ana@x.com'], stays: <String>[]);
  });
  when(backend.delete(any, any)).thenAnswer((_) => answer());
  when(backend.setRoles(any, any, any, any)).thenAnswer((_) => answer());
  when(backend.remove(any, any, any)).thenAnswer((_) => answer());
}

/// Makes every write wait on [gate].
void writesWaitOn(Completer<void> gate) => stubWrites(() => gate.future);

/// Makes every write fail with [failure].
void writesFail(Object failure) => stubWrites(() async => throw failure);

late MockGroupsBackend backend;

/// A controller for Rota Sul, not loaded yet.
GroupsController newController() =>
    GroupsController(organizationId: 'rotasul', backend: backend);

/// A started controller for Rota Sul with [norte] and [leste] loaded and
/// the backend's interactions cleared; [isAdmin] false is a group's
/// maintainer.
Future<GroupsController> loadedController({bool isAdmin = false}) async {
  final controller = GroupsController(
    organizationId: 'rotasul',
    backend: backend,
    isAdmin: isAdmin,
  );
  controller.load();
  await pumpEventQueue();
  clearInteractions(backend);
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = MockGroupsBackend();
    when(backend.list(any)).thenAnswer((_) async => [norte, leste]);
    stubWrites(() async {});
  });

  group('GroupsController.load - Unit Test Suite', () {
    test('Happy Path: loading reads the organization groups', () async {
      // 1. Arrange
      final controller = GroupsController(
        organizationId: 'rotasul',
        backend: backend,
      );

      // 2. Act
      controller.load();
      await pumpEventQueue();

      // 3. Assert
      verify(backend.list('rotasul')).called(1);
      verifyNoMoreInteractions(backend);
      expect(controller.state.groups, [norte, leste]);
      expect(controller.state.isLoading, isFalse);
    });

    test(
      'Sad Path: a failed load shows the message and leaves no team',
      () async {
        // 1. Arrange
        when(backend.list(any)).thenAnswer(
          (_) async => throw const GroupsException('Sem permissão.'),
        );
        final controller = GroupsController(
          organizationId: 'rotasul',
          backend: backend,
        );

        // 2. Act
        controller.load();
        await pumpEventQueue();

        // 3. Assert
        expect(controller.state.errorMessage, 'Sem permissão.');
        expect(controller.state.groups, isEmpty);
        expect(controller.state.isLoading, isFalse);
      },
    );
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
      expect(controller.state.groups, [norte, leste, serra]);
      verify(backend.create('rotasul', 'Equipe Serra')).called(1);
      verifyNoMoreInteractions(backend);
      expect(controller.state.isWorking, isFalse);
    });

    test(
      'Edge Case: a second operation while one runs calls nothing',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);
        final first = controller.create('Equipe Serra');

        // 2. Act
        final second = await controller.create('Equipe Mar');

        // 3. Assert
        expect(second, isNull);
        verify(backend.create('rotasul', 'Equipe Serra')).called(1);
        verifyNoMoreInteractions(backend);
        gate.complete();
        await first;
      },
    );

    test('Edge Case: isWorking is true while the backend works', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      writesWaitOn(gate);

      // 2. Act
      final pending = controller.create('Equipe Serra');

      // 3. Assert
      expect(controller.state.isWorking, isTrue);
      gate.complete();
      await pending;
    });

    test('Sad Path: a GroupsException returns null with its message', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(const GroupsException('Já existe a equipe Equipe Serra.'));

      // 2. Act
      final created = await controller.create('Equipe Serra');

      // 3. Assert
      expect(created, isNull);
      expect(controller.state.errorMessage, 'Já existe a equipe Equipe Serra.');
      expect(controller.state.groups, [norte, leste]);
      expect(controller.state.isWorking, isFalse);
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
      verifyInOrder([
        backend.setRoles('rotasul', '01', 'ana@x.com', {
          GroupRole.publisher,
          GroupRole.subscriber,
        }),
        backend.list('rotasul'),
      ]);
      verifyNoMoreInteractions(backend);
    });

    test(
      'Edge Case: a second operation while one runs returns false',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);
        final first = controller.delete('03');

        // 2. Act
        final ok = await controller.setRoles('01', 'ana@x.com', {
          GroupRole.subscriber,
        });

        // 3. Assert
        expect(ok, isFalse);
        verify(backend.delete('rotasul', '03')).called(1);
        verifyNoMoreInteractions(backend);
        gate.complete();
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
      verifyNoMoreInteractions(backend);
    });
  });

  group('GroupsController (administrator or maintainer) - Unit Test Suite', () {
    const vera = GroupPerson(
      email: 'vera@x.com',
      roles: {GroupRole.maintainer, GroupRole.subscriber},
    );

    test('Happy Path: an administrator may give Gestor do grupo', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);

      // 2. Act
      final roles = controller.assignableRoles;

      // 3. Assert
      expect(roles, contains(GroupRole.maintainer));
    });

    test('Happy Path: an administrator may leave someone with only Gestor '
        'do grupo', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);

      // 2. Act
      final ok = await controller.setRoles('01', 'vera@x.com', {
        GroupRole.maintainer,
      });

      // 3. Assert
      expect(ok, isTrue);
      verifyInOrder([
        backend.setRoles('rotasul', '01', 'vera@x.com', {GroupRole.maintainer}),
        backend.list('rotasul'),
      ]);
      verifyNoMoreInteractions(backend);
    });

    test('Edge Case: an administrator may remove a maintainer', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);

      // 2. Act
      final allowed = controller.canRemove(vera);

      // 3. Assert
      expect(allowed, isTrue);
    });

    test('Edge Case: by default the person is a maintainer, who gives only '
        'the everyday roles', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final roles = controller.assignableRoles;

      // 3. Assert
      expect(roles, GroupRole.everyday);
    });

    test('Sad Path: a maintainer cannot remove another maintainer', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final allowed = controller.canRemove(vera);

      // 3. Assert
      expect(allowed, isFalse);
    });

    test('Sad Path: a maintainer cannot leave someone with only Gestor do '
        'grupo and nothing is sent', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final ok = await controller.setRoles('01', 'vera@x.com', {
        GroupRole.maintainer,
      });

      // 3. Assert
      expect(ok, isFalse);
      verifyNoMoreInteractions(backend);
      expect(controller.state.errorMessage, 'Marque pelo menos uma opção.');
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
      expect(controller.state.groups, [leste]);
      verify(backend.delete('rotasul', '01')).called(1);
      verifyNoMoreInteractions(backend);
    });

    test('Edge Case: an unexpected error gives a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(StateError('network down'));

      // 2. Act
      final ok = await controller.delete('01');

      // 3. Assert
      expect(ok, isFalse);
      expect(controller.state.errorMessage, isNotEmpty);
      expect(controller.state.isWorking, isFalse);
    });

    test('Sad Path: a failed delete keeps the team', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(const GroupsException('Equipe não encontrada.'));

      // 2. Act
      final ok = await controller.delete('01');

      // 3. Assert
      expect(ok, isFalse);
      expect(controller.state.groups, [norte, leste]);
      expect(controller.state.errorMessage, 'Equipe não encontrada.');
      expect(controller.state.isWorking, isFalse);
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
        verifyInOrder([
          backend.rename('rotasul', '01', 'Guias Norte'),
          backend.list('rotasul'),
        ]);
        verifyNoMoreInteractions(backend);
      },
    );

    test('Edge Case: isWorking is true while the backend works', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      writesWaitOn(gate);

      // 2. Act
      final pending = controller.rename('01', 'Guias');

      // 3. Assert
      expect(controller.state.isWorking, isTrue);
      gate.complete();
      await pending;
      expect(controller.state.isWorking, isFalse);
    });

    test(
      'Sad Path: a refused name returns false with the server message',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        writesFail(const GroupsException('Já existe o grupo Equipe Léste.'));

        // 2. Act
        final ok = await controller.rename('01', 'equipe leste');

        // 3. Assert
        expect(ok, isFalse);
        expect(
          controller.state.errorMessage,
          'Já existe o grupo Equipe Léste.',
        );
        verify(backend.rename('rotasul', '01', 'equipe leste')).called(1);
        verifyNoMoreInteractions(backend);
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
      verify(backend.deletionImpact('rotasul', '01')).called(1);
      verifyNoMoreInteractions(backend);
    });

    test('Edge Case: while another operation runs it returns null', () async {
      // 1. Arrange
      final controller = await loadedController();
      final gate = Completer<void>();
      writesWaitOn(gate);
      final first = controller.delete('03');

      // 2. Act
      final impact = await controller.deletionImpact('01');

      // 3. Assert
      expect(impact, isNull);
      gate.complete();
      await first;
    });

    test('Sad Path: a failure returns null with its message', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(const GroupsException('Grupo não encontrado.'));

      // 2. Act
      final impact = await controller.deletionImpact('01');

      // 3. Assert
      expect(impact, isNull);
      expect(controller.state.errorMessage, 'Grupo não encontrado.');
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
      verifyInOrder([
        backend.remove('rotasul', '01', 'ana@x.com'),
        backend.list('rotasul'),
      ]);
      verifyNoMoreInteractions(backend);
    });

    test('Edge Case: an unexpected error gives a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(StateError('network down'));

      // 2. Act
      final ok = await controller.remove('01', 'ana@x.com');

      // 3. Assert
      expect(ok, isFalse);
      expect(controller.state.errorMessage, contains('tente de novo'));
    });

    test('Sad Path: a refused removal does not reload the groups', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(const GroupsException('Essa pessoa não está no grupo.'));

      // 2. Act
      final ok = await controller.remove('01', 'vera@x.com');

      // 3. Assert
      expect(ok, isFalse);
      verify(backend.remove('rotasul', '01', 'vera@x.com')).called(1);
      verifyNoMoreInteractions(backend);
      expect(controller.state.errorMessage, 'Essa pessoa não está no grupo.');
    });
  });

  group('GroupsController.load (more cases) - Unit Test Suite', () {
    test('Edge Case: isLoading is true while the groups are read', () async {
      // 1. Arrange
      final gate = Completer<List<Group>>();
      when(backend.list(any)).thenAnswer((_) => gate.future);
      final controller = newController();

      // 2. Act
      final pending = controller.load();

      // 3. Assert
      expect(controller.state.isLoading, isTrue);
      gate.complete([norte]);
      await pending;
      expect(controller.state.isLoading, isFalse);
    });

    test('Edge Case: an organization with no group loads an empty '
        'list', () async {
      // 1. Arrange
      when(backend.list(any)).thenAnswer((_) async => <Group>[]);
      final controller = newController();

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.groups, isEmpty);
      expect(controller.state.errorMessage, isEmpty);
    });

    test('Edge Case: a second load while one runs reads nothing', () async {
      // 1. Arrange
      final gate = Completer<List<Group>>();
      when(backend.list(any)).thenAnswer((_) => gate.future);
      final controller = newController();
      final first = controller.load();

      // 2. Act
      await controller.load();

      // 3. Assert
      verify(backend.list(any)).called(1);
      gate.complete([norte]);
      await first;
    });

    test('Sad Path: an unexpected error shows a generic message', () async {
      // 1. Arrange
      when(
        backend.list(any),
      ).thenAnswer((_) async => throw StateError('offline'));
      final controller = newController();

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(controller.state.errorMessage, isNotEmpty);
      expect(controller.state.errorMessage, isNot(contains('offline')));
      expect(controller.state.isLoading, isFalse);
    });
  });

  group('GroupsController (listeners) - Unit Test Suite', () {
    test('Happy Path: a load that changes the groups notifies three times: '
        'loading, groups, loaded', () async {
      // 1. Arrange
      final controller = newController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(notifications, 3);
    });

    test('Edge Case: reloading groups equal by content notifies only for '
        'the loading flag', () async {
      // 1. Arrange
      // Fresh objects on every read, as the backend builds them from JSON.
      when(backend.list(any)).thenAnswer(
        (_) async => [
          Group(
            id: '01',
            name: 'Equipe Norte',
            people: [
              GroupPerson(
                email: 'ana@x.com',
                roles: {GroupRole.publisher, GroupRole.subscriber},
              ),
            ],
            createdAt: DateTime.utc(2026, 10, 1),
          ),
        ],
      );
      final controller = newController();
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.load();

      // 3. Assert
      expect(notifications, 2);
    });

    test('Sad Path: roles refused locally notify once with the '
        'problem', () async {
      // 1. Arrange
      final controller = await loadedController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.setRoles('01', 'ana@x.com', {});

      // 3. Assert
      expect(notifications, 1);
    });

    test('Sad Path: a load finishing after dispose notifies nobody and does '
        'not throw', () async {
      // 1. Arrange
      final gate = Completer<List<Group>>();
      when(backend.list(any)).thenAnswer((_) => gate.future);
      final controller = newController();
      var notifications = 0;
      final pending = controller.load();
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete([norte]);

      // 3. Assert
      await expectLater(pending, completes);
      expect(notifications, 0);
    });

    test('Sad Path: an operation finishing after dispose notifies nobody '
        'and does not throw', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);
      final gate = Completer<void>();
      writesWaitOn(gate);
      var notifications = 0;
      final pending = controller.create('Equipe Serra');
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(pending, completion(serra));
      expect(notifications, 0);
    });
  });
}
