import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/create_group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/ui/creation/widgets/create_organization_screen.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/routing/routes.dart';

import '../support/test_app.dart';
import '../support/test_organization.dart';

/// The app's router over [TestApp]: in-memory repositories, real use
/// cases, service mocks. The session moves only as in the app:
/// [SessionRepository.moveTo] to bound (what *Login* does for a remembered
/// session), `SignOut.call` signs out and `SignOut.afterAccessLost` leads to
/// *Sem organização*.
typedef _App = TestApp;

Future<void> _pump(WidgetTester tester, _App app) => app.pump(tester);

Future<void> _settle(WidgetTester tester) => TestApp.settle(tester);

/// Opens [app] and binds its session: the person is on the map.
Future<void> _pumpBound(WidgetTester tester, _App app) async {
  await _pump(tester, app);
  app.session.moveTo(const SessionState.bound());
  await _settle(tester);
}

/// Whether [listenable] was disposed (a disposed `ChangeNotifier` refuses
/// new listeners).
bool _isDisposed(Listenable listenable) {
  try {
    listenable.addListener(_noop);
    listenable.removeListener(_noop);
    return false;
  } on FlutterError {
    return true;
  }
}

void _noop() {}

void main() {
  // Signing out forgets the organization (`Organization.current`), which
  // the shell's routes read: every test starts bound to the test one.
  setUp(() => Organization.bind(testOrganization));
  tearDown(() => Organization.bind(testOrganization));

  group('buildAppRouter sign-in flow - Widget Test Suite', () {
    testWidgets('Happy Path: the app starts on Login while signed out', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();

      // 2. Act
      await _pump(tester, app);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Happy Path: a session restored on Login opens the map', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();
      await _pump(tester, app);

      // 2. Act
      app.session.moveTo(const SessionState.bound());
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.monamie);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('Happy Path: signing out from the map opens Login', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);

      // 2. Act
      await app.signOut();
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Edge Case: losing access to the organization opens Sem '
        'organização', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);

      // 2. Act
      await app.signOut.afterAccessLost();
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.noOrganization);
      expect(find.byType(NoOrganizationScreen), findsOneWidget);
    });

    testWidgets('Edge Case: signing out from a screen pushed over the map '
        'opens Login with nothing under it', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);

      // 2. Act
      await app.signOut();
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(app.router.canPop(), isFalse);
    });

    testWidgets('Sad Path: a signed-out person asking for a shell screen '
        'stays on Login', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pump(tester, app);

      // 2. Act
      app.router.go(Routes.groups);
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(find.byType(GroupsScreen), findsNothing);
    });
  });

  group('buildAppRouter unknown paths - Widget Test Suite', () {
    testWidgets('Sad Path: an unknown path while bound opens the map', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);

      // 2. Act
      app.router.go('/nao-existe');
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.monamie);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Edge Case: an unknown admin path while bound (allowed by the '
        'redirect, matched by no route) opens the map', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);

      // 2. Act
      app.router.go('/admin/nao-existe');
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.monamie);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Sad Path: an unknown path while signed out opens Login', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();
      await _pump(tester, app);

      // 2. Act
      app.router.go('/nao-existe');
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('buildAppRouter screens over the map - Widget Test Suite', () {
    const pushed = {
      'Grupos': Routes.groups,
      'Administradores': Routes.administrators,
      'Aparência': Routes.appearance,
      'Ajustes de acompanhamento': Routes.trackingSettings,
      'Minha conta': Routes.myAccount,
    };

    for (final MapEntry(key: name, value: path) in pushed.entries) {
      testWidgets('Happy Path: $name pushed over the map shows a back button', (
        tester,
      ) async {
        // 1. Arrange
        final app = _App();
        await _pumpBound(tester, app);

        // 2. Act
        app.router.push(path);
        await _settle(tester);

        // 3. Assert
        expect(app.location, path);
        expect(find.byType(BackButton), findsOneWidget);
      });

      testWidgets('Happy Path: going back from $name returns to the map', (
        tester,
      ) async {
        // 1. Arrange
        final app = _App();
        await _pumpBound(tester, app);
        app.router.push(path);
        await _settle(tester);

        // 2. Act
        await tester.tap(find.byType(BackButton));
        await _settle(tester);

        // 3. Assert
        expect(app.location, Routes.monamie);
        expect(find.byType(HomeScreen), findsOneWidget);
      });
    }
  });

  group('buildAppRouter group sub-routes - Widget Test Suite', () {
    const subRoutes = {
      'Novo grupo': Routes.newGroup,
      'Convidar pessoas': Routes.invite,
      'a group': '/admin/groups/Xk3pQ9vL2mN7',
    };

    for (final MapEntry(key: name, value: path) in subRoutes.entries) {
      testWidgets('Sad Path: $name typed without the Grupos controller falls '
          'back to Grupos', (tester) async {
        // 1. Arrange
        final app = _App();
        await _pumpBound(tester, app);

        // 2. Act
        app.router.go(path);
        await _settle(tester);

        // 3. Assert
        expect(app.location, Routes.groups);
        expect(find.byType(GroupsScreen), findsOneWidget);
      });
    }

    testWidgets('Happy Path: Novo grupo pushed with the Grupos controller '
        'opens on that same controller', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);
      final groups = tester.widget<GroupsScreen>(find.byType(GroupsScreen));

      // 2. Act
      app.router.push(Routes.newGroup, extra: groups.controller);
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.newGroup);
      final created = tester.widget<CreateGroupScreen>(
        find.byType(CreateGroupScreen),
      );
      expect(created.controller, same(groups.controller));
    });

    testWidgets('Edge Case: a group pushed with the Grupos controller gets '
        'its id from the path', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);
      final groups = tester.widget<GroupsScreen>(find.byType(GroupsScreen));

      // 2. Act
      app.router.push(Routes.group('Xk3pQ9vL2mN7'), extra: groups.controller);
      await _settle(tester);

      // 3. Assert
      final group = tester.widget<GroupScreen>(find.byType(GroupScreen));
      expect(group.groupId, 'Xk3pQ9vL2mN7');
      expect(group.controller, same(groups.controller));
    });
  });

  group('buildAppRouter route-owned controllers - Widget Test Suite', () {
    testWidgets('Happy Path: closing Grupos disposes its controller', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);
      final GroupsViewModel controller = tester
          .widget<GroupsScreen>(find.byType(GroupsScreen))
          .controller;

      // 2. Act
      app.router.pop();
      await _settle(tester);

      // 3. Assert
      expect(_isDisposed(controller), isTrue);
    });

    testWidgets('Edge Case: a screen pushed over Grupos keeps its controller '
        'alive', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);
      final GroupsViewModel controller = tester
          .widget<GroupsScreen>(find.byType(GroupsScreen))
          .controller;

      // 2. Act
      app.router.push(Routes.newGroup, extra: controller);
      await _settle(tester);

      // 3. Assert
      expect(_isDisposed(controller), isFalse);
    });

    testWidgets('Sad Path: signing out while on Grupos disposes its '
        'controller', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);
      final GroupsViewModel controller = tester
          .widget<GroupsScreen>(find.byType(GroupsScreen))
          .controller;

      // 2. Act
      await app.signOut();
      await _settle(tester);

      // 3. Assert
      expect(_isDisposed(controller), isTrue);
    });

    testWidgets('Happy Path: closing Criar organização disposes its '
        'controller and returns to Sem organização', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      await app.signOut.afterAccessLost();
      await _settle(tester);
      app.router.go(Routes.createOrganizationOver(Routes.noOrganization));
      await _settle(tester);
      final controller = tester
          .widget<CreateOrganizationScreen>(
            find.byType(CreateOrganizationScreen),
          )
          .controller;

      // 2. Act
      app.router.pop();
      await _settle(tester);

      // 3. Assert
      expect(_isDisposed(controller), isTrue);
      expect(app.location, Routes.noOrganization);
    });
  });
}
