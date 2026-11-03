import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/ui/core/ui/logout_progress_overlay.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/app_locales.dart';

const String _kOverlayMessage = 'Encerrando sessão…';
const String _kBackgroundRouteText = 'tela-anterior';

/// Contador de toques recebidos pelos botões posicionados sob a camada.
class _TapCounter {
  int taps = 0;
  void increment() => taps++;
}

/// Reproduz o uso real (Stack com `StackFit.expand` na HomeScreen): um
/// botão sob a camada de progresso, alinhado conforme [buttonAlignment].
Widget _buildCoveredButtonApp(
  _TapCounter counter, {
  Alignment buttonAlignment = Alignment.center,
}) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: appSupportedLocales,
    home: Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: buttonAlignment,
            child: ElevatedButton(
              onPressed: counter.increment,
              child: const Text('botão-sob-a-camada'),
            ),
          ),
          const LogoutProgressOverlay(message: _kOverlayMessage),
        ],
      ),
    ),
  );
}

void main() {
  group('LogoutProgressOverlay - Suíte de Testes Unitários', () {
    // ---------------------------------------------------------------------
    // Happy Path
    // ---------------------------------------------------------------------
    testWidgets('Happy Path: Deve exibir um CircularProgressIndicator', (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      const overlay = LogoutProgressOverlay(message: _kOverlayMessage);

      // 2. Act
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: Scaffold(body: overlay),
        ),
      );

      // 3. Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets("Happy Path: Deve exibir o texto 'Encerrando sessão…'", (
      WidgetTester tester,
    ) async {
      // 1. Arrange
      const overlay = LogoutProgressOverlay(message: _kOverlayMessage);

      // 2. Act
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: Scaffold(body: overlay),
        ),
      );

      // 3. Assert
      expect(find.text(_kOverlayMessage), findsOneWidget);
    });

    testWidgets(
      "Happy Path: Deve exibir a mensagem informada e não a padrão ('Trocando de organização…')",
      (WidgetTester tester) async {
        // 1. Arrange
        const overlay = LogoutProgressOverlay(
          message: 'Trocando de organização…',
        );

        // 2. Act
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            home: Scaffold(body: overlay),
          ),
        );

        // 3. Assert
        expect(find.text('Trocando de organização…'), findsOneWidget);
        expect(find.text(_kOverlayMessage), findsNothing);
      },
    );

    // ---------------------------------------------------------------------
    // Edge Case
    // ---------------------------------------------------------------------
    testWidgets(
      'Edge Case: Deve bloquear toques sob a camada também com mensagem personalizada',
      (WidgetTester tester) async {
        // 1. Arrange
        final counter = _TapCounter();
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            home: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: ElevatedButton(
                      onPressed: counter.increment,
                      child: const Text('botão-sob-a-camada'),
                    ),
                  ),
                  const LogoutProgressOverlay(
                    message: 'Trocando de organização…',
                  ),
                ],
              ),
            ),
          ),
        );

        // 2. Act
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();

        // 3. Assert
        expect(counter.taps, 0);
      },
    );

    testWidgets(
      'Edge Case: Deve exibir o indicador de progresso em modo indeterminado (sem valor fixo)',
      (WidgetTester tester) async {
        // 1. Arrange
        const overlay = LogoutProgressOverlay(message: _kOverlayMessage);

        // 2. Act
        await tester.pumpWidget(
          const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            home: Scaffold(body: overlay),
          ),
        );

        // 3. Assert
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.value, isNull);
      },
    );

    testWidgets(
      'Edge Case: Não deve ser fechada por um toque na área escurecida (rota permanece aberta)',
      (WidgetTester tester) async {
        // 1. Arrange
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appSupportedLocales,
            navigatorKey: navigatorKey,
            home: const Scaffold(body: Text(_kBackgroundRouteText)),
          ),
        );
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: LogoutProgressOverlay(message: _kOverlayMessage),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // 2. Act
        await tester.tapAt(const Offset(5, 5));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // 3. Assert
        expect(find.text(_kOverlayMessage), findsOneWidget);
        expect(navigatorKey.currentState!.canPop(), isTrue);
      },
    );

    // ---------------------------------------------------------------------
    // Sad Path
    // ---------------------------------------------------------------------
    testWidgets(
      'Sad Path: Deve impedir que um toque alcance o botão posicionado sob o card de progresso',
      (WidgetTester tester) async {
        // 1. Arrange
        final counter = _TapCounter();
        await tester.pumpWidget(_buildCoveredButtonApp(counter));

        // 2. Act
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();

        // 3. Assert
        expect(counter.taps, 0);
      },
    );

    testWidgets(
      'Sad Path: Deve impedir que um toque alcance o botão posicionado fora do card (área da barreira)',
      (WidgetTester tester) async {
        // 1. Arrange
        final counter = _TapCounter();
        await tester.pumpWidget(
          _buildCoveredButtonApp(counter, buttonAlignment: Alignment.topLeft),
        );

        // 2. Act
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();

        // 3. Assert
        expect(counter.taps, 0);
      },
    );
  });
}
