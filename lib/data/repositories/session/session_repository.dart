import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/model/user_google_model.dart';

import 'session_state.dart';

export 'session_state.dart';

/// The app-wide source of truth of the session: where the sign-in flow
/// stands ([session], the router's `refreshListenable`), the Google sign-in
/// to the central MonAmie project and what it keeps (the ID token, the
/// e-mail), and whether the person is leaving the bound organization.
///
/// It moves only when told: the use cases (`EnterOrganization`, `SignOut`)
/// and the screens' view models decide each transition and set it with
/// [moveTo]. Created once by the composition root, which calls [start].
///
/// The sign-in methods throw when the plugin or Firebase does, like the
/// service they wrap; their callers turn failures into messages.
abstract class SessionRepository {
  /// Where the flow stands; notifies only when it changes.
  ValueListenable<SessionState> get session;

  /// Whether Google Sign-In finished initializing (or failed to).
  ValueListenable<bool> get googleReady;

  /// How the person is leaving the bound organization, `null` when they are
  /// not: set by `SignOut` while it runs.
  ValueListenable<SessionExit?> get leaving;

  /// Google ID tokens of the web sign-ins, which arrive as events (Google
  /// draws the button on *Login*); `null` when the central sign-in failed.
  Stream<String?> get webSignIns;

  /// E-mail of the Google account signed in to MonAmie (central project),
  /// shown on MonAmie's own screens; `null` once signed out.
  String? get signedInEmail;

  /// The Google ID token kept since the last sign-in (in memory, until
  /// sign-out), to enter an organization without asking Google again.
  String? get idToken;

  /// Initializes Google Sign-In; runs once.
  void start();

  /// Sets where the flow stands; the router takes the person there.
  void moveTo(SessionState next);

  /// Sets [leaving].
  void setLeaving(SessionExit? exit);

  /// Shows Google's account chooser and signs in to the central project;
  /// returns the Google ID token and keeps it, or `null` on the web, where
  /// the result arrives through [webSignIns]. [onAccountChosen] runs once an
  /// account is chosen, before the central sign-in.
  Future<String?> signInGoogle({void Function()? onAccountChosen});

  /// The kept [idToken], or a new one from [signInGoogle] when none is kept.
  Future<String?> keptOrSignIn();

  /// The kept [idToken] while it is still good, otherwise a fresh one asked
  /// of Google silently (without keeping it); `null` when none can be had.
  Future<String?> freshIdToken();

  /// Keeps [token] as [idToken].
  void keepIdToken(String token);

  /// Reads [signedInEmail] from the central project.
  Future<void> readSignedInEmail();

  /// Signs in to the bound organization's project with [idToken].
  Future<void> signInToOrganization(String idToken);

  /// Keeps on the device the Google profile of the person signed in to the
  /// bound organization; `null` when nobody is.
  Future<UserGoogleModel?> saveOrganizationProfile();

  /// Signs out of the bound organization's project only; the MonAmie
  /// (central) sign-in stays.
  Future<void> signOutOfOrganization();

  /// Signs out of Google, the central project and the bound organization,
  /// and forgets [idToken] and [signedInEmail].
  Future<void> signOut();

  /// Stops notifying.
  void dispose();
}
