import 'package:flutter/foundation.dart';

import 'package:monamie_app/data/repositories/administrators/administrators_repository.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'administrators_state.dart';

export 'administrators_state.dart';

/// State of *Administradores*, the owner's screen: who administers the
/// organization, appointing a member and turning an administrator back
/// into a member. One change at a time: [setAdministrator] ignores a call
/// while one runs, and its [Command1.argument] marks the row in flight. The
/// screen runs [load] when it opens.
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
    load.dispose();
    setAdministrator.dispose();
    super.dispose();
  }

  /// Reads the administrators and the members. The failure is also kept in
  /// [AdministratorsState.errorMessage].
  late final Command0<void> load = Command0(_load);

  /// Makes `email` an administrator (`admin` true) or a member again, then
  /// reads the list again. The failure is also kept in
  /// [AdministratorsState.errorMessage]. Ignored while [load] runs.
  late final Command1<void, ({String email, bool admin})> setAdministrator =
      Command1(_setAdministrator, blocked: () => load.running);

  Future<Result<void>> _load() async {
    _emit(_state.copyWith(errorMessage: ''));
    return _list();
  }

  /// Reads the list into the state.
  Future<Result<void>> _list() async {
    final listed = await repository.list(organizationId);
    switch (listed) {
      case Ok(value: final people):
        _emit(_state.copyWith(people: people));
      case Err(:final message):
        _emit(_state.copyWith(errorMessage: message));
    }
    return listed;
  }

  Future<Result<void>> _setAdministrator(
    ({String email, bool admin}) change,
  ) async {
    _emit(_state.copyWith(errorMessage: ''));
    final changed = await repository.setAdministrator(
      organizationId,
      change.email,
      admin: change.admin,
    );
    if (changed case Err(:final message)) {
      _emit(_state.copyWith(errorMessage: message));
      return changed;
    }
    return _list();
  }
}
