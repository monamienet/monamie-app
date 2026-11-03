import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository_remote.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<CentralFunctionsService>()])
import 'creation_repository_remote_test.mocks.dart';

/// Creating a project takes longer than the other calls.
const _timeout = Duration(seconds: 90);

late MockCentralFunctionsService functions;
late CreationRepositoryRemote repository;

/// Makes function [name] answer [data].
void answers(String name, Object? data) => when(
  functions.call(name, any, timeout: anyNamed('timeout')),
).thenAnswer((_) async => data);

/// Makes function [name] fail with [error].
void fails(String name, Object error) => when(
  functions.call(name, any, timeout: anyNamed('timeout')),
).thenAnswer((_) async => throw error);

/// The data and timeout function [name] was called with, verifying one
/// call.
({Object? data, Object? timeout}) sentTo(String name) {
  final captured = verify(
    functions.call(name, captureAny, timeout: captureAnyNamed('timeout')),
  ).captured;
  expect(captured, hasLength(2), reason: '$name called once');
  return (data: captured[0], timeout: captured[1]);
}

Failure failureOf(Result<Object?> result) => switch (result) {
  Err(:final failure) => failure,
  Ok() => fail('expected an Err, got $result'),
};

T valueOf<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err() => fail('expected an Ok, got $result'),
};

Future<Result<String>> createRotaSul() => repository.create(
  id: 'rotasul',
  name: 'Rota Sul',
  themeId: 'oceano',
  plan: 'community',
);

void main() {
  setUp(() {
    functions = MockCentralFunctionsService();
    repository = CreationRepositoryRemote(functions: functions);
  });

  group('CreationRepositoryRemote.idProblem - Unit Test Suite', () {
    test('Happy Path: an available id has no problem, asked with the long '
        'timeout', () async {
      // 1. Arrange
      answers('checkOrganizationId', {'available': true});

      // 2. Act
      final result = await repository.idProblem('rotasul');

      // 3. Assert
      final sent = sentTo('checkOrganizationId');
      expect(sent.data, {'id': 'rotasul'});
      expect(sent.timeout, _timeout);
      expect(valueOf(result), isNull);
    });

    test('Happy Path: a taken id returns the server\'s problem', () async {
      // 1. Arrange
      answers('checkOrganizationId', {
        'available': false,
        'problem': 'Esse identificador já está em uso.',
      });

      // 2. Act
      final result = await repository.idProblem('rotasul');

      // 3. Assert
      expect(
        valueOf(result),
        const Failure.serverRefusal('Esse identificador já está em uso.'),
      );
    });

    test('Edge Case: an unavailable id with no problem gets a generic '
        'one', () async {
      // 1. Arrange
      answers('checkOrganizationId', null);

      // 2. Act
      final result = await repository.idProblem('rotasul');

      // 3. Assert
      expect(
        valueOf(result),
        const Failure.organizationId(OrganizationIdProblem.unusable),
      );
    });

    test('Sad Path: an unexpected error gives the check message', () async {
      // 1. Arrange
      fails('checkOrganizationId', StateError('offline'));

      // 2. Act
      final result = await repository.idProblem('rotasul');

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.load(LoadTarget.organizationIdCheck),
      );
    });
  });

  group('CreationRepositoryRemote.create - Unit Test Suite', () {
    test('Happy Path: sends the choices with the long timeout and returns the '
        'status', () async {
      // 1. Arrange
      answers('createOrganization', {'status': 'active'});

      // 2. Act
      final result = await createRotaSul();

      // 3. Assert
      final sent = sentTo('createOrganization');
      expect(sent.data, {
        'id': 'rotasul',
        'name': 'Rota Sul',
        'themeId': 'oceano',
        'plan': 'community',
      });
      expect(sent.timeout, _timeout);
      expect(valueOf(result), 'active');
    });

    test('Edge Case: an answer without a status reads as failed', () async {
      // 1. Arrange
      answers('createOrganization', {'status': 3});

      // 2. Act
      final result = await createRotaSul();

      // 3. Assert
      expect(valueOf(result), 'failed');
    });

    for (final code in ['invalid-argument', 'failed-precondition']) {
      test('Sad Path: a $code refusal gives the server\'s own words', () async {
        // 1. Arrange
        fails(
          'createOrganization',
          FunctionsFailure(code, 'Esse identificador já está em uso.'),
        );

        // 2. Act
        final result = await createRotaSul();

        // 3. Assert
        expect(
          failureOf(result),
          const Failure.serverRefusal('Esse identificador já está em uso.'),
        );
      });
    }

    test('Edge Case: an explained refusal with no words gives the creation '
        'fallback', () async {
      // 1. Arrange
      fails(
        'createOrganization',
        const FunctionsFailure('invalid-argument', null),
      );

      // 2. Act
      final result = await createRotaSul();

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.unexplainedRefusal(RefusedAction.create),
      );
    });

    test('Sad Path: a permission-denied refusal is not explained here: it '
        'gives the connection hint', () async {
      // 1. Arrange
      fails(
        'createOrganization',
        const FunctionsFailure('permission-denied', 'No.'),
      );

      // 2. Act
      final result = await createRotaSul();

      // 3. Assert
      expect(
        failureOf(result),
        const Failure.connection(FailedAction.conclude),
      );
    });

    test('Sad Path: an unexpected error gives the create hint', () async {
      // 1. Arrange
      fails('createOrganization', Exception('offline'));

      // 2. Act
      final result = await createRotaSul();

      // 3. Assert
      expect(failureOf(result), const Failure.connection(FailedAction.create));
    });
  });

  group('CreationRepositoryRemote.mine - Unit Test Suite', () {
    test('Happy Path: parses the creations, skipping malformed ones, with '
        'the long timeout', () async {
      // 1. Arrange
      answers('myCreations', {
        'creations': [
          {
            'id': 'rotasul',
            'name': 'Rota Sul',
            'plan': 'community',
            'status': 'provisioning',
          },
          {'id': 'frota', 'name': 'Frota'},
          {
            'id': 'verdemar',
            'name': 'Verde Mar',
            'status': 'failed',
            'failureStep': 'project',
          },
        ],
      });

      // 2. Act
      final result = await repository.mine();

      // 3. Assert
      final sent = sentTo('myCreations');
      expect(sent.data, isEmpty);
      expect(sent.timeout, _timeout);
      final creations = valueOf(result);
      expect(creations.map((c) => c.id), ['rotasul', 'verdemar']);
      expect(creations.first.plan, 'community');
      expect(creations.last.plan, 'standard');
      expect(creations.last.failureStep, 'project');
    });

    test('Sad Path: an unexpected error gives the load message', () async {
      // 1. Arrange
      fails('myCreations', StateError('offline'));

      // 2. Act
      final result = await repository.mine();

      // 3. Assert
      expect(failureOf(result), const Failure.load(LoadTarget.creations));
    });
  });
}
