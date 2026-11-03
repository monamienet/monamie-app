import 'dart:async';

import 'package:flutter/foundation.dart';

import 'result.dart';

/// The action a [Command0] runs.
typedef CommandAction0<T> = Future<Result<T>> Function();

/// The action a [Command1] runs with its argument.
typedef CommandAction1<T, A> = Future<Result<T>> Function(A argument);

/// One action a screen triggers in a view model (load, save, create…), with
/// its pending state, adapted from the official Compass app's `Command`
/// (`compass_app/app/lib/utils/command.dart`).
///
/// A view model exposes each action as a command field; the screen listens
/// to it (a [ChangeNotifier]) to show a spinner and disable the trigger
/// while [running], then shows the [Err] message that [execute] returns.
///
/// What it does for every action:
/// - **Reentrancy guard**: a call made while the action runs is ignored
///   (e.g. a second tap on the button), and so is a call made while
///   [blocked] says so (other commands of the same view model that must not
///   overlap, "one operation at a time"). An ignored call returns `null`.
/// - **Guaranteed reset**: [running] goes back to `false` in a `finally`,
///   even when the action throws; the exception then reaches the caller of
///   `execute`, as any `await` would. Actions return [Result] and should
///   not throw.
/// - **Last result**: [result] keeps the last outcome ([completed] or
///   [error]) until the next call or [clearResult].
///
/// Differences from Compass: `execute` returns the [Result] (the screens
/// show an [Err] right after awaiting it), the optional [blocked] guard,
/// [Command1.argument], and [dispose] silencing the notifications of an
/// action that finishes after its view model is gone.
abstract class Command<T> extends ChangeNotifier {
  Command({this._blocked});

  final bool Function()? _blocked;

  bool _running = false;
  Result<T>? _result;
  bool _disposed = false;

  /// Whether the action is running.
  bool get running => _running;

  /// Whether the last call ended with an [Err].
  bool get error => _result is Err;

  /// Whether the last call ended with an [Ok].
  bool get completed => _result is Ok;

  /// The outcome of the last call, `null` while it runs, before the first
  /// call and after [clearResult].
  Result<T>? get result => _result;

  /// Forgets the last outcome, once the screen has shown it.
  void clearResult() {
    _result = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Runs [action] unless a call is running or [blocked]; see [Command].
  /// [onStart] runs just before the listeners hear that it started.
  Future<Result<T>?> _execute(
    CommandAction0<T> action, {
    void Function()? onStart,
  }) async {
    if (_running || (_blocked?.call() ?? false)) return null;
    onStart?.call();
    _running = true;
    _result = null;
    _notify();
    try {
      return _result = await action();
    } finally {
      _running = false;
      _clearArgument();
      _notify();
    }
  }

  /// Forgets the running call's argument ([Command1]), before the
  /// listeners hear that it finished.
  void _clearArgument() {}

  /// Releases the listeners. An action still running finishes, but no
  /// longer notifies. Only the first call does anything.
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

/// A [Command] whose action takes no argument.
class Command0<T> extends Command<T> {
  /// [blocked], when given, also makes [execute] ignore a call (see
  /// [Command]).
  Command0(this._action, {super.blocked});

  final CommandAction0<T> _action;

  /// Runs the action and returns its [Result]; `null` when the call was
  /// ignored (see [Command]).
  Future<Result<T>?> execute() => _execute(_action);
}

/// A [Command] whose action takes one argument of type [A] (use a record for
/// several).
class Command1<T, A> extends Command<T> {
  /// [blocked], when given, also makes [execute] ignore a call (see
  /// [Command]).
  Command1(this._action, {super.blocked});

  final CommandAction1<T, A> _action;
  A? _argument;

  /// The argument of the call running now, `null` while none runs: tells
  /// the screen *which* item is in flight (e.g. the row with the spinner).
  A? get argument => _argument;

  /// Runs the action with [argument] and returns its [Result]; `null` when
  /// the call was ignored (see [Command]).
  Future<Result<T>?> execute(A argument) =>
      _execute(() => _action(argument), onStart: () => _argument = argument);

  @override
  void _clearArgument() => _argument = null;
}
