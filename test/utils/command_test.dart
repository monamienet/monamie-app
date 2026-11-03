import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';

/// What a command looked like each time it notified its listeners.
typedef _Snapshot = ({
  bool running,
  bool error,
  bool completed,
  Object? result,
});

/// Records a [_Snapshot] of [command] on every notification.
List<_Snapshot> _record(Command<Object?> command) {
  final snapshots = <_Snapshot>[];
  command.addListener(
    () => snapshots.add((
      running: command.running,
      error: command.error,
      completed: command.completed,
      result: command.result,
    )),
  );
  return snapshots;
}

/// An action that waits on [gate] before returning [result], counting its
/// runs in [calls].
class _GatedAction<T> {
  _GatedAction(this.result);

  final Result<T> result;
  Completer<void> gate = Completer<void>();
  int calls = 0;

  Future<Result<T>> call() async {
    calls++;
    await gate.future;
    return result;
  }
}

void main() {
  group('Command0 - Unit Test Suite', () {
    test('Happy Path: starts idle, with no result', () {
      // 1. Arrange
      // 2. Act
      final command = Command0<int>(() async => const Ok(1));

      // 3. Assert
      expect(command.running, isFalse);
      expect(command.error, isFalse);
      expect(command.completed, isFalse);
      expect(command.result, isNull);
    });

    test(
      'Happy Path: an Ok is returned, kept and marks it completed',
      () async {
        // 1. Arrange
        final command = Command0<int>(() async => const Ok(7));

        // 2. Act
        final result = await command.execute();

        // 3. Assert
        expect(result, isA<Ok<int>>().having((ok) => ok.value, 'value', 7));
        expect(command.result, same(result));
        expect(command.completed, isTrue);
        expect(command.error, isFalse);
        expect(command.running, isFalse);
      },
    );

    test('Happy Path: running is true while the action runs', () async {
      // 1. Arrange
      final action = _GatedAction<int>(const Ok(1));
      final command = Command0<int>(action.call);

      // 2. Act
      final pending = command.execute();

      // 3. Assert
      expect(command.running, isTrue);
      expect(command.result, isNull);
      action.gate.complete();
      await pending;
      expect(command.running, isFalse);
    });

    test('Happy Path: notifies when it starts (running, no result) and when '
        'it ends (idle, with the result)', () async {
      // 1. Arrange
      const ok = Ok(3);
      final command = Command0<int>(() async => ok);
      final snapshots = _record(command);

      // 2. Act
      await command.execute();

      // 3. Assert
      expect(snapshots, [
        (running: true, error: false, completed: false, result: null),
        (running: false, error: false, completed: true, result: ok),
      ]);
    });

    test('Edge Case: a call while one runs is ignored: returns null, runs '
        'nothing and notifies nobody', () async {
      // 1. Arrange
      final action = _GatedAction<int>(const Ok(1));
      final command = Command0<int>(action.call);
      final first = command.execute();
      final snapshots = _record(command);

      // 2. Act
      final second = await command.execute();

      // 3. Assert
      expect(second, isNull);
      expect(action.calls, 1);
      expect(snapshots, isEmpty);
      expect(command.running, isTrue);
      action.gate.complete();
      await first;
    });

    test('Edge Case: once the call ends, a new call runs again', () async {
      // 1. Arrange
      var calls = 0;
      final command = Command0<int>(() async => Ok(++calls));
      await command.execute();

      // 2. Act
      final second = await command.execute();

      // 3. Assert
      expect(second, isA<Ok<int>>().having((ok) => ok.value, 'value', 2));
      expect(calls, 2);
    });

    test(
      'Edge Case: a new call clears the last result while it runs',
      () async {
        // 1. Arrange
        final action = _GatedAction<int>(
          const Err(Failure.connection(FailedAction.save)),
        );
        final command = Command0<int>(action.call);
        action.gate.complete();
        await command.execute();
        expect(command.error, isTrue);
        action.gate = Completer<void>();

        // 2. Act
        final pending = command.execute();

        // 3. Assert
        expect(command.result, isNull);
        expect(command.error, isFalse);
        expect(command.completed, isFalse);
        action.gate.complete();
        await pending;
      },
    );

    test('Edge Case: blocked() true ignores the call: null, nothing run, '
        'nobody notified', () async {
      // 1. Arrange
      var calls = 0;
      final command = Command0<int>(() async {
        calls++;
        return const Ok(1);
      }, blocked: () => true);
      final snapshots = _record(command);

      // 2. Act
      final result = await command.execute();

      // 3. Assert
      expect(result, isNull);
      expect(calls, 0);
      expect(snapshots, isEmpty);
      expect(command.running, isFalse);
    });

    test('Edge Case: blocked() is asked on every call', () async {
      // 1. Arrange
      var blocked = true;
      var asked = 0;
      final command = Command0<int>(
        () async => const Ok(1),
        blocked: () {
          asked++;
          return blocked;
        },
      );
      final ignored = await command.execute();
      blocked = false;

      // 2. Act
      final ran = await command.execute();

      // 3. Assert
      expect(ignored, isNull);
      expect(ran, isA<Ok<int>>());
      expect(asked, 2);
    });

    test('Edge Case: an ignored call keeps the last result', () async {
      // 1. Arrange
      var blocked = false;
      final command = Command0<int>(
        () async => const Ok(5),
        blocked: () => blocked,
      );
      final last = await command.execute();
      blocked = true;

      // 2. Act
      await command.execute();

      // 3. Assert
      expect(command.result, same(last));
      expect(command.completed, isTrue);
    });

    test('Sad Path: an Err is returned, kept and marks it as error', () async {
      // 1. Arrange
      final command = Command0<void>(
        () async => const Err(Failure.googleAuth()),
      );

      // 2. Act
      final result = await command.execute();

      // 3. Assert
      expect(
        result,
        isA<Err<void>>().having(
          (err) => err.failure,
          'failure',
          const Failure.googleAuth(),
        ),
      );
      expect(command.result, same(result));
      expect(command.error, isTrue);
      expect(command.completed, isFalse);
      expect(command.running, isFalse);
    });

    test('Sad Path: an exception from the action reaches the caller, and '
        'running resets with the listeners told', () async {
      // 1. Arrange
      final failure = StateError('boom');
      final command = Command0<int>(() async => throw failure);
      final snapshots = _record(command);

      // 2. Act
      final call = command.execute();

      // 3. Assert
      await expectLater(call, throwsA(same(failure)));
      expect(command.running, isFalse);
      expect(command.result, isNull);
      expect(command.error, isFalse);
      expect(command.completed, isFalse);
      expect(snapshots.map((s) => s.running), [true, false]);
    });

    test('Sad Path: after an exception a new call runs', () async {
      // 1. Arrange
      var fail = true;
      final command = Command0<int>(() async {
        if (fail) throw StateError('boom');
        return const Ok(1);
      });
      await expectLater(command.execute(), throwsStateError);
      fail = false;

      // 2. Act
      final result = await command.execute();

      // 3. Assert
      expect(result, isA<Ok<int>>());
    });
  });

  group('Command.clearResult - Unit Test Suite', () {
    test('Happy Path: forgets the last result and notifies', () async {
      // 1. Arrange
      final command = Command0<int>(() async => const Ok(1));
      await command.execute();
      final snapshots = _record(command);

      // 2. Act
      command.clearResult();

      // 3. Assert
      expect(command.result, isNull);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(snapshots, [
        (running: false, error: false, completed: false, result: null),
      ]);
    });

    test('Edge Case: clears an error too', () async {
      // 1. Arrange
      final command = Command0<int>(
        () async => const Err(Failure.connection(FailedAction.save)),
      );
      await command.execute();

      // 2. Act
      command.clearResult();

      // 3. Assert
      expect(command.error, isFalse);
      expect(command.result, isNull);
    });

    test('Sad Path: after dispose it notifies nobody and does not '
        'throw', () async {
      // 1. Arrange
      final command = Command0<int>(() async => const Ok(1));
      await command.execute();
      var notifications = 0;
      command.addListener(() => notifications++);
      command.dispose();

      // 2. Act
      command.clearResult();

      // 3. Assert
      expect(command.result, isNull);
      expect(notifications, 0);
    });
  });

  group('Command.dispose - Unit Test Suite', () {
    test('Happy Path: an action finishing after dispose still completes the '
        'caller, notifies nobody and does not throw', () async {
      // 1. Arrange
      final action = _GatedAction<int>(const Ok(9));
      final command = Command0<int>(action.call);
      var notifications = 0;
      final pending = command.execute();
      command.addListener(() => notifications++);
      command.dispose();

      // 2. Act
      action.gate.complete();

      // 3. Assert
      await expectLater(
        pending,
        completion(isA<Ok<int>>().having((ok) => ok.value, 'value', 9)),
      );
      expect(notifications, 0);
      expect(command.running, isFalse);
    });

    test('Edge Case: an exception after dispose still reaches the caller '
        'without a notification error', () async {
      // 1. Arrange
      final gate = Completer<void>();
      final failure = StateError('late');
      final command = Command0<int>(() async {
        await gate.future;
        throw failure;
      });
      final pending = command.execute();
      command.dispose();

      // 2. Act
      gate.complete();

      // 3. Assert
      await expectLater(pending, throwsA(same(failure)));
      expect(command.running, isFalse);
    });

    test('Edge Case: disposing twice does nothing the second time', () {
      // 1. Arrange
      final command = Command0<int>(() async => const Ok(1));
      command.dispose();

      // 2. Act
      void again() => command.dispose();

      // 3. Assert
      expect(again, returnsNormally);
    });

    test('Edge Case: Command1 also tolerates a second dispose', () {
      // 1. Arrange
      final command = Command1<int, String>((_) async => const Ok(1));
      command.dispose();

      // 2. Act
      void again() => command.dispose();

      // 3. Assert
      expect(again, returnsNormally);
    });
  });

  group('Command1 - Unit Test Suite', () {
    test('Happy Path: the action receives the argument and its result is '
        'returned', () async {
      // 1. Arrange
      final received = <String>[];
      final command = Command1<int, String>((argument) async {
        received.add(argument);
        return Ok(argument.length);
      });

      // 2. Act
      final result = await command.execute('rotasul');

      // 3. Assert
      expect(received, ['rotasul']);
      expect(result, isA<Ok<int>>().having((ok) => ok.value, 'value', 7));
      expect(command.completed, isTrue);
    });

    test('Happy Path: argument holds the running call\'s argument', () async {
      // 1. Arrange
      final gate = Completer<void>();
      final command = Command1<void, ({String email, bool admin})>((_) async {
        await gate.future;
        return const Ok(null);
      });

      // 2. Act
      final pending = command.execute((email: 'ana@x.com', admin: true));

      // 3. Assert
      expect(command.argument, (email: 'ana@x.com', admin: true));
      expect(command.running, isTrue);
      gate.complete();
      await pending;
      expect(command.argument, isNull);
    });

    test('Happy Path: argument is set before the start notification and '
        'cleared before the end one', () async {
      // 1. Arrange
      final command = Command1<void, String>((_) async => const Ok(null));
      final seen = <(bool, String?)>[];
      command.addListener(() => seen.add((command.running, command.argument)));

      // 2. Act
      await command.execute('01');

      // 3. Assert
      expect(seen, [(true, '01'), (false, null)]);
    });

    test('Edge Case: argument is null before any call', () {
      // 1. Arrange
      // 2. Act
      final command = Command1<void, String>((_) async => const Ok(null));

      // 3. Assert
      expect(command.argument, isNull);
    });

    test('Edge Case: a call while one runs is ignored and keeps the first '
        'argument', () async {
      // 1. Arrange
      final gate = Completer<void>();
      final received = <String>[];
      final command = Command1<void, String>((argument) async {
        received.add(argument);
        await gate.future;
        return const Ok(null);
      });
      final first = command.execute('01');

      // 2. Act
      final second = await command.execute('02');

      // 3. Assert
      expect(second, isNull);
      expect(received, ['01']);
      expect(command.argument, '01');
      gate.complete();
      await first;
    });

    test('Edge Case: a blocked call sets no argument', () async {
      // 1. Arrange
      final command = Command1<void, String>(
        (_) async => const Ok(null),
        blocked: () => true,
      );
      final snapshots = _record(command);

      // 2. Act
      final result = await command.execute('01');

      // 3. Assert
      expect(result, isNull);
      expect(command.argument, isNull);
      expect(snapshots, isEmpty);
    });

    test('Sad Path: an Err keeps the error and clears the argument', () async {
      // 1. Arrange
      final command = Command1<void, String>(
        (_) async => const Err(Failure.serverRefusal('Recusado.')),
      );

      // 2. Act
      final result = await command.execute('01');

      // 3. Assert
      expect(result, isA<Err<void>>());
      expect(command.error, isTrue);
      expect(command.argument, isNull);
    });

    test('Sad Path: an exception clears the argument and running, then '
        'reaches the caller', () async {
      // 1. Arrange
      final command = Command1<void, String>(
        (_) async => throw StateError('boom'),
      );

      // 2. Act
      final call = command.execute('01');

      // 3. Assert
      await expectLater(call, throwsStateError);
      expect(command.argument, isNull);
      expect(command.running, isFalse);
    });

    test('Sad Path: after dispose a late end clears the argument without '
        'notifying', () async {
      // 1. Arrange
      final gate = Completer<void>();
      final command = Command1<void, String>((_) async {
        await gate.future;
        return const Ok(null);
      });
      var notifications = 0;
      final pending = command.execute('01');
      command.addListener(() => notifications++);
      command.dispose();

      // 2. Act
      gate.complete();
      await pending;

      // 3. Assert
      expect(command.argument, isNull);
      expect(notifications, 0);
    });
  });
}
