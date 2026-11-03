import 'package:flutter/foundation.dart';

import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'my_account_state.dart';

export 'my_account_state.dart';

/// State of *Minha conta*: deleting the account. The owner (*titular*)
/// deletes their organization with it and confirms by typing its id. The
/// screen runs [loadOwnership] when it opens. Once the deletion is
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
    loadOwnership.dispose();
    deleteAccount.dispose();
    super.dispose();
  }

  /// Asks the server whether the person owns the organization, so the
  /// screen says what the deletion takes with it before it is confirmed.
  /// The failure is also kept in [MyAccountState.errorMessage].
  late final Command0<void> loadOwnership = Command0(_loadOwnership);

  /// "Excluir conta" / "Excluir conta e organização". Ignored unless
  /// [canDelete]; the failure is also kept in [MyAccountState.errorMessage].
  late final Command0<void> deleteAccount = Command0(
    _deleteAccount,
    blocked: () => !canDelete,
  );

  Future<Result<void>> _loadOwnership() async {
    _emit(_state.copyWith(errorMessage: ''));
    try {
      final owner = await _directory.ownsOrganization(organizationId);
      _emit(_state.copyWith(isOwner: owner));
      return const Ok(null);
    } catch (e, stackTrace) {
      debugPrint('[Account] Could not read the ownership: $e');
      const message =
          'Não foi possível carregar sua conta. Verifique a conexão e '
          'tente de novo.';
      _emit(_state.copyWith(errorMessage: message));
      return Err(message, error: e, stackTrace: stackTrace);
    }
  }

  /// What the owner typed to confirm.
  void setConfirmation(String value) =>
      _emit(_state.copyWith(confirmation: value));

  /// A member deletes at once; the owner once the id is typed. Nothing
  /// while the ownership is unknown or a deletion runs.
  bool get canDelete => switch (_state.isOwner) {
    null => false,
    final owner =>
      !deleteAccount.running &&
          (!owner || confirmsId(_state.confirmation, organizationId)),
  };

  Future<Result<void>> _deleteAccount() async {
    _emit(_state.copyWith(errorMessage: ''));
    try {
      final requested = await _repository.request(
        confirmIds: _state.isOwner == true ? [organizationId] : const [],
      );
      switch (requested) {
        case Ok(value: final deletion):
          await _signOut.afterAccountDeleted(deletion);
          return const Ok(null);
        case Err(:final message, :final title, :final error, :final stackTrace):
          _emit(_state.copyWith(errorMessage: message));
          return Err(
            message,
            title: title,
            error: error,
            stackTrace: stackTrace,
          );
      }
    } catch (e, stackTrace) {
      // Signing out after the deletion was scheduled failed.
      debugPrint('[Account] Deletion failed: $e');
      const message =
          'Não foi possível excluir agora. Verifique a conexão e tente de '
          'novo.';
      _emit(_state.copyWith(errorMessage: message));
      return Err(message, error: e, stackTrace: stackTrace);
    }
  }
}
