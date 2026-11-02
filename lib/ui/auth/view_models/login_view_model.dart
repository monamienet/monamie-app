import 'package:flutter/foundation.dart';
import 'package:monamie_app/ui/auth/view_models/login_state.dart';
import 'package:monamie_app/ui/auth/view_models/sign_in_actions.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/data/services/auth/stored_google_bond_check.dart';
import 'package:monamie_app/utils/result.dart';

export 'login_state.dart';

/// State of *Login*: restores a remembered session when the screen opens
/// ([restoreSession]) and starts the sign-in through [SignInActions].
class LoginViewModel extends ChangeNotifier {
  /// [signIn] runs the sign-in and sign-out (the `AuthGoogleViewModel`);
  /// [bondCheck] tells whether a sign-in survives from a previous run,
  /// [StoredGoogleBondCheck] by default.
  LoginViewModel({required this._signIn, GoogleBondCheck? bondCheck})
    : _injectedBondCheck = bondCheck;

  final SignInActions _signIn;
  final GoogleBondCheck? _injectedBondCheck;

  // Created on first use: the default reads Firebase and Hive.
  late final GoogleBondCheck _bondCheck =
      _injectedBondCheck ?? StoredGoogleBondCheck();

  LoginState _state = const LoginState();
  bool _disposed = false;
  bool _restoreStarted = false;

  /// What the screen shows; replaced whole, never changed in place.
  LoginState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(LoginState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Restores the session when the app is recreated from scratch, for
  /// example after Android kills the process while the person is in the
  /// system settings. Without it they would have to sign in again.
  ///
  /// Called by *Login* after its first frame; runs once per controller.
  Future<void> restoreSession() async {
    if (_restoreStarted) return;
    _restoreStarted = true;
    try {
      // The router follows the session to the map.
      if (await hasActiveGoogleBond()) _signIn.sessionRestored();
    } finally {
      _emit(_state.copyWith(isRestoringSession: false));
    }
  }

  /// See [GoogleBondCheck.hasActiveBond].
  Future<bool> hasActiveGoogleBond() => _bondCheck.hasActiveBond();

  /// See [SignInActions.loginGoogle].
  Future<Result<void>> loginGoogle() => _signIn.loginGoogle();

  /// See [SignInActions.logout].
  Future<Result<bool>> logoutGoogle() => _signIn.logout();
}
