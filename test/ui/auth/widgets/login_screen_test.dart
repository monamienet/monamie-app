import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/ui/auth/view_models/auth_google_view_model.dart';
import 'package:monamie_app/ui/auth/view_models/login_view_model.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/core/ui/notice_presenter.dart';

// mockito cannot generate a mock of `AuthGoogleViewModel` (its builder
// fails with "Bad state: No element"), so the screen gets a real one that
// never starts: nothing it does here reaches its services.
@GenerateNiceMocks([MockSpec<LoginViewModel>(), MockSpec<NoticePresenter>()])
import 'login_screen_test.mocks.dart';

/// A [MockLoginViewModel] still restoring, whose restore finishes at once.
MockLoginViewModel _loginViewModel() {
  final controller = MockLoginViewModel();
  when(controller.state).thenReturn(const LoginState());
  when(controller.restoreSession()).thenAnswer((_) async {});
  return controller;
}

/// An [AuthGoogleViewModel] never started (Google not ready yet).
AuthGoogleViewModel _auth() =>
    AuthGoogleViewModel(notices: MockNoticePresenter(), refreshTheme: () {});

void main() {
  group('LoginScreen - Unit Test Suite', () {
    testWidgets('Happy Path: the first frame restores the session once', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final controller = _loginViewModel();

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(controller: controller, auth: _auth()),
        ),
      );

      // 3. Assert
      verify(controller.restoreSession()).called(1);
    });

    testWidgets('Edge Case: later frames do not restore the session again', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final controller = _loginViewModel();
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(controller: controller, auth: _auth()),
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
        final controller = _loginViewModel();

        // 2. Act
        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(controller: controller, auth: _auth()),
          ),
        );

        // 3. Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
