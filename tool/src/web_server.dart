/// The local web server of `dart run tool/serve_web.dart`: serves the static
/// build in `build/web` and answers every other path with `index.html`.
///
/// The app uses path URLs (`/monamie`, not `/#/monamie`), so reloading a
/// screen asks the server for a path that is not a file; a single-page app
/// needs the server to hand back `index.html` there, and `go_router` then
/// opens the screen.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Content types of the files a Flutter web build contains.
const Map<String, String> contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
  '.bin': 'application/octet-stream',
  '.frag': 'application/octet-stream',
};

/// The content type of [path], by its extension; binary when unknown.
String contentTypeOf(String path) =>
    contentTypes[p.extension(path).toLowerCase()] ?? 'application/octet-stream';

/// The file under [root] that answers [requestPath]: the file itself when it
/// exists, otherwise `index.html` (a route of the app). A path that would
/// leave [root] (`..`) also gets `index.html`, never a file outside it.
File resolveWebFile(String root, String requestPath) {
  final rootPath = p.normalize(p.absolute(root));
  final index = File(p.join(rootPath, 'index.html'));
  final String relative;
  try {
    relative = Uri.decodeComponent(requestPath).replaceFirst(RegExp('^/+'), '');
  } on Object {
    // A malformed escape is no file of the build: the app decides.
    return index;
  }
  if (relative.isEmpty) return index;
  final target = p.normalize(p.join(rootPath, relative));
  if (!p.isWithin(rootPath, target)) return index;
  final file = File(target);
  return file.existsSync() ? file : index;
}

/// Serves [root] on [address]:[port] until the process is stopped.
Future<HttpServer> serveWeb({
  required String root,
  required InternetAddress address,
  required int port,
}) async {
  final server = await HttpServer.bind(address, port);
  server.listen((request) async {
    final response = request.response;
    if (request.method != 'GET' && request.method != 'HEAD') {
      response.statusCode = HttpStatus.methodNotAllowed;
      await response.close();
      return;
    }
    final file = resolveWebFile(root, request.uri.path);
    if (!file.existsSync()) {
      response.statusCode = HttpStatus.notFound;
      response.write('No build in $root: run `flutter build web` first.');
      await response.close();
      return;
    }
    response.headers
      ..contentType = ContentType.parse(contentTypeOf(file.path))
      // A rebuilt app must reach the browser at once.
      ..set(HttpHeaders.cacheControlHeader, 'no-cache');
    if (request.method == 'HEAD') {
      await response.close();
      return;
    }
    await response.addStream(file.openRead());
    await response.close();
  });
  return server;
}
