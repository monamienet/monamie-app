import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
// The platform interface is a transitive dependency of firebase_core and
// ships the official Firebase Core mocks for tests.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/config/partner/partner.dart';
import 'package:monamie_app/app/config/partner/partner_config.dart';
import 'package:monamie_app/app/config/partner/partner_logo.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:monamie_app/app/modules/login/views/login_view.dart';
import 'package:monamie_app/app/utils/color_pallete.dart';

import '../support/test_partner.dart';

/// A square SVG, so the logo keeps exactly the requested size.
const squareSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" '
    'viewBox="0 0 10 10"><rect width="10" height="10" fill="#112233"/></svg>';

/// Asset key of the logo of [testPartner], written out so the tests do not
/// trust the implementation's own helper.
const acmeLogoKey = 'partners/acme/logo-com-texto.svg';

/// A partner whose `colors.secondary` is dark, so the login background can
/// be told apart from the white default.
const nightlyPartner = PartnerConfig(
  id: 'nightly',
  name: 'Nightly',
  primaryColor: Color(0xFF112233),
  secondaryColor: Color(0xFF101820),
);

/// Skips the Google Sign-In and Firebase work of the real `onInit`.
class _FakeAuthGoogleController extends AuthGoogleController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

/// Keeps the session restore pending, so the view shows its spinner and
/// never navigates away.
class _FakeLoginController extends LoginController {
  @override
  // ignore: must_call_super
  Future<void> onReady() async {}
}

/// An [AssetBundle] that serves [assets] from memory and records every key
/// it is asked for. Unknown keys fail like a missing Flutter asset.
class FakeAssetBundle extends AssetBundle {
  FakeAssetBundle([this.assets = const {}]);

  final Map<String, String> assets;

  final requestedKeys = <String>[];

  @override
  Future<ByteData> load(String key) {
    requestedKeys.add(key);
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

/// The login screen with [bundle] as its asset bundle.
Widget loginApp(AssetBundle bundle) => MaterialApp(
  home: DefaultAssetBundle(bundle: bundle, child: const LoginView()),
);

/// Pumps [widget] and lets the logo load. The spinner of the pending session
/// restore never settles, so this pumps a few frames instead of settling.
/// Load errors that flutter_svg and vector_graphics leave unhandled (the
/// same error also reaches the logo's `errorBuilder`) are absorbed.
Future<void> pumpLogin(WidgetTester tester, Widget widget) async {
  await runZonedGuarded(
    () async {
      await tester.pumpWidget(widget);
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    },
    (_, _) {
      // Leaked copy of an error the errorBuilder already handled.
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // LoginController builds a UserGoogleRepository, which calls
    // `Firebase.app()`. The official mocks avoid native channels.
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    Get.testMode = true;
    Get.put<AuthGoogleController>(_FakeAuthGoogleController());
    Get.put<LoginController>(_FakeLoginController());
  });

  tearDown(Get.reset);

  group('LoginView partner logo and background - Unit Test Suite', () {
    testWidgets('Happy Path: shows a 220x220 PartnerLogo', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await pumpLogin(tester, loginApp(bundle));

      // 3. Assert
      expect(
        tester.widget<PartnerLogo>(find.byType(PartnerLogo)),
        isA<PartnerLogo>()
            .having((logo) => logo.width, 'width', 220)
            .having((logo) => logo.height, 'height', 220),
      );
    });

    testWidgets('Happy Path: the logo is the asset of the current '
        'partner', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await pumpLogin(tester, loginApp(bundle));

      // 3. Assert
      expect(bundle.requestedKeys, [acmeLogoKey]);
    });

    testWidgets('Happy Path: the Scaffold uses AppColors.background', (
      tester,
    ) async {
      // 1. Arrange
      final bundle = FakeAssetBundle({acmeLogoKey: squareSvg});

      // 2. Act
      await pumpLogin(tester, loginApp(bundle));

      // 3. Assert
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppColors.background,
      );
    });

    testWidgets('Edge Case: the background follows the colors.secondary of '
        'another partner', (tester) async {
      // 1. Arrange
      Partner.debugReset();
      Partner.init(nightlyPartner);
      addTearDown(() {
        Partner.debugReset();
        Partner.init(testPartner);
      });
      final bundle = FakeAssetBundle({
        'partners/nightly/logo-com-texto.svg': squareSvg,
      });

      // 2. Act
      await pumpLogin(tester, loginApp(bundle));

      // 3. Assert
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        const Color(0xFF101820),
      );
    });

    testWidgets('Edge Case: another partner gets its own logo', (tester) async {
      // 1. Arrange
      Partner.debugReset();
      Partner.init(nightlyPartner);
      addTearDown(() {
        Partner.debugReset();
        Partner.init(testPartner);
      });
      final bundle = FakeAssetBundle({
        'partners/nightly/logo-com-texto.svg': squareSvg,
      });

      // 2. Act
      await pumpLogin(tester, loginApp(bundle));

      // 3. Assert
      expect(bundle.requestedKeys, ['partners/nightly/logo-com-texto.svg']);
    });

    testWidgets('Sad Path: a missing logo shows the display name in its '
        'place, next to the app bar title', (tester) async {
      // 1. Arrange
      final bundle = FakeAssetBundle();

      // 2. Act
      await pumpLogin(tester, loginApp(bundle));

      // 3. Assert
      expect(find.text('MonAmie Acme'), findsNWidgets(2));
    });
  });
}
