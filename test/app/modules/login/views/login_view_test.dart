import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/controllers/login_controller.dart';
import 'package:monamie_app/app/modules/login/views/login_view.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';

// mockito cannot generate a mock of `AuthGoogleController` (its builder
// fails with "Bad state: No element"), so the screen gets a real one that
// never starts: nothing it does here reaches its services.
@GenerateNiceMocks([MockSpec<LoginController>(), MockSpec<NoticePresenter>()])
import 'login_view_test.mocks.dart';

/// A [MockLoginController] still restoring, whose restore finishes at once.
MockLoginController _loginController() {
  final controller = MockLoginController();
  when(controller.state).thenReturn(const LoginState());
  when(controller.restoreSession()).thenAnswer((_) async {});
  return controller;
}

/// An [AuthGoogleController] never started (Google not ready yet).
AuthGoogleController _auth() =>
    AuthGoogleController(notices: MockNoticePresenter(), refreshTheme: () {});

void main() {
  group('LoginView - Unit Test Suite', () {
    testWidgets('Happy Path: the first frame restores the session once', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final controller = _loginController();

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(controller: controller, auth: _auth()),
        ),
      );

      // 3. Assert
      verify(controller.restoreSession()).called(1);
    });

    testWidgets('Edge Case: later frames do not restore the session again', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final controller = _loginController();
      await tester.pumpWidget(
        MaterialApp(
          home: LoginView(controller: controller, auth: _auth()),
        ),
      );

      // 2. Act
      await tester.pump(const Duration(seconds: 1));

      // 3. Assert
      verify(controller.restoreSession()).called(1);
    });

    testWidgets(
      'Sad Path: a session still being restored shows the spinner, not the Google button',
      (WidgetTester tester) async {
        // 1. Arrange
        final controller = _loginController();

        // 2. Act
        await tester.pumpWidget(
          MaterialApp(
            home: LoginView(controller: controller, auth: _auth()),
          ),
        );

        // 3. Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
