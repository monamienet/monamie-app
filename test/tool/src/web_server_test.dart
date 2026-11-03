import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../../tool/src/web_server.dart';

void main() {
  group('resolveWebFile - Unit Test Suite', () {
    late Directory sandbox;
    late String root;
    late String index;

    setUp(() {
      sandbox = Directory.systemTemp.createTempSync('web_server_test');
      root = p.join(sandbox.path, 'web');
      Directory(p.join(root, 'assets')).createSync(recursive: true);
      File(p.join(root, 'index.html')).writeAsStringSync('<html>index</html>');
      File(p.join(root, 'main.dart.js')).writeAsStringSync('main();');
      File(p.join(root, 'assets', 'x.png')).writeAsBytesSync([1, 2, 3]);
      File(p.join(root, 'a b.txt')).writeAsStringSync('spaced');
      File(p.join(sandbox.path, 'outside.txt')).writeAsStringSync('secret');
      index = p.join(root, 'index.html');
    });

    tearDown(() => sandbox.deleteSync(recursive: true));

    String resolved(String requestPath) =>
        p.normalize(resolveWebFile(root, requestPath).path);

    final toIndex = <(String, String)>{
      ('Happy Path: the root path', '/'),
      ('Edge Case: an empty path', ''),
      ('Happy Path: an app route', '/monamie'),
      ('Happy Path: a nested app route', '/login/criar'),
      ('Edge Case: a directory path', '/assets'),
      ('Security: parent traversal', '/../outside.txt'),
      ('Security: encoded parent traversal', '/..%2Foutside.txt'),
      (
        'Security: traversal after a real directory',
        '/assets/../../outside.txt',
      ),
      ('Edge Case: a malformed escape', '/%zz'),
    };
    for (final (label, requestPath) in toIndex) {
      test('$label gets index.html', () {
        // 1. Arrange
        final expected = p.normalize(index);

        // 2. Act
        final file = resolved(requestPath);

        // 3. Assert
        expect(file, expected);
      });
    }

    final toFile = <(String, String, String)>[
      ('Happy Path: an existing file', '/main.dart.js', 'main.dart.js'),
      ('Happy Path: a nested asset', '/assets/x.png', 'assets/x.png'),
      ('Edge Case: a percent-encoded name', '/a%20b.txt', 'a b.txt'),
    ];
    for (final (label, requestPath, relative) in toFile) {
      test('$label gets that file', () {
        // 1. Arrange
        final expected = p.normalize(p.join(root, relative));

        // 2. Act
        final file = resolved(requestPath);

        // 3. Assert
        expect(file, expected);
      });
    }
  });

  group('contentTypeOf - Unit Test Suite', () {
    final cases = <(String, String, String)>[
      ('Happy Path: html', 'index.html', 'text/html; charset=utf-8'),
      ('Happy Path: js', 'main.dart.js', 'text/javascript; charset=utf-8'),
      ('Happy Path: json', 'a/b.json', 'application/json; charset=utf-8'),
      ('Happy Path: wasm', 'x.wasm', 'application/wasm'),
      ('Happy Path: png', 'x.png', 'image/png'),
      ('Happy Path: svg', 'x.svg', 'image/svg+xml'),
      ('Happy Path: woff2', 'x.woff2', 'font/woff2'),
      ('Edge Case: upper-case extension', 'X.PNG', 'image/png'),
      ('Edge Case: unknown extension', 'x.xyz', 'application/octet-stream'),
      ('Edge Case: no extension', 'LICENSE', 'application/octet-stream'),
    ];
    for (final (label, path, expected) in cases) {
      test(label, () {
        // 1. Arrange (see the table)

        // 2. Act
        final type = contentTypeOf(path);

        // 3. Assert
        expect(type, expected);
      });
    }
  });

  group('serveWeb - Integration Test Suite', () {
    late Directory root;
    late HttpServer server;
    late HttpClient client;

    Future<void> start({required bool withIndex}) async {
      root = Directory.systemTemp.createTempSync('serve_web_test');
      if (withIndex) {
        File(p.join(root.path, 'index.html')).writeAsStringSync('<p>home</p>');
        File(p.join(root.path, 'main.dart.js')).writeAsStringSync('main();');
      }
      server = await serveWeb(
        root: root.path,
        address: InternetAddress.loopbackIPv4,
        port: 0,
      );
      client = HttpClient();
    }

    Future<(HttpClientResponse, String)> send(
      String method,
      String path,
    ) async {
      final request = await client.openUrl(
        method,
        Uri.parse('http://127.0.0.1:${server.port}$path'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return (response, body);
    }

    tearDown(() async {
      client.close(force: true);
      await server.close(force: true);
      root.deleteSync(recursive: true);
    });

    test('Happy Path: an app route gets index.html as html', () async {
      // 1. Arrange
      await start(withIndex: true);

      // 2. Act
      final (response, body) = await send('GET', '/monamie');

      // 3. Assert
      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'text/html');
      expect(body, '<p>home</p>');
    });

    test('Happy Path: a file gets its content type and no-cache', () async {
      // 1. Arrange
      await start(withIndex: true);

      // 2. Act
      final (response, body) = await send('GET', '/main.dart.js');

      // 3. Assert
      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'text/javascript');
      expect(
        response.headers.value(HttpHeaders.cacheControlHeader),
        'no-cache',
      );
      expect(body, 'main();');
    });

    test('Happy Path: HEAD answers 200 without a body', () async {
      // 1. Arrange
      await start(withIndex: true);

      // 2. Act
      final (response, body) = await send('HEAD', '/');

      // 3. Assert
      expect(response.statusCode, HttpStatus.ok);
      expect(body, isEmpty);
    });

    test('Edge Case: POST is not allowed', () async {
      // 1. Arrange
      await start(withIndex: true);

      // 2. Act
      final (response, _) = await send('POST', '/');

      // 3. Assert
      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });

    test(
      'Edge Case: a root without index.html answers 404 with a hint',
      () async {
        // 1. Arrange
        await start(withIndex: false);

        // 2. Act
        final (response, body) = await send('GET', '/monamie');

        // 3. Assert
        expect(response.statusCode, HttpStatus.notFound);
        expect(body, contains('flutter build web'));
      },
    );
  });
}
