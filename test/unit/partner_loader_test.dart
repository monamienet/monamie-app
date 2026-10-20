import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_loader.dart';

/// The command every web loader error points to when re-staging fixes it.
const stageCommand = 'dart run tool/partner.dart web <id>';

const acmeJson =
    '{"name": "Acme", "colors": {"primary": "#112233", "secondary": "#FFFFFF"}}';
const betaJson =
    '{"name": "Beta", "colors": {"primary": "#445566", "secondary": "#000000"}}';

/// An [AssetBundle] holding [assets] (key to bytes) that fails like
/// [PlatformAssetBundle] for any other key, and records every key read.
class FakeAssetBundle extends AssetBundle {
  FakeAssetBundle(this.assets);

  final Map<String, List<int>> assets;
  final requestedKeys = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requestedKeys.add(key);
    final bytes = assets[key];
    if (bytes == null) {
      throw FlutterError('Unable to load asset: "$key".');
    }
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

/// A bundle with a single text asset [key] holding [content].
FakeAssetBundle bundleWith(String key, String content) =>
    FakeAssetBundle({key: utf8.encode(content)});

/// Matches a [PartnerLoadException] whose message contains every entry of
/// [parts].
Matcher loadErrorContaining(List<String> parts) => isA<PartnerLoadException>()
    .having((error) => error.message, 'message', stringContainsInOrder(parts));

/// Matches a [PartnerLoadException] whose message starts with [prefix] and
/// contains every entry of [parts].
Matcher loadErrorStartingWith(String prefix, [List<String> parts = const []]) =>
    isA<PartnerLoadException>().having(
      (error) => error.message,
      'message',
      allOf(startsWith(prefix), stringContainsInOrder(parts)),
    );

/// A fake static server: answers GETs whose path is a key of [files] with
/// status 200 and the UTF-8 bytes of the value, without a charset, and 404
/// otherwise. Every requested URL is added to [requests].
MockClient staticServer(Map<String, String> files, {List<Uri>? requests}) =>
    MockClient((request) async {
      requests?.add(request.url);
      final body = files[request.url.path];
      if (body == null) return http.Response('Not found', 404);
      return http.Response.bytes(
        utf8.encode(body),
        200,
        headers: {'content-type': 'application/octet-stream'},
      );
    });

/// The files `dart run tool/partner.dart web acme` serves at the root.
const acmeServerFiles = {
  '/partner/id.txt': 'acme\n',
  '/partner/partner.json': acmeJson,
};

final localBase = Uri.parse('http://localhost:5000/');

void main() {
  group('PartnerLoadException - Unit Test Suite', () {
    test('Happy Path: exposes the given message', () {
      // 1. Arrange
      const message = 'Run with --flavor acme.';

      // 2. Act
      final error = PartnerLoadException(message);

      // 3. Assert
      expect(error.message, message);
    });

    test('Happy Path: toString includes the message', () {
      // 1. Arrange
      final error = PartnerLoadException('Run with --flavor acme.');

      // 2. Act
      final text = error.toString();

      // 3. Assert
      expect(text, contains('Run with --flavor acme.'));
    });

    test('Edge Case: is an Exception, not an Error', () {
      // 1. Arrange
      const message = '';

      // 2. Act
      final error = PartnerLoadException(message);

      // 3. Assert
      expect(error, isA<Exception>());
    });
  });

  group('loadPartnerConfig - Unit Test Suite', () {
    test('Happy Path: loads the partner of the given flavor', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', acmeJson);

      // 2. Act
      final config = await loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      expect(
        [config.id, config.name, config.primaryColor, config.secondaryColor],
        ['acme', 'Acme', const Color(0xFF112233), const Color(0xFFFFFFFF)],
      );
    });

    test('Happy Path: reads partners/<flavor>/partner.json from the '
        'bundle', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', acmeJson);

      // 2. Act
      await loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      expect(bundle.requestedKeys, ['partners/acme/partner.json']);
    });

    test(
      'Happy Path: derives the display name from the bundled name',
      () async {
        // 1. Arrange
        final bundle = bundleWith('partners/acme/partner.json', acmeJson);

        // 2. Act
        final config = await loadPartnerConfig(bundle: bundle, flavor: 'acme');

        // 3. Assert
        expect(config.displayName, 'MonAmie Acme');
      },
    );

    test('Edge Case: decodes an accented UTF-8 name', () async {
      // 1. Arrange
      final bundle = bundleWith(
        'partners/acme/partner.json',
        '{"name": "Acmé Tur", "colors": '
            '{"primary": "#112233", "secondary": "#FFFFFF"}}',
      );

      // 2. Act
      final config = await loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      expect(config.name, 'Acmé Tur');
    });

    test('Edge Case: picks the flavor partner when the bundle holds '
        'another one too', () async {
      // 1. Arrange
      final bundle = FakeAssetBundle({
        'partners/acme/partner.json': utf8.encode(acmeJson),
        'partners/beta/partner.json': utf8.encode(betaJson),
      });

      // 2. Act
      final config = await loadPartnerConfig(bundle: bundle, flavor: 'beta');

      // 3. Assert
      expect(config.id, 'beta');
    });

    test('Edge Case: accepts a lowercase color in the bundled file', () async {
      // 1. Arrange
      final bundle = bundleWith(
        'partners/acme/partner.json',
        '{"name": "Acme", "colors": '
            '{"primary": "#0abab5", "secondary": "#ffffff"}}',
      );

      // 2. Act
      final config = await loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      expect(config.primaryColor, const Color(0xFF0ABAB5));
    });

    test('Sad Path: a null flavor tells to run with --flavor <id>', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', acmeJson);

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: null);

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorContaining(['--flavor <id>'])),
      );
    });

    test('Sad Path: a null flavor does not read the bundle', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', acmeJson);

      // 2. Act
      try {
        await loadPartnerConfig(bundle: bundle, flavor: null);
      } on PartnerLoadException {
        // Expected: the assertion checks the bundle reads.
      }

      // 3. Assert
      expect(bundle.requestedKeys, isEmpty);
    });

    test(
      'Sad Path: a flavor missing from the bundle names the asset',
      () async {
        // 1. Arrange
        final bundle = bundleWith('partners/acme/partner.json', acmeJson);

        // 2. Act
        Future<PartnerConfig> action() =>
            loadPartnerConfig(bundle: bundle, flavor: 'beta');

        // 3. Assert
        await expectLater(
          action(),
          throwsA(loadErrorContaining(['partners/beta/partner.json'])),
        );
      },
    );

    test('Sad Path: a flavor missing from the bundle explains the pubspec '
        'entry', () async {
      // 1. Arrange
      final bundle = FakeAssetBundle({});

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'beta');

      // 3. Assert
      await expectLater(
        action(),
        throwsA(
          loadErrorContaining([
            'partners/beta/',
            'flavors: [beta]',
            'pubspec.yaml',
          ]),
        ),
      );
    });

    test(
      'Sad Path: an empty flavor is reported as an invalid --flavor',
      () async {
        // 1. Arrange
        final bundle = bundleWith('partners/acme/partner.json', acmeJson);

        // 2. Act
        Future<PartnerConfig> action() =>
            loadPartnerConfig(bundle: bundle, flavor: '');

        // 3. Assert
        await expectLater(
          action(),
          throwsA(loadErrorStartingWith('--flavor :')),
        );
      },
    );

    test('Sad Path: an empty flavor does not read the bundle', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', acmeJson);

      // 2. Act
      try {
        await loadPartnerConfig(bundle: bundle, flavor: '');
      } on PartnerLoadException {
        // Expected: the assertion checks the bundle reads.
      }

      // 3. Assert
      expect(bundle.requestedKeys, isEmpty);
    });

    test('Sad Path: an uppercase flavor is reported as an invalid --flavor '
        'naming it', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/Acme/partner.json', acmeJson);

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'Acme');

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorStartingWith('--flavor Acme:', ['Acme'])),
      );
    });

    test(
      'Sad Path: a flavor with a path separator does not read the bundle',
      () async {
        // 1. Arrange
        final bundle = bundleWith('partners/acme/partner.json', acmeJson);

        // 2. Act
        try {
          await loadPartnerConfig(bundle: bundle, flavor: '../acme');
        } on PartnerLoadException {
          // Expected: the assertion checks the bundle reads.
        }

        // 3. Assert
        expect(bundle.requestedKeys, isEmpty);
      },
    );

    test('Sad Path: malformed JSON names the file', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', '{"name": ');

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorContaining(['partners/acme/partner.json'])),
      );
    });

    test('Sad Path: an empty file throws PartnerLoadException', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', '');

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      await expectLater(action(), throwsA(isA<PartnerLoadException>()));
    });

    test('Sad Path: a JSON array throws PartnerLoadException', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/acme/partner.json', '[$acmeJson]');

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      await expectLater(action(), throwsA(isA<PartnerLoadException>()));
    });

    test('Sad Path: a blank name names the file and the field', () async {
      // 1. Arrange
      final bundle = bundleWith(
        'partners/acme/partner.json',
        '{"name": " ", "colors": '
            '{"primary": "#112233", "secondary": "#FFFFFF"}}',
      );

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorContaining(['partners/acme/partner.json', '"name"'])),
      );
    });

    test('Sad Path: a missing colors.secondary names the file and the '
        'field', () async {
      // 1. Arrange
      final bundle = bundleWith(
        'partners/acme/partner.json',
        '{"name": "Acme", "colors": {"primary": "#112233"}}',
      );

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      await expectLater(
        action(),
        throwsA(
          loadErrorContaining([
            'partners/acme/partner.json',
            'colors.secondary',
          ]),
        ),
      );
    });

    test(
      'Sad Path: an invalid primary color names the file and the field',
      () async {
        // 1. Arrange
        final bundle = bundleWith(
          'partners/acme/partner.json',
          '{"name": "Acme", "colors": '
              '{"primary": "#123", "secondary": "#FFFFFF"}}',
        );

        // 2. Act
        Future<PartnerConfig> action() =>
            loadPartnerConfig(bundle: bundle, flavor: 'acme');

        // 3. Assert
        await expectLater(
          action(),
          throwsA(
            loadErrorContaining([
              'partners/acme/partner.json',
              'colors.primary',
            ]),
          ),
        );
      },
    );

    test('Sad Path: invalid UTF-8 names the file', () async {
      // 1. Arrange
      final bundle = FakeAssetBundle({
        'partners/acme/partner.json': [0x7B, 0xFF, 0xFE, 0x7D],
      });

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'acme');

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorContaining(['partners/acme/partner.json'])),
      );
    });

    test('Sad Path: a reserved flavor is rejected even when its asset '
        'exists', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/debug/partner.json', acmeJson);

      // 2. Act
      Future<PartnerConfig> action() =>
          loadPartnerConfig(bundle: bundle, flavor: 'debug');

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorStartingWith('--flavor debug:', ['debug'])),
      );
    });

    test('Sad Path: a reserved flavor does not read the bundle', () async {
      // 1. Arrange
      final bundle = bundleWith('partners/debug/partner.json', acmeJson);

      // 2. Act
      try {
        await loadPartnerConfig(bundle: bundle, flavor: 'debug');
      } on PartnerLoadException {
        // Expected: the assertion checks the bundle reads.
      }

      // 3. Assert
      expect(bundle.requestedKeys, isEmpty);
    });

    test(
      'Sad Path: a flavor starting with "test" does not read the bundle',
      () async {
        // 1. Arrange
        final bundle = bundleWith('partners/testacme/partner.json', acmeJson);

        // 2. Act
        try {
          await loadPartnerConfig(bundle: bundle, flavor: 'testacme');
        } on PartnerLoadException {
          // Expected: the assertion checks the bundle reads.
        }

        // 3. Assert
        expect(bundle.requestedKeys, isEmpty);
      },
    );
  });

  group('loadWebPartner - Unit Test Suite', () {
    test('Happy Path: loads the staged partner', () async {
      // 1. Arrange
      final client = staticServer(acmeServerFiles);

      // 2. Act
      final config = await loadWebPartner(client: client, base: localBase);

      // 3. Assert
      expect(
        [config.id, config.name, config.primaryColor, config.secondaryColor],
        ['acme', 'Acme', const Color(0xFF112233), const Color(0xFFFFFFFF)],
      );
    });

    test('Happy Path: fetches partner/id.txt and partner/partner.json next '
        'to the page', () async {
      // 1. Arrange
      final requests = <Uri>[];
      final client = staticServer(acmeServerFiles, requests: requests);

      // 2. Act
      await loadWebPartner(client: client, base: localBase);

      // 3. Assert
      expect(
        requests,
        unorderedEquals([
          Uri.parse('http://localhost:5000/partner/id.txt'),
          Uri.parse('http://localhost:5000/partner/partner.json'),
        ]),
      );
    });

    test('Happy Path: the id comes from id.txt', () async {
      // 1. Arrange
      final client = staticServer({
        '/partner/id.txt': 'beta\n',
        '/partner/partner.json': acmeJson,
      });

      // 2. Act
      final config = await loadWebPartner(client: client, base: localBase);

      // 3. Assert
      expect(config.id, 'beta');
    });

    test('Edge Case: a #/route fragment in the page URL is ignored', () async {
      // 1. Arrange
      final requests = <Uri>[];
      final client = staticServer(acmeServerFiles, requests: requests);

      // 2. Act
      await loadWebPartner(
        client: client,
        base: Uri.parse('http://localhost:5000/#/login'),
      );

      // 3. Assert
      expect(
        requests,
        unorderedEquals([
          Uri.parse('http://localhost:5000/partner/id.txt'),
          Uri.parse('http://localhost:5000/partner/partner.json'),
        ]),
      );
    });

    test(
      'Edge Case: an app served under a sub-path fetches below it',
      () async {
        // 1. Arrange
        final requests = <Uri>[];
        final client = staticServer({
          '/app/partner/id.txt': 'acme\n',
          '/app/partner/partner.json': acmeJson,
        }, requests: requests);

        // 2. Act
        await loadWebPartner(
          client: client,
          base: Uri.parse('https://example.org/app/'),
        );

        // 3. Assert
        expect(
          requests,
          unorderedEquals([
            Uri.parse('https://example.org/app/partner/id.txt'),
            Uri.parse('https://example.org/app/partner/partner.json'),
          ]),
        );
      },
    );

    test('Edge Case: a sub-path page URL with a query and a #/route fragment '
        'fetches below the sub-path', () async {
      // 1. Arrange
      final client = staticServer({
        '/app/partner/id.txt': 'acme\n',
        '/app/partner/partner.json': acmeJson,
      });

      // 2. Act
      final config = await loadWebPartner(
        client: client,
        base: Uri.parse('https://example.org/app/?lang=pt#/home/map'),
      );

      // 3. Assert
      expect(config.id, 'acme');
    });

    test(
      'Edge Case: an id.txt without a trailing newline is accepted',
      () async {
        // 1. Arrange
        final client = staticServer({
          '/partner/id.txt': 'acme',
          '/partner/partner.json': acmeJson,
        });

        // 2. Act
        final config = await loadWebPartner(client: client, base: localBase);

        // 3. Assert
        expect(config.id, 'acme');
      },
    );

    test('Edge Case: an id.txt with a CRLF line ending is accepted', () async {
      // 1. Arrange
      final client = staticServer({
        '/partner/id.txt': 'acme\r\n',
        '/partner/partner.json': acmeJson,
      });

      // 2. Act
      final config = await loadWebPartner(client: client, base: localBase);

      // 3. Assert
      expect(config.id, 'acme');
    });

    test('Edge Case: decodes an accented name as UTF-8 when the server sends '
        'no charset', () async {
      // 1. Arrange
      final client = MockClient((request) async {
        final body = request.url.path.endsWith('id.txt')
            ? 'acme\n'
            : '{"name": "Acmé São", "colors": '
                  '{"primary": "#112233", "secondary": "#FFFFFF"}}';
        return http.Response.bytes(
          utf8.encode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // 2. Act
      final config = await loadWebPartner(client: client, base: localBase);

      // 3. Assert
      expect(config.name, 'Acmé São');
    });

    test('Edge Case: decodes an accented name as UTF-8 when the server sends '
        'no content type', () async {
      // 1. Arrange
      final client = MockClient((request) async {
        final body = request.url.path.endsWith('id.txt')
            ? 'acme\n'
            : '{"name": "Ação", "colors": '
                  '{"primary": "#112233", "secondary": "#FFFFFF"}}';
        return http.Response.bytes(utf8.encode(body), 200);
      });

      // 2. Act
      final config = await loadWebPartner(client: client, base: localBase);

      // 3. Assert
      expect(config.name, 'Ação');
    });

    testWidgets('Edge Case: a response arriving shortly before the timeout '
        'still loads', (tester) async {
      // 1. Arrange
      final client = MockClient((request) async {
        await Future<void>.delayed(
          webPartnerFetchTimeout - const Duration(seconds: 1),
        );
        final body = acmeServerFiles[request.url.path]!;
        return http.Response.bytes(utf8.encode(body), 200);
      });
      PartnerConfig? loaded;
      unawaited(
        loadWebPartner(
          client: client,
          base: localBase,
        ).then((config) => loaded = config),
      );

      // 2. Act
      await tester.pump(webPartnerFetchTimeout * 2);

      // 3. Assert
      expect(loaded?.id, 'acme');
    });

    test(
      'Sad Path: a missing id.txt tells to run the staging command',
      () async {
        // 1. Arrange
        final client = staticServer({'/partner/partner.json': acmeJson});

        // 2. Act
        Future<PartnerConfig> action() =>
            loadWebPartner(client: client, base: localBase);

        // 3. Assert
        await expectLater(
          action(),
          throwsA(loadErrorContaining(['partner/id.txt', '404', stageCommand])),
        );
      },
    );

    test(
      'Sad Path: a missing partner.json tells to run the staging command',
      () async {
        // 1. Arrange
        final client = staticServer({'/partner/id.txt': 'acme\n'});

        // 2. Act
        Future<PartnerConfig> action() =>
            loadWebPartner(client: client, base: localBase);

        // 3. Assert
        await expectLater(
          action(),
          throwsA(
            loadErrorContaining(['partner/partner.json', '404', stageCommand]),
          ),
        );
      },
    );

    test('Sad Path: a server error throws PartnerLoadException with the '
        'status', () async {
      // 1. Arrange
      final client = MockClient((_) async => http.Response('boom', 500));

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(action(), throwsA(loadErrorContaining(['500'])));
    });

    test('Sad Path: a 2xx status other than 200 throws '
        'PartnerLoadException', () async {
      // 1. Arrange
      final client = MockClient((_) async => http.Response('', 204));

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(action(), throwsA(isA<PartnerLoadException>()));
    });

    test(
      'Sad Path: a network error tells to run the staging command',
      () async {
        // 1. Arrange
        final client = MockClient(
          (request) async =>
              throw http.ClientException('Connection refused', request.url),
        );

        // 2. Act
        Future<PartnerConfig> action() =>
            loadWebPartner(client: client, base: localBase);

        // 3. Assert
        await expectLater(
          action(),
          throwsA(loadErrorContaining(['Connection refused', stageCommand])),
        );
      },
    );

    testWidgets('Sad Path: a server that never answers times out with '
        'PartnerLoadException', (tester) async {
      // 1. Arrange
      final client = MockClient((_) => Completer<http.Response>().future);
      Object? failure;
      unawaited(
        loadWebPartner(
          client: client,
          base: localBase,
        ).then<void>((_) {}, onError: (Object error) => failure = error),
      );

      // 2. Act
      await tester.pump(webPartnerFetchTimeout + const Duration(seconds: 1));

      // 3. Assert
      expect(failure, loadErrorContaining(['partner/id.txt']));
    });

    test('Sad Path: invalid UTF-8 in partner.json throws '
        'PartnerLoadException naming the URL', () async {
      // 1. Arrange
      final client = MockClient((request) async {
        if (request.url.path.endsWith('id.txt')) {
          return http.Response.bytes(utf8.encode('acme\n'), 200);
        }
        return http.Response.bytes([0x7B, 0xFF, 0xFE, 0x7D], 200);
      });

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorContaining(['partner/partner.json'])),
      );
    });

    test(
      'Sad Path: invalid UTF-8 in id.txt throws PartnerLoadException',
      () async {
        // 1. Arrange
        final client = MockClient((request) async {
          if (request.url.path.endsWith('id.txt')) {
            return http.Response.bytes([0x61, 0xC3, 0x28], 200);
          }
          return http.Response.bytes(utf8.encode(acmeJson), 200);
        });

        // 2. Act
        Future<PartnerConfig> action() =>
            loadWebPartner(client: client, base: localBase);

        // 3. Assert
        await expectLater(
          action(),
          throwsA(loadErrorContaining(['partner/id.txt'])),
        );
      },
    );

    test('Sad Path: malformed partner.json names the file', () async {
      // 1. Arrange
      final client = staticServer({
        '/partner/id.txt': 'acme\n',
        '/partner/partner.json': '{"name": ',
      });

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorContaining(['partner/partner.json'])),
      );
    });

    test(
      'Sad Path: an invalid colors.primary names the file and the field',
      () async {
        // 1. Arrange
        final client = staticServer({
          '/partner/id.txt': 'acme\n',
          '/partner/partner.json':
              '{"name": "Acme", "colors": '
              '{"primary": "teal", "secondary": "#FFFFFF"}}',
        });

        // 2. Act
        Future<PartnerConfig> action() =>
            loadWebPartner(client: client, base: localBase);

        // 3. Assert
        await expectLater(
          action(),
          throwsA(
            loadErrorContaining(['partner/partner.json', 'colors.primary']),
          ),
        );
      },
    );

    test('Sad Path: an empty id.txt is reported on partner/id.txt with the '
        'staging command', () async {
      // 1. Arrange
      final client = staticServer({
        '/partner/id.txt': '\n',
        '/partner/partner.json': acmeJson,
      });

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorStartingWith('partner/id.txt:', [stageCommand])),
      );
    });

    test('Sad Path: an empty id.txt does not fetch partner.json', () async {
      // 1. Arrange
      final requests = <Uri>[];
      final client = staticServer({
        '/partner/id.txt': '\n',
        '/partner/partner.json': acmeJson,
      }, requests: requests);

      // 2. Act
      try {
        await loadWebPartner(client: client, base: localBase);
      } on PartnerLoadException {
        // Expected: the assertion checks the requests made.
      }

      // 3. Assert
      expect(requests, [Uri.parse('http://localhost:5000/partner/id.txt')]);
    });

    test('Sad Path: a reserved id in id.txt is reported on partner/id.txt '
        'naming the id', () async {
      // 1. Arrange
      final client = staticServer({
        '/partner/id.txt': 'release\n',
        '/partner/partner.json': acmeJson,
      });

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(
        action(),
        throwsA(
          loadErrorStartingWith('partner/id.txt:', ['release', stageCommand]),
        ),
      );
    });

    test(
      'Sad Path: a reserved id in id.txt does not fetch partner.json',
      () async {
        // 1. Arrange
        final requests = <Uri>[];
        final client = staticServer({
          '/partner/id.txt': 'release\n',
          '/partner/partner.json': acmeJson,
        }, requests: requests);

        // 2. Act
        try {
          await loadWebPartner(client: client, base: localBase);
        } on PartnerLoadException {
          // Expected: the assertion checks the requests made.
        }

        // 3. Assert
        expect(requests, hasLength(1));
      },
    );

    test('Sad Path: an id.txt with inner whitespace is reported on '
        'partner/id.txt', () async {
      // 1. Arrange
      final client = staticServer({
        '/partner/id.txt': 'acme beta\n',
        '/partner/partner.json': acmeJson,
      });

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorStartingWith('partner/id.txt:')),
      );
    });

    test('Sad Path: an SPA fallback serving index.html with 200 is reported '
        'on partner/id.txt with the staging command', () async {
      // 1. Arrange
      final client = MockClient(
        (_) async => http.Response(
          '<!DOCTYPE html><html><body></body></html>',
          200,
          headers: {'content-type': 'text/html'},
        ),
      );

      // 2. Act
      Future<PartnerConfig> action() =>
          loadWebPartner(client: client, base: localBase);

      // 3. Assert
      await expectLater(
        action(),
        throwsA(loadErrorStartingWith('partner/id.txt:', [stageCommand])),
      );
    });

    test('Sad Path: an SPA fallback does not fetch partner.json', () async {
      // 1. Arrange
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return http.Response('<!DOCTYPE html><html></html>', 200);
      });

      // 2. Act
      try {
        await loadWebPartner(client: client, base: localBase);
      } on PartnerLoadException {
        // Expected: the assertion checks the requests made.
      }

      // 3. Assert
      expect(requests, [Uri.parse('http://localhost:5000/partner/id.txt')]);
    });
  });
}
