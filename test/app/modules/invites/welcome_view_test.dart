import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:monamie_app/app/modules/invites/welcome_view.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/routes/app_pages.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';

// mockito cannot generate a mock of `AuthGoogleController` (its builder
// fails with "Bad state: No element"), so the screen gets a real one that
// never starts; `finishWelcome` shows in its session state.
@GenerateNiceMocks([MockSpec<NoticePresenter>()])
import 'welcome_view_test.mocks.dart';

const _kWelcomeRoute = '/welcome-test';
const _kMapPlaceholder = 'map-placeholder';

/// An [AuthGoogleController] never started, with no invite to welcome.
AuthGoogleController _controller() =>
    AuthGoogleController(notices: MockNoticePresenter(), refreshTheme: () {});

/// Opens *Boas-vindas* over [controller], with a placeholder map route.
Future<void> _pump(WidgetTester tester, AuthGoogleController controller) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: _kWelcomeRoute,
      getPages: [
        GetPage(
          name: _kWelcomeRoute,
          page: () => WelcomeView(controller: controller),
        ),
        GetPage(
          name: Routes.MONAMIE,
          page: () => const Scaffold(body: Text(_kMapPlaceholder)),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  group('WelcomeView - Unit Test Suite', () {
    testWidgets('Happy Path: "Abrir o mapa" finishes the welcome (bound)', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final controller = _controller();
      await _pump(tester, controller);

      // 2. Act
      await tester.tap(find.text('Abrir o mapa'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(controller.state.session, const SessionState.bound());
    });
  });
}
