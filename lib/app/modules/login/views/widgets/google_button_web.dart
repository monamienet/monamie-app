import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart' as web;

Widget buildGoogleButton(VoidCallback onPressed) {
  final plugin = GoogleSignInPlatform.instance as web.GoogleSignInPlugin;
  return plugin.renderButton(
    configuration: web.GSIButtonConfiguration(
      type: web.GSIButtonType.standard,
      theme: web.GSIButtonTheme.filledBlue,
      size: web.GSIButtonSize.large,
      text: web.GSIButtonText.signinWith,
    ),
  );
}
