import 'package:firebase_core/firebase_core.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';

/// Everything the app remembers about the partner a user is bound to: the
/// partner and its branding, and the options of its Firebase project.
///
/// The root group is not stored: it is derived from the id
/// ([PartnerConfig.rootGroupEmail]).
class PartnerBinding {
  const PartnerBinding({required this.partner, required this.options});

  /// Reads what [toJson] wrote. Throws a [FormatException] when a required
  /// field is missing.
  factory PartnerBinding.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('partner binding must be a JSON object');
    }
    final id = json['id'];
    final options = json['options'];
    if (id is! String || options is! Map) {
      throw const FormatException('partner binding needs "id" and "options"');
    }
    String required(String key) {
      final value = options[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('partner binding needs "options.$key"');
      }
      return value;
    }

    String? optional(String key) {
      final value = options[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return PartnerBinding(
      partner: PartnerConfig.fromBranding(id, json['branding']),
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

  final PartnerConfig partner;
  final FirebaseOptions options;

  /// Name of the partner's [FirebaseApp]. One name per partner, so an app
  /// is never reused for another project.
  String get appName => firebaseAppNameFor(partner.id);

  /// The JSON stored on the device. `MonAmieApplication.kt` reads the same
  /// keys to create the app before any Flutter engine starts.
  Map<String, Object?> toJson() => {
    'id': partner.id,
    'options': {
      'apiKey': options.apiKey,
      'appId': options.appId,
      'projectId': options.projectId,
      'messagingSenderId': options.messagingSenderId,
      'storageBucket': ?options.storageBucket,
      'authDomain': ?options.authDomain,
    },
    'branding': partner.toBranding(),
  };
}

/// `partner-<id>`: the [FirebaseApp] name of partner [id].
String firebaseAppNameFor(String id) => 'partner-$id';
