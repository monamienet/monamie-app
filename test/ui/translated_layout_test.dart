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
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/domain/models/role_names.dart';
import 'package:monamie_app/domain/models/sharing_notification.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/ui/account/view_models/my_account_view_model.dart';
import 'package:monamie_app/ui/account/widgets/my_account_screen.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';
import 'package:monamie_app/ui/auth/widgets/organization_picker_screen.dart';
import 'package:monamie_app/ui/creation/view_models/create_organization_view_model.dart';
import 'package:monamie_app/ui/creation/widgets/create_organization_screen.dart';
import 'package:monamie_app/ui/core/themes/app_theme.dart';
import 'package:monamie_app/ui/core/ui/domain_labels.dart';
import 'package:monamie_app/ui/groups/view_models/group_invites_view_model.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/ui/history/widgets/history_calendar_sheet.dart';
import 'package:monamie_app/ui/home/view_models/home_session_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_menu.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/ui/invites/widgets/welcome_screen.dart';
import 'package:monamie_app/ui/language/view_models/language_view_model.dart';
import 'package:monamie_app/ui/language/widgets/language_button.dart';
import 'package:monamie_app/ui/language/widgets/language_scheme.dart';
import 'package:monamie_app/ui/language/widgets/language_sheet.dart';
import 'package:monamie_app/ui/tracking_settings/view_models/tracking_settings_edit_view_model.dart';
import 'package:monamie_app/ui/tracking_settings/widgets/tracking_settings_screen.dart';
import 'package:monamie_app/utils/command.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

import '../../testing/fakes/repositories/fake_account_deletion_repository.dart';
import '../../testing/fakes/repositories/fake_creation_repository.dart';
import '../../testing/fakes/repositories/fake_groups_repository.dart';
import '../../testing/fakes/repositories/fake_invites_repository.dart';
import '../../testing/fakes/repositories/fake_language_repository.dart';
import '../../testing/fakes/repositories/fake_organization_directory.dart';
import '../../testing/fakes/repositories/fake_session_repository.dart';
import '../../testing/fakes/repositories/fake_theme_repository.dart';
import '../../testing/fakes/repositories/fake_tracking_settings_repository.dart';
import '../support/phone_layout.dart';
import '../support/test_app.dart';
import '../support/test_organization.dart';
import 'account/widgets/my_account_screen_test.mocks.dart';
import 'creation/widgets/create_organization_screen_test.mocks.dart'
    show MockEnterOrganization;
import 'home/widgets/home_doubles.dart';
import 'home/widgets/home_doubles.mocks.dart' show MockCalendarViewModel;
import 'language/widgets/language_harness.dart' show languageRow;

const _rotaSul = OrganizationConfig(id: 'rotasul', name: 'Rota Sul');

/// The app's texts in Portuguese, read from the generated localizations so a
/// reworded text does not break these tests.
final _pt = lookupAppLocalizations(const Locale('pt'));

/// A language the app has besides Portuguese, as these tests check it: the
/// layout on a phone at a larger text size and the texts a device in that
/// language shows.
class _Translation {
  const _Translation({
    required this.name,
    required this.language,
    required this.device,
    required this.code,
    required this.endonym,
    required this.calendarTitle,
  });

  /// The language's name in English, for the test names.
  final String name;

  final AppLanguage language;

  /// The locale of a device with this language, with a country as devices
  /// have it.
  final Locale device;

  /// The code on the language button.
  final String code;

  /// The language's name in itself, as the language sheet lists it.
  final String endonym;

  /// What the history calendar sheet calls November 2026.
  final String calendarTitle;

  /// The app's texts in this language.
  AppLocalizations get texts => lookupAppLocalizations(language.locale);
}

const _spanish = _Translation(
  name: 'Spanish',
  language: AppLanguage.es,
  device: Locale('es', 'ES'),
  code: 'ES',
  endonym: 'Español',
  calendarTitle: 'Noviembre de 2026',
);

const _french = _Translation(
  name: 'French',
  language: AppLanguage.fr,
  device: Locale('fr', 'FR'),
  code: 'FR',
  endonym: 'Français',
  calendarTitle: 'Novembre 2026',
);

/// Every translation the layout is checked in.
const _translations = [_spanish, _french];

/// The Spanish texts, for the exact wording the unit tests below check.
final _es = _spanish.texts;

