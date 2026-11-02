import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/utils/result.dart';

/// The central account-deletion functions, behind a contract so the
/// screens are tested with a fake. Every method returns an [Err] with a
/// message the person can read instead of throwing.
abstract interface class AccountDeletionRepository {
  /// Schedules the deletion of the signed-in account. The owner
  /// (*titular*) confirms each organization they own by its id in
  /// [confirmIds].
  Future<Result<AccountDeletion>> request({List<String> confirmIds = const []});

  /// Cancels the pending deletion of the signed-in account.
  Future<Result<void>> cancel();

  /// The signed-in account's pending deletion, or `null`.
  Future<Result<AccountDeletion?>> pending();
}
