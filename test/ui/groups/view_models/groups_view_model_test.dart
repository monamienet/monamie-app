import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<GroupsRepository>()])
import 'groups_view_model_test.mocks.dart';

const norte = Group(id: '01', name: 'Equipe Norte', people: []);
const leste = Group(id: '03', name: 'Equipe Léste', people: []);
const serra = Group(id: '02', name: 'Equipe Serra', people: []);

/// Stubs every write of [repository] to wait on [wait] before its result:
/// `create` returns [serra] and `deletionImpact` says only ana@x.com
/// leaves the organization; with [failure], every write returns an [Err]
/// with that failure instead.
void stubWrites(Future<void> Function() wait, {Failure? failure}) {
  Future<Result<T>> answer<T>(T value) async {
    await wait();
    return failure == null ? Ok(value) : Err(failure);
  }

  when(repository.create(any, any)).thenAnswer((_) => answer(serra));
  when(repository.rename(any, any, any)).thenAnswer((_) => answer(null));
  when(
    repository.deletionImpact(any, any),
  ).thenAnswer((_) => answer((loses: ['ana@x.com'], stays: <String>[])));
  when(repository.delete(any, any)).thenAnswer((_) => answer(null));
  when(repository.setRoles(any, any, any, any)).thenAnswer((_) => answer(null));
  when(repository.remove(any, any, any)).thenAnswer((_) => answer(null));
}

/// Makes every write wait on [gate].
void writesWaitOn(Completer<void> gate) => stubWrites(() => gate.future);

/// Makes every write return an [Err] with [failure].
void writesFail(Failure failure) => stubWrites(() async {}, failure: failure);

/// The repository's failure for an unexpected (non-Functions) error.
const _generic = Failure.connection(FailedAction.conclude);

late MockGroupsRepository repository;

/// A controller for Rota Sul, not loaded yet.
GroupsViewModel newController() =>
    GroupsViewModel(organizationId: 'rotasul', repository: repository);

/// A started controller for Rota Sul with [norte] and [leste] loaded and
/// the repository's interactions cleared; [isAdmin] false is a group's
/// maintainer.
Future<GroupsViewModel> loadedController({bool isAdmin = false}) async {
  final controller = GroupsViewModel(
    organizationId: 'rotasul',
    repository: repository,
    isAdmin: isAdmin,
  );
  controller.load.execute();
  await pumpEventQueue();
  clearInteractions(repository);
  return controller;
}

