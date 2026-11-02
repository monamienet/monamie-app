import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/ui/core/monamie_app.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/core/themes/app_theme.dart';

/// Opens the app. Its real sign-in controller starts: Google Sign-In has
/// no implementation in tests, so it fails to initialize and *Login* shows
/// the Google button. Not `pumpAndSettle`, in case a spinner stays.
Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MonAmieApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('MonAmieApp (app scope) - Widget Test Suite', () {
    testWidgets('Happy Path: the app opens on Login, whose route finds the '
        'sign-in controller above the router', (tester) async {
      // 1. Arrange
      // (nothing: the app builds its own controller and router)

      // 2. Act
      await _pumpApp(tester);

      // 3. Assert
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: the router starts on the theme of the bound '
        'organization', (tester) async {
      // 1. Arrange
      final expected = AppTheme.lightTheme;

      // 2. Act
      await _pumpApp(tester);

      // 3. Assert
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, expected);
      expect(app.themeMode, ThemeMode.light);
    });

    testWidgets('Sad Path: closing the app releases the router, the '
        'controller and the theme without errors', (tester) async {
      // 1. Arrange
      await _pumpApp(tester);

      // 2. Act
      await tester.pumpWidget(const SizedBox());

      // 3. Assert
      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}
