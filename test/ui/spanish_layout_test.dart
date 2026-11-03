import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/model/user_google_model.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/role_names.dart';
import 'package:monamie_app/domain/models/sharing_notification.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/ui/account/widgets/my_account_screen.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';
import 'package:monamie_app/ui/auth/widgets/organization_picker_screen.dart';
import 'package:monamie_app/ui/core/themes/app_theme.dart';
import 'package:monamie_app/ui/groups/view_models/group_invites_view_model.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/ui/history/widgets/history_calendar_sheet.dart';
import 'package:monamie_app/ui/home/view_models/home_session_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_menu.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_button.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

import '../../testing/fakes/repositories/fake_account_deletion_repository.dart';
import '../../testing/fakes/repositories/fake_groups_repository.dart';
import '../../testing/fakes/repositories/fake_invites_repository.dart';
import '../../testing/fakes/repositories/fake_language_repository.dart';
import '../../testing/fakes/repositories/fake_organization_directory.dart';
import '../../testing/fakes/repositories/fake_session_repository.dart';
import '../support/phone_layout.dart';
import '../support/test_app.dart';
import '../support/test_organization.dart';
import 'account/widgets/my_account_screen_test.mocks.dart';
import 'home/widgets/home_doubles.dart';
import 'home/widgets/home_doubles.mocks.dart' show MockCalendarViewModel;
import 'language/widgets/language_harness.dart' show languageRow;

const _rotaSul = OrganizationConfig(id: 'rotasul', name: 'Rota Sul');

/// The app's texts in Spanish and in Portuguese, read from the generated
/// localizations so a reworded text does not break these tests.
final _es = lookupAppLocalizations(const Locale('es'));
final _pt = lookupAppLocalizations(const Locale('pt'));

/// Spanish as a device with Spanish as its language shows it.
const _spanish = Locale('es', 'ES');

Invite _invite({String? groupName = 'Rota Norte'}) => Invite(
  id: 'inv-1',
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groupId: 'norte',
  groupName: groupName,
  email: 'ana@example.com',
  roles: const {GroupRole.publisher, GroupRole.subscriber},
  inviterName: 'Carolina Fernández',
  expiresAt: DateTime.now().add(const Duration(days: 14)),
);

/// The Spanish app (see [TestApp.pump]) on a phone, the larger text.
Future<void> _pumpSpanish(WidgetTester tester, TestApp app) => app.pump(
  tester,
  locale: _spanish,
  theme: AppTheme.lightTheme,
  textScale: largerTextScale,
  physicalSize: phonePhysicalSize,
  devicePixelRatio: phoneDevicePixelRatio,
);

