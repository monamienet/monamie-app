import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A fake API key placed in every config built by [googleServicesJson]: no
/// message or output of the organization tool may ever contain it.
const secretMarker = 'AIzaFAKE-secret-key-0123456789abcdef';

/// One `client` entry of a `google-services.json` for [packageName], with an
/// OAuth client of each type in [oauthClientTypes] (3 is the web client).
/// Pass `null` to omit the `oauth_client` key entirely.
Map<String, Object?> androidClient(
  String packageName, {
  List<int>? oauthClientTypes = const [1, 3],
}) => {
  'client_info': {
    'mobilesdk_app_id': '1:111:android:$packageName',
    'android_client_info': {'package_name': packageName},
  },
  if (oauthClientTypes != null)
    'oauth_client': [
      for (final type in oauthClientTypes)
        {
          'client_id': '$type-client.apps.googleusercontent.com',
          'client_type': type,
        },
    ],
  'api_key': [
    {'current_key': secretMarker},
  ],
};

/// A `google-services.json` for [projectId] with [clients], formatted like
/// the Firebase console does (2-space indentation).
String googleServicesJson({
  required String projectId,
  required List<Map<String, Object?>> clients,
}) => const JsonEncoder.withIndent('  ').convert({
  'project_info': {
    'project_number': '111',
    'project_id': projectId,
    'storage_bucket': '$projectId.firebasestorage.app',
  },
  'client': clients,
  'configuration_version': '1',
});

/// Creates `organizations/<id>/organization.json` under [repoRoot].
void writeOrganization(Directory repoRoot, String id) {
  File(p.join(repoRoot.path, 'organizations', id, 'organization.json'))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('{"name": "Acme", "colors": {"primary": "#112233"}}');
}

/// The `google-services.json` of organization [id] under [repoRoot], at the path
/// the spec fixes (`android/app/src/<id>/google-services.json`).
File specConfigFile(Directory repoRoot, String id) => File(
  p.join(repoRoot.path, 'android', 'app', 'src', id, 'google-services.json'),
);
