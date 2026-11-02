import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/ui/invites/view_models/welcome_view_model.dart';
import 'package:monamie_app/ui/invites/widgets/welcome_screen.dart';

@GenerateNiceMocks([MockSpec<WelcomeViewModel>()])
import 'welcome_screen_test.mocks.dart';

/// A [MockWelcomeViewModel] with no invite to welcome.
MockWelcomeViewModel _controller() {
  final controller = MockWelcomeViewModel();
  when(controller.invite).thenReturn(null);
  return controller;
}

/// Opens *Boas-vindas* over [controller].
Future<void> _pump(WidgetTester tester, WelcomeViewModel controller) async {
  await tester.pumpWidget(
    MaterialApp(home: WelcomeScreen(controller: controller)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('WelcomeScreen - Unit Test Suite', () {
    testWidgets('Happy Path: "Abrir o mapa" finishes the welcome (the router '
        'follows the session to the map)', (WidgetTester tester) async {
      // 1. Arrange
      final controller = _controller();
      await _pump(tester, controller);

      // 2. Act
      await tester.tap(find.text('Abrir o mapa'));
      await tester.pumpAndSettle();

      // 3. Assert
      verify(controller.finishWelcome()).called(1);
    });
  });
}
