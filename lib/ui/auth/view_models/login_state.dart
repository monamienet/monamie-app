import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

/// What *Login* shows of its own, replaced whole by `LoginViewModel`.
@freezed
abstract class LoginState with _$LoginState {
  const factory LoginState({
    /// Whether a session remembered from a previous run is being checked.
    @Default(true) bool isRestoringSession,
  }) = _LoginState;
}
