import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'android_firebase_config.dart';
import 'firebase_cli.dart';
import 'partners.dart';

/// Path, relative to the repository root, of the staged central web config.
///
/// `flutter build web` copies `web/` into the output and `flutter run -d
/// chrome` serves it, so the web app reads `central/firebase.json` over HTTP
/// at startup. Gitignored, and kept in sync with
/// `lib/app/data/firebase/central_firebase.dart`.
final webCentralConfigPath = p.join('web', 'central', 'firebase.json');

/// The FirebaseOptions fields the web app needs from the web SDK config.
const _requiredWebFields = [
  'apiKey',
  'appId',
  'projectId',
  'messagingSenderId',
];
const _optionalWebFields = ['authDomain', 'storageBucket'];

/// Writes [webCentralConfigPath] with the central project's web Firebase
/// options and the OAuth web client id for Google sign-in.
///
/// Everything is fetched and validated before writing, so a failed run keeps
/// the previous file. Throws a [PartnerToolException] on failure; messages
/// never include the config contents.
Future<void> stageCentralWebConfig({
  required Directory repoRoot,
  required FirebaseCli cli,
}) async {
  const projectId = centralProjectId;
  final webApps = await cli.listWebApps(projectId);
  if (webApps.length != 1) {
    throw PartnerToolException(
      "Expected exactly one web app in '$projectId', found "
      "${webApps.length}: ${webApps.isEmpty ? '(none)' : webApps.join(', ')}. "
      'Remove the stale ones in the Firebase console.',
    );
  }
  final sdkConfig = await cli.webConfig(
    projectId: projectId,
    appId: webApps.single.appId,
  );
  final options = <String, Object?>{};
  for (final field in _requiredWebFields) {
    final value = sdkConfig[field];
    if (value is! String || value.isEmpty) {
      throw PartnerToolException(
        "The web config of '$projectId' has no '$field'.",
      );
    }
    options[field] = value;
  }
  for (final field in _optionalWebFields) {
    if (sdkConfig[field] case final String value when value.isNotEmpty) {
      options[field] = value;
    }
  }

  final androidApps = await cli.listAndroidApps(projectId);
  final android = androidApps.where((a) => a.packageName == appPackageName);
  if (android.length != 1) {
    throw PartnerToolException(
      "Expected one Android app '$appPackageName' in '$projectId' to read the "
      'OAuth web client from, found ${android.length}.',
    );
  }
  final googleServices = await cli.androidConfig(
    projectId: projectId,
    appId: android.single.appId,
  );
  final clientId = webClientIdFromGoogleServices(googleServices);

  final target = File(p.join(repoRoot.path, webCentralConfigPath));
  target.parent.createSync(recursive: true);
  final temp = File('${target.path}.tmp')
    ..writeAsStringSync(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'options': options, 'googleClientId': clientId}),
    );
  temp.renameSync(target.path);
}
