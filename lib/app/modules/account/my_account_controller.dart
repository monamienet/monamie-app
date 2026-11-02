import 'package:flutter/foundation.dart';

import 'account_deletion.dart';
import 'account_deletion_backend.dart';
import 'my_account_state.dart';

export 'my_account_state.dart';

/// State of *Minha conta*: deleting the account. The owner (*titular*)
/// deletes their organization with it and confirms by typing its id. The
/// screen calls [loadOwnership] when it opens.
class MyAccountController extends ChangeNotifier {
  MyAccountController({
    required this._backend,
    required this.organizationId,
    required this._checkOwner,
    required this._onDeleted,
  });

  final AccountDeletionBackend _backend;
  final Future<bool> Function() _checkOwner;
  final Future<void> Function(AccountDeletion) _onDeleted;

  /// The bound organization.
  final String organizationId;

  MyAccountState _state = const MyAccountState();
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  MyAccountState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(MyAccountState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Asks the server whether the person owns the organization, so the
  /// screen says what the deletion takes with it before it is confirmed.
  Future<void> loadOwnership() async {
    if (_state.isCheckingOwner) return;
    _emit(_state.copyWith(isCheckingOwner: true, errorMessage: ''));
    try {
      final owner = await _checkOwner();
      _emit(_state.copyWith(isOwner: owner));
    } catch (e) {
      debugPrint('[Account] Could not read the ownership: $e');
      _emit(
        _state.copyWith(
          errorMessage:
              'Não foi possível carregar sua conta. Verifique a conexão e '
              'tente de novo.',
        ),
      );
    } finally {
      _emit(_state.copyWith(isCheckingOwner: false));
    }
  }

  /// What the owner typed to confirm.
  void setConfirmation(String value) =>
      _emit(_state.copyWith(confirmation: value));

  /// A member deletes at once; the owner once the id is typed. Nothing
  /// while the ownership is unknown.
  bool get canDelete => switch (_state.isOwner) {
    null => false,
    final owner =>
      !_state.isDeleting &&
          (!owner || confirmsId(_state.confirmation, organizationId)),
  };

  /// "Excluir conta" / "Excluir conta e organização".
  Future<void> deleteAccount() async {
    if (!canDelete) return;
    _emit(_state.copyWith(isDeleting: true, errorMessage: ''));
    try {
      final deletion = await _backend.request(
        confirmIds: _state.isOwner == true ? [organizationId] : const [],
      );
      await _onDeleted(deletion);
    } on AccountDeletionException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
    } catch (e) {
      debugPrint('[Account] Deletion failed: $e');
      _emit(
        _state.copyWith(
          errorMessage:
              'Não foi possível excluir agora. Verifique a conexão e tente de '
              'novo.',
        ),
      );
    } finally {
      _emit(_state.copyWith(isDeleting: false));
    }
  }
}