void main() {
  // Signed out, no organization is bound; the other test files expect the
  // test organization, so it is put back after each test.
  setUp(Organization.unbind);
  tearDown(() => Organization.bind(testOrganization));

  setUpAll(loadAppFonts);

  group('Spanish texts in the app - Widget Test Suite', () {
    testWidgets('Happy Path: a Spanish device opens Login in Spanish', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);

      // 2. Act
      await app.pump(tester, locale: _spanish);

      // 3. Assert
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(_es.loginTagline), findsOneWidget);
      expect(find.text(_es.loginWithGoogle), findsOneWidget);
      expect(find.text(_pt.loginWithGoogle), findsNothing);
      expect(_es.loginWithGoogle, isNot(_pt.loginWithGoogle));
      expect(find.text('ES'), findsOneWidget);
    });

    testWidgets('Happy Path: the language sheet marks Español when it is the '
        'choice', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.language.stored = AppLanguage.es;
      await app.pump(tester);

      // 2. Act
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsOneWidget);
      expect(find.text(_es.languageTitle), findsOneWidget);
      expect(
        find.descendant(
          of: languageRow('Español'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Português'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('Happy Path: the sheet lists the three languages, each in '
        'itself, marking Español on a Spanish device', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester, locale: _spanish);

      // 2. Act
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();

      // 3. Assert
      for (final language in AppLanguage.values) {
        expect(find.text(language.name.toUpperCase()), findsWidgets);
      }
      expect(find.text('Português'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(
        find.descendant(
          of: languageRow('Español'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Happy Path: choosing Español on Login redraws it in Spanish '
        'at once and stores the choice', (tester) async {
      // 1. Arrange: a Portuguese device.
      final app = TestApp(googleReady: true);
      await app.pump(tester);
      expect(find.text(_pt.loginWithGoogle), findsOneWidget);

      // 2. Act
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      await tester.tap(languageRow('Español'));
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.byType(LanguageSheet), findsNothing);
      expect(find.text(_es.loginWithGoogle), findsOneWidget);
      expect(find.text(_es.loginTagline), findsOneWidget);
      expect(find.text(_pt.loginWithGoogle), findsNothing);
      expect(find.text('ES'), findsOneWidget);
      expect(app.language.stored, AppLanguage.es);
      expect(app.location, Routes.login);
    });

    testWidgets('Happy Path: the language chosen on Login is the one of Sem '
        'organización', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await app.pump(tester);
      await tester.tap(find.byType(LanguageButton));
      await tester.pumpAndSettle();
      await tester.tap(languageRow('Español'));
      await tester.pumpAndSettle();

      // 2. Act
      await tester.tap(find.text(_es.loginWithGoogle));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.noOrganization);
      expect(find.byType(NoOrganizationScreen), findsOneWidget);
      expect(find.text(_es.noOrganizationTitle), findsOneWidget);
      expect(find.text(_es.noOrganizationCreate), findsOneWidget);
      expect(find.text(_pt.noOrganizationTitle), findsNothing);
    });

    testWidgets('Happy Path: the picker counts the organizations in Spanish', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.language.stored = AppLanguage.es;
      app.directory.organizations.add(fakeCandidate('rotasul'));
      app.directory.organizations.add(fakeCandidate('norte'));
      app.brandingLoader.brandings['rotasul'] = _rotaSul;
      app.brandingLoader.brandings['norte'] = const OrganizationConfig(
        id: 'norte',
        name: 'Rota Norte',
      );
      await app.pump(tester);

      // 2. Act
      await tester.tap(find.text(_es.loginWithGoogle));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.organizationPicker);
      expect(find.byType(OrganizationPickerScreen), findsOneWidget);
      expect(find.text(_es.pickerTitle), findsOneWidget);
      expect(find.text(_es.pickerCount(2)), findsOneWidget);
      expect(find.text(_es.pickerCreate), findsOneWidget);
    });

    testWidgets('Happy Path: the map menu is in Spanish', (tester) async {
      // 1. Arrange
      Organization.bind(testOrganization);
      final app = TestApp();
      app.language.stored = AppLanguage.es;
      await app.pump(tester);
      app.session.moveTo(const SessionState.bound());
      await TestApp.settle(tester);

      // 2. Act
      await tester.tap(find.byIcon(Icons.menu));
      await TestApp.settle(tester);

      // 3. Assert
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(_es.commonSignOut), findsOneWidget);
      expect(find.text(_es.menuSwitchOrganization), findsOneWidget);
      expect(find.text(_es.languageTitle), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text(_pt.commonSignOut), findsNothing);
    });
  });

  group('Spanish messages with plurals and selects - Unit Test Suite', () {
    test('Happy Path: pickerCount names zero, one and several', () {
      // 1. Arrange / 2. Act
      final texts = [
        for (final n in [0, 1, 2, 7]) _es.pickerCount(n),
      ];

      // 3. Assert
      expect(texts, [
        'Participas en 0. Puedes cambiar después desde el menú.',
        'Participas en 1 organización.',
        'Participas en 2. Puedes cambiar después desde el menú.',
        'Participas en 7. Puedes cambiar después desde el menú.',
      ]);
    });

    test('Happy Path: the deletion title counts the days left', () {
      // 1. Arrange / 2. Act
      final texts = [
        for (final days in [0, 1, 30]) _es.deletionPendingAccountTitle(days),
      ];
      final organization = [
        for (final days in [0, 1, 30])
          _es.deletionPendingOrganizationTitle('Rota Sul', days),
      ];

      // 3. Assert
      expect(texts, [
        'Tu cuenta se eliminará hoy',
        'Tu cuenta se eliminará en 1 día',
        'Tu cuenta se eliminará en 30 días',
      ]);
      expect(organization, [
        'Rota Sul se eliminará hoy',
        'Rota Sul se eliminará en 1 día',
        'Rota Sul se eliminará en 30 días',
      ]);
    });

    test('Edge Case: zero, one and several read each in its own wording', () {
      // 1. Arrange / 2. Act
      final people = [
        for (final n in [0, 1, 3]) _es.peopleCount(n),
      ];
      final members = [
        for (final n in [0, 1, 3]) _es.memberCount(n),
      ];
      final pending = [
        for (final n in [0, 1, 3]) _es.pendingInvites(n),
      ];
      final lost = [
        for (final n in [0, 1, 3]) _es.groupDeletedLost(n, 'Rota'),
      ];

      // 3. Assert
      expect(people, ['Nadie aún', '1 persona', '3 personas']);
      expect(members, ['0 personas', '1 persona', '3 personas']);
      expect(pending, [
        '0 invitaciones pendientes',
        '1 invitación pendiente',
        '3 invitaciones pendientes',
      ]);
      expect(lost, [
        '0 personas perdieron el acceso a Rota.',
        '1 persona perdió el acceso a Rota.',
        '3 personas perdieron el acceso a Rota.',
      ]);
    });

    test('Happy Path: inviteCardBody picks the role wording', () {
      // 1. Arrange / 2. Act
      final both = _es.inviteCardBody('Carolina', 'Rota Norte', 'both');
      final publisher = _es.inviteCardBody(
        'Carolina',
        'Rota Norte',
        'publisher',
      );
      final subscriber = _es.inviteCardBody(
        'Carolina',
        'Rota Norte',
        'subscriber',
      );

      // 3. Assert
      expect(
        both,
        'Carolina te invitó al grupo Rota Norte, en campo y viendo el mapa.',
      );
      expect(publisher, 'Carolina te invitó al grupo Rota Norte, en campo.');
      expect(
        subscriber,
        'Carolina te invitó al grupo Rota Norte, viendo el mapa.',
      );
    });
  });

  group('Test fonts - Widget Test Suite', () {
    testWidgets('Edge Case: texts are drawn with Manrope, not the square '
        'glyphs of Ahem', (tester) async {
      // 1. Arrange
      const text = 'Iniciar sesión con Google';
      await pumpOnPhone(tester, const Scaffold(body: Text(text)));

      // 2. Act
      final width = tester.getSize(find.text(text)).width;

      // 3. Assert: Ahem would make every glyph as wide as the font size
      // (16 x 1.3 here, 25 glyphs: 520 pixels).
      expect(width, lessThan(260));
    });
  });

  group('Spanish at a larger text size - Widget Test Suite', () {
    // The real font and a phone's screen: see test/support/phone_layout.dart.
    testWidgets('Happy Path: Login does not overflow', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);

      // 2. Act
      await _pumpSpanish(tester, app);

      // 3. Assert
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(_es.loginWithGoogle), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('Happy Path: Sem organização does not overflow', (
      tester,
    ) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      await _pumpSpanish(tester, app);

      // 2. Act
      await tester.tap(find.text(_es.loginWithGoogle));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.noOrganization);
      expect(find.text(_es.noOrganizationTitle), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('Happy Path: Escolher organização does not overflow, '
        'invites included', (tester) async {
      // 1. Arrange
      final app = TestApp(googleReady: true);
      app.directory.organizations.addAll([
        fakeCandidate('rotasul'),
        fakeCandidate('norte'),
      ]);
      app.brandingLoader.brandings['rotasul'] = _rotaSul;
      app.brandingLoader.brandings['norte'] = const OrganizationConfig(
        id: 'norte',
        name: 'Rota Norte',
      );
      app.invites.mineInvites.add(_invite());
      await _pumpSpanish(tester, app);

      // 2. Act
      await tester.tap(find.text(_es.loginWithGoogle));
      await TestApp.settle(tester);

      // 3. Assert
      expect(app.location, Routes.organizationPicker);
      expect(find.text(_es.pickerTitle), findsOneWidget);
      expect(
        find.textContaining('Carolina Fernández te invitó'),
        findsOneWidget,
      );
      expectNoLayoutError(tester);
    });

    for (final (label, deletion, button) in [
      (
        'an account',
        AccountDeletion(deleteAt: DateTime.now().add(const Duration(days: 30))),
        _es.deletionCancelAccount,
      ),
      (
        'an organization with its owner\'s account',
        AccountDeletion(
          deleteAt: DateTime.now().add(const Duration(days: 30)),
          ownedOrganizationIds: const ['rotasul'],
          ownedOrganizationNames: const {'rotasul': 'Rota Sul'},
        ),
        _es.deletionCancel,
      ),
    ]) {
      testWidgets('Happy Path: Em exclusão of $label does not overflow', (
        tester,
      ) async {
        // 1. Arrange
        final app = TestApp(googleReady: true);
        await _pumpSpanish(tester, app);

        // 2. Act
        app.session.moveTo(SessionState.deletionPending(deletion));
        await TestApp.settle(tester);

        // 3. Assert
        expect(app.location, Routes.deletionPending);
        expect(find.text(button), findsOneWidget);
        expectNoLayoutError(tester);
      });
    }

    // flutter_map's attribution is drawn with a family-less style (Ahem in
    // the test) and overflows by under a pixel at this text size, in every
    // language: Portuguese is the baseline.
    testWidgets('Happy Path: the map and its menu do not overflow more than '
        'in Portuguese', (tester) async {
      // 1. Arrange / 2. Act
      await expectSpanishNoWorseThanPortuguese(tester, (locale) async {
        Organization.bind(testOrganization);
        final app = TestApp();
        await app.pump(
          tester,
          locale: locale,
          theme: AppTheme.lightTheme,
          textScale: largerTextScale,
          physicalSize: phonePhysicalSize,
          devicePixelRatio: phoneDevicePixelRatio,
        );
        app.session.moveTo(const SessionState.bound());
        await TestApp.settle(tester);
        await tester.tap(find.byIcon(Icons.menu));
        await TestApp.settle(tester);
      });

      // 3. Assert
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(_es.menuSwitchOrganization), findsOneWidget);
    });

    testWidgets('Happy Path: the menu of an administrator who owns the '
        'organization does not overflow', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpMenu(
        tester,
        const Capabilities(isMember: true, isAdmin: true),
        directory: FakeOrganizationDirectory(
          organizations: [fakeCandidate('acme', owner: true)],
        ),
      );

      // 3. Assert: every administrator entry is there.
      expect(find.text(_es.menuAdministration), findsOneWidget);
      expect(find.text(_es.groupsTitle), findsOneWidget);
      expect(find.text(_es.administratorsTitle), findsOneWidget);
      expect(find.text(_es.menuAppearance), findsOneWidget);
      expect(find.text(_es.menuTrackingSettings), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('Happy Path: the menu of a group maintainer does not '
        'overflow', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpMenu(
        tester,
        const Capabilities(
          isMember: true,
          rolesByGroup: {
            'norte': {GroupRoles.maintainer},
          },
        ),
      );

      // 3. Assert
      expect(find.text(_es.menuGroupManagement), findsOneWidget);
      expect(find.text(_es.menuMyGroups), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('Happy Path: Grupos does not overflow', (tester) async {
      // 1. Arrange
      final repository = FakeGroupsRepository(groups: {'rotasul': _groups});
      final controller = GroupsViewModel(
        organizationId: 'rotasul',
        repository: repository,
        isAdmin: true,
      );
      addTearDown(controller.dispose);

      // 2. Act
      await pumpOnPhone(tester, GroupsScreen(controller: controller));
      await tester.pump();

      // 3. Assert
      expect(find.text(_es.groupsTitle), findsWidgets);
      expect(find.text('Rota Norte'), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('Edge Case: Grupos with no group does not overflow', (
      tester,
    ) async {
      // 1. Arrange
      final controller = GroupsViewModel(
        organizationId: 'rotasul',
        repository: FakeGroupsRepository(),
        isAdmin: true,
      );
      addTearDown(controller.dispose);

      // 2. Act
      await pumpOnPhone(tester, GroupsScreen(controller: controller));
      await tester.pump();

      // 3. Assert
      expect(find.byType(GroupsScreen), findsOneWidget);
      expectNoLayoutError(tester);
    });

    // The buttons' labels use a family-less style (Ahem in the test): see
    // expectSpanishNoWorseThanPortuguese.
    for (final (label, tab) in [
      ('its people tab', _GroupTab.people),
      ('its invites tab', _GroupTab.invites),
    ]) {
      testWidgets('Happy Path: Grupo, $label, does not overflow more than in '
          'Portuguese', (tester) async {
        // 1. Arrange
        final groups = FakeGroupsRepository(groups: {'rotasul': _groups});
        final invites = FakeInvitesRepository(
          sent: {
            'rotasul': [
              _invite(),
              _invite().copyWith(
                id: 'inv-2',
                email: 'una.direccion.muy.larga@example.com',
                expired: true,
                roles: const {GroupRole.subscriber},
              ),
            ],
          },
        );

        // 2. Act
        await expectSpanishNoWorseThanPortuguese(tester, (locale) async {
          final controller = GroupsViewModel(
            organizationId: 'rotasul',
            repository: groups,
            isAdmin: true,
          );
          final groupInvites = GroupInvitesViewModel(
            organizationId: 'rotasul',
            groupId: 'norte',
            repository: invites,
          );
          addTearDown(controller.dispose);
          addTearDown(groupInvites.dispose);
          await controller.load.execute();
          await pumpOnPhone(
            tester,
            GroupScreen(
              controller: controller,
              groupId: 'norte',
              invites: groupInvites,
            ),
            locale: locale,
          );
          await tester.pump();
          if (tab == _GroupTab.invites) {
            await tester.tap(
              find.text(lookupAppLocalizations(locale).groupTabInvited('2')),
            );
            await tester.pump();
          }
        });

        // 3. Assert
        expect(find.text('Rota Norte'), findsWidgets);
        expect(find.text(_es.groupInvite), findsOneWidget);
      });
    }

    testWidgets('Happy Path: Minha conta of a member does not overflow', (
      tester,
    ) async {
      // 1. Arrange
      final controller = MyAccountViewModel(
        repository: FakeAccountDeletionRepository(),
        organizationId: 'rotasul',
        directory: FakeOrganizationDirectory(
          organizations: [fakeCandidate('rotasul')],
        ),
        signOut: MockSignOut(),
      );
      addTearDown(controller.dispose);

      // 2. Act
      await pumpOnPhone(
        tester,
        MyAccountScreen(
          controller: controller,
          email: 'carolina.fernandez@example.com',
          organizationName: 'Rota Sul',
        ),
      );
      await tester.pump();

      // 3. Assert
      expect(find.text(_es.myAccountDelete), findsWidgets);
      expect(find.text(_es.myAccountMemberLeaves('Rota Sul')), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('Happy Path: Minha conta of the owner does not overflow', (
      tester,
    ) async {
      // 1. Arrange
      final controller = MyAccountViewModel(
        repository: FakeAccountDeletionRepository(),
        organizationId: 'rotasul',
        directory: FakeOrganizationDirectory(
          organizations: [fakeCandidate('rotasul', owner: true)],
        ),
        signOut: MockSignOut(),
      );
      addTearDown(controller.dispose);

      // 2. Act
      await pumpOnPhone(
        tester,
        MyAccountScreen(
          controller: controller,
          email: 'carolina.fernandez@example.com',
          organizationName: 'Rota Sul',
        ),
      );
      await tester.pump();

      // 3. Assert
      expect(find.text(_es.myAccountDeleteWithOrganization), findsOneWidget);
      expect(find.text(_es.myAccountConfirmPrompt('rotasul')), findsOneWidget);
      expectNoLayoutError(tester);
    });

    for (final scheme in LanguageScheme.values) {
      testWidgets('Happy Path: the language sheet (${scheme.name} scheme) '
          'does not overflow', (tester) async {
        // 1. Arrange
        final language = LanguageViewModel(
          repository: FakeLanguageRepository(),
          deviceLocales: () => const [_spanish],
        );
        addTearDown(language.dispose);
        await pumpOnPhone(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showLanguageSheet(
                  context,
                  controller: language,
                  scheme: scheme,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        );

        // 2. Act
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();

        // 3. Assert
        expect(find.byType(LanguageSheet), findsOneWidget);
        expect(find.text('Español'), findsOneWidget);
        expectNoLayoutError(tester);
      });
    }

    testWidgets('Happy Path: the history calendar sheet does not overflow', (
      tester,
    ) async {
      // 1. Arrange
      final today = DateTime(2026, 11, 2);
      final calendar = MockCalendarViewModel();
      when(calendar.viewMonth).thenReturn(
        ValueNotifier(HistoryMonth(year: 2026, month: 11, today: today)),
      );
      when(calendar.observedDay).thenReturn(ValueNotifier(today));
      when(calendar.isLoadingMonth).thenReturn(ValueNotifier(false));

      // 2. Act
      await pumpOnPhone(
        tester,
        Scaffold(body: HistoryCalendarSheet(controller: calendar)),
      );
      await tester.pump();

      // 3. Assert
      expect(find.text('Noviembre de 2026'), findsOneWidget);
      expect(find.text(_es.calendarDaysWithTrails), findsOneWidget);
      expectNoLayoutError(tester);
    });
  });
}

/// The map's menu for a person with [capabilities], opened on a phone in
/// Spanish at the larger text size.
Future<void> _pumpMenu(
  WidgetTester tester,
  Capabilities capabilities, {
  FakeOrganizationDirectory? directory,
}) async {
  final doubles = HomeDoubles();
  doubles.capabilities.value = capabilities;
  when(doubles.tracking.toggleService).thenReturn(
    Command1<UserNotice?, SharingNotification>((_) async => const Ok(null)),
  );
  when(doubles.user.googleUser).thenReturn(
    UserGoogleModel(
      id: 'u',
      name: 'Carolina Fernández de la Torre',
      email: 'carolina.fernandez@example.com',
    ),
  );
  final session = HomeSessionViewModel(
    session: FakeSessionRepository(),
    signOut: MockSignOut(),
    directory: directory ?? FakeOrganizationDirectory(),
  );
  final language = LanguageViewModel(
    repository: FakeLanguageRepository(),
    deviceLocales: () => const [_spanish],
  );
  addTearDown(session.dispose);
  addTearDown(language.dispose);
  Organization.bind(testOrganization);
  final scaffold = GlobalKey<ScaffoldState>();
  await pumpOnPhone(
    tester,
    Scaffold(
      key: scaffold,
      drawer: HomeMenu(
        home: doubles.home,
        user: doubles.user,
        session: session,
        tracking: doubles.tracking,
        language: language,
      ),
    ),
  );
  scaffold.currentState!.openDrawer();
  await tester.pumpAndSettle();
}

enum _GroupTab { people, invites }

final _groups = [
  Group(
    id: 'norte',
    name: 'Rota Norte',
    people: const [
      GroupPerson(
        email: 'carolina.fernandez@example.com',
        roles: {GroupRole.publisher, GroupRole.subscriber},
      ),
      GroupPerson(
        email: 'luis@example.com',
        roles: {GroupRole.publisher, GroupRole.maintainer},
      ),
      GroupPerson(email: 'marta@example.com', roles: {GroupRole.subscriber}),
    ],
  ),
  const Group(id: 'sur', name: 'Rota Sur', people: []),
];
