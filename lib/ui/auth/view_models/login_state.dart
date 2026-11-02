import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

/// What *Login* shows, replaced whole by `LoginViewModel`.
@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    /// Whether a session remembered from a previous run is being checked.
    @Default(true) bool isRestoringSession,

    /// Whether Google Sign-In finished initializing (or failed to).
    @Default(false) bool googleReady,

    /// Whether a sign-in or an organization entry runs.
    @Default(false) bool isLoading,

    /// The login button was tapped and the sign-in has not finished:
    /// Google's account chooser may be open. Guards against a second tap
    /// without showing [isLoading]'s "Procurando sua organização…", which
    /// only makes sense once an account is chosen.
    @Default(false) bool isChoosingAccount,

    /// Name of the organization being entered, for "Entrando em ...".
    String? enteringOrganizationName,
  }) = _LoginState;
}
