// check_layers: state_contract

import 'package:monamie_app/utils/result.dart';

/// The sign-in and sign-out the login screen starts, implemented by
/// `AuthGoogleViewModel`.
abstract interface class SignInActions {
  /// Signs in with Google and enters the person's organization. [Err] says
  /// why the sign-in failed; [Ok] also while another sign-in runs.
  Future<Result<void>> loginGoogle();

  /// Signs out. [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  Future<Result<bool>> logout();

  /// A session remembered from a previous run was restored: the person goes
  /// straight to the map (sets the session to bound, which the router
  /// follows).
  void sessionRestored();
}
