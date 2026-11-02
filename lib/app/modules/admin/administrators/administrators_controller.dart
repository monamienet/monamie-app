import 'package:flutter/foundation.dart';

import 'administrators_backend.dart';
import 'administrators_state.dart';

export 'administrators_state.dart';

/// State of *Administradores*, the owner's screen: who administers the
/// organization, appointing a member and turning an administrator back
/// into a member. One change at a time: [AdministratorsState.workingEmail]
/// guards reentrancy and marks the row in flight; it always resets in
/// `finally`. The screen calls [load] when it opens.
class AdministratorsController extends ChangeNotifier {
  AdministratorsController({
    required this.organizationId,
    required this.backend,
  });

  final String organizationId;

  /// The central functions (a fake in tests).
  final AdministratorsBackend backend;

  AdministratorsState _state = const AdministratorsState();
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  AdministratorsState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(AdministratorsState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (_state.isLoading) return;
    _emit(_state.copyWith(isLoading: true, errorMessage: ''));
    try {
      final people = await backend.list(organizationId);
      _emit(_state.copyWith(people: people));
    } on AdministratorsException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
    } catch (e) {
      debugPrint('[Administrators] Could not load: $e');
      _emit(
        _state.copyWith(
          errorMessage: 'Não foi possível carregar os administradores.',
        ),
      );
    } finally {
      _emit(_state.copyWith(isLoading: false));
    }
  }

  /// Makes [email] an administrator ([admin] true) or a member again;
  /// returns whether it changed (the message is in
  /// [AdministratorsState.errorMessage] when not).
  Future<bool> setAdministrator(String email, {required bool admin}) async {
    if (_state.workingEmail != null || _state.isLoading) return false;
    _emit(_state.copyWith(workingEmail: email, errorMessage: ''));
    try {
      await backend.setAdministrator(organizationId, email, admin: admin);
      final people = await backend.list(organizationId);
      _emit(_state.copyWith(people: people));
      return true;
    } on AdministratorsException catch (e) {
      _emit(_state.copyWith(errorMessage: e.message));
      return false;
    } catch (e) {
      debugPrint('[Administrators] Change failed: $e');
      _emit(
        _state.copyWith(
          errorMessage:
              'Não foi possível concluir agora. Verifique a conexão e tente '
              'de novo.',
        ),
      );
      return false;
    } finally {
      _emit(_state.copyWith(workingEmail: null));
    }
  }
}