/// The French texts, for the same.
final _fr = _french.texts;

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

/// The app in [translation]'s language (see [TestApp.pump]) on a phone, the
/// larger text.
Future<void> _pumpTranslated(
  WidgetTester tester,
  TestApp app,
  _Translation translation,
) => app.pump(
  tester,
  locale: translation.device,
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

  for (final t in _translations) {
    group('${t.name} texts in the app - Widget Test Suite', () {
      final texts = t.texts;
      testWidgets('Happy Path: a ${t.name} device opens Login in ${t.name}', (
        tester,
      ) async {
        // 1. Arrange
        final app = TestApp(googleReady: true);

        // 2. Act
        await app.pump(tester, locale: t.device);

        // 3. Assert
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text(texts.loginTagline), findsOneWidget);
        expect(find.text(texts.loginWithGoogle), findsOneWidget);
        expect(find.text(_pt.loginWithGoogle), findsNothing);
        expect(texts.loginWithGoogle, isNot(_pt.loginWithGoogle));
        expect(find.text(t.code), findsOneWidget);
      });

      testWidgets(
        'Happy Path: the language sheet marks ${t.endonym} when it is '
        'the choice',
        (tester) async {
          // 1. Arrange
          final app = TestApp(googleReady: true);
          app.language.stored = t.language;
          await app.pump(tester);

          // 2. Act
          await tester.tap(find.byType(LanguageButton));
          await tester.pumpAndSettle();

          // 3. Assert
          expect(find.byType(LanguageSheet), findsOneWidget);
          expect(find.text(texts.languageTitle), findsOneWidget);
          expect(
            find.descendant(
              of: languageRow(t.endonym),
              matching: find.byIcon(Icons.check),
            ),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.check), findsOneWidget);
          expect(find.text('Português'), findsOneWidget);
          expect(find.text('English'), findsOneWidget);
        },
      );

      testWidgets('Happy Path: the sheet lists the four languages, each in '
          'itself, marking ${t.endonym} on a ${t.name} device', (tester) async {
        // 1. Arrange
        final app = TestApp(googleReady: true);
        await app.pump(tester, locale: t.device);

        // 2. Act
        await tester.tap(find.byType(LanguageButton));
        await tester.pumpAndSettle();

        // 3. Assert
        for (final language in AppLanguage.values) {
          expect(find.text(language.name.toUpperCase()), findsWidgets);
        }
        expect(find.text('Português'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text(t.endonym), findsOneWidget);
        expect(
          find.descendant(
            of: languageRow(t.endonym),
            matching: find.byIcon(Icons.check),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Happy Path: choosing ${t.endonym} on Login redraws it in '
          '${t.name} at once and stores the choice', (tester) async {
        // 1. Arrange: a Portuguese device.
        final app = TestApp(googleReady: true);
        await app.pump(tester);
        expect(find.text(_pt.loginWithGoogle), findsOneWidget);

        // 2. Act
        await tester.tap(find.byType(LanguageButton));
        await tester.pumpAndSettle();
        await tester.tap(languageRow(t.endonym));
        await tester.pumpAndSettle();

        // 3. Assert
        expect(find.byType(LanguageSheet), findsNothing);
        expect(find.text(texts.loginWithGoogle), findsOneWidget);
        expect(find.text(texts.loginTagline), findsOneWidget);
        expect(find.text(_pt.loginWithGoogle), findsNothing);
        expect(find.text(t.code), findsOneWidget);
        expect(app.language.stored, t.language);
        expect(app.location, Routes.login);
      });

      testWidgets('Happy Path: the language chosen on Login is the one of Sem '
          'organización', (tester) async {
        // 1. Arrange
        final app = TestApp(googleReady: true);
        await app.pump(tester);
        await tester.tap(find.byType(LanguageButton));
        await tester.pumpAndSettle();
        await tester.tap(languageRow(t.endonym));
        await tester.pumpAndSettle();

        // 2. Act
        await tester.tap(find.text(texts.loginWithGoogle));
        await TestApp.settle(tester);

        // 3. Assert
        expect(app.location, Routes.noOrganization);
        expect(find.byType(NoOrganizationScreen), findsOneWidget);
        expect(find.text(texts.noOrganizationTitle), findsOneWidget);
        expect(find.text(texts.noOrganizationCreate), findsOneWidget);
        expect(find.text(_pt.noOrganizationTitle), findsNothing);
      });

      testWidgets(
        'Happy Path: the picker counts the organizations in ${t.name}',
        (tester) async {
          // 1. Arrange
          final app = TestApp(googleReady: true);
          app.language.stored = t.language;
          app.directory.organizations.add(fakeCandidate('rotasul'));
          app.directory.organizations.add(fakeCandidate('norte'));
          app.brandingLoader.brandings['rotasul'] = _rotaSul;
          app.brandingLoader.brandings['norte'] = const OrganizationConfig(
            id: 'norte',
            name: 'Rota Norte',
          );
          await app.pump(tester);

          // 2. Act
          await tester.tap(find.text(texts.loginWithGoogle));
          await TestApp.settle(tester);

          // 3. Assert
          expect(app.location, Routes.organizationPicker);
          expect(find.byType(OrganizationPickerScreen), findsOneWidget);
          expect(find.text(texts.pickerTitle), findsOneWidget);
          expect(find.text(texts.pickerCount(2)), findsOneWidget);
          expect(find.text(texts.pickerCreate), findsOneWidget);
        },
      );

      testWidgets('Happy Path: the map menu is in ${t.name}', (tester) async {
        // 1. Arrange
        Organization.bind(testOrganization);
        final app = TestApp();
        app.language.stored = t.language;
        await app.pump(tester);
        app.session.moveTo(const SessionState.bound());
        await TestApp.settle(tester);

        // 2. Act
        await tester.tap(find.byIcon(Icons.menu));
        await TestApp.settle(tester);

        // 3. Assert
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text(texts.commonSignOut), findsOneWidget);
        expect(find.text(texts.menuSwitchOrganization), findsOneWidget);
        expect(find.text(texts.languageTitle), findsOneWidget);
        expect(find.text(t.endonym), findsOneWidget);
        expect(find.text(_pt.commonSignOut), findsNothing);
      });
    });
  }

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

  group('French messages with plurals and selects - Unit Test Suite', () {
    test('Happy Path: pickerCount names zero, one and several', () {
      // 1. Arrange / 2. Act
      final texts = [
        for (final n in [0, 1, 2, 7]) _fr.pickerCount(n),
      ];

      // 3. Assert
      expect(texts, [
        'Vous appartenez à 0 organisation. Vous pourrez en changer plus tard '
            'depuis le menu.',
        'Vous appartenez à 1 organisation.',
        'Vous appartenez à 2 organisations. Vous pourrez en changer plus tard '
            'depuis le menu.',
        'Vous appartenez à 7 organisations. Vous pourrez en changer plus tard '
            'depuis le menu.',
      ]);
    });

    test('Happy Path: the deletion title counts the days left', () {
      // 1. Arrange / 2. Act
      final account = [
        for (final days in [0, 1, 30]) _fr.deletionPendingAccountTitle(days),
      ];
      final organization = [
        for (final days in [0, 1, 30])
          _fr.deletionPendingOrganizationTitle('Rota Sul', days),
      ];

      // 3. Assert
      expect(account, [
        'Votre compte sera supprimé aujourd’hui',
        'Votre compte sera supprimé dans 1 jour',
        'Votre compte sera supprimé dans 30 jours',
      ]);
      expect(organization, [
        'L’organisation Rota Sul sera supprimée aujourd’hui',
        'L’organisation Rota Sul sera supprimée dans 1 jour',
        'L’organisation Rota Sul sera supprimée dans 30 jours',
      ]);
    });

    test('Edge Case: zero, one and several read each in its own wording', () {
      // 1. Arrange / 2. Act
      final people = [
        for (final n in [0, 1, 3]) _fr.peopleCount(n),
      ];
      final members = [
        for (final n in [0, 1, 3]) _fr.memberCount(n),
      ];
      final pending = [
        for (final n in [0, 1, 3]) _fr.pendingInvites(n),
      ];
      final lost = [
        for (final n in [0, 1, 3]) _fr.groupDeletedLost(n, 'Rota'),
      ];

      // 3. Assert
      expect(people, ['Personne pour l’instant', '1 personne', '3 personnes']);
      expect(members, ['0 personne', '1 personne', '3 personnes']);
      expect(pending, [
        '0 invitation en attente',
        '1 invitation en attente',
        '3 invitations en attente',
      ]);
      expect(lost, [
        '0 personne a perdu l’accès à Rota.',
        '1 personne a perdu l’accès à Rota.',
        '3 personnes ont perdu l’accès à Rota.',
      ]);
    });

    test('Happy Path: inviteCardBody picks the role wording', () {
      // 1. Arrange / 2. Act
      final both = _fr.inviteCardBody('Carolina', 'Rota Norte', 'both');
      final publisher = _fr.inviteCardBody(
        'Carolina',
        'Rota Norte',
        'publisher',
      );
      final subscriber = _fr.inviteCardBody(
        'Carolina',
        'Rota Norte',
        'subscriber',
      );

      // 3. Assert
      expect(
        both,
        'Carolina vous invite à rejoindre le groupe Rota Norte, pour être sur '
        'le terrain et voir la carte.',
      );
      expect(
        publisher,
        'Carolina vous invite à rejoindre le groupe Rota Norte, pour être sur '
        'le terrain.',
      );
      expect(
        subscriber,
        'Carolina vous invite à rejoindre le groupe Rota Norte, pour voir la '
        'carte.',
      );
    });

    test('Happy Path: the no-break spaces of French typography reach the '
        'texts', () {
      // 1. Arrange / 2. Act
      final label = _fr.languageButtonLabel('Français');
      final question = _fr.creationNameTitle;
      final ago = _fr.agoMinutes(5);
      final meters = _fr.trackingMeters(50);
      final quoted = _fr.inviteRolesExplained;

      // 3. Assert: U+00A0, which a line cannot break at.
      expect(label, 'Langue\u00a0: Français');
      expect(question, 'Comment s’appelle votre organisation\u00a0?');
      expect(ago, 'il y a 5\u00a0min');
      expect(meters, '50\u00a0m');
      expect(quoted, startsWith('\u00ab\u00a0Sur le terrain\u00a0\u00bb'));
      expect([
        label,
        question,
        ago,
        meters,
      ], everyElement(isNot(contains(' :'))));
    });
  });

  // Real overflows of the French texts found by the tests above (the header
  // of Criar organização, 0.43 px, and the tracking preset's "in use" tag,
  // 3.1 px at text scale 1.3), now fixed: these tests keep them from coming
  // back.
  group('Fixed overflows of the French texts - Widget Test Suite', () {
    final texts = _french.texts;

    testWidgets(
      'Edge Case: the header of Criar organização does not overflow',
      (tester) async {
        // 1. Arrange / 2. Act: through the name and the theme to the plans,
        // where the step counter is "2 sur 4" and "3 sur 4".
        final controller = await _openCreation(
          tester,
          _french,
          FakeCreationRepository(),
          stopAtPlans: true,
        );
        addTearDown(controller.dispose);

        // 3. Assert
        expect(find.text(texts.creationTitle), findsOneWidget);
      },
    );

    testWidgets(
      'Edge Case: the tracking presets, the one in use included, do not '
      'overflow',
      (tester) async {
        // 1. Arrange
        Organization.bind(testOrganization);
        final repository = FakeTrackingSettingsRepository(minPeriod: 15);
        addTearDown(repository.dispose);
        final controller = TrackingSettingsEditViewModel(
          repository: repository,
          saved: const TrackingSettings(periodMinutes: 15, radiusMeters: 100),
        );
        addTearDown(controller.dispose);

        // 2. Act
        await expectNoRealOverflow(tester, () async {
          await pumpOnPhone(
            tester,
            TrackingSettingsScreen(controller: controller),
            locale: _french.device,
          );
          await tester.pump();
          await tester.pump();
        });

        // 3. Assert
        expect(find.text(texts.trackingInUse), findsOneWidget);
      },
    );
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

  for (final t in _translations) {
    group('${t.name} at a larger text size - Widget Test Suite', () {
      final texts = t.texts;
      // The real font and a phone's screen: see test/support/phone_layout.dart.
      testWidgets('Happy Path: Login does not overflow', (tester) async {
        // 1. Arrange
        final app = TestApp(googleReady: true);

        // 2. Act
        await _pumpTranslated(tester, app, t);

        // 3. Assert
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text(texts.loginWithGoogle), findsOneWidget);
        expectNoLayoutError(tester);
      });

      testWidgets('Happy Path: Sem organização does not overflow', (
        tester,
      ) async {
        // 1. Arrange
        final app = TestApp(googleReady: true);
        await _pumpTranslated(tester, app, t);

        // 2. Act
        await tester.tap(find.text(texts.loginWithGoogle));
        await TestApp.settle(tester);

        // 3. Assert
        expect(app.location, Routes.noOrganization);
        expect(find.text(texts.noOrganizationTitle), findsOneWidget);
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
        await _pumpTranslated(tester, app, t);

        // 2. Act
        await tester.tap(find.text(texts.loginWithGoogle));
        await TestApp.settle(tester);

        // 3. Assert
        expect(app.location, Routes.organizationPicker);
        expect(find.text(texts.pickerTitle), findsOneWidget);
        expect(
          find.textContaining(
            texts.inviteCardBody('Carolina Fernández', 'Rota Norte', 'both'),
          ),
          findsOneWidget,
        );
        expectNoLayoutError(tester);
      });

      for (final (label, deletion, button) in [
        (
          'an account',
          AccountDeletion(
            deleteAt: DateTime.now().add(const Duration(days: 30)),
          ),
          texts.deletionCancelAccount,
        ),
        (
          'an organization with its owner\'s account',
          AccountDeletion(
            deleteAt: DateTime.now().add(const Duration(days: 30)),
            ownedOrganizationIds: const ['rotasul'],
            ownedOrganizationNames: const {'rotasul': 'Rota Sul'},
          ),
          texts.deletionCancel,
        ),
      ]) {
        testWidgets('Happy Path: Em exclusão of $label does not overflow', (
          tester,
        ) async {
          // 1. Arrange
          final app = TestApp(googleReady: true);
          await _pumpTranslated(tester, app, t);

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
        await expectNoWorseThanPortuguese(tester, t.device, (locale) async {
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
        expect(find.text(texts.menuSwitchOrganization), findsOneWidget);
      });

      testWidgets('Happy Path: the menu of an administrator who owns the '
          'organization does not overflow', (tester) async {
        // 1. Arrange / 2. Act
        await _pumpMenu(
          tester,
          t,
          const Capabilities(isMember: true, isAdmin: true),
          directory: FakeOrganizationDirectory(
            organizations: [fakeCandidate('acme', owner: true)],
          ),
        );

        // 3. Assert: every administrator entry is there.
        expect(find.text(texts.menuAdministration), findsOneWidget);
        expect(find.text(texts.groupsTitle), findsOneWidget);
        expect(find.text(texts.administratorsTitle), findsOneWidget);
        expect(find.text(texts.menuAppearance), findsOneWidget);
        expect(find.text(texts.menuTrackingSettings), findsOneWidget);
        expectNoLayoutError(tester);
      });

      testWidgets('Happy Path: the menu of a group maintainer does not '
          'overflow', (tester) async {
        // 1. Arrange / 2. Act
        await _pumpMenu(
          tester,
          t,
          const Capabilities(
            isMember: true,
            rolesByGroup: {
              'norte': {GroupRoles.maintainer},
            },
          ),
        );

        // 3. Assert
        expect(find.text(texts.menuGroupManagement), findsOneWidget);
        expect(find.text(texts.menuMyGroups), findsOneWidget);
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

        // 2. Act: the button that creates a group is labelled with a
        // family-less style, see expectNoRealOverflow.
        await expectNoRealOverflow(tester, () async {
          await pumpOnPhone(
            tester,
            GroupsScreen(controller: controller),
            locale: t.device,
          );
          await tester.pump();
        });

        // 3. Assert
        expect(find.text(texts.groupsTitle), findsWidgets);
        expect(find.text('Rota Norte'), findsOneWidget);
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

        // 2. Act: the button that creates a group is labelled with a
        // family-less style, see expectNoRealOverflow.
        await expectNoRealOverflow(tester, () async {
          await pumpOnPhone(
            tester,
            GroupsScreen(controller: controller),
            locale: t.device,
          );
          await tester.pump();
        });

        // 3. Assert
        expect(find.byType(GroupsScreen), findsOneWidget);
      });

      // The buttons' labels use a family-less style (Ahem in the test): see
      // expectNoRealOverflow.
      for (final (label, tab) in [
        ('its people tab', _GroupTab.people),
        ('its invites tab', _GroupTab.invites),
      ]) {
        testWidgets('Happy Path: Grupo, $label, does not overflow', (
          tester,
        ) async {
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
          await expectNoRealOverflow(tester, () async {
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
              locale: t.device,
            );
            await tester.pump();
            if (tab == _GroupTab.invites) {
              await tester.tap(find.text(texts.groupTabInvited('2')));
              await tester.pump();
            }
          });

          // 3. Assert
          expect(find.text('Rota Norte'), findsWidgets);
          expect(find.text(texts.groupInvite), findsOneWidget);
        });
      }

      testWidgets('Happy Path: Boas-vindas, with the longest welcome text, '
          'does not overflow', (tester) async {
        // 1. Arrange
        final app = TestApp(googleReady: true);
        await _pumpTranslated(tester, app, t);

        // 2. Act
        app.session.moveTo(SessionState.welcome(_invite()));
        await TestApp.settle(tester);

        // 3. Assert
        expect(app.location, Routes.welcome);
        expect(find.byType(WelcomeScreen), findsOneWidget);
        expectNoLayoutError(tester);
      });

      testWidgets('Happy Path: the tracking settings do not overflow', (
        tester,
      ) async {
        // 1. Arrange
        Organization.bind(testOrganization);
        final repository = FakeTrackingSettingsRepository(minPeriod: 15);
        addTearDown(repository.dispose);
        final controller = TrackingSettingsEditViewModel(
          repository: repository,
          saved: const TrackingSettings(periodMinutes: 15, radiusMeters: 100),
        );
        addTearDown(controller.dispose);

        // 2. Act: its buttons use a family-less style, see
        // expectNoRealOverflow.
        await expectNoRealOverflow(tester, () async {
          await pumpOnPhone(
            tester,
            TrackingSettingsScreen(controller: controller),
            locale: t.device,
          );
          await tester.pump();
          await tester.pump();
        });

        // 3. Assert
        expect(find.text(texts.trackingQuestion), findsOneWidget);
        expect(
          find.text(texts.trackingAppliesTo(testOrganization.name)),
          findsOneWidget,
        );
      });

      testWidgets('Happy Path: the sheet that changes a person\'s roles does '
          'not overflow', (tester) async {
        // 1. Arrange
        final controller = GroupsViewModel(
          organizationId: 'rotasul',
          repository: FakeGroupsRepository(groups: {'rotasul': _groups}),
          isAdmin: true,
        );
        final groupInvites = GroupInvitesViewModel(
          organizationId: 'rotasul',
          groupId: 'norte',
          repository: FakeInvitesRepository(),
        );
        addTearDown(controller.dispose);
        addTearDown(groupInvites.dispose);
        await controller.load.execute();

        // 2. Act: opens the sheet of the person who only follows the map.
        await expectNoRealOverflow(tester, () async {
          await pumpOnPhone(
            tester,
            GroupScreen(
              controller: controller,
              groupId: 'norte',
              invites: groupInvites,
            ),
            locale: t.device,
          );
          await tester.pump();
          await tester.tap(
            find.text(texts.rolesLabel(const {GroupRole.subscriber})),
          );
          await tester.pumpAndSettle();
        });

        // 3. Assert
        expect(find.text(texts.groupRolesImmediate), findsOneWidget);
        expect(find.text('marta@example.com'), findsWidgets);
      });

      testWidgets('Happy Path: Criar organização, the plan step and the '
          'review, do not overflow', (tester) async {
        // 1. Arrange / 2. Act
        final controller = await _openCreation(tester, t, _FakeCreation());

        // 3. Assert: the wizard stands on the review, after the plans.
        expect(find.text(texts.creationReviewTitle), findsOneWidget);
        expect(find.text(texts.creationCreate), findsOneWidget);
        controller.dispose();
      });

      testWidgets('Edge Case: the plan step with Standard chosen does not '
          'overflow', (tester) async {
        // 1. Arrange
        final controller = await _openCreation(
          tester,
          t,
          _FakeCreation(),
          stopAtPlans: true,
        );

        // 2. Act
        await expectNoRealOverflow(tester, () async {
          await tester.ensureVisible(find.text(texts.planStandard));
          await tester.pump();
          await tester.tap(find.text(texts.planStandard));
          await tester.pump();
        });

        // 3. Assert
        expect(
          find.text(texts.creationPlanStandardProject('Rota Sul')),
          findsOneWidget,
        );
        controller.dispose();
      });

      testWidgets('Edge Case: the outcome of a creation that failed does not '
          'overflow', (tester) async {
        // 1. Arrange
        final controller = await _openCreation(
          tester,
          t,
          _FakeCreation(status: 'failed'),
        );

        // 2. Act
        await expectNoRealOverflow(tester, () async {
          await tester.tap(find.byType(Checkbox));
          await tester.pump();
          await tester.tap(find.text(texts.creationCreate));
          await tester.pump();
          await tester.pump();
        });

        // 3. Assert
        expect(
          find.text(texts.creationFailedTitle('Rota Sul')),
          findsOneWidget,
        );
        controller.dispose();
      });

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
          locale: t.device,
        );
        await tester.pump();

        // 3. Assert
        expect(find.text(texts.myAccountDelete), findsWidgets);
        expect(
          find.text(texts.myAccountMemberLeaves('Rota Sul')),
          findsOneWidget,
        );
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
          locale: t.device,
        );
        await tester.pump();

        // 3. Assert
        expect(
          find.text(texts.myAccountDeleteWithOrganization),
          findsOneWidget,
        );
        expect(
          find.text(texts.myAccountConfirmPrompt('rotasul')),
          findsOneWidget,
        );
        expectNoLayoutError(tester);
      });

      for (final scheme in LanguageScheme.values) {
        testWidgets('Happy Path: the language sheet (${scheme.name} scheme) '
            'does not overflow', (tester) async {
          // 1. Arrange
          final language = LanguageViewModel(
            repository: FakeLanguageRepository(),
            deviceLocales: () => [t.device],
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
            locale: t.device,
          );

          // 2. Act
          await tester.tap(find.text('Abrir'));
          await tester.pumpAndSettle();

          // 3. Assert
          expect(find.byType(LanguageSheet), findsOneWidget);
          expect(find.text(t.endonym), findsOneWidget);
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
          locale: t.device,
        );
        await tester.pump();

        // 3. Assert
        expect(find.text(t.calendarTitle), findsOneWidget);
        expect(find.text(texts.calendarDaysWithTrails), findsOneWidget);
        expectNoLayoutError(tester);
      });
    });
  }
}

