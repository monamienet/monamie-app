import 'package:flutter/foundation.dart';

import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/utils/result.dart';
import 'my_account_state.dart';

export 'my_account_state.dart';

/// State of *Minha conta*: deleting the account. The owner (*titular*)
/// deletes their organization with it and confirms by typing its id. The
/// screen calls [loadOwnership] when it opens. Once the deletion is
/// scheduled, [SignOut] signs out of everything and shows *Em exclusão*.
class MyAccountViewModel extends ChangeNotifier {
  MyAccountViewModel({
    required this._repository,
    required this.organizationId,
    required this._directory,
    required this._signOut,
  });

  final AccountDeletionRepository _repository;
  final OrganizationDirectory _directory;
  final SignOut _signOut;

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
      final owner = await _directory.ownsOrganization(organizationId);
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
      final requested = await _repository.request(
        confirmIds: _state.isOwner == true ? [organizationId] : const [],
      );
      switch (requested) {
        case Ok(value: final deletion):
          await _signOut.afterAccountDeleted(deletion);
        case Err(:final message):
          _emit(_state.copyWith(errorMessage: message));
      }
    } catch (e) {
      // Signing out after the deletion was scheduled failed.
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
