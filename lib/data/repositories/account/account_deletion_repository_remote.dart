import 'package:monamie_app/data/repositories/functions_result.dart';
import 'package:monamie_app/data/services/functions/functions_service.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/utils/result.dart';

import 'account_deletion_repository.dart';

/// [AccountDeletionRepository] over the central project's functions.
class AccountDeletionRepositoryRemote implements AccountDeletionRepository {
  const AccountDeletionRepositoryRemote({required this._functions});

  final CentralFunctionsService _functions;

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function() operation, {
    required String unexpected,
  }) => functionsResult(
    operation,
    refusal: (failure) => functionsFailureMessage(
      failure,
      explained: const {'failed-precondition'},
      fallback: 'Não foi possível agora.',
    ),
    unexpected: unexpected,
    logTag: 'Account',
  );

  @override
  Future<Result<AccountDeletion>> request({
    List<String> confirmIds = const [],
  }) => _run(
    () async {
      final deletion = AccountDeletion.fromJson(
        await _functions.call('requestAccountDeletion', {
          'confirmIds': confirmIds,
        }),
      );
      return deletion == null
          ? const Err('Resposta inesperada do servidor.')
          : Ok(deletion);
    },
    unexpected:
        'Não foi possível excluir agora. Verifique a conexão e tente de novo.',
  );

  @override
  Future<Result<void>> cancel() => _run(
    () async {
      await _functions.call('cancelAccountDeletion', const {});
      return const Ok(null);
    },
    unexpected:
        'Não foi possível cancelar agora. Verifique a conexão e tente de novo.',
  );

  @override
  Future<Result<AccountDeletion?>> pending() => _run(() async {
    final data = await _functions.call('myAccountDeletion', const {});
    return Ok(AccountDeletion.fromJson(data is Map ? data['deletion'] : null));
  }, unexpected: 'Não foi possível ler a exclusão da conta.');
}
