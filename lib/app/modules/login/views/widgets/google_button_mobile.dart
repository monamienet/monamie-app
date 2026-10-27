import 'package:flutter/material.dart';
import 'package:monamie_app/app/config/partner/monamie_brand.dart';

/// "Entrar com Google" in the MonAmie sign-in style: cream on navy, with
/// Google's "G" (from the sign_in_button package's assets).
Widget buildGoogleButton(VoidCallback onPressed) => SizedBox(
  height: 56,
  child: FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: MonAmieBrand.cream,
      foregroundColor: MonAmieBrand.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logos/google_light.png',
          package: 'sign_in_button',
          width: 22,
          height: 22,
        ),
        const SizedBox(width: 12),
        const Text('Entrar com Google'),
      ],
    ),
  ),
);
