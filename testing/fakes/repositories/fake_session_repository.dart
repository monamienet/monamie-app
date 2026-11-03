import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';

import 'fake_outcomes.dart';

/// [SessionRepository] with Google simulated in memory.
///
/// The session, `leaving` and Google's readiness behave like the real
/// repository's ([moveTo], [setLeaving], [start]), and every move is also
/// written to [moves], in order. Google's chooser returns
/// [googleAccountToken] (`null`: the person closed it), the central
/// project's account is [centralEmail], a silent refresh returns
/// [refreshedToken], and signing in to an organization leaves
/// [organizationProfile] signed in there. [addWebSignIn] sends a sign-in of
/// the web button. A failure asked for with `fail` throws, as the plugin
/// does (`fail('signInGoogle', …)`).
class FakeSessionRepository with FakeOutcomes implements SessionRepository {
  FakeSessionRepository({
    SessionState initial = const SessionState.signedOut(),
    bool googleReady = false,
    this.googleAccountToken = 'fake-google-id-token',
    this.centralEmail = 'ana@example.com',
    this.refreshedToken,
    UserGoogleModel? organizationProfile,
    this._idToken,
    this._signedInEmail,
  }) : _session = ValueNotifier(initial),
       _googleReady = ValueNotifier(googleReady),
       organizationProfile =
           organizationProfile ??
           UserGoogleModel(id: 'uid-ana', name: 'Ana', email: centralEmail);

  final ValueNotifier<SessionState> _session;
  final ValueNotifier<bool> _googleReady;
  final _leaving = ValueNotifier<SessionExit?>(null);
  final _webSignIns = StreamController<String?>.broadcast();

  /// What Google's account chooser returns; `null` when it is closed.
  String? googleAccountToken;

  /// The e-mail of the central project's signed-in account.
  String centralEmail;

  /// What a silent refresh of the Google token returns, when none is kept.
  String? refreshedToken;

  /// Who is signed in to the organization's project after
  /// [signInToOrganization]; `null` makes the entry fail.
  UserGoogleModel? organizationProfile;

  /// Whether someone is signed in to the bound organization's project.
  bool signedInToOrganization = false;

  /// Every session moved to, in order.
  final List<SessionState> moves = [];

  /// Every value given to [setLeaving], in order.
  final List<SessionExit?> leavingHistory = [];

  String? _idToken;
  String? _signedInEmail;
  bool _started = false;
  bool _disposed = false;

  @override
  ValueListenable<SessionState> get session => _session;

  @override
  ValueListenable<bool> get googleReady => _googleReady;

  @override
  ValueListenable<SessionExit?> get leaving => _leaving;

  @override
  Stream<String?> get webSignIns => _webSignIns.stream;

  /// Sends a sign-in of the web button: its ID token, or `null` when the
  /// central sign-in failed.
  void addWebSignIn(String? idToken) => _webSignIns.add(idToken);

  @override
  String? get signedInEmail => _signedInEmail;

  @override
  String? get idToken => _idToken;

  /// Google Sign-In is ready at once.
  @override
  void start() {
    calls.add((method: 'start', arguments: const []));
    if (_started) return;
    _started = true;
    if (!_disposed) _googleReady.value = true;
  }

  @override
  void moveTo(SessionState next) {
    calls.add((method: 'moveTo', arguments: [next]));
    moves.add(next);
    if (!_disposed) _session.value = next;
  }

  @override
  void setLeaving(SessionExit? exit) {
    calls.add((method: 'setLeaving', arguments: [exit]));
    leavingHistory.add(exit);
    if (!_disposed) _leaving.value = exit;
  }

  @override
  Future<String?> signInGoogle({void Function()? onAccountChosen}) =>
      run('signInGoogle', const [], () {
        final token = googleAccountToken;
        if (token != null) {
          onAccountChosen?.call();
          _idToken = token;
        }
        return token;
      });

  @override
  Future<String?> keptOrSignIn() async => _idToken ?? await signInGoogle();

  /// The kept token (the fake's tokens never expire), else
  /// [refreshedToken].
  @override
  Future<String?> freshIdToken() =>
      run('freshIdToken', const [], () => _idToken ?? refreshedToken);

  @override
  void keepIdToken(String token) {
    calls.add((method: 'keepIdToken', arguments: [token]));
    _idToken = token;
  }

  @override
  Future<void> readSignedInEmail() =>
      run('readSignedInEmail', const [], () => _signedInEmail = centralEmail);

  @override
  Future<void> signInToOrganization(String idToken) => run(
    'signInToOrganization',
    [idToken],
    () => signedInToOrganization = true,
  );

  @override
  Future<UserGoogleModel?> saveOrganizationProfile() => run(
    'saveOrganizationProfile',
    const [],
    () => signedInToOrganization ? organizationProfile : null,
  );

  @override
  Future<void> signOutOfOrganization() => run(
    'signOutOfOrganization',
    const [],
    () => signedInToOrganization = false,
  );

  @override
  Future<void> signOut() => run('signOut', const [], () {
    signedInToOrganization = false;
    _idToken = null;
    _signedInEmail = null;
  });

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session.dispose();
    _googleReady.dispose();
    _leaving.dispose();
    _webSignIns.close();
  }
}
