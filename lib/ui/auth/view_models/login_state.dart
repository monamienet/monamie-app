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

    /// Whether an account was chosen and the organization is being looked
    /// for or entered ("Procurando sua organização…"), after the button or
    /// a web sign-in. While Google's account chooser is open only
    /// `LoginViewModel.loginGoogle` runs, without this spinner.
    @Default(false) bool isLoading,

    /// Name of the organization being entered, for "Entrando em ...".
    String? enteringOrganizationName,
  }) = _LoginState;
}
