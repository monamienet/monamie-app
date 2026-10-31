import 'dart:io';

import 'package:args/command_runner.dart';

import 'android_firebase_config.dart';
import 'firebase_cli.dart';
import 'organizations.dart';

/// `firebase`: fetches the Android Firebase config of the central project.
class FirebaseCommand extends Command<void> {
  FirebaseCommand(this._repoRoot, this._cli);

  final Directory _repoRoot;
  final FirebaseCli _cli;

  @override
  String get name => 'firebase';

  @override
  String get description =>
      'Fetch the app\'s google-services.json from the central Firebase '
      'project ($centralProjectId). The Android build runs it when the file '
      'is missing.';

  @override
  Future<void> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException('Takes no arguments: organizations are bound at runtime.');
    }
    final appId = await fetchAndroidFirebaseConfig(
      repoRoot: _repoRoot,
      cli: _cli,
    );
    // Only the app id: the file holds API keys.
    stdout.writeln('Wrote $androidFirebaseConfigPath (app $appId).');
  }
}
