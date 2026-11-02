import 'package:freezed_annotation/freezed_annotation.dart';

import 'administrators.dart';

part 'administrators_state.freezed.dart';

/// What *Administradores* shows, replaced whole by
/// `AdministratorsController`.
@freezed
abstract class AdministratorsState with _$AdministratorsState {
  const factory AdministratorsState({
    /// The administrators and the members who may be appointed.
    @Default(OrganizationAdministrators()) OrganizationAdministrators people,

    /// Whether the list is being loaded.
    @Default(false) bool isLoading,

    /// The e-mail whose role is being changed, or `null`.
    String? workingEmail,

    /// Why the last load or change failed; empty when it did not.
    @Default('') String errorMessage,
  }) = _AdministratorsState;
}
