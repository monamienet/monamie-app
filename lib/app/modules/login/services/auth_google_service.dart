import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/firebase/central_firebase.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:monamie_app/app/data/firebase/current_partner_firebase.dart';

/// Google sign-in in two steps.
///
/// 1. [signInGoogle] (or, on the web, the Google button and [onWebSignIn])
///    signs in to the central MonAmie project and returns the Google ID
///    token. The central session lets the app ask which partners the user
///    belongs to.
/// 2. [signInToPartner] reuses that ID token for the bound partner's project,
///    which accepts the central web client under "Allowed client IDs".
class AuthGoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserGoogleRepository _userRepository = UserGoogleRepository();

  fb.FirebaseAuth get _partnerAuth => CurrentPartnerFirebase.instance.auth;

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
  Future<String?> signInGoogle() async {
    await _init;
    if (kIsWeb) return null;
    final account = await _googleSignIn.authenticate();
    return _signInCentral(account);
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

  /// Signs in to the bound partner's project with the Google [idToken] from
  /// [signInGoogle], and creates or refreshes the user's profile there.
  /// Signs in to the bound partner's project with the central Google ID
  /// token. The profile is saved later by [savePartnerProfile], once the
  /// claims let the rules accept it.
  Future<void> signInToPartner(String idToken) async {
    await _partnerAuth.signInWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Saves the signed-in person's profile in the bound partner
  /// (`partners/{id}/users/{uid}`). Needs synced claims: the rules only let
  /// the partner's members write there.
  Future<UserGoogleModel?> savePartnerProfile() async {
    final user = _partnerAuth.currentUser;
    if (user == null) return null;
    return _createUserDoc(user);
  }

  Future<UserGoogleModel?> _createUserDoc(fb.User user) async {
    final photoUrl = user.photoURL;
    final avatarBase64 = await _downloadAvatarBase64(photoUrl);
    final userDoc = await _userRepository.createUserDoc(
      user.email ?? '',
      user.displayName ?? '',
      user.uid,
      photoUrl ?? '',
      avatarBase64: avatarBase64,
    );

    return userDoc;
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

  /// Signs out of Google, the central project and the bound partner.
  Future<void> logoutGoogle() async {
    await _googleSignIn.signOut();
    await CentralFirebase.auth.signOut();
    if (CurrentPartnerFirebase.isSet) await _partnerAuth.signOut();
  }

  Future<String?> getFirebaseIdToken() async {
    // Pega o usuário logado atualmente no Firebase
    final user = _partnerAuth.currentUser;

    if (user != null) {
      // getIdToken(true) força a atualização do token caso ele esteja expirado
      return await user.getIdToken(true);
    }
    return null;
  }

  void dispose() {
    _webSignInController.close();
  }
}
