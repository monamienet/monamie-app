import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:monamie_app/data/repositories/session/session_state.dart';

part 'home_session_state.freezed.dart';

/// What the home screen shows of the session (the menu's owner-only entry,
/// the overlay while leaving), replaced whole by `HomeSessionViewModel`.
@freezed
abstract class HomeSessionState with _$HomeSessionState {
  const factory HomeSessionState({
    /// How the person is leaving the organization, `null` when they are not.
    SessionExit? leaving,

    /// Whether the signed-in user owns each organization read so far (by
    /// id). The owner-only menu entries (*Administradores*) follow it.
    @Default({}) Map<String, bool> ownership,
  }) = _HomeSessionState;

  const HomeSessionState._();

  /// Whether a sign-out (tracking stop and sign-out) or a change of
  /// organization runs: the lock and the overlay.
  bool get isLoggingOut => leaving != null;

  /// The busy operation is a change of organization, not a sign-out: it
  /// decides the overlay's message.
  bool get isSwitchingOrganization => leaving == SessionExit.switchOrganization;
}
