import 'package:monamie_app/data/repositories/functions_result.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/utils/result.dart';

import 'administrators_repository.dart';

/// [AdministratorsRepository] over the central project's functions, called
/// with the MonAmie (central) session.
class AdministratorsRepositoryRemote implements AdministratorsRepository {
  const AdministratorsRepositoryRemote({required this._functions});

  final CentralFunctionsService _functions;

  @override
  Future<Result<OrganizationAdministrators>> list(String organizationId) =>
      functionsResult(
        () async => Ok(
          OrganizationAdministrators.fromJson(
            await _functions.call('listAdministrators', {
              'organizationId': organizationId,
            }),
          ),
        ),
        refusal: functionsRefusal,
        unexpected: const Failure.load(LoadTarget.administrators),
        logTag: 'Administrators',
      );

  @override
  Future<Result<void>> setAdministrator(
    String organizationId,
    String email, {
    required bool admin,
  }) => functionsResult(
    () async {
      await _functions.call('setAdministrator', {
        'organizationId': organizationId,
        'email': email,
        'admin': admin,
      });
      return const Ok(null);
    },
    refusal: functionsRefusal,
    unexpected: const Failure.connection(FailedAction.conclude),
    logTag: 'Administrators',
  );
}
