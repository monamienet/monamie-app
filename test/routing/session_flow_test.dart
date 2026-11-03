import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/account/widgets/deletion_pending_screen.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';
import 'package:monamie_app/ui/auth/widgets/organization_picker_screen.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/ui/invites/widgets/welcome_screen.dart';

import '../../testing/fakes/repositories/fake_organization_directory.dart';
import '../support/test_app.dart';
import '../support/test_organization.dart';

const _rotaSul = OrganizationConfig(id: 'rotasul', name: 'Rota Sul');
const _acme = OrganizationConfig(id: 'acme', name: 'Acme');

final _invite = Invite(
  id: 'i1',
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groupId: 'g1',
  groupName: 'Guias',
  email: 'ana@example.com',
  roles: const {GroupRole.publisher},
  inviterName: 'Olga',
  expiresAt: null,
);

/// The app's real router, screens and use cases over [TestApp]'s
/// in-memory repositories, driven as a person would: Google's chooser,
/// the screens' buttons and the map's menu. The session moves only
/// through what those taps run.
void main() {
  // Signed out, no organization is bound; the other test files expect the
  // test organization, so it is put back after each test.
  setUp(Organization.unbind);
  tearDown(() => Organization.bind(testOrganization));

  group('Session flow over the real router - Widget Test Suite', () {
    testWidgets('Happy Path: signing in with no organization, then two, '
        'choosing one opens its map, and Sair returns to Login', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester);
      expect(app.location, Routes.login);
      expect(find.byType(LoginScreen), findsOneWidget);

      // 2. Act: Google's chooser returns an account in no organization.
      await tester.tap(find.text('Entrar com o Google'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.noOrganization);
      expect(find.byType(NoOrganizationScreen), findsOneWidget);
      expect(app.session.signedInEmail, 'ana@example.com');

      // 2. Act: the person is added to two organizations and checks again.
      app.directory.organizations.addAll([
        fakeCandidate('rotasul'),
        fakeCandidate('acme'),
      ]);
      app.brandingLoader.brandings.addAll({'rotasul': _rotaSul, 'acme': _acme});
      await tester.tap(find.text('Já me convidaram · verificar de novo'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.organizationPicker);
      expect(find.byType(OrganizationPickerScreen), findsOneWidget);
      expect(find.text('Rota Sul'), findsOneWidget);
      expect(find.text('Acme'), findsOneWidget);

      // 2. Act: Rota Sul is chosen.
      await tester.tap(find.text('Rota Sul'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.monamie);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(Organization.current?.id, 'rotasul');
      expect(app.organizationSession.store.stored?.organization.id, 'rotasul');
      expect(app.session.signedInToOrganization, isTrue);
      expect(app.userRepository.user?.email, 'ana@example.com');

      // 2. Act: "Sair" in the map's menu.
      await tester.tap(find.byIcon(Icons.menu));
      await TestApp.settle(tester);
      await tester.tap(find.text('Sair'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
      expect(Organization.current, isNull);
      expect(app.organizationSession.store.stored, isNull);
      expect(app.userRepository.user, isNull);
      expect(app.localData.callCount('clear'), 1);
      expect(app.session.idToken, isNull);
      verify(app.stopper.stop(email: 'ana@example.com')).called(1);
    });

    testWidgets('Edge Case: a single organization still shows the picker', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.directory.organizations.add(fakeCandidate('rotasul'));
      app.brandingLoader.brandings['rotasul'] = _rotaSul;
      await app.pump(tester);

      // 2. Act
      await tester.tap(find.text('Entrar com o Google'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.organizationPicker);
      expect(find.text('Rota Sul'), findsOneWidget);
    });

    testWidgets('Edge Case: an account scheduled for deletion opens Em '
        'exclusão instead of its organizations', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.directory.organizations.add(fakeCandidate('rotasul'));
      app.deletion.pendingDeletion = AccountDeletion(
        deleteAt: DateTime.now().add(const Duration(days: 30)),
      );
      await app.pump(tester);

      // 2. Act
      await tester.tap(find.text('Entrar com o Google'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.deletionPending);
      expect(find.byType(DeletionPendingScreen), findsOneWidget);
    });

    testWidgets('Sad Path: closing Google\'s chooser stays on Login', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.session.googleAccountToken = null;
      await app.pump(tester);

      // 2. Act
      await tester.tap(find.text('Entrar com o Google'));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(app.directory.callCount('organizationsOfSignedInUser'), 0);
    });

    testWidgets('Happy Path: an accepted invite shows Boas-vindas before the '
        'map', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester);

      // 2. Act
      app.session.moveTo(SessionState.welcome(_invite));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.welcome);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('Session flow typed paths - Widget Test Suite', () {
    final screens = <String, (SessionState, String)>{
      'Login': (const SessionState.signedOut(), Routes.login),
      'Sem organização': (
        const SessionState.noOrganization(),
        Routes.noOrganization,
      ),
      'the picker': (const SessionState.picking([]), Routes.organizationPicker),
      'Em exclusão': (
        SessionState.deletionPending(AccountDeletion(deleteAt: DateTime(2026))),
        Routes.deletionPending,
      ),
      'Boas-vindas': (SessionState.welcome(_invite), Routes.welcome),
      'the map': (const SessionState.bound(), Routes.monamie),
    };

    for (final MapEntry(key: name, value: (state, path)) in screens.entries) {
      testWidgets('Sad Path: an unknown path typed on $name stays on $name', (
        tester,
      ) async {
        // 1. Arrange
        if (state is SessionBound) Organization.bind(testOrganization);
        final app = TestApp();
        await app.pump(tester);
        app.session.moveTo(state);
        await TestApp.settle(tester);

        // 2. Act
        app.router.go('/nao-existe');
        await TestApp.settle(tester);

        // 3. Assert
        expect(app.location, path);
      });
    }
  });
}
