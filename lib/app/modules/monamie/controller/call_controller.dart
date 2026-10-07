import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class CallController extends GetxController {
    Future<void> launchGoogleMeet(String email) async {
    await Clipboard.setData(ClipboardData(text: email));

    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        //action: 'action_view',
        action: 'android.intent.action.MAIN',
        //data: url,
        package: 'com.google.android.apps.tachyon', // Google Meet standalone
      );

      try {
        await intent.launch();
      } catch (e) {
        if (kDebugMode) {
          print('Não foi possível abrir o Google Meet standalone: $e');
        }
      }
    } else if (Platform.isIOS) {
      final Uri meetAppUri = Uri.parse('gmeet://');
      final Uri meetWebUri = Uri.parse('https://meet.google.com/');
      try {
        // Tenta abrir o aplicativo nativo do Google Meet
        if (await canLaunchUrl(meetAppUri)) {
          await launchUrl(meetAppUri);
        } else {
          // Caso não esteja instalado, abre no Safari como fallback
          await launchUrl(meetWebUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Não foi possível abrir o Google Meet no iOS: $e');
        }
      }
    }
  }
}