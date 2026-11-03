import 'dart:io';

import 'package:path/path.dart' as p;

import 'src/web_server.dart';

/// Serves the web build on `http://localhost:5000`, the only local origin the
/// OAuth web client accepts for Google sign-in (see
/// `docs/en-us/run-web-locally.md`). Every path that is not a file gets
/// `index.html`, so reloading a screen (`/monamie`) works.
///
/// Run from anywhere in the repo: `dart run tool/serve_web.dart`.
Future<void> main() async {
  // tool/serve_web.dart -> repository root, independent of the working
  // directory.
  final repoRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final root = p.join(repoRoot, 'build', 'web');
  // Loopback only: the server is reachable from this machine alone.
  await serveWeb(root: root, address: InternetAddress.loopbackIPv4, port: 5000);
  stdout.writeln('Serving $root on http://localhost:5000 (Ctrl+C to stop).');
}
