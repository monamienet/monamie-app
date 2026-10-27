import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

/// The "Google" sign-in button from the sign_in_button package, which draws
/// Google's own button style and "G". (Google ships a ready-made button only
/// for the web; see google_button_web.dart.)
Widget buildGoogleButton(VoidCallback onPressed) => SignInButton(
  Buttons.google,
  text: 'Entrar com o Google',
  onPressed: onPressed,
);
