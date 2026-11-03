import 'package:monamie_app/data/repositories/functions_result.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/creation.dart';
import 'package:monamie_app/utils/result.dart';

import 'creation_repository.dart';

/// Creating a project takes longer than the other calls.
const _timeout = Duration(seconds: 90);

/// [CreationRepository] over the central project's creation functions.
class CreationRepositoryRemote implements CreationRepository {
  const CreationRepositoryRemote({required this._functions});

  final CentralFunctionsService _functions;

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function() operation, {
    required Failure unexpected,
  }) => functionsResult(
    operation,
    refusal: (failure) => functionsRefusal(
      failure,
      explained: const {'invalid-argument', 'failed-precondition'},
      fallback: RefusedAction.create,
    ),
    unexpected: unexpected,
    logTag: 'Creation',
  );

  @override
  Future<Result<Failure?>> idProblem(String id) => _run(() async {
    final data = await _functions.call('checkOrganizationId', {
      'id': id,
    }, timeout: _timeout);
    if (data is Map && data['available'] == true) return const Ok(null);
    return Ok(
      data is Map && data['problem'] is String
          ? Failure.serverRefusal(data['problem'] as String)
          : const Failure.organizationId(OrganizationIdProblem.unusable),
    );
  }, unexpected: const Failure.load(LoadTarget.organizationIdCheck));

  @override
  Future<Result<String>> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  }) => _run(() async {
    final data = await _functions.call('createOrganization', {
      'id': id,
      'name': name,
      'themeId': themeId,
      'plan': plan,
    }, timeout: _timeout);
    return Ok(
      data is Map && data['status'] is String
          ? data['status'] as String
          : 'failed',
    );
  }, unexpected: const Failure.connection(FailedAction.create));

  @override
  Future<Result<List<Creation>>> mine() => _run(() async {
    final data = await _functions.call(
      'myCreations',
      const {},
      timeout: _timeout,
    );
    return Ok([
      for (final entry
          in (data is Map ? data['creations'] : null) as List? ?? const [])
        ?Creation.fromJson(entry),
    ]);
  }, unexpected: const Failure.load(LoadTarget.creations));
}
