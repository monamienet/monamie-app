import 'dart:async';

import 'package:monamie_app/utils/result.dart';

/// One call a fake received: the method's name and its arguments, in the
/// order the method declares them (named arguments included).
typedef FakeCall = ({String method, List<Object?> arguments});

/// What every in-memory fake under `testing/fakes/repositories/` shares:
/// the calls it received ([calls]), failures a test asks for ([fail]) and
/// answers a test holds back to see the pending state ([hold]).
///
/// Methods are named by their Dart name (`'list'`, `'create'`). A fake
/// answers through [answer] (methods that return a [Result]) or [run]
/// (methods that throw), which record the call, wait for a held answer and
/// only then change the fake's data, so a failed or still pending call
/// changes nothing.
mixin FakeOutcomes {
  /// Every call received, in order.
  final List<FakeCall> calls = [];

  final Map<String, ({Failure failure, bool once})> _failures = {};
  final Map<String, Completer<void>> _holds = {};

  /// How many times [method] was called.
  int callCount(String method) => argumentsOf(method).length;

  /// The arguments of each call to [method], in order.
  List<List<Object?>> argumentsOf(String method) => [
    for (final call in calls)
      if (call.method == method) call.arguments,
  ];

  /// Makes [method] fail with [failure]: an [Err] carrying it for the
  /// methods that return a [Result], a [FakeFailure] carrying it for those
  /// that throw. It fails until [succeed], or only on its next call when
  /// [once] is true.
  void fail(String method, Failure failure, {bool once = false}) =>
      _failures[method] = (failure: failure, once: once);

  /// Makes [method] answer normally again.
  void succeed(String method) => _failures.remove(method);

  /// Holds [method]'s answers (every call made from now on) until the
  /// returned completer completes, so a test can see the pending state.
  Completer<void> hold(String method) => _holds[method] = Completer<void>();

  /// Records the call, waits while [method] is held, then returns the
  /// failure asked for, or [Ok] with what [value] computes.
  Future<Result<T>> answer<T>(
    String method,
    List<Object?> arguments,
    FutureOr<T> Function() value,
  ) async {
    final failure = await _arrive(method, arguments);
    if (failure != null) return Err(failure);
    return Ok(await value());
  }

  /// Like [answer], for the methods that throw: the failure asked for is
  /// thrown as a [FakeFailure].
  Future<T> run<T>(
    String method,
    List<Object?> arguments,
    FutureOr<T> Function() value,
  ) async {
    final failure = await _arrive(method, arguments);
    if (failure != null) throw FakeFailure(failure);
    return value();
  }

  /// Records the call synchronously (before any wait), then returns the
  /// failure asked for [method], if any.
  Future<Failure?> _arrive(String method, List<Object?> arguments) async {
    calls.add((method: method, arguments: arguments));
    final hold = _holds[method];
    if (hold != null) await hold.future;
    final failure = _failures[method];
    if (failure == null) return null;
    if (failure.once) _failures.remove(method);
    return failure.failure;
  }
}

/// What a fake throws when a test made one of its throwing methods fail.
class FakeFailure implements Exception {
  const FakeFailure(this.failure);

  /// The [Failure] the test asked for.
  final Failure failure;

  @override
  String toString() => 'FakeFailure: $failure';
}
