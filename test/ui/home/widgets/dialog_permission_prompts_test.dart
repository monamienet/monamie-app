import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/ui/home/widgets/dialog_permission_prompts.dart';
import 'package:monamie_app/ui/core/ui/app_messenger.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

const _prompts = DialogPermissionPrompts();

const String _batterySnippet =
    'O seu aparelho está restringindo o aplicativo em segundo plano.';

/// An app whose navigator is [rootNavigatorKey], where the dialogs open.
Future<void> _pumpApp(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: appSupportedLocales,
    navigatorKey: rootNavigatorKey,
    home: const Scaffold(body: SizedBox.shrink()),
  ),
);

/// Opens the battery question and waits until it is on screen.
Future<Future<bool>> _askBattery(WidgetTester tester) async {
  final answer = _prompts.confirmBackgroundUsageSettings();
  await tester.pumpAndSettle();
  return answer;
}

void main() {
  group('DialogPermissionPrompts - confirmations', () {
    testWidgets('Happy Path: PROSSEGUIR completes with true', (tester) async {
      // 1. Arrange
      await _pumpApp(tester);
      final answer = await _askBattery(tester);

      // 2. Act
      await tester.tap(find.text('PROSSEGUIR'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(await answer, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Sad Path: AGORA NÃO completes with false', (tester) async {
      // 1. Arrange
      await _pumpApp(tester);
      final answer = await _askBattery(tester);

      // 2. Act
      await tester.tap(find.text('AGORA NÃO'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(await answer, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'Happy Path: the battery question explains the restriction and offers both answers',
      (tester) async {
        // 1. Arrange
        await _pumpApp(tester);

        // 2. Act
        await _askBattery(tester);

        // 3. Assert
        expect(find.textContaining(_batterySnippet), findsOneWidget);
        expect(find.text('AGORA NÃO'), findsOneWidget);
        expect(find.text('PROSSEGUIR'), findsOneWidget);
      },
    );

    testWidgets(
      'Happy Path: the background-location question completes with true on PROSSEGUIR',
      (tester) async {
        // 1. Arrange
        await _pumpApp(tester);
        final answer = _prompts.confirmBackgroundLocation();
        await tester.pumpAndSettle();

        // 2. Act
        await tester.tap(find.text('PROSSEGUIR'));
        await tester.pumpAndSettle();

        // 3. Assert
        expect(await answer, isTrue);
      },
    );

    testWidgets('Edge Case: tapping outside the dialog does not dismiss it', (
      tester,
    ) async {
      // 1. Arrange
      await _pumpApp(tester);
      await _askBattery(tester);

      // 2. Act
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Sad Path: completes with false when no navigator is mounted', (
      tester,
    ) async {
      // 1. Arrange
      await tester.pumpWidget(const SizedBox.shrink());

      // 2. Act
      final answer = await _prompts.confirmBackgroundUsageSettings();

      // 3. Assert
      expect(answer, isFalse);
    });
  });

  group('DialogPermissionPrompts - notifyGpsDisabled', () {
    testWidgets('Happy Path: completes once ENTENDI is tapped', (tester) async {
      // 1. Arrange
      await _pumpApp(tester);
      var done = false;
      _prompts.notifyGpsDisabled().then((_) => done = true);
      await tester.pumpAndSettle();

      // 2. Act
      await tester.tap(find.text('ENTENDI'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(done, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
