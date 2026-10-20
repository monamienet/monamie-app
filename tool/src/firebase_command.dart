import 'dart:io';

import 'package:args/command_runner.dart';

import 'android_firebase_config.dart';
import 'firebase_cli.dart';

/// `firebase <id>`: fetches the Android Firebase config of partner `<id>`.
class FirebaseCommand extends Command<void> {
  FirebaseCommand(this._repoRoot, this._cli);

  final Directory _repoRoot;
  final FirebaseCli _cli;

  @override
  String get name => 'firebase';

  @override
  String get description =>
      "Fetch a partner's google-services.json from its Firebase project "
      '(monamienet-<id>).';

  @override
  String get invocation => '${runner!.executableName} $name <id>';

  @override
  Future<void> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) usageException('Expected exactly one partner id.');
    final id = rest.single;

    final appId = await fetchAndroidFirebaseConfig(
      repoRoot: _repoRoot,
      id: id,
      cli: _cli,
    );
    // Only the app id: the file holds API keys.
    stdout.writeln('Wrote ${androidFirebaseConfigPath(id)} (app $appId).');
  }
}
