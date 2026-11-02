import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository_remote.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<CentralFunctionsService>()])
import 'groups_repository_remote_test.mocks.dart';

const _connection =
    'Não foi possível concluir agora. Verifique a conexão e tente de novo.';

late MockCentralFunctionsService functions;
late GroupsRepositoryRemote repository;

/// Makes function [name] answer [data].
void answers(String name, Object? data) => when(
  functions.call(name, any, timeout: anyNamed('timeout')),
).thenAnswer((_) async => data);

/// Makes function [name] fail with [error].
void fails(String name, Object error) => when(
  functions.call(name, any, timeout: anyNamed('timeout')),
).thenAnswer((_) async => throw error);

/// The data function [name] was called with, verifying one call.
Object? sentTo(String name) => verify(
  functions.call(name, captureAny, timeout: anyNamed('timeout')),
).captured.single;

/// The message of [result], failing when it is an [Ok].
String messageOf(Result<Object?> result) => switch (result) {
  Err(:final message) => message,
  Ok() => fail('expected an Err, got $result'),
};

/// The value of [result], failing when it is an [Err].
T valueOf<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err() => fail('expected an Ok, got $result'),
};

void main() {
  setUp(() {
    functions = MockCentralFunctionsService();
    repository = GroupsRepositoryRemote(functions: functions);
  });

  group('GroupsRepositoryRemote.list - Unit Test Suite', () {
    test('Happy Path: sends the organization and parses each group', () async {
      // 1. Arrange
      answers('listGroups', {
        'groups': [
          {
            'id': '01',
            'name': 'Equipe Norte',
            'createdAt': '2026-10-01T00:00:00.000Z',
            'people': [
              {
                'email': 'ana@x.com',
                'roles': ['publisher', 'subscriber'],
              },
            ],
          },
          {'id': '02', 'name': 'Equipe Serra'},
        ],
      });

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(sentTo('listGroups'), {'organizationId': 'rotasul'});
      expect(valueOf(result), [
        Group(
          id: '01',
          name: 'Equipe Norte',
          people: const [
            GroupPerson(
              email: 'ana@x.com',
              roles: {GroupRole.publisher, GroupRole.subscriber},
            ),
          ],
          createdAt: DateTime.utc(2026, 10, 1),
        ),
        const Group(id: '02', name: 'Equipe Serra', people: []),
      ]);
    });

    test('Edge Case: malformed entries are skipped', () async {
      // 1. Arrange
      answers('listGroups', {
        'groups': [
          'not a map',
          {'id': '', 'name': 'Sem id'},
          {'id': '03', 'name': 'Equipe Leste'},
        ],
      });

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(valueOf(result).map((g) => g.id), ['03']);
    });

    test('Edge Case: an answer without a list of groups is no group', () async {
      // 1. Arrange
      answers('listGroups', null);

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(valueOf(result), isEmpty);
    });

    test('Sad Path: a permission-denied refusal gives the server\'s own '
        'words', () async {
      // 1. Arrange
      fails(
        'listGroups',
        const FunctionsFailure('permission-denied', 'Sem permissão.'),
      );

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(messageOf(result), 'Sem permissão.');
    });

    test('Sad Path: an unexpected error gives the load message and keeps the '
        'error', () async {
      // 1. Arrange
      final error = StateError('offline');
      fails('listGroups', error);

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(messageOf(result), 'Não foi possível carregar os grupos.');
      final err = result as Err;
      expect(err.error, same(error));
      expect(err.stackTrace, isNotNull);
    });
  });

  group('GroupsRepositoryRemote.create - Unit Test Suite', () {
    test(
      'Happy Path: sends the name and returns the new, empty group',
      () async {
        // 1. Arrange
        answers('createGroup', {'id': '04', 'name': 'Equipe Mar'});

        // 2. Act
        final result = await repository.create('rotasul', 'Equipe Mar');

        // 3. Assert
        expect(sentTo('createGroup'), {
          'organizationId': 'rotasul',
          'name': 'Equipe Mar',
        });
        expect(
          valueOf(result),
          const Group(id: '04', name: 'Equipe Mar', people: []),
        );
      },
    );

    test('Edge Case: the group starts with nobody even if the answer names '
        'people', () async {
      // 1. Arrange
      answers('createGroup', {
        'id': '04',
        'name': 'Equipe Mar',
        'people': [
          {
            'email': 'ana@x.com',
            'roles': ['publisher'],
          },
        ],
      });

      // 2. Act
      final result = await repository.create('rotasul', 'Equipe Mar');

      // 3. Assert
      expect(valueOf(result).people, isEmpty);
    });

    test(
      'Sad Path: an answer with no group id is an unexpected answer',
      () async {
        // 1. Arrange
        answers('createGroup', {'name': 'Equipe Mar'});

        // 2. Act
        final result = await repository.create('rotasul', 'Equipe Mar');

        // 3. Assert
        expect(messageOf(result), 'Resposta inesperada ao criar o grupo.');
      },
    );

    test('Sad Path: a failed-precondition refusal gives the server\'s own '
        'words', () async {
      // 1. Arrange
      fails(
        'createGroup',
        const FunctionsFailure(
          'failed-precondition',
          'Já existe o grupo Equipe Mar.',
        ),
      );

      // 2. Act
      final result = await repository.create('rotasul', 'Equipe Mar');

      // 3. Assert
      expect(messageOf(result), 'Já existe o grupo Equipe Mar.');
    });

    test('Sad Path: an unexpected error gives the connection hint', () async {
      // 1. Arrange
      fails('createGroup', Exception('socket closed'));

      // 2. Act
      final result = await repository.create('rotasul', 'Equipe Mar');

      // 3. Assert
      expect(messageOf(result), _connection);
    });
  });

  group('GroupsRepositoryRemote.deletionImpact - Unit Test Suite', () {
    test('Happy Path: returns who loses access and who stays', () async {
      // 1. Arrange
      answers('groupDeletionImpact', {
        'loses': ['ana@x.com'],
        'stays': ['rui@x.com', 'vera@x.com'],
      });

      // 2. Act
      final result = await repository.deletionImpact('rotasul', '01');

      // 3. Assert
      expect(sentTo('groupDeletionImpact'), {
        'organizationId': 'rotasul',
        'groupId': '01',
      });
      final impact = valueOf(result);
      expect(impact.loses, ['ana@x.com']);
      expect(impact.stays, ['rui@x.com', 'vera@x.com']);
    });

    test('Edge Case: missing lists and non-text entries read as '
        'nobody', () async {
      // 1. Arrange
      answers('groupDeletionImpact', {
        'loses': [42, 'ana@x.com', null],
      });

      // 2. Act
      final result = await repository.deletionImpact('rotasul', '01');

      // 3. Assert
      final impact = valueOf(result);
      expect(impact.loses, ['ana@x.com']);
      expect(impact.stays, isEmpty);
    });

    test('Sad Path: a not-found refusal gives the connection hint, not the '
        'server\'s words', () async {
      // 1. Arrange
      fails(
        'groupDeletionImpact',
        const FunctionsFailure('not-found', 'Grupo não encontrado.'),
      );

      // 2. Act
      final result = await repository.deletionImpact('rotasul', '01');

      // 3. Assert
      expect(messageOf(result), _connection);
    });
  });

  group('GroupsRepositoryRemote (writes) - Unit Test Suite', () {
    final writes = <String, (Future<Result<void>> Function(), Object)>{
      'renameGroup': (
        () => repository.rename('rotasul', '01', 'Guias Norte'),
        {'organizationId': 'rotasul', 'groupId': '01', 'name': 'Guias Norte'},
      ),
      'deleteGroup': (
        () => repository.delete('rotasul', '01'),
        {'organizationId': 'rotasul', 'groupId': '01'},
      ),
      'setMemberRoles': (
        () => repository.setRoles('rotasul', '01', 'ana@x.com', {
          GroupRole.publisher,
          GroupRole.maintainer,
        }),
        {
          'organizationId': 'rotasul',
          'groupId': '01',
          'email': 'ana@x.com',
          'roles': ['publisher', 'maintainer'],
        },
      ),
      'removeMember': (
        () => repository.remove('rotasul', '01', 'ana@x.com'),
        {'organizationId': 'rotasul', 'groupId': '01', 'email': 'ana@x.com'},
      ),
    };

    for (final MapEntry(key: name, value: (write, payload)) in writes.entries) {
      test(
        'Happy Path: $name is sent with its payload and returns Ok',
        () async {
          // 1. Arrange
          answers(name, {'ok': true});

          // 2. Act
          final result = await write();

          // 3. Assert
          expect(result, isA<Ok<void>>());
          expect(sentTo(name), payload);
          verifyNoMoreInteractions(functions);
        },
      );

      test('Sad Path: an invalid-argument refusal of $name gives the '
          'server\'s own words', () async {
        // 1. Arrange
        fails(
          name,
          const FunctionsFailure('invalid-argument', 'Nome inválido.'),
        );

        // 2. Act
        final result = await write();

        // 3. Assert
        expect(messageOf(result), 'Nome inválido.');
        expect((result as Err).error, isA<FunctionsFailure>());
      });

      test('Sad Path: an unavailable refusal of $name gives the connection '
          'hint', () async {
        // 1. Arrange
        fails(name, const FunctionsFailure('unavailable', 'Try later.'));

        // 2. Act
        final result = await write();

        // 3. Assert
        expect(messageOf(result), _connection);
      });
    }

    test('Edge Case: a refusal the server did not explain gives the generic '
        'fallback', () async {
      // 1. Arrange
      fails('removeMember', const FunctionsFailure('permission-denied', null));

      // 2. Act
      final result = await repository.remove('rotasul', '01', 'ana@x.com');

      // 3. Assert
      expect(messageOf(result), 'Não foi possível concluir.');
    });
  });
}
