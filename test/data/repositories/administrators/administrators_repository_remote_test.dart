import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_repository_remote.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<CentralFunctionsService>()])
import 'administrators_repository_remote_test.mocks.dart';

late MockCentralFunctionsService functions;
late AdministratorsRepositoryRemote repository;

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

Failure failureOf(Result<Object?> result) => switch (result) {
  Err(:final failure) => failure,
  Ok() => fail('expected an Err, got $result'),
};

T valueOf<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err() => fail('expected an Ok, got $result'),
};

void main() {
  setUp(() {
    functions = MockCentralFunctionsService();
    repository = AdministratorsRepositoryRemote(functions: functions);
  });

  group('AdministratorsRepositoryRemote.list - Unit Test Suite', () {
    test('Happy Path: sends the organization and parses administrators and '
        'members', () async {
      // 1. Arrange
      answers('listAdministrators', {
        'administrators': [
          {'email': 'olga@x.com', 'owner': true},
          {'email': 'caio@x.com'},
        ],
        'members': [
          {'email': 'rui@x.com'},
        ],
      });

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(sentTo('listAdministrators'), {'organizationId': 'rotasul'});
      expect(
        valueOf(result),
        const OrganizationAdministrators(
          administrators: [
            Administrator(email: 'olga@x.com', owner: true),
            Administrator(email: 'caio@x.com'),
          ],
          members: ['rui@x.com'],
        ),
      );
    });

    test('Edge Case: an answer that is not a map is nobody', () async {
      // 1. Arrange
      answers('listAdministrators', 'unexpected');

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(valueOf(result), const OrganizationAdministrators());
    });

    test('Sad Path: a permission-denied refusal gives the server\'s own '
        'words', () async {
      // 1. Arrange
      fails(
        'listAdministrators',
        const FunctionsFailure(
          'permission-denied',
          'Só o titular escolhe os administradores.',
        ),
      );

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.serverRefusal('Só o titular escolhe os administradores.'),
      );
    });

    test('Sad Path: an unexpected error gives the load message', () async {
      // 1. Arrange
      fails('listAdministrators', StateError('offline'));

      // 2. Act
      final result = await repository.list('rotasul');

      // 3. Assert
      expect(failureOf(result), const Failure.load(LoadTarget.administrators));
    });
  });

  group('AdministratorsRepositoryRemote.setAdministrator - Unit Test '
      'Suite', () {
    for (final admin in [true, false]) {
      test('Happy Path: sends the e-mail and admin: $admin', () async {
        // 1. Arrange
        answers('setAdministrator', {'ok': true});

        // 2. Act
        final result = await repository.setAdministrator(
          'rotasul',
          'caio@x.com',
          admin: admin,
        );

        // 3. Assert
        expect(result, isA<Ok<void>>());
        expect(sentTo('setAdministrator'), {
          'organizationId': 'rotasul',
          'email': 'caio@x.com',
          'admin': admin,
        });
      });
    }

    test('Sad Path: a failed-precondition refusal gives the server\'s own '
        'words', () async {
      // 1. Arrange
      fails(
        'setAdministrator',
        const FunctionsFailure(
          'failed-precondition',
          'Essa pessoa não faz parte da organização.',
        ),
      );

      // 2. Act
      final result = await repository.setAdministrator(
        'rotasul',
        'rui@x.com',
        admin: true,
      );

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.serverRefusal(
          'Essa pessoa não faz parte da organização.',
        ),
      );
    });

    test('Sad Path: a deadline-exceeded refusal gives the connection '
        'hint', () async {
      // 1. Arrange
      fails(
        'setAdministrator',
        const FunctionsFailure('deadline-exceeded', 'Timed out.'),
      );

      // 2. Act
      final result = await repository.setAdministrator(
        'rotasul',
        'rui@x.com',
        admin: true,
      );

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.connection(FailedAction.conclude),
      );
    });

    test('Sad Path: an unexpected error gives the connection hint', () async {
      // 1. Arrange
      fails('setAdministrator', Exception('offline'));

      // 2. Act
      final result = await repository.setAdministrator(
        'rotasul',
        'rui@x.com',
        admin: false,
      );

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.connection(FailedAction.conclude),
      );
    });
  });
}
