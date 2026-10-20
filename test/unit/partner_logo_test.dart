import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_logo.dart';

import '../support/test_partner.dart';

/// A square SVG, so the rendered logo keeps exactly the requested size.
const squareSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" '
    'viewBox="0 0 10 10"><rect width="10" height="10" fill="#112233"/></svg>';

/// Bytes that are not an SVG document.
const notAnSvg = 'this is not an svg';

/// Asset key of the logo of [testPartner], written out so the tests do not
/// trust the implementation's own helper.
const acmeLogoKey = 'partners/acme/logo-com-texto.svg';

/// Display name of [testPartner].
const acmeLabel = 'MonAmie Acme';

/// A second partner, to check that the widget follows its `partner`.
const betaPartner = PartnerConfig(
  id: 'beta',
  name: 'Beta',
  primaryColor: Color(0xFF445566),
  secondaryColor: Color(0xFF000000),
);

/// An [AssetBundle] that serves [assets] from memory and records every key
/// it is asked for. Unknown keys fail like a missing Flutter asset.
class FakeAssetBundle extends AssetBundle {
  FakeAssetBundle([this.assets = const {}, this.pending]);

  final Map<String, String> assets;

  /// When set, every load waits on it instead of answering.
  final Completer<ByteData>? pending;

  final requestedKeys = <String>[];

  @override
  Future<ByteData> load(String key) {
    requestedKeys.add(key);
    final waiting = pending;
    if (waiting != null) return waiting.future;
    final content = assets[key];
    if (content == null) {
      return Future.error(FlutterError('Unable to load asset: "$key".'));
    }
    return Future.value(
      ByteData.sublistView(Uint8List.fromList(utf8.encode(content))),
    );
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) async => parser(await loadString(key));
}

/// A [MockClient] that records every requested URL and answers with
/// [respond].
class RecordingClient {
  RecordingClient(Future<http.Response> Function(http.Request) respond) {
    client = MockClient((request) {
      urls.add(request.url);
      return respond(request);
    });
  }

  /// Every URL requested so far, in order.
  final urls = <Uri>[];

  late final MockClient client;
}

/// [child] inside a minimal app, centered so it gets loose constraints, with
/// [bundle] as its [DefaultAssetBundle].
Widget host(Widget child, {AssetBundle? bundle}) {
  final centered = Center(child: child);
  return MaterialApp(
    home: Scaffold(
      body: bundle == null
          ? centered
          : DefaultAssetBundle(bundle: bundle, child: centered),
    ),
  );
}

/// Pumps [widget] until it settles, absorbing the asynchronous errors that
/// flutter_svg and vector_graphics leave unhandled when a load fails. The
/// same error still reaches the `errorBuilder`, which is what these tests
/// check; without this, the test zone would report the leaked copies as
/// test failures.
Future<void> pumpFailingLoad(WidgetTester tester, Widget widget) async {
  await runZonedGuarded(
    () async {
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    },
    (_, _) {
      // Leaked copy of an error the errorBuilder already handled.
    },
  );
}

/// The decoded picture inside the logo: vector_graphics wraps it in a
/// [FittedBox], which neither the placeholder nor the fallback has.
final renderedPicture = find.descendant(
  of: find.byType(SvgPicture),
  matching: find.byType(FittedBox),
);

/// Counter behind [freshBase].
var _baseCount = 0;

/// A base URL no other test uses. flutter_svg keeps a load that failed or is
/// still pending in its cache for good (`svg.cache.clear()` does not drop
/// it), so every web test fetches from its own URL.
Uri freshBase() => Uri.parse('https://app${++_baseCount}.example/');

