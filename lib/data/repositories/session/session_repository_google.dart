import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/data/services/auth/id_token_expiry.dart';

import 'session_repository.dart';

/// [SessionRepository] over Google Sign-In and the central project's
/// Firebase Auth ([AuthGoogleService]).
class SessionRepositoryGoogle implements SessionRepository {
  SessionRepositoryGoogle({required this._auth});

  final AuthGoogleService _auth;

  final ValueNotifier<SessionState> _session = ValueNotifier(
    const SessionState.signedOut(),
  );
  final ValueNotifier<bool> _googleReady = ValueNotifier(false);
  final ValueNotifier<SessionExit?> _leaving = ValueNotifier(null);
  bool _started = false;
  bool _disposed = false;
  String? _idToken;
  String? _signedInEmail;

  @override
  ValueListenable<SessionState> get session => _session;

  @override
  ValueListenable<bool> get googleReady => _googleReady;

  @override
  ValueListenable<SessionExit?> get leaving => _leaving;

  @override
  Stream<String?> get webSignIns => _auth.onWebSignIn;

  @override
  String? get signedInEmail => _signedInEmail;

  @override
  String? get idToken => _idToken;

  @override
  void start() {
    if (_started) return;
    _started = true;
    _auth
        .ensureInitialized()
        .then((_) => _setGoogleReady())
        .catchError((_) => _setGoogleReady());
  }

  void _setGoogleReady() {
    if (!_disposed) _googleReady.value = true;
  }

  @override
  void moveTo(SessionState next) {
    if (!_disposed) _session.value = next;
  }

  @override
  void setLeaving(SessionExit? exit) {
    if (!_disposed) _leaving.value = exit;
  }

  @override
  Future<String?> signInGoogle({void Function()? onAccountChosen}) async {
    final token = await _auth.signInGoogle(onAccountChosen: onAccountChosen);
    if (token != null) _idToken = token;
    return token;
  }

  @override
  Future<String?> keptOrSignIn() async => _idToken ?? await signInGoogle();

  @override
  Future<String?> freshIdToken() async {
    // The token kept since sign-in is used while it is good; only then does
    // Google need to be asked again.
    final kept = _idToken;
    return idTokenIsFresh(kept, DateTime.now())
        ? kept
        : _auth.refreshGoogleIdToken();
  }

  @override
  void keepIdToken(String token) => _idToken = token;

  @override
  Future<void> readSignedInEmail() async {
    _signedInEmail = await _auth.centralEmail();
  }

  @override
  Future<void> signInToOrganization(String idToken) =>
      _auth.signInToOrganization(idToken);

  @override
  Future<UserGoogleModel?> saveOrganizationProfile() =>
      _auth.saveOrganizationProfile();

  @override
  Future<void> signOutOfOrganization() => _auth.signOutOfOrganization();

  @override
  Future<void> signOut() async {
    await _auth.logoutGoogle();
    _idToken = null;
    _signedInEmail = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _session.dispose();
    _googleReady.dispose();
    _leaving.dispose();
  }
}
