import 'package:monamie_app/utils/failure.dart';

export 'package:monamie_app/utils/failure.dart';

/// The outcome of an operation that can fail in a way the person must hear
/// about: [Ok] with its value, or [Err] with the [Failure] that says why.
///
/// Controllers return it instead of showing messages; the screen that started
/// the operation decides how to show an [Err] (a `SnackBar`, as a rule) and
/// turns its failure into text in the device's language (`FailureText`).
///
/// This is also where error reporting (e.g. Crashlytics) will hook in later:
/// every [Err] already carries the original [Err.error] and
/// [Err.stackTrace]. Nothing is reported yet.
sealed class Result<T> {
  const Result();
}

/// The operation succeeded with [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';
}

/// The operation failed for [failure], which the screen names; [error] and
/// [stackTrace] are the original failure, when there was one.
final class Err<T> extends Result<T> {
  const Err(this.failure, {this.error, this.stackTrace});

  final Failure failure;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'Err($failure)';
}
