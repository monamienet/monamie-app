import 'dart:io';

import 'package:args/command_runner.dart';

import 'firebase_cli.dart';
import 'web_central.dart';

/// `web`: stages the central Firebase web config for web builds.
class WebCommand extends Command<void> {
  WebCommand(this._repoRoot, this._cli);

  final Directory _repoRoot;
  final FirebaseCli _cli;

  @override
  String get name => 'web';

  @override
  String get description =>
      'Stage the central Firebase web config in $webCentralConfigPath for '
      'flutter build/run on web.';

  @override
  Future<void> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException('Takes no arguments: partners are bound at runtime.');
    }
    await stageCentralWebConfig(repoRoot: _repoRoot, cli: _cli);
    stdout.writeln('Wrote $webCentralConfigPath.');
  }
}
