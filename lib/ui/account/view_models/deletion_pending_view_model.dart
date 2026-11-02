import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/account/view_models/deletion_pending_state.dart';
import 'package:monamie_app/utils/result.dart';

export 'deletion_pending_state.dart';

/// State of *Em exclusão*: the account's pending deletion (from the
/// session), cancelling it, then entering again, or signing out.
class DeletionPendingViewModel extends ChangeNotifier {
  DeletionPendingViewModel({
    required this._session,
    required this._enterOrganization,
    required this._signOut,
    required this._repository,
  }) {
    _onSession();
    _onLeaving();
    _session.session.addListener(_onSession);
    _session.leaving.addListener(_onLeaving);
  }

  final SessionRepository _session;
  final EnterOrganization _enterOrganization;
  final SignOut _signOut;
  final AccountDeletionRepository _repository;

  DeletionPendingState _state = const DeletionPendingState();
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  DeletionPendingState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(DeletionPendingState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  void _onSession() {
    if (_session.session.value case SessionDeletionPending(:final deletion)) {
      _emit(_state.copyWith(accountDeletion: deletion));
    }
  }

  void _onLeaving() =>
      _emit(_state.copyWith(isLoggingOut: _session.leaving.value != null));

  @override
  void dispose() {
    _disposed = true;
    _session.session.removeListener(_onSession);
    _session.leaving.removeListener(_onLeaving);
    super.dispose();
  }

  /// "Cancelar exclusão": signs in again if needed (the deletion signed the
  /// account out), then cancels it.
  Future<void> cancelAccountDeletion() async {
    if (_state.cancellingDeletion || _state.isLoading) return;
    _emit(_state.copyWith(cancellingDeletion: true, deletionError: ''));
    try {
      if (await _session.keptOrSignIn() == null) return;
      switch (await _repository.cancel()) {
        case Ok():
          _emit(_state.copyWith(deletionRestored: true));
        case Err(:final message):
          _emit(_state.copyWith(deletionError: message));
      }
    } catch (e) {
      // Signing in to Google again failed.
      debugPrint('[Account] Cancel failed: $e');
      _emit(
        _state.copyWith(
          deletionError:
              'Não foi possível cancelar agora. Verifique a conexão e tente '
              'de novo.',
        ),
      );
    } finally {
      _emit(_state.copyWith(cancellingDeletion: false));
    }
  }

  /// "Entrar", once the deletion is cancelled: asks again which
  /// organizations the person belongs to, without the deletion check. [Err]
  /// says why it could not; [Ok] also while another operation runs.
  Future<Result<void>> enter() async {
    if (_state.isLoading) return const Ok(null);
    _emit(_state.copyWith(isLoading: true));
    try {
      return switch (await _enterOrganization.withKeptSignIn(
        checkDeletion: !_state.deletionRestored,
      )) {
        Ok() => const Ok(null),
        Err(:final error, :final stackTrace) => Err(
          "Não foi possível verificar agora: $error",
          title: EnterOrganization.errorTitle,
          error: error,
          stackTrace: stackTrace,
        ),
      };
    } finally {
      _emit(_state.copyWith(isLoading: false));
    }
  }

  /// "Sair". [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  Future<Result<bool>> logout() => _signOut();
}
