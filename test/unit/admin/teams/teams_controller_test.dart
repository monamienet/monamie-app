import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/admin/teams/team.dart';
import 'package:monamie_app/app/modules/admin/teams/teams_backend.dart';
import 'package:monamie_app/app/modules/admin/teams/teams_controller.dart';

const norte = Team(
  number: '01',
  key: 'rotasul01',
  name: 'Equipe Norte',
  people: [],
);
const leste = Team(
  number: '03',
  key: 'rotasul03',
  name: 'Equipe Léste',
  people: [],
);
const serra = Team(
  number: '02',
  key: 'rotasul02',
  name: 'Equipe Serra',
  people: [],
);

/// [TeamsBackend] that records every call, returns [teams] from `list`,
/// optionally waits on [gate] and fails with [failure] in the writes.
class FakeTeamsBackend implements TeamsBackend {
  final calls = <String>[];
  List<Team> teams = [norte, leste];
  Completer<void>? gate;
  Object? failure;

  Future<void> _write(String call) async {
    calls.add(call);
    await gate?.future;
    if (failure case final failure?) throw failure;
  }

  @override
  Future<List<Team>> list(String partnerId) async {
    calls.add('list:$partnerId');
    return teams;
  }

  @override
  Future<Team> create(String partnerId, String name) async {
    await _write('create:$partnerId:$name');
    return serra;
  }

  @override
  Future<void> rename(String partnerId, String team, String name) =>
      _write('rename:$partnerId:$team:$name');

  @override
  Future<({List<String> loses, List<String> stays})> deletionImpact(
    String partnerId,
    String team,
  ) async {
    await _write('deletionImpact:$partnerId:$team');
    return (loses: ['ana@x.com'], stays: <String>[]);
  }

  @override
  Future<void> delete(String partnerId, String team) =>
      _write('delete:$partnerId:$team');

  @override
  Future<void> setRoles(
    String partnerId,
    String team,
    String email,
    Set<TeamRole> roles,
  ) => _write(
    'setRoles:$partnerId:$team:$email:${(roles.map((r) => r.name).toList()..sort()).join(',')}',
  );

  @override
  Future<void> remove(String partnerId, String team, String email) =>
      _write('remove:$partnerId:$team:$email');
}

late FakeTeamsBackend backend;

/// A started controller for Rota Sul with [norte] and [leste] loaded and
/// the backend's call log cleared.
Future<TeamsController> loadedController() async {
  final controller = TeamsController(partnerId: 'rotasul', backend: backend);
  controller.onStart();
  await pumpEventQueue();
  backend.calls.clear();
  return controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
    backend = FakeTeamsBackend();
  });

  group('TeamsController.onInit - Unit Test Suite', () {
    test('Happy Path: starting loads the partner teams', () async {
      // 1. Arrange
      final controller = TeamsController(
        partnerId: 'rotasul',
        backend: backend,
      );

      // 2. Act
      controller.onStart();
      await pumpEventQueue();

      // 3. Assert
      expect(backend.calls, ['list:rotasul']);
      expect(controller.teams, [norte, leste]);
      expect(controller.isLoading.value, isFalse);
    });

    test('Edge Case: no teams read "0 de 99"', () async {
      // 1. Arrange
      backend.teams = [];

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
        final controller = TeamsController(
          partnerId: 'rotasul',
          backend: backend,
        );

        // 2. Act
        controller.onStart();
        await pumpEventQueue();

        // 3. Assert
        expect(controller.errorMessage.value, 'Sem permissão.');
        expect(controller.teams, isEmpty);
        expect(controller.isLoading.value, isFalse);
      },
    );
  });

  group('TeamsController.countLabel - Unit Test Suite', () {
    test('Happy Path: two teams read "2 de 99"', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final label = controller.countLabel;

      // 3. Assert
      expect(label, '2 de 99');
    });
  });

  group('TeamsController.nameProblem - Unit Test Suite', () {
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
        expect(problem, 'Já existe a equipe Equipe Léste.');
      },
    );
  });

  group('TeamsController.create - Unit Test Suite', () {
    test('Happy Path: the created team is returned and added', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final created = await controller.create('Equipe Serra');

      // 3. Assert
      expect(created, serra);
      expect(controller.teams, [norte, leste, serra]);
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

    test('Sad Path: a TeamsException returns null with its message', () async {
      // 1. Arrange
      final controller = await loadedController();
      backend.failure = const TeamsException(
        'Já existe a equipe Equipe Serra.',
      );

      // 2. Act
      final created = await controller.create('Equipe Serra');

      // 3. Assert
      expect(created, isNull);
      expect(controller.errorMessage.value, 'Já existe a equipe Equipe Serra.');
      expect(controller.teams, [norte, leste]);
      expect(controller.isWorking.value, isFalse);
    });
  });

  group('TeamsController.setRoles - Unit Test Suite', () {
    test('Happy Path: roles are sent and the teams reloaded', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final ok = await controller.setRoles('01', 'ana@x.com', {
        TeamRole.share,
        TeamRole.watch,
      });

      // 3. Assert
      expect(ok, isTrue);
      expect(backend.calls, [
        'setRoles:rotasul:01:ana@x.com:share,watch',
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
          TeamRole.watch,
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

  group('TeamsController.delete - Unit Test Suite', () {
    test('Happy Path: the deleted team leaves the list', () async {
      // 1. Arrange
      final controller = await loadedController();

      // 2. Act
      final ok = await controller.delete('01');

      // 3. Assert
      expect(ok, isTrue);
      expect(controller.teams, [leste]);
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
      backend.failure = const TeamsException('Equipe não encontrada.');

      // 2. Act
      final ok = await controller.delete('01');

      // 3. Assert
      expect(ok, isFalse);
      expect(controller.teams, [norte, leste]);
      expect(controller.errorMessage.value, 'Equipe não encontrada.');
      expect(controller.isWorking.value, isFalse);
    });
  });
}

/// A backend whose `list` fails with a [TeamsException].
class _FailingListBackend extends FakeTeamsBackend {
  @override
  Future<List<Team>> list(String partnerId) async {
    calls.add('list:$partnerId');
    throw const TeamsException('Sem permissão.');
  }
}
