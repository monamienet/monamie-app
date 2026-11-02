import 'package:flutter/foundation.dart';

import 'package:monamie_app/data/repositories/administrators/administrators_repository.dart';
import 'package:monamie_app/utils/result.dart';
import 'administrators_state.dart';

export 'administrators_state.dart';

/// State of *Administradores*, the owner's screen: who administers the
/// organization, appointing a member and turning an administrator back
/// into a member. One change at a time: [AdministratorsState.workingEmail]
/// guards reentrancy and marks the row in flight; it always resets in
/// `finally`. The screen calls [load] when it opens.
class AdministratorsViewModel extends ChangeNotifier {
  AdministratorsViewModel({
    required this.organizationId,
    required this.repository,
  });

  final String organizationId;

  /// The administrators' data (a fake in tests).
  final AdministratorsRepository repository;

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
      switch (await repository.list(organizationId)) {
        case Ok(value: final people):
          _emit(_state.copyWith(people: people));
        case Err(:final message):
          _emit(_state.copyWith(errorMessage: message));
      }
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
      final changed = await repository.setAdministrator(
        organizationId,
        email,
        admin: admin,
      );
      if (changed case Err(:final message)) {
        _emit(_state.copyWith(errorMessage: message));
        return false;
      }
      switch (await repository.list(organizationId)) {
        case Ok(value: final people):
          _emit(_state.copyWith(people: people));
          return true;
        case Err(:final message):
          _emit(_state.copyWith(errorMessage: message));
          return false;
      }
    } finally {
      _emit(_state.copyWith(workingEmail: null));
    }
  }
}
