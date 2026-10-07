import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/config/secrets.dart';
import 'package:monamie_app/app/data/models/user_google_model.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthGoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserGoogleRepository _userRepository = UserGoogleRepository();
  final FirebaseApp _app = Firebase.app();
  late final fb.FirebaseAuth _auth = fb.FirebaseAuth.instanceFor(app: _app);

  // stream para avisar a UI/controller quando o login web (via evento) terminar
  final _webSignInController = StreamController<UserGoogleModel?>.broadcast();
  Stream<UserGoogleModel?> get onWebSignIn => _webSignInController.stream;

  late final Future<void> _init = _initialize();

  Future<void> ensureInitialized() => _init;

  AuthGoogleService();

  Future<void> _initialize() async {
    debugPrint('AuthGoogleService: initialize start');

    try {
      await _googleSignIn.initialize(
        // clientId é obrigatório na web
        // NOTE: estou usando o mesmo id para clientId e serverClientId
        clientId: kIsWeb ? Secrets.umpGoogleServerWebClientId : null,
        serverClientId: kIsWeb ? null : Secrets.monamieGoogleServerWebClientId,
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
      final user = await _signIn(event.user);
      debugPrint('AuthGoogleService _signIn result: ${user?.email}');
      _webSignInController.add(user);
      return;
    } 
    if (event is GoogleSignInAuthenticationEventSignOut) {
      //_webSignInController.add(null);
      debugPrint('AuthGoogleService sign-out event');
      return;
    }
  }

  Future<UserGoogleModel?> signInGoogle() async {
    await _init;

    if (kIsWeb) return null;

    //await _init;
    var account = await _googleSignIn.authenticate();
    return _signIn(account);
  }

  Future<UserGoogleModel?> _signIn(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication googleAuth = account.authentication;
    final authCredential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    var userCredential = await _auth.signInWithCredential(authCredential);

    return await _createUserDoc(userCredential);
  }

  Future<UserGoogleModel?> _createUserDoc(
    fb.UserCredential userCredential,
  ) async {
    final photoUrl = userCredential.user?.photoURL;
    final avatarBase64 = await _downloadAvatarBase64(photoUrl);
    final userDoc = await _userRepository.createUserDoc(
      userCredential.user!.email ?? '',
      userCredential.user!.displayName ?? '',
      userCredential.user!.uid,
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

  Future<UserGoogleModel?> trySignInGoogle() async {
    await _init;
    final account = _googleSignIn.attemptLightweightAuthentication();
    if (account == null) {
      return null;
    }
    final googleUser = await account;
    return googleUser != null ? await _signIn(googleUser) : null;
  }

  Future<void> logoutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<String?> getFirebaseIdToken() async {
    // Pega o usuário logado atualmente no Firebase
    final user = _auth.currentUser;

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
