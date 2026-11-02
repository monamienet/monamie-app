import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/utils/result.dart';

/// The message most repositories give a refused call: the server's own
/// words when the code says it explains the refusal ([explained]), else a
/// connection hint.
String functionsFailureMessage(
  FunctionsFailure failure, {
  Set<String> explained = const {
    'invalid-argument',
    'failed-precondition',
    'permission-denied',
  },
  String fallback = 'Não foi possível concluir.',
  String otherwise =
      'Não foi possível concluir agora. Verifique a conexão e tente de novo.',
}) => explained.contains(failure.code)
    ? (failure.message ?? fallback)
    : otherwise;

/// Runs [operation], a repository's use of the functions services, so it
/// never throws: a [FunctionsFailure] becomes an [Err] with [refusal]'s
/// message, any other error an [Err] with [unexpected] (logged with
/// [logTag]). Both keep the original error and stack trace.
Future<Result<T>> functionsResult<T>(
  Future<Result<T>> Function() operation, {
  required String Function(FunctionsFailure failure) refusal,
  required String unexpected,
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
