import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [AccountDeletionRepository] over one [pendingDeletion]: requesting
/// schedules it 30 days ahead (owning the organizations confirmed),
/// cancelling clears it.
class FakeAccountDeletionRepository
    with FakeOutcomes
    implements AccountDeletionRepository {
  FakeAccountDeletionRepository({this.pendingDeletion, this._now});

  /// The signed-in account's pending deletion, or `null`.
  AccountDeletion? pendingDeletion;

  final DateTime? _now;

  @override
  Future<Result<AccountDeletion>> request({
    List<String> confirmIds = const [],
  }) => answer('request', [confirmIds], () {
    final deletion = AccountDeletion(
      deleteAt: (_now ?? DateTime.now()).add(const Duration(days: 30)),
      ownedOrganizationIds: [...confirmIds],
    );
    pendingDeletion = deletion;
    return deletion;
  });

  @override
  Future<Result<void>> cancel() => answer('cancel', const [], () {
    pendingDeletion = null;
  });

  @override
  Future<Result<AccountDeletion?>> pending() =>
      answer('pending', const [], () => pendingDeletion);
}
