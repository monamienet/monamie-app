import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';

part 'create_organization_state.freezed.dart';

/// Where the id check is.
enum IdCheck { idle, checking, available, unavailable }

/// What *Criar organização* shows, replaced whole by
/// `CreateOrganizationViewModel`.
@freezed
abstract class CreateOrganizationState with _$CreateOrganizationState {
  const factory CreateOrganizationState({
    @Default('') String name,
    @Default('') String id,
    @Default(IdCheck.idle) IdCheck idCheck,

    /// Why [id] cannot be used; empty when it can or is being checked.
    @Default('') String idProblem,

    /// The themes that can be picked.
    @Default([]) List<OrganizationTheme> themes,
    required String themeId,
    @Default('community') String plan,

    /// Why the last creation failed; empty when it did not.
    @Default('') String errorMessage,

    /// The status after creating (`active`, `awaiting_billing`, `failed`).
    String? result,
  }) = _CreateOrganizationState;
}
