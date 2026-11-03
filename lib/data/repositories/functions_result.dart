import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/utils/result.dart';

/// The failure most repositories give a refused call: the server's own
/// words ([ServerRefusal]) when the code says it explains the refusal
/// ([explained]), an [UnexplainedRefusal] of [fallback] when it explains
/// nothing, else [otherwise] (a connection hint).
Failure functionsRefusal(
  FunctionsFailure failure, {
  Set<String> explained = const {
    'invalid-argument',
    'failed-precondition',
    'permission-denied',
  },
  RefusedAction fallback = RefusedAction.conclude,
  Failure otherwise = const Failure.connection(FailedAction.conclude),
}) {
  if (!explained.contains(failure.code)) return otherwise;
  final message = failure.message;
  return message == null
      ? Failure.unexplainedRefusal(fallback)
      : Failure.serverRefusal(message);
}

/// Runs [operation], a repository's use of the functions services, so it
/// never throws: a [FunctionsFailure] becomes an [Err] with [refusal]'s
/// failure, any other error an [Err] with [unexpected] (logged with
/// [logTag]). Both keep the original error and stack trace.
Future<Result<T>> functionsResult<T>(
  Future<Result<T>> Function() operation, {
  required Failure Function(FunctionsFailure failure) refusal,
  required Failure unexpected,
  required String logTag,
}) async {
  try {
    return await operation();
  } on FunctionsFailure catch (e, stackTrace) {
    return Err(refusal(e), error: e, stackTrace: stackTrace);
  } catch (e, stackTrace) {
    debugPrint('[$logTag] $unexpected ($e)');
    return Err(unexpected, error: e, stackTrace: stackTrace);
  }
}
