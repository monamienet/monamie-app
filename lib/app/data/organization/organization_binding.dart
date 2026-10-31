import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:monamie_app/app/config/organization/organization_config.dart';
import 'package:monamie_app/app/config/organization/organization_theme.dart';

/// Everything the app remembers about the organization a user is bound to: the
/// organization and its branding, and the options of its Firebase project.
///
/// The root group is not stored: it is derived from the id
/// ([OrganizationConfig.rootGroupEmail]).
class OrganizationBinding {
  const OrganizationBinding({
    required this.organization,
    required this.options,
  });

  /// Reads what [toJson] wrote. Throws a [FormatException] when a required
  /// field is missing.
  factory OrganizationBinding.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('organization binding must be a JSON object');
    }
    final id = json['id'];
    final options = json['options'];
    if (id is! String || options is! Map) {
      throw const FormatException(
        'organization binding needs "id" and "options"',
      );
    }
    String required(String key) {
      final value = options[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('organization binding needs "options.$key"');
      }
      return value;
    }

    String? optional(String key) {
      final value = options[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return OrganizationBinding(
      organization: OrganizationConfig.fromBranding(
        id,
        json['branding'],
        theme: _storedTheme(json['theme']),
        logoPng: _storedLogo(json['logoPng']),
      ),
      options: FirebaseOptions(
        apiKey: required('apiKey'),
        appId: required('appId'),
        projectId: required('projectId'),
        messagingSenderId: required('messagingSenderId'),
        storageBucket: optional('storageBucket'),
        authDomain: optional('authDomain'),
      ),
    );
  }

  final OrganizationConfig organization;
  final FirebaseOptions options;

  /// Name of the organization's [FirebaseApp]. One name per organization, so an app
  /// is never reused for another project.
  String get appName => firebaseAppNameFor(organization.id);

  /// The JSON stored on the device. `MonAmieApplication.kt` reads the same
  /// keys to create the app before any Flutter engine starts.
  Map<String, Object?> toJson() => {
    'id': organization.id,
    'options': {
      'apiKey': options.apiKey,
      'appId': options.appId,
      'projectId': options.projectId,
      'messagingSenderId': options.messagingSenderId,
      'storageBucket': ?options.storageBucket,
      'authDomain': ?options.authDomain,
    },
    'branding': organization.toBranding(),
    if (organization.theme case final theme?)
      'theme': {'id': theme.id, ...theme.toJson()},
    if (organization.logoPng case final png?) 'logoPng': base64Encode(png),
  };
}

Uint8List? _storedLogo(Object? value) {
  if (value is! String) return null;
  try {
    return base64Decode(value);
  } on FormatException {
    return null;
  }
}

OrganizationTheme? _storedTheme(Object? json) => switch (json) {
  {'id': final String id} => OrganizationTheme.fromJson(id, json),
  _ => null,
};

/// `organization-<id>`: the [FirebaseApp] name of organization [id].
String firebaseAppNameFor(String id) => 'organization-$id';
