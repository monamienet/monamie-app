import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/invite.dart';

/// State of *Boas-vindas*: the invite just accepted, read once from the
/// session, and going on to the map.
class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel({required this._session})
    : invite = switch (_session.session.value) {
        SessionWelcome(:final invite) => invite,
        _ => null,
      };

  final SessionRepository _session;

  /// The invite the screen opened with (`null` only if the session moved
  /// on before the screen was built).
  final Invite? invite;

  /// *Boas-vindas* closed: the person goes on to the map (the router
  /// follows the session).
  void finishWelcome() => _session.moveTo(const SessionState.bound());
}
