import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';

import '../support/test_app.dart';
import '../support/test_organization.dart';

/// The entry screens in English, over the real router and [TestApp]'s
/// in-memory repositories: the texts come from `app_en.arb`, not from the
/// Portuguese template.
void main() {
  // Signed out, no organization is bound; the other test files expect the
  // test organization, so it is put back after each test.
  setUp(Organization.unbind);
  tearDown(() => Organization.bind(testOrganization));

  group('Entry screens in English - Widget Test Suite', () {
    testWidgets('Happy Path: Login shows the English tagline and button', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);

      // 2. Act
      await app.pump(tester, locale: const Locale('en'));

      // 3. Assert
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Your team, on the same page.'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Entrar com o Google'), findsNothing);
    });

    testWidgets('Happy Path: Sem organização shows its English texts', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester, locale: const Locale('en'));

      // 2. Act: Google's chooser returns an account in no organization.
      await tester.tap(find.text('Sign in with Google'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.noOrganization);
      expect(find.byType(NoOrganizationScreen), findsOneWidget);
      expect(
        find.text('You are not part of an organization yet'),
        findsOneWidget,
      );
      expect(find.text('Create my organization'), findsOneWidget);
      expect(find.text('I was invited · check again'), findsOneWidget);
      expect(find.text('Criar minha organização'), findsNothing);
    });

    testWidgets('Edge Case: an English locale with a region still reads '
        'English', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);

      // 2. Act
      await app.pump(tester, locale: const Locale('en', 'GB'));

      // 3. Assert
      expect(find.text('Sign in with Google'), findsOneWidget);
    });
  });
}
