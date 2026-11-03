import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/home/view_models/home_session_state.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';

export 'home_session_state.dart';

/// State of the home screen's session part: the menu's "Sair", "Trocar de
/// organização" and owner-only entries, and the overlay while the person
/// leaves the organization, however the leaving started (also losing access
/// or deleting the account, from elsewhere in the organization's shell).
class HomeSessionViewModel extends ChangeNotifier {
  HomeSessionViewModel({
    required this._session,
    required this._signOut,
    required this._directory,
  }) {
    _onLeaving();
    _session.leaving.addListener(_onLeaving);
  }

  final SessionRepository _session;
  final SignOut _signOut;
  final OrganizationDirectory _directory;

  HomeSessionState _state = const HomeSessionState();
  bool _disposed = false;

  /// What the screen shows; replaced whole, never changed in place.
  HomeSessionState get state => _state;

  /// Replaces the state, notifying only when it differs.
  void _emit(HomeSessionState next) {
    final changed = next != _state;
    _state = next;
    if (changed && !_disposed) notifyListeners();
  }

  void _onLeaving() => _emit(_state.copyWith(leaving: _session.leaving.value));

  @override
  void dispose() {
    _disposed = true;
    _session.leaving.removeListener(_onLeaving);
    logout.dispose();
    switchOrganization.dispose();
    loadOwnership.dispose();
    super.dispose();
  }

  /// "Sair". [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  late final Command0<bool> logout = Command0(() => _signOut());

  /// "Trocar de organização". [Err] says why nothing changed; [Ok] also
  /// while a sign-out runs; `null` while this switch already runs.
  late final Command0<void> switchOrganization = Command0(
    () => _signOut.switchOrganization(),
  );

  /// Reads once whether the signed-in user owns the organization given
  /// into [HomeSessionState.ownership]. A failure leaves it unknown, so
  /// owner-only entries stay hidden (the server refuses anyone else anyway)
  /// and the next call retries; it always ends [Ok].
  late final Command1<void, String> loadOwnership = Command1(_loadOwnership);

  Future<Result<void>> _loadOwnership(String organizationId) async {
    if (_state.ownership.containsKey(organizationId)) return const Ok(null);
    try {
      final owns = await _directory.ownsOrganization(organizationId);
      _emit(
        _state.copyWith(ownership: {..._state.ownership, organizationId: owns}),
      );
    } catch (e) {
      debugPrint('[Account] Could not read the ownership: $e');
    }
    return const Ok(null);
  }
}
