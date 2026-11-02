import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_account_state.freezed.dart';

/// What *Minha conta* shows, replaced whole by `MyAccountViewModel`.
@freezed
abstract class MyAccountState with _$MyAccountState {
  const factory MyAccountState({
    /// Whether the person owns the bound organization; `null` while it is
    /// being read or when it could not be read, and then nothing can be
    /// deleted.
    bool? isOwner,
    @Default(false) bool isCheckingOwner,

    /// What the owner typed to confirm (the organization's id).
    @Default('') String confirmation,
    @Default(false) bool isDeleting,

    /// Why the last load or deletion failed; empty when it did not.
    @Default('') String errorMessage,
  }) = _MyAccountState;
}
