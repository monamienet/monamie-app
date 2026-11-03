import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/utils/failure.dart';

part 'my_account_state.freezed.dart';

/// What *Minha conta* shows, replaced whole by `MyAccountViewModel`.
@freezed
abstract class MyAccountState with _$MyAccountState {
  const factory MyAccountState({
    /// Whether the person owns the bound organization; `null` while it is
    /// being read or when it could not be read, and then nothing can be
    /// deleted.
    bool? isOwner,

    /// What the owner typed to confirm (the organization's id).
    @Default('') String confirmation,

    /// Why the last load or deletion failed; `null` when it did not.
    Failure? failure,
  }) = _MyAccountState;
}
