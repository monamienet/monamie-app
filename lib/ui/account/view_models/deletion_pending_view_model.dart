import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/account/view_models/deletion_pending_state.dart';
import 'package:monamie_app/utils/command.dart';
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
    cancelAccountDeletion.dispose();
    enter.dispose();
    logout.dispose();
    super.dispose();
  }

  /// "Cancelar exclusão": signs in again if needed (the deletion signed the
  /// account out), then cancels it. The failure is also kept in
  /// [DeletionPendingState.deletionFailure], which the screen shows. Ignored
  /// while [enter] runs.
  late final Command0<void> cancelAccountDeletion = Command0(
    _cancelAccountDeletion,
    blocked: () => enter.running,
  );

  /// "Entrar", once the deletion is cancelled: asks again which
  /// organizations the person belongs to, without the deletion check. [Err]
  /// says why it could not.
  late final Command0<void> enter = Command0(_enter);

  /// "Sair". [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  late final Command0<bool> logout = Command0(() => _signOut());

  Future<Result<void>> _cancelAccountDeletion() async {
    _emit(_state.copyWith(deletionFailure: null));
    try {
      if (await _session.keptOrSignIn() == null) return const Ok(null);
      final cancelled = await _repository.cancel();
      switch (cancelled) {
        case Ok():
          _emit(_state.copyWith(deletionRestored: true));
        case Err(:final failure):
          _emit(_state.copyWith(deletionFailure: failure));
      }
      return cancelled;
    } catch (e, stackTrace) {
      // Signing in to Google again failed.
      debugPrint('[Account] Cancel failed: $e');
      const failure = Failure.connection(FailedAction.cancel);
      _emit(_state.copyWith(deletionFailure: failure));
      return Err(failure, error: e, stackTrace: stackTrace);
    }
  }

  Future<Result<void>> _enter() async => switch (await _enterOrganization
      .withKeptSignIn(checkDeletion: !_state.deletionRestored)) {
    Ok() => const Ok(null),
    Err(:final error, :final stackTrace) => Err(
      Failure.entry(EntryStage.check, '$error'),
      error: error,
      stackTrace: stackTrace,
    ),
  };
}
