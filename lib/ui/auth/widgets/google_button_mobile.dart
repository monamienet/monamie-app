import 'package:flutter/material.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:sign_in_button/sign_in_button.dart';

/// The "Google" sign-in button from the sign_in_button package, which draws
/// Google's own button style and "G", sized and rounded like the design
/// (56 px tall, 16 px corners). Google ships a ready-made button only for
/// the web, which needs the app's [locale]; see google_button_web.dart. This
/// one draws its text from the app's texts, so it ignores [locale].
Widget buildGoogleButton(VoidCallback onPressed, {required Locale locale}) =>
    Builder(
      builder: (context) => SizedBox(
        height: 56,
        child: SignInButton(
          Buttons.google,
          text: AppLocalizations.of(context).loginWithGoogle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B1838),
          ),
          onPressed: onPressed,
        ),
      ),
    );
