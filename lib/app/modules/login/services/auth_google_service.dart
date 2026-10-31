import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';

/// Google sign-in in two steps.
///
/// 1. [signInGoogle] (or, on the web, the Google button and [onWebSignIn])
///    signs in to the central MonAmie project and returns the Google ID
///    token. The central session lets the app ask which organizations the user
///    belongs to.
/// 2. [signInToOrganization] reuses that ID token for the bound organization's project,
///    which accepts the central web client under "Allowed client IDs".
class AuthGoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserGoogleRepository _userRepository = UserGoogleRepository();

  fb.FirebaseAuth get _organizationAuth =>
      CurrentOrganizationFirebase.instance.auth;

  // Google ID tokens of web sign-ins, which arrive as events (the button is
  // rendered by Google); null when the central sign-in failed.
  final _webSignInController = StreamController<String?>.broadcast();
  Stream<String?> get onWebSignIn => _webSignInController.stream;

  late final Future<void> _init = _initialize();

  Future<void> ensureInitialized() => _init;

  AuthGoogleService();

  Future<void> _initialize() async {
    debugPrint('AuthGoogleService: initialize start');

    try {
      await _googleSignIn.initialize(
        // Web needs the central OAuth web client id. On Android a null
        // serverClientId makes the plugin use default_web_client_id, which the
        // google-services plugin generates from the central project's config.
        clientId: kIsWeb ? CentralFirebase.webGoogleClientId : null,
      );

      debugPrint('AuthGoogleService: initialize done');

      // só na web o login chega via evento (o botão é do próprio Google)
      if (kIsWeb) {
        //_googleSignIn.authenticationEvents.listen(_onWebAuthEvent);
        _googleSignIn.authenticationEvents.listen((event) {
          debugPrint('AuthGoogleService event: $event');
          _onWebAuthEvent(event);
        });
      }
    } catch (e) {
      debugPrint('AuthGoogleService: initialize error: $e');
      rethrow;
    }
  }

  Future<void> _onWebAuthEvent(GoogleSignInAuthenticationEvent event) async {
    debugPrint('AuthGoogleService _onWebAuthEvent: ${event.runtimeType}');

    if (event is GoogleSignInAuthenticationEventSignIn) {
      debugPrint('AuthGoogleService sign-in event user: ${event.user.email}');
      try {
        _webSignInController.add(await _signInCentral(event.user));
      } catch (e) {
        debugPrint('AuthGoogleService central sign-in failed: $e');
        _webSignInController.add(null);
      }
      return;
    }
    if (event is GoogleSignInAuthenticationEventSignOut) {
      //_webSignInController.add(null);
      debugPrint('AuthGoogleService sign-out event');
      return;
    }
  }

  /// Shows Google's account chooser and signs in to the central project.
  /// Returns the Google ID token, or `null` on the web, where the result
  /// arrives through [onWebSignIn].
  ///
  /// [onAccountChosen] runs once the chooser is dismissed with an account, before
  /// the central sign-in, so the caller can show progress only from then on.
  Future<String?> signInGoogle({void Function()? onAccountChosen}) async {
    await _init;
    if (kIsWeb) return null;
    final account = await _googleSignIn.authenticate();
    onAccountChosen?.call();
    return _signInCentral(account);
  }

  /// A fresh Google ID token for the account that is already signed in,
  /// without showing the account chooser. `null` when it cannot be had
  /// silently (on the web, when Google asks the person to choose again, or
  /// when the attempt fails).
  Future<String?> refreshGoogleIdToken() async {
    await _init;
    if (kIsWeb) return null;
    try {
      final account = await _googleSignIn.attemptLightweightAuthentication();
      return account?.authentication.idToken;
    } catch (e) {
      debugPrint('AuthGoogleService: silent sign-in failed: $e');
      return null;
    }
  }

  Future<String> _signInCentral(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google returned no ID token for ${account.email}.');
    }
    await CentralFirebase.auth.signInWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
    return idToken;
  }

  /// Signs in to the bound organization's project with the central Google ID
  /// token. The profile is saved later by [saveOrganizationProfile].
  Future<void> signInToOrganization(String idToken) async {
    await _organizationAuth.signInWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Builds the profile of the person signed in to the bound organization
  /// and keeps it on the device (Hive). Nothing is written to Firestore.
  Future<UserGoogleModel?> saveOrganizationProfile() async {
    final user = _organizationAuth.currentUser;
    if (user == null) return null;
    return _saveGoogleProfile(user);
  }

  Future<UserGoogleModel?> _saveGoogleProfile(fb.User user) async {
    final photoUrl = user.photoURL;
    final avatarBase64 = await _downloadAvatarBase64(photoUrl);
    final profile = await _userRepository.saveGoogleProfile(
      user.email ?? '',
      user.displayName ?? '',
      user.uid,
      photoUrl ?? '',
      avatarBase64: avatarBase64,
    );

    return profile;
  }

  Future<String?> _downloadAvatarBase64(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode != 200) {
        return null;
      }

      return base64Encode(response.bodyBytes);
    } catch (e) {
      debugPrint('AuthGoogleService: avatar download failed: $e');
      return null;
    }
  }

  /// E-mail of the account signed in to the central project, or `null`.
  Future<String?> centralEmail() async =>
      CentralFirebase.auth.currentUser?.email;

  /// Signs out of the bound organization's project only; the MonAmie (central)
  /// session stays.
  Future<void> signOutOfOrganization() async {
    if (CurrentOrganizationFirebase.isSet) await _organizationAuth.signOut();
  }

  /// Signs out of Google, the central project and the bound organization.
  Future<void> logoutGoogle() async {
    await _googleSignIn.signOut();
    await CentralFirebase.auth.signOut();
    if (CurrentOrganizationFirebase.isSet) await _organizationAuth.signOut();
  }

  void dispose() {
    _webSignInController.close();
  }
}