void main() {
  setUp(() {
    // The SVG cache outlives a test; clear it so every test loads afresh.
    svg.cache.clear();
  });

  group('partner logo paths - Unit Test Suite', () {
    test('Happy Path: partnerLogoFileName is logo-com-texto.svg', () {
      // 1. Arrange
      const expected = 'logo-com-texto.svg';

      // 2. Act
      const name = partnerLogoFileName;

      // 3. Assert
      expect(name, expected);
    });

    test('Happy Path: webPartnerLogoPath is partner/logo-com-texto.svg', () {
      // 1. Arrange
      const expected = 'partner/logo-com-texto.svg';

      // 2. Act
      const path = webPartnerLogoPath;

      // 3. Assert
      expect(path, expected);
    });

    test('Happy Path: partnerLogoAssetKey points into the partner '
        'folder', () {
      // 1. Arrange
      const id = 'aquariustur';

      // 2. Act
      final key = partnerLogoAssetKey(id);

      // 3. Assert
      expect(key, 'partners/aquariustur/logo-com-texto.svg');
    });

    test('Edge Case: the web path is relative, so it resolves against the '
        'base href', () {
      // 1. Arrange
      final base = Uri.parse('https://host.example/app/');

      // 2. Act
      final resolved = base.resolve(webPartnerLogoPath);

      // 3. Assert
      expect(
        resolved,
        Uri.parse('https://host.example/app/partner/logo-com-texto.svg'),
      );
    });

    test('Edge Case: partnerLogoAssetKey uses the id as given', () {
      // 1. Arrange
      const id = 'beta2';

      // 2. Act
      final key = partnerLogoAssetKey(id);

      // 3. Assert
      expect(key, 'partners/beta2/logo-com-texto.svg');
    });

    test('Sad Path: partnerLogoAssetKey works before Partner.init', () {
      // 1. Arrange
      Partner.debugReset();
      addTearDown(() {
        Partner.debugReset();
        Partner.init(testPartner);
      });

      // 2. Act
      final key = partnerLogoAssetKey('beta');

      // 3. Assert
      expect(key, 'partners/beta/logo-com-texto.svg');
    });
  });

  group('PartnerLogo on mobile - Unit Test Suite', () {
    testWidgets('Happy Path: loads the logo of Partner.current from the '
        'asset bundle', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(bundle.requestedKeys, [acmeLogoKey]);
    });

    testWidgets('Happy Path: off the web it uses the bundled asset by '
        'default', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await tester.pumpWidget(
        host(const PartnerLogo(width: 220, height: 220), bundle: bundle),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(bundle.requestedKeys, [acmeLogoKey]);
    });

    testWidgets('Happy Path: renders an SvgPicture of the asset key', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        picture.bytesLoader,
        isA<SvgAssetLoader>().having(
          (loader) => loader.assetName,
          'assetName',
          acmeLogoKey,
        ),
      );
    });

    testWidgets('Happy Path: the loaded picture replaces the placeholder', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(renderedPicture, findsOneWidget);
    });

    testWidgets('Happy Path: a loaded logo shows no fallback text', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.text(acmeLabel), findsNothing);
    });

    testWidgets('Happy Path: a loaded logo takes the given size', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(tester.getSize(find.byType(PartnerLogo)), const Size(220, 220));
    });

    testWidgets('Happy Path: the logo is labeled with the partner display '
        'name', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.bySemanticsLabel(acmeLabel), findsOneWidget);
    });

    testWidgets('Happy Path: an explicit partner overrides Partner.current', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({
        'partners/beta/logo-com-texto.svg': squareSvg,
      });

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(
            width: 220,
            height: 220,
            partner: betaPartner,
            web: false,
          ),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(bundle.requestedKeys, ['partners/beta/logo-com-texto.svg']);
    });

    testWidgets('Edge Case: while loading it shows an empty box of the given '
        'size', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle(const {}, Completer<ByteData>());

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 180, height: 90, web: false),
          bundle: bundle,
        ),
      );

      // 3. Assert
      expect(tester.getSize(find.byType(PartnerLogo)), const Size(180, 90));
    });

    testWidgets('Edge Case: while loading it shows no fallback text', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle(const {}, Completer<ByteData>());

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 180, height: 90, web: false),
          bundle: bundle,
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsNothing);
    });

    testWidgets('Edge Case: the label follows an explicit partner', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({
        'partners/beta/logo-com-texto.svg': squareSvg,
      });

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(
            width: 220,
            height: 220,
            partner: betaPartner,
            web: false,
          ),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.bySemanticsLabel('MonAmie Beta'), findsOneWidget);
    });

    testWidgets('Sad Path: a missing asset shows the display name instead', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle();

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsOneWidget);
    });

    testWidgets('Sad Path: an asset that is not an SVG shows the display '
        'name instead', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: notAnSvg});

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: bundle,
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsOneWidget);
    });

    testWidgets('Sad Path: the fallback keeps the given size', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle();

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          const PartnerLogo(width: 180, height: 90, web: false),
          bundle: bundle,
        ),
      );

      // 3. Assert
      expect(tester.getSize(find.byType(PartnerLogo)), const Size(180, 90));
    });

    testWidgets('Sad Path: the fallback names an explicit partner', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle();

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          const PartnerLogo(
            width: 220,
            height: 220,
            partner: betaPartner,
            web: false,
          ),
          bundle: bundle,
        ),
      );

      // 3. Assert
      expect(find.text('MonAmie Beta'), findsOneWidget);
    });

    testWidgets('Sad Path: without a partner and before Partner.init the '
        'build throws StateError', (tester) async {
      // 1. Arrange
      Partner.debugReset();
      addTearDown(() {
        Partner.debugReset();
        Partner.init(testPartner);
      });

      // 2. Act
      await tester.pumpWidget(
        host(
          const PartnerLogo(width: 220, height: 220, web: false),
          bundle: FakeAssetBundle(),
        ),
      );

      // 3. Assert
      expect(tester.takeException(), isA<StateError>());
    });
  });

  group('PartnerLogo on web - Unit Test Suite', () {
    testWidgets('Happy Path: fetches partner/logo-com-texto.svg relative to '
        'the base URL', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(recorder.urls, [Uri.parse('${base}partner/logo-com-texto.svg')]);
    });

    testWidgets('Happy Path: renders an SvgPicture of the staged copy', (
      tester,
    ) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        picture.bytesLoader,
        isA<SvgNetworkLoader>().having(
          (loader) => loader.url,
          'url',
          '${base}partner/logo-com-texto.svg',
        ),
      );
    });

    testWidgets('Happy Path: the fetched picture replaces the placeholder', (
      tester,
    ) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(renderedPicture, findsOneWidget);
    });

    testWidgets('Happy Path: a fetched logo shows no fallback text', (
      tester,
    ) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.text(acmeLabel), findsNothing);
    });

    testWidgets('Happy Path: the fetched logo is labeled with the partner '
        'display name', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.bySemanticsLabel(acmeLabel), findsOneWidget);
    });

    testWidgets('Happy Path: on web the asset bundle is not read', (
      tester,
    ) async {
      // 1. Arrange
      final base = freshBase();
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
          bundle: bundle,
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(bundle.requestedKeys, isEmpty);
    });

    testWidgets('Edge Case: a base URL with a subfolder keeps the '
        'subfolder', (tester) async {
      // 1. Arrange
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: Uri.parse('https://host.example/monamie/'),
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(recorder.urls, [
        Uri.parse('https://host.example/monamie/partner/logo-com-texto.svg'),
      ]);
    });

    testWidgets('Edge Case: a hash route in the base URL is dropped', (
      tester,
    ) async {
      // 1. Arrange
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: Uri.parse('https://hash.example/#/login'),
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(recorder.urls, [
        Uri.parse('https://hash.example/partner/logo-com-texto.svg'),
      ]);
    });

    testWidgets('Edge Case: the base URL defaults to Uri.base', (tester) async {
      // 1. Arrange
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(recorder.urls, [Uri.base.resolve('partner/logo-com-texto.svg')]);
    });

    testWidgets('Edge Case: the staged path does not depend on the partner '
        'id', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response(squareSvg, 200),
      );

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            partner: betaPartner,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3. Assert
      expect(recorder.urls, [Uri.parse('${base}partner/logo-com-texto.svg')]);
    });

    testWidgets('Edge Case: while downloading it shows an empty box of the '
        'given size', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final response = Completer<http.Response>();
      final recorder = RecordingClient((_) => response.future);

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 180,
            height: 90,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );

      // 3. Assert
      expect(tester.getSize(find.byType(PartnerLogo)), const Size(180, 90));
    });

    testWidgets('Edge Case: while downloading it shows no fallback text', (
      tester,
    ) async {
      // 1. Arrange
      final base = freshBase();
      final response = Completer<http.Response>();
      final recorder = RecordingClient((_) => response.future);

      // 2. Act
      await tester.pumpWidget(
        host(
          PartnerLogo(
            width: 180,
            height: 90,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsNothing);
    });

    testWidgets('Sad Path: a 404 page shows the display name instead', (
      tester,
    ) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response('Not Found', 404),
      );

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsOneWidget);
    });

    testWidgets('Sad Path: a network failure shows the display name '
        'instead', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => throw http.ClientException('offline'),
      );

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsOneWidget);
    });

    testWidgets('Sad Path: a body that is not an SVG shows the display name '
        'instead', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response(notAnSvg, 200),
      );

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsOneWidget);
    });

    testWidgets('Sad Path: the fallback keeps the given size', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final recorder = RecordingClient(
        (_) async => http.Response('Not Found', 404),
      );

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          PartnerLogo(
            width: 180,
            height: 90,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );

      // 3. Assert
      expect(tester.getSize(find.byType(PartnerLogo)), const Size(180, 90));
    });

    testWidgets('Sad Path: the app shell served in place of a missing logo '
        '(hosting rewrite to index.html) shows the display name '
        'instead', (tester) async {
      // 1. Arrange
      final base = freshBase();
      final indexHtml = File('web/index.html').readAsStringSync();
      final recorder = RecordingClient(
        (_) async => http.Response(
          indexHtml,
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        ),
      );

      // 2. Act
      await pumpFailingLoad(
        tester,
        host(
          PartnerLogo(
            width: 220,
            height: 220,
            web: true,
            base: base,
            httpClient: recorder.client,
          ),
        ),
      );

      // 3. Assert
      expect(find.text(acmeLabel), findsOneWidget);
    });
  });
}
