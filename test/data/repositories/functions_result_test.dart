import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/repositories/functions_result.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/utils/result.dart';

const _otherwise =
    'Não foi possível concluir agora. Verifique a conexão e tente de novo.';

/// Runs [operation] through [functionsResult] with a refusal that prefixes
/// the code, so the test can tell which branch produced the message.
Future<Result<int>> run(Future<Result<int>> Function() operation) =>
    functionsResult(
      operation,
      refusal: (failure) => 'refused: ${failure.code}',
      unexpected: 'unexpected',
      logTag: 'Test',
    );

void main() {
  group('functionsFailureMessage - Unit Test Suite', () {
    for (final code in [
      'invalid-argument',
      'failed-precondition',
      'permission-denied',
    ]) {
      test('Happy Path: by default $code gives the server\'s own words', () {
        // 1. Arrange
        final failure = FunctionsFailure(code, 'Nome inválido.');

        // 2. Act
        final message = functionsFailureMessage(failure);

        // 3. Assert
        expect(message, 'Nome inválido.');
      });
    }

    test('Edge Case: an explained code with no words gives the '
        'fallback', () {
      // 1. Arrange
      const failure = FunctionsFailure('invalid-argument', null);

      // 2. Act
      final message = functionsFailureMessage(failure);

      // 3. Assert
      expect(message, 'Não foi possível concluir.');
    });

    test('Edge Case: custom explained codes, fallback and otherwise are '
        'used', () {
      // 1. Arrange
      const explained = FunctionsFailure('failed-precondition', null);
      const other = FunctionsFailure('invalid-argument', 'raw');

      // 2. Act
      String message(FunctionsFailure f) => functionsFailureMessage(
        f,
        explained: const {'failed-precondition'},
        fallback: 'fallback',
        otherwise: 'otherwise',
      );

      // 3. Assert
      expect([message(explained), message(other)], ['fallback', 'otherwise']);
    });

    for (final code in ['unavailable', 'internal', 'not-found', 'unknown']) {
      test('Sad Path: $code hides the server\'s words behind the connection '
          'hint', () {
        // 1. Arrange
        final failure = FunctionsFailure(code, 'stack trace text');

        // 2. Act
        final message = functionsFailureMessage(failure);

        // 3. Assert
        expect(message, _otherwise);
      });
    }
  });

  group('functionsResult - Unit Test Suite', () {
    test('Happy Path: the operation\'s Ok is returned as it is', () async {
      // 1. Arrange
      const ok = Ok(7);

      // 2. Act
      final result = await run(() async => ok);

      // 3. Assert
      expect(result, same(ok));
    });

    test('Edge Case: the operation\'s own Err is returned as it is', () async {
      // 1. Arrange
      const err = Err<int>('Resposta inesperada.');

      // 2. Act
      final result = await run(() async => err);

      // 3. Assert
      expect(result, same(err));
    });

    test('Sad Path: a FunctionsFailure becomes an Err with the refusal\'s '
        'message, keeping the failure', () async {
      // 1. Arrange
      const failure = FunctionsFailure('permission-denied', 'Sem permissão.');

      // 2. Act
      final result = await run(() async => throw failure);

      // 3. Assert
      expect(result, isA<Err<int>>());
      final err = result as Err<int>;
      expect(err.message, 'refused: permission-denied');
      expect(err.error, same(failure));
      expect(err.stackTrace, isNotNull);
    });

    test('Sad Path: any other error becomes an Err with the unexpected '
        'message, keeping the error', () async {
      // 1. Arrange
      final error = StateError('offline');

      // 2. Act
      final result = await run(() async => throw error);

      // 3. Assert
      final err = result as Err<int>;
      expect(err.message, 'unexpected');
      expect(err.error, same(error));
      expect(err.stackTrace, isNotNull);
    });

    test('Sad Path: an error thrown before the first await is caught '
        'too', () async {
      // 1. Arrange
      Future<Result<int>> throwsAtOnce() => throw ArgumentError('bad');

      // 2. Act
      final result = await run(throwsAtOnce);

      // 3. Assert
      expect((result as Err<int>).message, 'unexpected');
    });
  });
}
