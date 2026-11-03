import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/utils/failure.dart';

part 'deletion_pending_state.freezed.dart';

/// What *Em exclusão* shows, replaced whole by `DeletionPendingViewModel`.
@freezed
abstract class DeletionPendingState with _$DeletionPendingState {
  const factory DeletionPendingState({
    /// The signed-in account's pending deletion.
    AccountDeletion? accountDeletion,

    /// The deletion was cancelled: the screen says everything is back.
    @Default(false) bool deletionRestored,

    /// Why the last cancel failed; `null` when it did not.
    Failure? deletionFailure,

    /// Whether a sign-out runs (this screen's or any other).
    @Default(false) bool isLoggingOut,
  }) = _DeletionPendingState;
}
