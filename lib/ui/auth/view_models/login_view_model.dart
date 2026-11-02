import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/ui/auth/view_models/login_state.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

export 'login_state.dart';

/// State of *Login*: restores a remembered session when the screen opens
/// ([restoreSession]), signs in with Google ([loginGoogle], or the web
/// button's sign-ins) and goes on with [EnterOrganization].
///
/// It never navigates: the session it sets (or the entry sets) takes the
/// person to the next screen.
class LoginViewModel extends ChangeNotifier {
  /// [bondCheck] tells whether a sign-in survives from a previous run;
  /// [notices] shows the failures of the web sign-ins, which no tap waits
  /// for. Listens to Google's readiness and to the web sign-ins at once.
  LoginViewModel({
    required this._session,
    required this._enterOrganization,
    required this._bondCheck,
    required this._notices,
  }) {
    _state = _state.copyWith(googleReady: _session.googleReady.value);
    _session.googleReady.addListener(_onGoogleReady);
    _webSignInSub = _session.webSignIns.listen(_onWebGoogleSignIn);
  }

  final SessionRepository _session;
  final EnterOrganization _enterOrganization;
  final GoogleBondCheck _bondCheck;
  final NoticePresenter _notices;
  late final StreamSubscription<String?> _webSignInSub;

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

  void _onGoogleReady() =>
      _emit(_state.copyWith(googleReady: _session.googleReady.value));

  void _onEntering(String name) =>
      _emit(_state.copyWith(enteringOrganizationName: name));

  @override
  void dispose() {
    _disposed = true;
    _session.googleReady.removeListener(_onGoogleReady);
    _webSignInSub.cancel();
    super.dispose();
  }

  /// Restores the session when the app is recreated from scratch, for
  /// example after Android kills the process while the person is in the
  /// system settings. Without it they would have to sign in again.
  ///
  /// Called by *Login* after its first frame; runs once per view model.
  Future<void> restoreSession() async {
    if (_restoreStarted) return;
    _restoreStarted = true;
    try {
      // The router follows the session to the map.
      if (await hasActiveGoogleBond()) {
        _session.moveTo(const SessionState.bound());
      }
    } finally {
      _emit(_state.copyWith(isRestoringSession: false));
    }
  }

  /// See [GoogleBondCheck.hasActiveBond].
  Future<bool> hasActiveGoogleBond() => _bondCheck.hasActiveBond();

  /// "Entrar com o Google". [Err] says why the sign-in failed; [Ok] also
  /// while another sign-in runs.
  Future<Result<void>> loginGoogle() async {
    if (_state.isLoading || _state.isChoosingAccount) return const Ok(null);
    _emit(_state.copyWith(isChoosingAccount: true));
    try {
      // The spinner waits for an account: while Google's chooser is open there
      // is no organization to look for yet.
      final idToken = await _session.signInGoogle(
        onAccountChosen: () => _emit(_state.copyWith(isLoading: true)),
      );
      // Na web o login retorna null propositalmente (o resultado chega via
      // stream), portanto não exibimos erro quando idToken é null.
      if (idToken == null) return const Ok(null);
      return switch (await _enterOrganization.afterSignIn(
        idToken,
        onEntering: _onEntering,
      )) {
        Ok() => const Ok(null),
        Err(:final error, :final stackTrace) => _loginError(
          "Ocorreu um erro inesperado: $error",
          error,
          stackTrace,
        ),
      };
    } catch (e, stackTrace) {
      return _loginError("Ocorreu um erro inesperado: $e", e, stackTrace);
    } finally {
      _emit(
        _state.copyWith(
          isLoading: false,
          isChoosingAccount: false,
          enteringOrganizationName: null,
        ),
      );
    }
  }

  Future<void> _onWebGoogleSignIn(String? idToken) async {
    if (idToken == null) {
      _notices.show(
        const UserNotice(
          "Falha ao autenticar o usuário. Verifique sua conta Google e tente novamente.",
          title: EnterOrganization.errorTitle,
        ),
      );
      return;
    }
    if (_state.isLoading) return;
    _emit(_state.copyWith(isLoading: true));
    try {
      final entered = await _enterOrganization.afterSignIn(
        idToken,
        onEntering: _onEntering,
      );
      if (entered case Err(:final error)) {
        _notices.show(
          UserNotice(
            "Ocorreu um erro ao carregar seus dados: $error",
            title: EnterOrganization.errorTitle,
          ),
        );
      }
    } finally {
      _emit(_state.copyWith(isLoading: false, enteringOrganizationName: null));
    }
  }

  Err<void> _loginError(String message, Object? error, StackTrace? stack) =>
      Err(
        message,
        title: EnterOrganization.errorTitle,
        error: error,
        stackTrace: stack,
      );
}
