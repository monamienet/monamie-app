import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/utils/failure.dart';

part 'administrators_state.freezed.dart';

/// What *Administradores* shows, replaced whole by
/// `AdministratorsViewModel`.
@freezed
abstract class AdministratorsState with _$AdministratorsState {
  const factory AdministratorsState({
    /// The administrators and the members who may be appointed.
    @Default(OrganizationAdministrators()) OrganizationAdministrators people,

    /// Why the last load or change failed; `null` when it did not.
    Failure? failure,
  }) = _AdministratorsState;
}
