import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Path, relative to the web app's base URL, of the central web config staged
/// by `dart run tool/partner.dart web`.
const webCentralConfigPath = 'central/firebase.json';

const _webConfigTimeout = Duration(seconds: 10);

/// Thrown when the central Firebase project cannot be set up. The message
/// says how to fix the build.
class CentralFirebaseException implements Exception {
  CentralFirebaseException(this.message);

  final String message;

  @override
  String toString() => 'CentralFirebaseException: $message';
}

/// The central MonAmie Firebase project (`monamienet-app`): Google sign-in
/// and the `resolvePartners` function. It is the `[DEFAULT]` app; partners'
/// projects are separate named apps (see `PartnerSession`).
abstract final class CentralFirebase {
  static String? _webGoogleClientId;

  /// OAuth web client id for Google sign-in on the web; `null` on Android,
  /// where the google-services plugin provides `default_web_client_id`.
  static String? get webGoogleClientId => _webGoogleClientId;

  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: Firebase.app());

  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(app: Firebase.app());

  /// Initializes the `[DEFAULT]` app with the central project.
  ///
  /// Android reads the options the google-services plugin generated from the
  /// fetched `google-services.json`. Web reads [webCentralConfigPath].
  static Future<void> initialize({http.Client? client}) async {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      return;
    }
    final config = await _loadWebConfig(client ?? http.Client());
    _webGoogleClientId = config.googleClientId;
    await Firebase.initializeApp(options: config.options);
  }
}

/// The central web config: Firebase options plus the Google client id.
@visibleForTesting
class CentralWebConfig {
  const CentralWebConfig({required this.options, required this.googleClientId});

  /// Reads what `tool/partner.dart web` writes. Throws a
  /// [CentralFirebaseException] naming the missing field.
  factory CentralWebConfig.fromJson(Object? json) {
    if (json case {
      'options': final Map<String, Object?> options,
      'googleClientId': final String clientId,
    } when clientId.isNotEmpty) {
      String field(String key, {bool required = true}) {
        final value = options[key];
        if (value is String && value.isNotEmpty) return value;
        if (!required) return '';
        throw CentralFirebaseException(
          '$webCentralConfigPath has no options.$key. $_webFix',
        );
      }

      String? optional(String key) {
        final value = field(key, required: false);
        return value.isEmpty ? null : value;
      }

      return CentralWebConfig(
        options: FirebaseOptions(
          apiKey: field('apiKey'),
          appId: field('appId'),
          projectId: field('projectId'),
          messagingSenderId: field('messagingSenderId'),
          authDomain: optional('authDomain'),
          storageBucket: optional('storageBucket'),
        ),
        googleClientId: clientId,
      );
    }
    throw CentralFirebaseException(
      '$webCentralConfigPath needs "options" and "googleClientId". $_webFix',
    );
  }

  final FirebaseOptions options;
  final String googleClientId;
}

const _webFix =
    'Run "dart run tool/partner.dart web" before building or running the web '
    'app.';

Future<CentralWebConfig> _loadWebConfig(http.Client client) async {
  final uri = Uri.base.resolve(webCentralConfigPath);
  final http.Response response;
  try {
    response = await client.get(uri).timeout(_webConfigTimeout);
  } on TimeoutException {
    throw CentralFirebaseException('Timed out fetching $uri. $_webFix');
  } on http.ClientException catch (error) {
    throw CentralFirebaseException(
      'Could not fetch $uri: ${error.message}. $_webFix',
    );
  } finally {
    client.close();
  }
  if (response.statusCode != 200) {
    throw CentralFirebaseException(
      'Could not fetch $uri (HTTP ${response.statusCode}). $_webFix',
    );
  }
  try {
    return CentralWebConfig.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  } on FormatException {
    throw CentralFirebaseException('$uri is not valid JSON. $_webFix');
  }
}
