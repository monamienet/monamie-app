import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';

Widget buildGoogleButton(VoidCallback onPressed) {
  return SignInButton(
    Buttons.google,
    text: "Entrar com o Google",
    onPressed: onPressed,
  );
}