/// The map's menu for a person with [capabilities], opened on a phone in
/// [translation]'s language at the larger text size.
Future<void> _pumpMenu(
  WidgetTester tester,
  _Translation translation,
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
    deviceLocales: () => [translation.device],
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
    locale: translation.device,
  );
  scaffold.currentState!.openDrawer();
  await tester.pumpAndSettle();
}

/// A [FakeCreationRepository] whose creations end in [status].
class _FakeCreation extends FakeCreationRepository {
  _FakeCreation({this.status});

  final String? status;

  @override
  Future<Result<String>> create({
    required String id,
    required String name,
    required String themeId,
    required String plan,
  }) async => status == null
      ? super.create(id: id, name: name, themeId: themeId, plan: plan)
      : Ok(status!);
}

/// Opens *Criar organização* on a phone in [translation]'s language and goes
/// through the name and the theme to the plans, then (unless [stopAtPlans])
/// on to the review. Returns the screen's view model, for the test to
/// dispose.
Future<CreateOrganizationViewModel> _openCreation(
  WidgetTester tester,
  _Translation translation,
  FakeCreationRepository repository, {
  bool stopAtPlans = false,
}) async {
  final texts = translation.texts;
  final controller = CreateOrganizationViewModel(
    repository: repository,
    themes: FakeThemeRepository(),
    enterOrganization: MockEnterOrganization(),
    session: FakeSessionRepository(),
    debounce: Duration.zero,
  );
  await expectNoRealOverflow(tester, () async {
    await pumpOnPhone(
      tester,
      CreateOrganizationScreen(controller: controller),
      locale: translation.device,
    );
    await tester.enterText(find.byType(TextField).first, 'Rota Sul');
    // Lets the zero debounce fire and the availability answer arrive.
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, texts.commonContinue));
    await tester.pump();
    await tester.tap(find.text(defaultOrganizationTheme.name));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, texts.commonContinue));
    await tester.pump();
    if (!stopAtPlans) {
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          texts.creationPlanContinue(texts.planCommunity),
        ),
      );
      await tester.pump();
    }
  });
  return controller;
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
