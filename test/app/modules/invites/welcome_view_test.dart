import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/modules/invites/welcome_view.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_state.dart';
import 'package:monamie_app/app/modules/login/controllers/session_flow.dart';

@GenerateNiceMocks([MockSpec<SessionFlow>()])
import 'welcome_view_test.mocks.dart';

/// A [MockSessionFlow] with no invite to welcome.
MockSessionFlow _flow() {
  final flow = MockSessionFlow();
  when(flow.state).thenReturn(const AuthGoogleState());
  return flow;
}

/// Opens *Boas-vindas* over [flow].
Future<void> _pump(WidgetTester tester, SessionFlow flow) async {
  await tester.pumpWidget(MaterialApp(home: WelcomeView(controller: flow)));
  await tester.pumpAndSettle();
}

void main() {
  group('WelcomeView - Unit Test Suite', () {
    testWidgets('Happy Path: "Abrir o mapa" finishes the welcome (the router '
        'follows the session to the map)', (WidgetTester tester) async {
      // 1. Arrange
      final flow = _flow();
      await _pump(tester, flow);

      // 2. Act
      await tester.tap(find.text('Abrir o mapa'));
      await tester.pumpAndSettle();

      // 3. Assert
      verify(flow.finishWelcome()).called(1);
    });
  });
}
