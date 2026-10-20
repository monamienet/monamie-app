import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'firebase_cli.dart';
import 'partners.dart';

/// `client_type` of the OAuth web client in `google-services.json`. The
/// google-services plugin turns it into `default_web_client_id`, which Google
/// sign-in needs on Android.
const oauthWebClientType = 3;

/// Path, relative to the repository root, of the fetched Firebase config of
/// partner [id]. The google-services plugin finds it in the flavor's source
/// set. Gitignored, and kept in sync with `android/app/build.gradle.kts`.
String androidFirebaseConfigPath(String id) =>
    p.join('android', 'app', 'src', id, 'google-services.json');

/// Fetches the `google-services.json` of partner [id] from its own Firebase
/// project (`monamienet-<id>`) and writes it to [androidFirebaseConfigPath].
/// Returns the Firebase app id.
///
/// The config is validated before anything is written, so a failed run keeps
/// the previous file. Throws a [PartnerToolException] on failure; messages
/// never include the config contents, which hold API keys.
Future<String> fetchAndroidFirebaseConfig({
  required Directory repoRoot,
  required String id,
  required FirebaseCli cli,
}) async {
  partnerConfigFile(repoRoot, id);
  final projectId = firebaseProjectId(id);
  final packageName = androidApplicationId(id);

  final apps = await cli.listAndroidApps(projectId);
  final matches = apps.where((app) => app.packageName == packageName).toList();
  if (matches.length != 1) {
    final candidates = apps.isEmpty ? '(none)' : apps.join(', ');
    throw PartnerToolException(
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

  final target = File(p.join(repoRoot.path, androidFirebaseConfigPath(id)));
  target.parent.createSync(recursive: true);
  // Rename within the same folder, so readers never see a partial file.
  final temp = File('${target.path}.tmp')..writeAsStringSync(contents);
  temp.renameSync(target.path);
  return appId;
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
    throw PartnerToolException('$source is not valid JSON.');
  }

  final configProjectId = switch (config) {
    {'project_info': {'project_id': final String value}} => value,
    _ => null,
  };
  if (configProjectId != projectId) {
    throw PartnerToolException(
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
    throw PartnerToolException(
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
    throw PartnerToolException(
      "$source has no OAuth web client (client_type $oauthWebClientType) for "
      "'$packageName', so Google sign-in would fail. Enable Google sign-in in "
      'the Firebase console (Authentication) and run again.',
    );
  }
}
