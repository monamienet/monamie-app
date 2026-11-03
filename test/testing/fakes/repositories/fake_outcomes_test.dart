import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/utils/result.dart';

import '../../../../testing/fakes/repositories/fake_outcomes.dart';

class _Counter with FakeOutcomes {
  int value = 0;

  Future<Result<int>> increment(int by) => answer('increment', [by], () {
    value += by;
    return value;
  });

  Future<int> incrementOrThrow() => run('incrementOrThrow', const [], () {
    value += 1;
    return value;
  });
}

void main() {
  group('FakeOutcomes - Unit Test Suite', () {
    test(
      'Happy Path: a call is recorded with its arguments and answers Ok',
      () async {
        // 1. Arrange
        final fake = _Counter();

        // 2. Act
        final result = await fake.increment(2);

        // 3. Assert
        expect((result as Ok<int>).value, 2);
        expect(fake.argumentsOf('increment'), [
          [2],
        ]);
        expect(fake.callCount('incrementOrThrow'), 0);
      },
    );

    test('Sad Path: a failing method answers Err and changes nothing until '
        'it succeeds again', () async {
      // 1. Arrange
      final fake = _Counter()
        ..fail('increment', const Failure.connection(FailedAction.save));

      // 2. Act
      final failed = await fake.increment(1);
      final again = await fake.increment(1);
      fake.succeed('increment');
      final ok = await fake.increment(1);

      // 3. Assert
      expect(
        (failed as Err<int>).failure,
        const Failure.connection(FailedAction.save),
      );
      expect(again, isA<Err<int>>());
      expect((ok as Ok<int>).value, 1);
      expect(fake.callCount('increment'), 3);
    });

    test(
      'Edge Case: a failure asked for once fails only the next call',
      () async {
        // 1. Arrange
        final fake = _Counter()
          ..fail(
            'increment',
            const Failure.load(LoadTarget.groups),
            once: true,
          );

        // 2. Act
        final first = await fake.increment(1);
        final second = await fake.increment(1);

        // 3. Assert
        expect(first, isA<Err<int>>());
        expect((second as Ok<int>).value, 1);
      },
    );

    test('Sad Path: a throwing method throws FakeFailure', () async {
      // 1. Arrange
      final fake = _Counter()
        ..fail(
          'incrementOrThrow',
          const Failure.serverRefusal('Indisponível.'),
        );

      // 2. Act & 3. Assert
      await expectLater(
        fake.incrementOrThrow(),
        throwsA(
          isA<FakeFailure>().having(
            (f) => f.failure,
            'failure',
            const Failure.serverRefusal('Indisponível.'),
          ),
        ),
      );
      expect(fake.value, 0);
    });

    test('Edge Case: a held method is recorded at once but answers only '
        'when released', () async {
      // 1. Arrange
      final fake = _Counter();
      final hold = fake.hold('increment');

      // 2. Act
      var answered = false;
      final pending = fake.increment(1).then((_) => answered = true);
      await Future<void>.delayed(Duration.zero);

      // 3. Assert
      expect(fake.callCount('increment'), 1);
      expect(answered, isFalse);
      expect(fake.value, 0);
      hold.complete();
      await pending;
      expect(answered, isTrue);
      expect(fake.value, 1);
    });
  });
}
