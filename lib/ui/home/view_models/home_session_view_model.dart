import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/home/view_models/home_session_state.dart';
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
  bool _readingOwnership = false;

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
    super.dispose();
  }

  /// "Sair". [Ok] holds whether the sign-out finished (`false` while
  /// another one runs); [Err] says why it failed.
  Future<Result<bool>> logout() => _signOut();

  /// "Trocar de organização". [Err] says why nothing changed; [Ok] also
  /// while another operation runs.
  Future<Result<void>> switchOrganization() => _signOut.switchOrganization();

  /// Reads once whether the signed-in user owns [organizationId] into
  /// [HomeSessionState.ownership]. A failure leaves it unknown, so
  /// owner-only entries stay hidden (the server refuses anyone else anyway)
  /// and the next call retries.
  Future<void> loadOwnership(String organizationId) async {
    if (_readingOwnership || _state.ownership.containsKey(organizationId)) {
      return;
    }
    _readingOwnership = true;
    try {
      final owns = await _directory.ownsOrganization(organizationId);
      _emit(
        _state.copyWith(ownership: {..._state.ownership, organizationId: owns}),
      );
    } catch (e) {
      debugPrint('[Account] Could not read the ownership: $e');
    } finally {
      _readingOwnership = false;
    }
  }
}
