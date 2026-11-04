import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/ui/language/widgets/language_button.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/utils/result.dart';

import '../../testing/fakes/repositories/fake_organization_directory.dart';
import '../support/test_app.dart';
import '../support/test_organization.dart';
import '../ui/language/widgets/language_harness.dart' show languageRow;

const _rotaSul = OrganizationConfig(id: 'rotasul', name: 'Rota Sul');

/// The language picker on the screens that have it, over the real router and
/// [TestApp]'s in-memory repositories: the globe on the entry screens and the
/// menu's *Idioma*, and the choice changing the texts on screen at once and
/// following the person to the next screen.
void main() {
  // Signed out, no organization is bound; the other test files expect the
  // test organization, so it is put back after each test.
  setUp(Organization.unbind);
  tearDown(() => Organization.bind(testOrganization));

  /// Opens the picker from the globe on the screen and chooses [name].
  Future<void> chooseFromGlobe(WidgetTester tester, String name) async {
    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();
    await tester.tap(languageRow(name));
    await tester.pumpAndSettle();
  }

  group('Language picker on the entry screens - Widget Test Suite', () {
    testWidgets('Happy Path: Login has the globe, in the login scheme', (
      tester,
    ) async {
      // 1. Arrange / 2. Act
      final app = TestApp(googleReady: true);
      await app.pump(tester);

      // 3. Assert
      expect(find.byType(LanguageButton), findsOneWidget);
      expect(find.text('PT'), findsOneWidget);
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LanguageSheet>(find.byType(LanguageSheet)).scheme,
        LanguageScheme.login,
      );
    });

    testWidgets('Happy Path: choosing English on Login changes its texts at '
        'once', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester);
      expect(find.text('Entrar com o Google'), findsOneWidget);

      // 2. Act
      await chooseFromGlobe(tester, 'English');

      // 3. Assert
      expect(find.byType(LanguageSheet), findsNothing);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Entrar com o Google'), findsNothing);
      expect(find.text('EN'), findsOneWidget);
      expect(app.language.stored, AppLanguage.en);
      expect(app.location, Routes.login);
    });

    testWidgets('Edge Case: a language stored on the device is the one Login '
        'opens in', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.language.stored = AppLanguage.en;

      // 2. Act: the device's language is Brazilian Portuguese.
      await app.pump(tester);

      // 3. Assert
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('Happy Path: the language chosen on Login is the one of the '
        'next screen, Sem organização', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester);
      await chooseFromGlobe(tester, 'English');

      // 2. Act
      await tester.tap(find.text('Sign in with Google'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.noOrganization);
      expect(find.text('You are not part of an organization yet'), findsOne);
      expect(
        find.text('Você ainda não faz parte de uma organização'),
        findsNothing,
      );
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('Happy Path: Sem organização has the globe, in the '
        'organization scheme, and English changes its texts at once', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester);
      await tester.tap(find.text('Entrar com o Google'));
      await TestApp.settle(tester);
      expect(app.location, Routes.noOrganization);
      expect(find.byType(LanguageButton), findsOneWidget);

      // 2. Act
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      final scheme = tester
          .widget<LanguageSheet>(find.byType(LanguageSheet))
          .scheme;
      await tester.tap(languageRow('English'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(scheme, LanguageScheme.organization);
      expect(find.byType(LanguageSheet), findsNothing);
      expect(find.text('You are not part of an organization yet'), findsOne);
      expect(find.text('Create my organization'), findsOneWidget);
      expect(find.text('Criar minha organização'), findsNothing);
    });

    testWidgets('Happy Path: the picker (Escolher organização) has the globe '
        'and English changes its texts at once', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.directory.organizations.add(fakeCandidate('rotasul'));
      app.brandingLoader.brandings['rotasul'] = _rotaSul;
      await app.pump(tester);
      await tester.tap(find.text('Entrar com o Google'));
      await TestApp.settle(tester);
      expect(app.location, Routes.organizationPicker);
      expect(find.byType(LanguageButton), findsOneWidget);
      expect(find.text('Criar nova organização'), findsOneWidget);

      // 2. Act
      await chooseFromGlobe(tester, 'English');

      // 3. Assert
      expect(find.text('Which organization do you want to open?'), findsOne);
      expect(find.text('Create a new organization'), findsOneWidget);
      expect(find.text('Criar nova organização'), findsNothing);
      expect(find.text('Rota Sul'), findsOneWidget);
      expect(app.location, Routes.organizationPicker);
    });

    testWidgets('Sad Path: a choice that cannot be stored keeps Login in '
        'Portuguese with the message', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.language.fail('choose', const Failure.languageNotSaved());
      await app.pump(tester);

      // 2. Act
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      await tester.tap(languageRow('English'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsOneWidget);
      expect(
        find.text('Não foi possível guardar o idioma. Tente de novo.'),
        findsOneWidget,
      );
      expect(find.text('PT'), findsWidgets);
      expect(app.language.stored, isNull);
    });
  });

  group('Language picker in the map menu - Widget Test Suite', () {
    /// Opens the map of the test organization and its menu.
    Future<TestApp> openMenu(WidgetTester tester) async {
      Organization.bind(testOrganization);
      final app = TestApp();
      await app.pump(tester);
      app.session.moveTo(const SessionState.bound());
      await TestApp.settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.menu));
      await TestApp.settle(tester);
      return app;
    }

    testWidgets('Happy Path: the menu has Idioma with the language in use at '
        'its end', (tester) async {
      // 1. Arrange / 2. Act
      await openMenu(tester);

      // 3. Assert
      expect(find.text('Idioma'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Idioma'),
            matching: find.byType(InkWell),
          ),
          matching: find.text('Português'),
        ),
        findsOneWidget,
      );
      // Below "Trocar de organização".
      expect(
        tester.getTopLeft(find.text('Idioma')).dy,
        greaterThan(tester.getTopLeft(find.text('Trocar de organização')).dy),
      );
    });

    testWidgets('Happy Path: tapping Idioma closes the menu and opens the '
        'picker in the menu scheme', (tester) async {
      // 1. Arrange
      await openMenu(tester);

      // 2. Act
      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsOneWidget);
      expect(
        tester.widget<LanguageSheet>(find.byType(LanguageSheet)).scheme,
        LanguageScheme.menu,
      );
      expect(find.text('Sair'), findsNothing);
      expect(find.text('Trocar de organização'), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Happy Path: choosing English redraws the map and the menu, '
        'whose Idioma then ends in English', (tester) async {
      // 1. Arrange
      final app = await openMenu(tester);
      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      // 2. Act
      await tester.tap(languageRow('English'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsNothing);
      expect(app.language.stored, AppLanguage.en);
      await tester.tap(find.byIcon(Icons.menu));
      await TestApp.settle(tester);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Switch organization'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Language'),
            matching: find.byType(InkWell),
          ),
          matching: find.text('English'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Edge Case: the language chosen on Login is the menu\'s', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.directory.organizations.add(fakeCandidate('rotasul'));
      app.brandingLoader.brandings['rotasul'] = _rotaSul;
      await app.pump(tester);
      await chooseFromGlobe(tester, 'English');
      await tester.tap(find.text('Sign in with Google'));
      await TestApp.settle(tester);
      await tester.tap(find.text('Rota Sul'));
      await TestApp.settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);

      // 2. Act
      await tester.tap(find.byIcon(Icons.menu));
      await TestApp.settle(tester);

      // 3. Assert
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
