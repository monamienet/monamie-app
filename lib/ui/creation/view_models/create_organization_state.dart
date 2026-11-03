import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/utils/failure.dart';

part 'create_organization_state.freezed.dart';

/// Where the id check is.
enum IdCheck { idle, checking, available, unavailable }

/// What *Criar organização* shows, replaced whole by
/// `CreateOrganizationViewModel`.
@freezed
abstract class CreateOrganizationState with _$CreateOrganizationState {
  const factory CreateOrganizationState({
    /// The wizard's step: 0 Nome, 1 Tema, 2 Plano, 3 Revisão.
    @Default(0) int step,

    @Default('') String name,
    @Default('') String id,
    @Default(IdCheck.idle) IdCheck idCheck,

    /// Why [id] cannot be used; `null` when it can or is being checked.
    Failure? idProblem,

    /// Whether the identifier field changed what the person typed (case,
    /// accents, anything but a to z), which the screen says.
    @Default(false) bool idAdjusted,

    /// The themes that can be picked.
    @Default([]) List<OrganizationTheme> themes,
    required String themeId,
    @Default('community') String plan,

    /// Whether the person ticked "Li e aceito os Termos para organizações".
    @Default(false) bool acceptedTerms,

    /// Why the last creation failed; `null` when it did not.
    Failure? failure,

    /// The status after creating (`active`, `awaiting_billing`, `failed`).
    String? result,
  }) = _CreateOrganizationState;
}
