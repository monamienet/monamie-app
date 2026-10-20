import 'dart:io';

import 'package:args/command_runner.dart';

import 'web_staging.dart';

/// `web <id>`: stages partner `<id>` in `web/partner/` for web builds.
class WebCommand extends Command<void> {
  WebCommand(this._repoRoot);

  final Directory _repoRoot;

  @override
  String get name => 'web';

  @override
  String get description =>
      'Stage a partner in $webPartnerDirPath/ for flutter build/run on web.';

  @override
  String get invocation => '${runner!.executableName} $name <id>';

  @override
  void run() {
    final rest = argResults!.rest;
    if (rest.length != 1) usageException('Expected exactly one partner id.');
    final id = rest.single;

    final staged = stageWebPartner(repoRoot: _repoRoot, id: id);
    stdout.writeln("Staged '$id' in $webPartnerDirPath/: ${staged.join(', ')}");
  }
}
