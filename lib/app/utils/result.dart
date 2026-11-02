/// The outcome of an operation that can fail in a way the person must hear
/// about: [Ok] with its value, or [Err] with a message for the screen.
///
/// Controllers return it instead of showing messages; the screen that started
/// the operation decides how to show an [Err] (a `SnackBar`, as a rule).
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

/// The operation failed. [message] (and the optional [title]) are written for
/// the person using the app, in pt-BR; [error] and [stackTrace] are the
/// original failure, when there was one.
final class Err<T> extends Result<T> {
  const Err(this.message, {this.title, this.error, this.stackTrace});

  final String message;
  final String? title;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  String toString() => 'Err(${title == null ? '' : '$title: '}$message)';
}
