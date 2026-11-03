import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/ui/auth/view_models/login_view_model.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

@GenerateNiceMocks([MockSpec<LoginViewModel>()])
import 'login_screen_test.mocks.dart';

/// A [MockLoginViewModel] still restoring (and Google not ready yet), whose
/// restore finishes at once and counts its runs in [restores].
({MockLoginViewModel controller, List<void> restores}) _loginViewModel() {
  final controller = MockLoginViewModel();
  final restores = <void>[];
  when(controller.state).thenReturn(const LoginState());
  when(controller.restoreSession).thenReturn(
    Command0(() async {
      restores.add(null);
      return const Ok(null);
    }),
  );
  when(controller.loginGoogle).thenReturn(Command0(() async => const Ok(null)));
  return (controller: controller, restores: restores);
}

void main() {
  group('LoginScreen - Unit Test Suite', () {
    testWidgets('Happy Path: the first frame restores the session once', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final (:controller, :restores) = _loginViewModel();

      // 2. Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: LoginScreen(controller: controller),
        ),
      );

      // 3. Assert
      expect(restores, hasLength(1));
    });

    testWidgets('Edge Case: later frames do not restore the session again', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      final (:controller, :restores) = _loginViewModel();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: LoginScreen(controller: controller),
        ),
      );

      // 2. Act
      await tester.pump(const Duration(seconds: 1));

      // 3. Assert
      expect(restores, hasLength(1));
    });

    testWidgets(
      'Sad Path: a session still being restored shows the spinner, not the Google button',
      (WidgetTester tester) async {
        // 1. Arrange
        final (:controller, restores: _) = _loginViewModel();

        // 2. Act
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            home: LoginScreen(controller: controller),
          ),
        );

        // 3. Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