void main() {
  provideDummy<Result<List<Group>>>(const Ok([]));
  provideDummy<Result<Group>>(const Ok(norte));
  provideDummy<Result<void>>(const Ok(null));
  provideDummy<Result<({List<String> loses, List<String> stays})>>(
    const Ok((loses: <String>[], stays: <String>[])),
  );

  setUp(() {
    repository = MockGroupsRepository();
    when(
      repository.list(any),
    ).thenAnswer((_) async => const Ok([norte, leste]));
    stubWrites(() async {});
  });

  group('GroupsViewModel.load - Unit Test Suite', () {
    test('Happy Path: loading reads the organization groups', () async {
      // 1. Arrange
      final controller = GroupsViewModel(
        organizationId: 'rotasul',
        repository: repository,
      );

      // 2. Act
      controller.load.execute();
      await pumpEventQueue();

      // 3. Assert
      verify(repository.list('rotasul')).called(1);
      verifyNoMoreInteractions(repository);
      expect(controller.state.groups, [norte, leste]);
      expect(controller.load.running, isFalse);
    });

    test(
      'Sad Path: a failed load shows the message and leaves no team',
      () async {
        // 1. Arrange
        when(repository.list(any)).thenAnswer(
          (_) async => const Err(Failure.serverRefusal('Sem permissão.')),
        );
        final controller = GroupsViewModel(
          organizationId: 'rotasul',
          repository: repository,
        );

        // 2. Act
        controller.load.execute();
        await pumpEventQueue();

        // 3. Assert
        expect(
          controller.state.failure,
          const Failure.serverRefusal('Sem permissão.'),
        );
        expect(controller.state.groups, isEmpty);
        expect(controller.load.running, isFalse);
      },
    );
  });

  group('GroupsViewModel.nameProblem - Unit Test Suite', () {
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
        expect(problem, const Failure.groupNameTaken('Equipe Léste'));
      },
    );
  });

  group('GroupsViewModel.create - Unit Test Suite', () {
    test('Happy Path: the created team is returned and added', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final created = await controller.create.execute('Equipe Serra');

      // 3. Assert
      expect(
        created,
        isA<Ok<Group>>().having((ok) => ok.value, 'value', serra),
      );
      expect(controller.state.groups, [norte, leste, serra]);
      verify(repository.create('rotasul', 'Equipe Serra')).called(1);
      verifyNoMoreInteractions(repository);
      expect(controller.isWorking, isFalse);
    });

    test(
      'Edge Case: a second operation while one runs calls nothing',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);
        final first = controller.create.execute('Equipe Serra');

        // 2. Act
        final second = await controller.create.execute('Equipe Mar');

        // 3. Assert
        expect(second, isNull);
        verify(repository.create('rotasul', 'Equipe Serra')).called(1);
        verifyNoMoreInteractions(repository);
        gate.complete();
        await first;
      },
    );

    test(
      'Edge Case: isWorking (the command runs) while the repository works',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);

        // 2. Act
        final pending = controller.create.execute('Equipe Serra');

        // 3. Assert
        expect(controller.isWorking, isTrue);
        gate.complete();
        await pending;
      },
    );

    test('Sad Path: an Err is returned with its failure', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(
        const Failure.serverRefusal('Já existe a equipe Equipe Serra.'),
      );

      // 2. Act
      final created = await controller.create.execute('Equipe Serra');

      // 3. Assert
      expect(created, isA<Err<Group>>());
      expect(
        controller.state.failure,
        const Failure.serverRefusal('Já existe a equipe Equipe Serra.'),
      );
      expect(controller.state.groups, [norte, leste]);
      expect(controller.isWorking, isFalse);
    });
  });

  group('GroupsViewModel.setRoles - Unit Test Suite', () {
    test('Happy Path: roles are sent and the groups reloaded', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final result = await controller.setRoles.execute((
        groupId: '01',
        email: 'ana@x.com',
        roles: {GroupRole.publisher, GroupRole.subscriber},
      ));

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyInOrder([
        repository.setRoles('rotasul', '01', 'ana@x.com', {
          GroupRole.publisher,
          GroupRole.subscriber,
        }),
        repository.list('rotasul'),
      ]);
      verifyNoMoreInteractions(repository);
    });

    test(
      'Edge Case: a second operation while one runs is ignored (null)',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);
        final first = controller.delete.execute('03');

        // 2. Act
        final result = await controller.setRoles.execute((
          groupId: '01',
          email: 'ana@x.com',
          roles: {GroupRole.subscriber},
        ));

        // 3. Assert
        expect(result, isNull);
        verify(repository.delete('rotasul', '03')).called(1);
        verifyNoMoreInteractions(repository);
        gate.complete();
        await first;
      },
    );

    test('Sad Path: no roles returns an Err and calls nothing', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final result = await controller.setRoles.execute((
        groupId: '01',
        email: 'ana@x.com',
        roles: {},
      ));

      // 3. Assert
      expect(result, isA<Err<void>>());
      verifyNoMoreInteractions(repository);
    });
  });

  group('GroupsViewModel (administrator or maintainer) - Unit Test Suite', () {
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
      final result = await controller.setRoles.execute((
        groupId: '01',
        email: 'vera@x.com',
        roles: {GroupRole.maintainer},
      ));

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyInOrder([
        repository.setRoles('rotasul', '01', 'vera@x.com', {
          GroupRole.maintainer,
        }),
        repository.list('rotasul'),
      ]);
      verifyNoMoreInteractions(repository);
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
      final result = await controller.setRoles.execute((
        groupId: '01',
        email: 'vera@x.com',
        roles: {GroupRole.maintainer},
      ));

      // 3. Assert
      expect(result, isA<Err<void>>());
      verifyNoMoreInteractions(repository);
      expect(controller.state.failure, const Failure.noRoleChosen());
    });
  });

  group('GroupsViewModel.delete - Unit Test Suite', () {
    test('Happy Path: the deleted team leaves the list', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final result = await controller.delete.execute('01');

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(controller.state.groups, [leste]);
      verify(repository.delete('rotasul', '01')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('Edge Case: an unexpected error gives a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(_generic);

      // 2. Act
      final result = await controller.delete.execute('01');

      // 3. Assert
      expect(result, isA<Err<void>>());
      expect(controller.state.failure, isNotNull);
      expect(controller.isWorking, isFalse);
    });

    test('Sad Path: a failed delete keeps the team', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(const Failure.serverRefusal('Equipe não encontrada.'));

      // 2. Act
      final result = await controller.delete.execute('01');

      // 3. Assert
      expect(result, isA<Err<void>>());
      expect(controller.state.groups, [norte, leste]);
      expect(
        controller.state.failure,
        const Failure.serverRefusal('Equipe não encontrada.'),
      );
      expect(controller.isWorking, isFalse);
    });
  });

  group('GroupsViewModel.rename - Unit Test Suite', () {
    test(
      'Happy Path: the trimmed name is sent and the groups reloaded',
      () async {
        // 1. Arrange
        final controller = await loadedController();

        // 2. Act
        final result = await controller.rename.execute((
          groupId: '01',
          name: '  Guias Norte ',
        ));

        // 3. Assert
        expect(result, isA<Ok<void>>());
        verifyInOrder([
          repository.rename('rotasul', '01', 'Guias Norte'),
          repository.list('rotasul'),
        ]);
        verifyNoMoreInteractions(repository);
      },
    );

    test(
      'Edge Case: isWorking (the command runs) while the repository works',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);

        // 2. Act
        final pending = controller.rename.execute((
          groupId: '01',
          name: 'Guias',
        ));

        // 3. Assert
        expect(controller.isWorking, isTrue);
        gate.complete();
        await pending;
        expect(controller.isWorking, isFalse);
      },
    );

    test(
      'Edge Case: the rename in flight is its argument, cleared after',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);

        // 2. Act
        final pending = controller.rename.execute((
          groupId: '01',
          name: 'Guias',
        ));

        // 3. Assert
        expect(controller.rename.argument, (groupId: '01', name: 'Guias'));
        gate.complete();
        await pending;
        expect(controller.rename.argument, isNull);
      },
    );

    test(
      'Sad Path: a refused name returns an Err with the server message',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        writesFail(
          const Failure.serverRefusal('Já existe o grupo Equipe Léste.'),
        );

        // 2. Act
        final result = await controller.rename.execute((
          groupId: '01',
          name: 'equipe leste',
        ));

        // 3. Assert
        expect(result, isA<Err<void>>());
        expect(
          controller.state.failure,
          const Failure.serverRefusal('Já existe o grupo Equipe Léste.'),
        );
        verify(repository.rename('rotasul', '01', 'equipe leste')).called(1);
        verifyNoMoreInteractions(repository);
      },
    );
  });

  group('GroupsViewModel.deletionImpact - Unit Test Suite', () {
    test('Happy Path: returns who would leave the organization', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final impact = await controller.deletionImpact.execute('01');

      // 3. Assert
      expect(
        impact,
        isA<Ok<({List<String> loses, List<String> stays})>>().having(
          (ok) => ok.value.loses,
          'loses',
          ['ana@x.com'],
        ),
      );
      verify(repository.deletionImpact('rotasul', '01')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test(
      'Edge Case: while another operation runs it is ignored (null)',
      () async {
        // 1. Arrange
        final controller = await loadedController();
        final gate = Completer<void>();
        writesWaitOn(gate);
        final first = controller.delete.execute('03');

        // 2. Act
        final impact = await controller.deletionImpact.execute('01');

        // 3. Assert
        expect(impact, isNull);
        gate.complete();
        await first;
      },
    );

    test('Sad Path: a failure returns an Err with its failure', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(const Failure.serverRefusal('Grupo não encontrado.'));

      // 2. Act
      final impact = await controller.deletionImpact.execute('01');

      // 3. Assert
      expect(impact, isA<Err<Object?>>());
      expect(
        controller.state.failure,
        const Failure.serverRefusal('Grupo não encontrado.'),
      );
    });
  });

  group('GroupsViewModel.remove - Unit Test Suite', () {
    test('Happy Path: the person is removed and the groups reloaded', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final result = await controller.remove.execute((
        groupId: '01',
        email: 'ana@x.com',
      ));

      // 3. Assert
      expect(result, isA<Ok<void>>());
      verifyInOrder([
        repository.remove('rotasul', '01', 'ana@x.com'),
        repository.list('rotasul'),
      ]);
      verifyNoMoreInteractions(repository);
    });

    test('Edge Case: an unexpected error gives a generic message', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(_generic);

      // 2. Act
      final result = await controller.remove.execute((
        groupId: '01',
        email: 'ana@x.com',
      ));

      // 3. Assert
      expect(result, isA<Err<void>>());
      expect(controller.state.failure, _generic);
    });

    test('Sad Path: a refused removal does not reload the groups', () async {
      // 1. Arrange
      final controller = await loadedController();
      writesFail(const Failure.serverRefusal('Essa pessoa não está no grupo.'));

      // 2. Act
      final result = await controller.remove.execute((
        groupId: '01',
        email: 'vera@x.com',
      ));

      // 3. Assert
      expect(result, isA<Err<void>>());
      verify(repository.remove('rotasul', '01', 'vera@x.com')).called(1);
      verifyNoMoreInteractions(repository);
      expect(
        controller.state.failure,
        const Failure.serverRefusal('Essa pessoa não está no grupo.'),
      );
    });
  });

  group('GroupsViewModel.load (more cases) - Unit Test Suite', () {
    test('Edge Case: load runs while the groups are read', () async {
      // 1. Arrange
      final gate = Completer<List<Group>>();
      when(repository.list(any)).thenAnswer((_) async => Ok(await gate.future));
      final controller = newController();

      // 2. Act
      final pending = controller.load.execute();

      // 3. Assert
      expect(controller.load.running, isTrue);
      gate.complete([norte]);
      await pending;
      expect(controller.load.running, isFalse);
    });

    test('Edge Case: an organization with no group loads an empty '
        'list', () async {
      // 1. Arrange
      when(repository.list(any)).thenAnswer((_) async => const Ok(<Group>[]));
      final controller = newController();

      // 2. Act
      await controller.load.execute();

      // 3. Assert
      expect(controller.state.groups, isEmpty);
      expect(controller.state.failure, isNull);
    });

    test('Edge Case: a second load while one runs reads nothing', () async {
      // 1. Arrange
      final gate = Completer<List<Group>>();
      when(repository.list(any)).thenAnswer((_) async => Ok(await gate.future));
      final controller = newController();
      final first = controller.load.execute();

      // 2. Act
      await controller.load.execute();

      // 3. Assert
      verify(repository.list(any)).called(1);
      gate.complete([norte]);
      await first;
    });

    test('Sad Path: an unexpected error shows a generic message', () async {
      // 1. Arrange
      when(repository.list(any)).thenAnswer(
        (_) async => Err(
          const Failure.load(LoadTarget.groups),
          error: StateError('offline'),
        ),
      );
      final controller = newController();

      // 2. Act
      await controller.load.execute();

      // 3. Assert
      expect(controller.state.failure, isNotNull);
      expect(controller.state.failure, isNot(contains('offline')));
      expect(controller.load.running, isFalse);
    });
  });

  group('GroupsViewModel (listeners) - Unit Test Suite', () {
    test(
      'Happy Path: a load that changes the groups notifies the view '
      'model once (groups) and the command twice (started, finished)',
      () async {
        // 1. Arrange
        final controller = newController();
        var notifications = 0;
        final running = <bool>[];
        controller.addListener(() => notifications++);
        controller.load.addListener(() => running.add(controller.load.running));

        // 2. Act
        await controller.load.execute();

        // 3. Assert
        expect(notifications, 1);
        expect(running, [true, false]);
      },
    );

    test('Edge Case: reloading groups equal by content does not notify the '
        'view model', () async {
      // 1. Arrange
      // Fresh objects on every read, as the repository builds them from JSON.
      when(repository.list(any)).thenAnswer(
        (_) async => Ok([
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
        ]),
      );
      final controller = newController();
      await controller.load.execute();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.load.execute();

      // 3. Assert
      expect(notifications, 0);
    });

    test('Sad Path: roles refused locally notify once with the '
        'problem', () async {
      // 1. Arrange
      final controller = await loadedController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      // 2. Act
      await controller.setRoles.execute((
        groupId: '01',
        email: 'ana@x.com',
        roles: {},
      ));

      // 3. Assert
      expect(notifications, 1);
    });

    test('Sad Path: a load finishing after dispose notifies nobody and does '
        'not throw', () async {
      // 1. Arrange
      final gate = Completer<List<Group>>();
      when(repository.list(any)).thenAnswer((_) async => Ok(await gate.future));
      final controller = newController();
      var notifications = 0;
      final pending = controller.load.execute();
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
      final pending = controller.create.execute('Equipe Serra');
      controller.addListener(() => notifications++);
      controller.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(
        pending,
        completion(isA<Ok<Group>>().having((ok) => ok.value, 'value', serra)),
      );
      expect(notifications, 0);
    });
  });

  group('GroupsViewModel.deleted - Unit Test Suite', () {
    test('Happy Path: deleting keeps the group and the count its impact '
        'read', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);
      await controller.deletionImpact.execute('01');

      // 2. Act
      await controller.delete.execute('01');

      // 3. Assert
      expect(
        controller.state.deleted,
        const DeletedGroup(id: '01', name: 'Equipe Norte', loses: 1),
      );
    });

    test('Edge Case: no deleted group before one is deleted', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);

      // 2. Act
      await controller.deletionImpact.execute('01');

      // 3. Assert
      expect(controller.state.deleted, isNull);
    });

    test('Edge Case: an impact read for another group counts nobody', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);
      await controller.deletionImpact.execute('03');

      // 2. Act
      await controller.delete.execute('01');

      // 3. Assert
      expect(
        controller.state.deleted,
        const DeletedGroup(id: '01', name: 'Equipe Norte', loses: 0),
      );
    });

    test(
      'Edge Case: deleting without reading the impact counts nobody',
      () async {
        // 1. Arrange
        final controller = await loadedController(isAdmin: true);

        // 2. Act
        await controller.delete.execute('03');

        // 3. Assert
        expect(
          controller.state.deleted,
          const DeletedGroup(id: '03', name: 'Equipe Léste', loses: 0),
        );
      },
    );

    test('Sad Path: a failed delete leaves no deleted group', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);
      await controller.deletionImpact.execute('01');
      writesFail(const Failure.serverRefusal('Equipe não encontrada.'));

      // 2. Act
      await controller.delete.execute('01');

      // 3. Assert
      expect(controller.state.deleted, isNull);
    });
  });

  group('GroupsViewModel (name helpers) - Unit Test Suite', () {
    test('Happy Path: a new valid name may be created', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);

      // 2. Act & 3. Assert
      expect(controller.newNameProblem('Equipe Serra'), isNull);
      expect(controller.canCreate('  Equipe Serra  '), isTrue);
    });

    test('Edge Case: an empty or blank name says nothing but cannot be '
        'created', () async {
      // 1. Arrange
      final controller = await loadedController(isAdmin: true);

      // 2. Act & 3. Assert
      expect(controller.newNameProblem(''), isNull);
      expect(controller.newNameProblem('   '), isNull);
      expect(controller.canCreate(''), isFalse);
      expect(controller.canCreate('   '), isFalse);
    });

    test(
      'Sad Path: a short or taken name says why and cannot be created',
      () async {
        // 1. Arrange
        final controller = await loadedController(isAdmin: true);

        // 2. Act & 3. Assert
        expect(
          controller.newNameProblem('A'),
          const Failure.groupNameTooShort(),
        );
        expect(controller.canCreate('A'), isFalse);
        expect(
          controller.newNameProblem('equipe norte'),
          const Failure.groupNameTaken('Equipe Norte'),
        );
        expect(controller.canCreate('equipe norte'), isFalse);
      },
    );

    test('Happy Path: tidyName keeps single spaces and trims', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act & 3. Assert
      expect(controller.tidyName('  Equipe \t  Sul \n'), 'Equipe Sul');
      expect(controller.tidyName('   '), '');
    });

    test('Happy Path: a group may be renamed to a new valid name', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act & 3. Assert
      expect(controller.renameProblem(norte, 'Equipe  Sul'), isNull);
      expect(controller.canRename(norte, ' Equipe  Sul '), isTrue);
    });

    test('Edge Case: its own name has no problem but is no rename', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act & 3. Assert
      expect(controller.renameProblem(norte, ' Equipe   Norte '), isNull);
      expect(controller.canRename(norte, ' Equipe   Norte '), isFalse);
    });

    test('Edge Case: an empty name says nothing and is no rename', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act & 3. Assert
      expect(controller.renameProblem(norte, '  '), isNull);
      expect(controller.canRename(norte, '  '), isFalse);
    });

    test("Sad Path: another group's name or a short one says why", () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act & 3. Assert
      expect(
        controller.renameProblem(norte, 'Equipe Leste'),
        const Failure.groupNameTaken('Equipe Léste'),
      );
      expect(controller.canRename(norte, 'Equipe Leste'), isFalse);
      expect(
        controller.renameProblem(norte, 'X'),
        const Failure.groupNameTooShort(),
      );
      expect(controller.canRename(norte, 'X'), isFalse);
    });
  });

  group('GroupsViewModel (roles helpers) - Unit Test Suite', () {
    const person = GroupPerson(
      email: 'ana@x.com',
      roles: {GroupRole.publisher},
    );

    test('Happy Path: different valid roles may be set', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act & 3. Assert
      final roles = {GroupRole.publisher, GroupRole.subscriber};
      expect(controller.rolesProblem(roles), isNull);
      expect(controller.canSetRoles(person, roles), isTrue);
    });

    test('Edge Case: the same roles are no change', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act & 3. Assert
      expect(controller.canSetRoles(person, {GroupRole.publisher}), isFalse);
    });

    test('Sad Path: no roles says why and cannot be set', () async {
      // 1. Arrange
      final controller = newController();

      // 2. Act & 3. Assert
      expect(controller.rolesProblem({}), const Failure.noRoleChosen());
      expect(controller.canSetRoles(person, {}), isFalse);
    });

    test('Sad Path: only Gestor do grupo is enough for an administrator, '
        'not for a maintainer', () async {
      // 1. Arrange
      final admin = GroupsViewModel(
        organizationId: 'rotasul',
        repository: repository,
        isAdmin: true,
      );
      final maintainer = newController();

      // 2. Act & 3. Assert
      expect(admin.rolesProblem({GroupRole.maintainer}), isNull);
      expect(admin.canSetRoles(person, {GroupRole.maintainer}), isTrue);
      expect(
        maintainer.rolesProblem({GroupRole.maintainer}),
        const Failure.noRoleChosen(),
      );
      expect(maintainer.canSetRoles(person, {GroupRole.maintainer}), isFalse);
    });
  });
}
