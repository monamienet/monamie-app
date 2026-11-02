// check_layers: state_contract

import 'package:monamie_app/app/utils/result.dart';

/// The sign-in and sign-out the login screen starts, implemented by
/// `AuthGoogleController`.
abstract interface class SignInActions {
  /// Signs in with Google and enters the person's organization. [Err] says
  /// why the sign-in failed; [Ok] also while another sign-in runs.
  Future<Result<void>> loginGoogle();

  /// Signs out. [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  Future<Result<bool>> logout();
}
