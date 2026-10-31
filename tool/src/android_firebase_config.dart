import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'firebase_cli.dart';
import 'organizations.dart';

/// `client_type` of the OAuth web client in `google-services.json`. The
/// google-services plugin turns it into `default_web_client_id`, which Google
/// sign-in needs on Android.
const oauthWebClientType = 3;

/// Path, relative to the repository root, of the fetched Firebase config of
/// the central project. Gitignored, and kept in sync with
/// `android/app/build.gradle.kts`.
final androidFirebaseConfigPath = p.join(
  'android',
  'app',
  'google-services.json',
);

/// Fetches the `google-services.json` of the MonAmie app
/// ([appPackageName]) from the central project ([centralProjectId]) and
/// writes it to [androidFirebaseConfigPath]. Returns the Firebase app id.
///
/// Organizations' projects are not involved: the app binds them at runtime.
///
/// The config is validated before anything is written, so a failed run keeps
/// the previous file. Throws a [OrganizationToolException] on failure; messages
/// never include the config contents, which hold API keys.
Future<String> fetchAndroidFirebaseConfig({
  required Directory repoRoot,
  required FirebaseCli cli,
}) async {
  const projectId = centralProjectId;
  const packageName = appPackageName;

  final apps = await cli.listAndroidApps(projectId);
  final matches = apps.where((app) => app.packageName == packageName).toList();
  if (matches.length != 1) {
    final candidates = apps.isEmpty ? '(none)' : apps.join(', ');
    throw OrganizationToolException(
      matches.isEmpty
          ? "No Android app with package '$packageName' in Firebase project "
                "'$projectId'. Android apps: $candidates."
          : "Several Android apps with package '$packageName' in Firebase "
                "project '$projectId': $candidates. Remove the stale ones in "
                'the Firebase console.',
    );
  }
  final appId = matches.single.appId;

  final contents = await cli.androidConfig(projectId: projectId, appId: appId);
  _validateConfig(contents, projectId: projectId, packageName: packageName);

  final target = File(p.join(repoRoot.path, androidFirebaseConfigPath));
  target.parent.createSync(recursive: true);
  // Rename within the same folder, so readers never see a partial file.
  final temp = File('${target.path}.tmp')..writeAsStringSync(contents);
  temp.renameSync(target.path);
  return appId;
}

/// The OAuth web client id in a `google-services.json`: the client id
/// Google sign-in uses on the web, and the server client id on Android.
///
/// Throws a [OrganizationToolException] when there is none or [contents] is not
/// JSON. The message never echoes [contents], which hold API keys (a
/// [FormatException] from `jsonDecode` would).
String webClientIdFromGoogleServices(String contents) {
  final Object? config;
  try {
    config = jsonDecode(contents);
  } on FormatException {
    throw OrganizationToolException(
      'The google-services.json is not valid JSON.',
    );
  }
  final clients = switch (config) {
    {'client': final List<Object?> value} => value,
    _ => const <Object?>[],
  };
  for (final client in clients) {
    final oauthClients = switch (client) {
      {'oauth_client': final List<Object?> value} => value,
      _ => const <Object?>[],
    };
    for (final oauth in oauthClients) {
      if (oauth case {
        'client_type': oauthWebClientType,
        'client_id': final String id,
      }) {
        return id;
      }
    }
  }
  throw OrganizationToolException(
    'The google-services.json has no OAuth web client. Enable Google sign-in '
    'in the central project (Authentication) and run again.',
  );
}

void _validateConfig(
  String contents, {
  required String projectId,
  required String packageName,
}) {
  const source = 'The fetched google-services.json';
  final Object? config;
  try {
    config = jsonDecode(contents);
  } on FormatException {
    throw OrganizationToolException('$source is not valid JSON.');
  }

  final configProjectId = switch (config) {
    {'project_info': {'project_id': final String value}} => value,
    _ => null,
  };
  if (configProjectId != projectId) {
    throw OrganizationToolException(
      "$source has project_info.project_id '$configProjectId', "
      "expected '$projectId'.",
    );
  }

  final clients = switch (config) {
    {'client': final List<Object?> value} => value,
    _ => const <Object?>[],
  };
  final matching = clients.where(
    (client) => switch (client) {
      {'client_info': {'android_client_info': {'package_name': final name}}} =>
        name == packageName,
      _ => false,
    },
  );
  if (matching.length != 1) {
    throw OrganizationToolException(
      "$source must have exactly one client with package '$packageName', "
      'found ${matching.length}.',
    );
  }

  final oauthClients = switch (matching.single) {
    {'oauth_client': final List<Object?> value} => value,
    _ => const <Object?>[],
  };
  final hasWebClient = oauthClients.any(
    (client) => switch (client) {
      {'client_type': oauthWebClientType} => true,
      _ => false,
    },
  );
  if (!hasWebClient) {
    throw OrganizationToolException(
      "$source has no OAuth web client (client_type $oauthWebClientType) for "
      "'$packageName', so Google sign-in would fail. Enable Google sign-in in "
      'the Firebase console (Authentication) and run again.',
    );
  }
}
