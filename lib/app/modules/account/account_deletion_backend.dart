import 'account_deletion.dart';

/// The central account-deletion functions, behind a contract so the
/// screens are tested with a fake. Throws [AccountDeletionException] with a
/// message the person can read.
abstract interface class AccountDeletionBackend {
  /// Schedules the deletion of the signed-in account. An owner confirms
  /// each organization they own by its id in [confirmIds].
  Future<AccountDeletion> request({List<String> confirmIds = const []});

  /// Cancels the pending deletion of the signed-in account.
  Future<void> cancel();

  /// The signed-in account's pending deletion, or `null`.
  Future<AccountDeletion?> pending();
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}
