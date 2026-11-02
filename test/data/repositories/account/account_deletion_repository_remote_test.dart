import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository_remote.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([MockSpec<CentralFunctionsService>()])
import 'account_deletion_repository_remote_test.mocks.dart';

late MockCentralFunctionsService functions;
late AccountDeletionRepositoryRemote repository;

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

String messageOf(Result<Object?> result) => switch (result) {
  Err(:final message) => message,
  Ok() => fail('expected an Err, got $result'),
};

T valueOf<T>(Result<T> result) => switch (result) {
  Ok(:final value) => value,
  Err() => fail('expected an Ok, got $result'),
};

const _deletionJson = {
  'deleteAt': '2026-12-02T12:00:00.000Z',
  'ownedOrganizationIds': ['rotasul'],
  'ownedOrganizationNames': {'rotasul': 'Rota Sul'},
};

final _deletion = AccountDeletion(
  deleteAt: DateTime.utc(2026, 12, 2, 12),
  ownedOrganizationIds: const ['rotasul'],
  ownedOrganizationNames: const {'rotasul': 'Rota Sul'},
);

void main() {
  setUp(() {
    functions = MockCentralFunctionsService();
    repository = AccountDeletionRepositoryRemote(functions: functions);
  });

  group('AccountDeletionRepositoryRemote.request - Unit Test Suite', () {
    test('Happy Path: sends the ids to confirm and parses the '
        'deletion', () async {
      // 1. Arrange
      answers('requestAccountDeletion', _deletionJson);

      // 2. Act
      final result = await repository.request(confirmIds: ['rotasul']);

      // 3. Assert
      expect(sentTo('requestAccountDeletion'), {
        'confirmIds': ['rotasul'],
      });
      expect(valueOf(result), _deletion);
    });

    test('Edge Case: a member confirms no id', () async {
      // 1. Arrange
      answers('requestAccountDeletion', _deletionJson);

      // 2. Act
      await repository.request();

      // 3. Assert
      expect(sentTo('requestAccountDeletion'), {'confirmIds': <String>[]});
    });

    test('Sad Path: an answer that is not a deletion is an unexpected '
        'answer', () async {
      // 1. Arrange
      answers('requestAccountDeletion', {'deleteAt': 'soon'});

      // 2. Act
      final result = await repository.request();

      // 3. Assert
      expect(messageOf(result), 'Resposta inesperada do servidor.');
    });

    test('Sad Path: a failed-precondition refusal gives the server\'s own '
        'words', () async {
      // 1. Arrange
      fails(
        'requestAccountDeletion',
        const FunctionsFailure(
          'failed-precondition',
          'Confirme a organização pelo identificador.',
        ),
      );

      // 2. Act
      final result = await repository.request();

      // 3. Assert
      expect(messageOf(result), 'Confirme a organização pelo identificador.');
    });

    test('Edge Case: a failed-precondition refusal with no words gives the '
        'account fallback', () async {
      // 1. Arrange
      fails(
        'requestAccountDeletion',
        const FunctionsFailure('failed-precondition', null),
      );

      // 2. Act
      final result = await repository.request();

      // 3. Assert
      expect(messageOf(result), 'Não foi possível agora.');
    });

    test('Sad Path: an invalid-argument refusal is not explained to the '
        'person: it gives the connection hint', () async {
      // 1. Arrange
      fails(
        'requestAccountDeletion',
        const FunctionsFailure('invalid-argument', 'confirmIds must be a list'),
      );

      // 2. Act
      final result = await repository.request();

      // 3. Assert
      expect(
        messageOf(result),
        'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
      );
    });

    test('Sad Path: an unexpected error gives the delete hint', () async {
      // 1. Arrange
      fails('requestAccountDeletion', StateError('offline'));

      // 2. Act
      final result = await repository.request();

      // 3. Assert
      expect(
        messageOf(result),
        'Não foi possível excluir agora. Verifique a conexão e tente de novo.',
      );
    });
  });

  group('AccountDeletionRepositoryRemote.cancel - Unit Test Suite', () {
    test('Happy Path: calls cancelAccountDeletion with no data', () async {
      // 1. Arrange
      answers('cancelAccountDeletion', null);

      // 2. Act
      final result = await repository.cancel();

      // 3. Assert
      expect(result, isA<Ok<void>>());
      expect(sentTo('cancelAccountDeletion'), isEmpty);
    });

    test('Sad Path: an unexpected error gives the cancel hint', () async {
      // 1. Arrange
      fails('cancelAccountDeletion', Exception('offline'));

      // 2. Act
      final result = await repository.cancel();

      // 3. Assert
      expect(
        messageOf(result),
        'Não foi possível cancelar agora. Verifique a conexão e tente de '
        'novo.',
      );
    });
  });

  group('AccountDeletionRepositoryRemote.pending - Unit Test Suite', () {
    test('Happy Path: parses the pending deletion', () async {
      // 1. Arrange
      answers('myAccountDeletion', {'deletion': _deletionJson});

      // 2. Act
      final result = await repository.pending();

      // 3. Assert
      expect(sentTo('myAccountDeletion'), isEmpty);
      expect(valueOf(result), _deletion);
    });

    test('Edge Case: no deletion is null', () async {
      // 1. Arrange
      answers('myAccountDeletion', {'deletion': null});

      // 2. Act
      final result = await repository.pending();

      // 3. Assert
      expect(valueOf(result), isNull);
    });

    test('Sad Path: an unexpected error gives the read message', () async {
      // 1. Arrange
      final error = StateError('offline');
      fails('myAccountDeletion', error);

      // 2. Act
      final result = await repository.pending();

      // 3. Assert
      expect(messageOf(result), 'Não foi possível ler a exclusão da conta.');
      expect((result as Err).error, same(error));
    });
  });
}
