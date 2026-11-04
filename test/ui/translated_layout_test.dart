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
import 'package:monamie_app/domain/models/invite_send_result.dart';
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
import 'package:monamie_app/ui/groups/widgets/create_group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/group_screen.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/ui/history/widgets/history_calendar_sheet.dart';
import 'package:monamie_app/ui/home/view_models/home_session_view_model.dart';
import 'package:monamie_app/ui/home/widgets/home_menu.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/ui/invites/view_models/invite_view_model.dart';
import 'package:monamie_app/ui/invites/widgets/invite_screen.dart';
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

/// Portuguese, the baseline the translations are compared with.
const _portuguese = _Translation(
  name: 'Portuguese',
  language: AppLanguage.pt,
  device: Locale('pt', 'BR'),
  code: 'PT',
  endonym: 'Português',
  calendarTitle: 'Novembro de 2026',
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
  _Translation translation, {
  double textScale = largerTextScale,
}) => app.pump(
  tester,
  locale: translation.device,
  theme: AppTheme.lightTheme,
  textScale: textScale,
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
          stopAt: _CreationStep.plans,
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
          stopAt: _CreationStep.plans,
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

  // A text cut with an ellipsis (or clipped at its `maxLines`) throws nothing,
  // so the tests above never see it: every screen they open is opened again
  // here, in each translation and in Portuguese, and a translation may not
  // cut a text where Portuguese cuts none.
  group('Truncated texts - Widget Test Suite', () {
    for (final t in _translations) {
      for (final textScale in _textScales) {
        for (final MapEntry(key: name, value: scene) in _scenes.entries) {
          final known =
              _knownTruncations['$name|${t.language.name}|$textScale'];
          testWidgets(
            'Happy Path: $name in ${t.name} at text scale $textScale cuts no '
            'text short${known == null ? '' : ' (KNOWN: $known)'}',
            (tester) async {
              // 1. Arrange / 2. Act / 3. Assert
              await expectNoNewTruncation(
                tester,
                t.device,
                (locale) => scene(
                  tester,
                  locale.languageCode == 'pt' ? _portuguese : t,
                  textScale,
                ),
                ignoring: _dataTexts,
              );
            },
            skip: known != null,
          );
        }
      }
    }

    for (final textScale in _textScales) {
      final known = _knownTruncations['Criar grupo|fr|$textScale'];
      testWidgets(
        'Edge Case: the group name field of Criar grupo, in French, shows its '
        'whole helper text at text scale $textScale'
        '${known == null ? '' : ' (KNOWN: $known)'}',
        skip: known != null,
        (tester) async {
          // 1. Arrange / 2. Act: through expectNoRealOverflow, which leaves
          // out the family-less button label drawn in the test font (#125).
          await expectNoRealOverflow(
            tester,
            () => _openCreateGroup(tester, _french, textScale),
          );

          // 3. Assert: 72 characters in French, one line cut it.
          final texts = _french.texts;
          expect(find.text(texts.groupNameHelper), findsOneWidget);
          expect(
            truncatedTexts(tester),
            isNot(contains(texts.groupNameHelper)),
          );
          expect(truncatedTexts(tester, ignoring: _dataTexts), isEmpty);
        },
      );
    }
  });
}

/// The map's menu for a person with [capabilities], opened on a phone in
/// [translation]'s language at the larger text size.
Future<void> _pumpMenu(
  WidgetTester tester,
  _Translation translation,
  Capabilities capabilities, {
  FakeOrganizationDirectory? directory,
  double textScale = largerTextScale,
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
    textScale: textScale,
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

/// The steps of *Criar organização*, in order.
enum _CreationStep { name, theme, plans, review }

/// Opens *Criar organização* on a phone in [translation]'s language at
/// [textScale] and goes through the name and the theme to the plans, then
/// (unless [stopAt] says to stop earlier) on to the review. Returns the
/// screen's view model, for the test to dispose.
Future<CreateOrganizationViewModel> _openCreation(
  WidgetTester tester,
  _Translation translation,
  FakeCreationRepository repository, {
  _CreationStep stopAt = _CreationStep.review,
  double textScale = largerTextScale,
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
      textScale: textScale,
    );
    if (stopAt == _CreationStep.name) return;
    await tester.enterText(find.byType(TextField).first, 'Rota Sul');
    // Lets the zero debounce fire and the availability answer arrive.
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, texts.commonContinue));
    await tester.pump();
    if (stopAt == _CreationStep.theme) return;
    await tester.tap(find.text(defaultOrganizationTheme.name));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, texts.commonContinue));
    await tester.pump();
    if (stopAt == _CreationStep.plans) return;
    await tester.tap(
      find.widgetWithText(
        FilledButton,
        texts.creationPlanContinue(texts.planCommunity),
      ),
    );
    await tester.pump();
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

/// The text sizes the truncation checks run at: the default and a common
/// "larger text" setting.
const _textScales = [1.0, largerTextScale];

/// Texts that are data (typed by a person or sent by the server) and cut on
/// purpose when too long: e-mail addresses, and the names the fixtures give
/// people and organizations, matched whole so a translated sentence that
/// holds a name is still checked.
final _dataTexts = <Pattern>[
  '@example.com',
  RegExp(r'^(Rota (Sul|Norte)|Rota Sur|Carolina Fernández( de la Torre)?)$'),
];

/// The truncations the checks found that are not fixed yet, by
/// `scene|language|text scale`, each with a pointer to what is cut. The case
/// is skipped (the rest of the screen is still checked in the other cases);
/// remove the entry when the layout is fixed. None is left: the three French
/// ones found at text scale 1.3 (the group name's helper text, the title of
/// the organization creation header and the menu's subtitle) were fixed.
const _knownTruncations = <String, String>{};

/// Opens a screen in [translation]'s language on a phone at [textScale] and
/// leaves it open.
typedef _Scene =
    Future<void> Function(
      WidgetTester tester,
      _Translation translation,
      double textScale,
    );

/// Every screen the layout tests above open, by name, each in the state with
/// the longest texts.
final _scenes = <String, _Scene>{
  'Login': (tester, t, scale) async {
    await _pumpTranslated(
      tester,
      TestApp(googleReady: true),
      t,
      textScale: scale,
    );
  },
  'Sem organização': (tester, t, scale) async {
    final app = TestApp(googleReady: true);
    await _pumpTranslated(tester, app, t, textScale: scale);
    await tester.tap(find.text(t.texts.loginWithGoogle));
    await TestApp.settle(tester);
  },
  'the organization picker with an invite': (tester, t, scale) async {
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
    await _pumpTranslated(tester, app, t, textScale: scale);
    await tester.tap(find.text(t.texts.loginWithGoogle));
    await TestApp.settle(tester);
  },
  'Em exclusão of an account': (tester, t, scale) async {
    final app = TestApp(googleReady: true);
    await _pumpTranslated(tester, app, t, textScale: scale);
    app.session.moveTo(
      SessionState.deletionPending(
        AccountDeletion(deleteAt: DateTime.now().add(const Duration(days: 30))),
      ),
    );
    await TestApp.settle(tester);
  },
  'Em exclusão of an organization': (tester, t, scale) async {
    final app = TestApp(googleReady: true);
    await _pumpTranslated(tester, app, t, textScale: scale);
    app.session.moveTo(
      SessionState.deletionPending(
        AccountDeletion(
          deleteAt: DateTime.now().add(const Duration(days: 30)),
          ownedOrganizationIds: const ['rotasul'],
          ownedOrganizationNames: const {'rotasul': 'Rota Sul'},
        ),
      ),
    );
    await TestApp.settle(tester);
  },
  'the map and its menu': (tester, t, scale) async {
    Organization.bind(testOrganization);
    final app = TestApp();
    await _pumpTranslated(tester, app, t, textScale: scale);
    app.session.moveTo(const SessionState.bound());
    await TestApp.settle(tester);
    await tester.tap(find.byIcon(Icons.menu));
    await TestApp.settle(tester);
  },
  'the menu of an administrator who owns the organization':
      (tester, t, scale) => _pumpMenu(
        tester,
        t,
        const Capabilities(isMember: true, isAdmin: true),
        directory: FakeOrganizationDirectory(
          organizations: [fakeCandidate('acme', owner: true)],
        ),
        textScale: scale,
      ),
  'the menu of a group maintainer': (tester, t, scale) => _pumpMenu(
    tester,
    t,
    const Capabilities(
      isMember: true,
      rolesByGroup: {
        'norte': {GroupRoles.maintainer},
      },
    ),
    textScale: scale,
  ),
  'Grupos': (tester, t, scale) => _openGroups(
    tester,
    t,
    scale,
    FakeGroupsRepository(groups: {'rotasul': _groups}),
  ),
  'Grupos with no group': (tester, t, scale) =>
      _openGroups(tester, t, scale, FakeGroupsRepository()),
  'Grupo, its people tab': (tester, t, scale) =>
      _openGroup(tester, t, scale, _GroupTab.people),
  'Grupo, its invites tab': (tester, t, scale) =>
      _openGroup(tester, t, scale, _GroupTab.invites),
  'the sheet that changes a person\'s roles': (tester, t, scale) async {
    final groups = GroupsViewModel(
      organizationId: 'rotasul',
      repository: FakeGroupsRepository(groups: {'rotasul': _groups}),
      isAdmin: true,
    );
    final invites = GroupInvitesViewModel(
      organizationId: 'rotasul',
      groupId: 'norte',
      repository: FakeInvitesRepository(),
    );
    addTearDown(groups.dispose);
    addTearDown(invites.dispose);
    await groups.load.execute();
    await pumpOnPhone(
      tester,
      GroupScreen(controller: groups, groupId: 'norte', invites: invites),
      locale: t.device,
      textScale: scale,
    );
    await tester.pump();
    await tester.tap(
      find.text(t.texts.rolesLabel(const {GroupRole.subscriber})),
    );
    await tester.pumpAndSettle();
  },
  'Criar grupo': (tester, t, scale) => _openCreateGroup(tester, t, scale),
  'Criar grupo with a name that is too short': (tester, t, scale) =>
      _openCreateGroup(tester, t, scale, typed: 'a'),
  'Criar grupo with a name that is taken': (tester, t, scale) =>
      _openCreateGroup(tester, t, scale, typed: 'rota norte'),
  'Criar grupo, done': (tester, t, scale) async {
    await _openCreateGroup(tester, t, scale, typed: 'Rota Leste');
    await tester.tap(find.text(t.texts.createGroupButton));
    await tester.pump();
    await tester.pump();
  },
  'Convidar pessoas': (tester, t, scale) => _openInvite(tester, t, scale),
  'Convidar pessoas with people, one with no role': (tester, t, scale) =>
      _openInvite(
        tester,
        t,
        scale,
        prepare: (c) {
          c.add('una.direccion.muy.larga@example.com');
          c.add('marta@example.com');
          c.toggle(c.state.people.last, GroupRole.publisher);
        },
      ),
  'Convidar pessoas with an e-mail already listed': (tester, t, scale) =>
      _openInvite(
        tester,
        t,
        scale,
        prepare: (c) {
          c.add('marta@example.com');
          c.add('marta@example.com');
        },
      ),
  'Convidar pessoas with an invalid e-mail': (tester, t, scale) =>
      _openInvite(tester, t, scale, prepare: (c) => c.add('not an e-mail')),
  'Convidar pessoas, first group with a short name': (tester, t, scale) =>
      _openInvite(
        tester,
        t,
        scale,
        groups: const [],
        prepare: (c) => c.setFirstGroupName('a'),
      ),
  'Convidar pessoas when the send failed': (tester, t, scale) async {
    final repository = FakeInvitesRepository();
    repository.fail('send', const Failure.connection(FailedAction.send));
    await _openInvite(
      tester,
      t,
      scale,
      repository: repository,
      prepare: (c) => c.add('marta@example.com'),
      send: true,
    );
  },
  'Convidar pessoas, sent': (tester, t, scale) => _openInvite(
    tester,
    t,
    scale,
    repository: _FakeSend(
      const InviteSendResult(
        groupId: 'norte',
        groupName: 'Rota Norte',
        sent: ['marta@example.com', 'una.direccion.muy.larga@example.com'],
        notEmailed: ['una.direccion.muy.larga@example.com'],
        skipped: {'luis@example.com': 'Já está no grupo.'},
      ),
    ),
    prepare: (c) => c.add('marta@example.com'),
    send: true,
  ),
  'Boas-vindas': (tester, t, scale) async {
    final app = TestApp(googleReady: true);
    await _pumpTranslated(tester, app, t, textScale: scale);
    app.session.moveTo(SessionState.welcome(_invite()));
    await TestApp.settle(tester);
  },
  'the tracking settings': (tester, t, scale) async {
    Organization.bind(testOrganization);
    final repository = FakeTrackingSettingsRepository(minPeriod: 15);
    addTearDown(repository.dispose);
    final controller = TrackingSettingsEditViewModel(
      repository: repository,
      saved: const TrackingSettings(periodMinutes: 15, radiusMeters: 100),
    );
    addTearDown(controller.dispose);
    await pumpOnPhone(
      tester,
      TrackingSettingsScreen(controller: controller),
      locale: t.device,
      textScale: scale,
    );
    await tester.pump();
    await tester.pump();
  },
  for (final step in _CreationStep.values)
    'Criar organização, the ${step.name} step': (tester, t, scale) async {
      final controller = await _openCreation(
        tester,
        t,
        FakeCreationRepository(),
        stopAt: step,
        textScale: scale,
      );
      addTearDown(controller.dispose);
    },
  'Criar organização, the plan step with Standard chosen':
      (tester, t, scale) async {
        final controller = await _openCreation(
          tester,
          t,
          FakeCreationRepository(),
          stopAt: _CreationStep.plans,
          textScale: scale,
        );
        addTearDown(controller.dispose);
        await tester.ensureVisible(find.text(t.texts.planStandard));
        await tester.pump();
        await tester.tap(find.text(t.texts.planStandard));
        await tester.pump();
      },
  'Criar organização, the outcome of a creation that failed':
      (tester, t, scale) async {
        final controller = await _openCreation(
          tester,
          t,
          _FakeCreation(status: 'failed'),
          textScale: scale,
        );
        addTearDown(controller.dispose);
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.tap(find.text(t.texts.creationCreate));
        await tester.pump();
        await tester.pump();
      },
  'Minha conta of a member': (tester, t, scale) =>
      _openMyAccount(tester, t, scale, owner: false),
  'Minha conta of the owner': (tester, t, scale) =>
      _openMyAccount(tester, t, scale, owner: true),
  for (final scheme in LanguageScheme.values)
    'the language sheet (${scheme.name} scheme)': (tester, t, scale) async {
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
        textScale: scale,
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    },
  'the history calendar sheet': (tester, t, scale) async {
    final today = DateTime(2026, 11, 2);
    final calendar = MockCalendarViewModel();
    when(calendar.viewMonth).thenReturn(
      ValueNotifier(HistoryMonth(year: 2026, month: 11, today: today)),
    );
    when(calendar.observedDay).thenReturn(ValueNotifier(today));
    when(calendar.isLoadingMonth).thenReturn(ValueNotifier(false));
    await pumpOnPhone(
      tester,
      Scaffold(body: HistoryCalendarSheet(controller: calendar)),
      locale: t.device,
      textScale: scale,
    );
    await tester.pump();
  },
};

/// *Grupos* over [repository], for an administrator.
Future<void> _openGroups(
  WidgetTester tester,
  _Translation t,
  double scale,
  FakeGroupsRepository repository,
) async {
  final controller = GroupsViewModel(
    organizationId: 'rotasul',
    repository: repository,
    isAdmin: true,
  );
  addTearDown(controller.dispose);
  await pumpOnPhone(
    tester,
    GroupsScreen(controller: controller),
    locale: t.device,
    textScale: scale,
  );
  await tester.pump();
}

/// *Grupo* of *Rota Norte* on [tab], with an expired invite to a long
/// address.
Future<void> _openGroup(
  WidgetTester tester,
  _Translation t,
  double scale,
  _GroupTab tab,
) async {
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
  final controller = GroupsViewModel(
    organizationId: 'rotasul',
    repository: FakeGroupsRepository(groups: {'rotasul': _groups}),
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
    textScale: scale,
  );
  await tester.pump();
  if (tab == _GroupTab.invites) {
    await tester.tap(find.text(t.texts.groupTabInvited('2')));
    await tester.pump();
  }
}

/// *Criar grupo* in the organization that has *Rota Norte*, with [typed] in
/// the name field when given.
Future<void> _openCreateGroup(
  WidgetTester tester,
  _Translation t,
  double scale, {
  String? typed,
}) async {
  final controller = GroupsViewModel(
    organizationId: 'rotasul',
    repository: FakeGroupsRepository(groups: {'rotasul': _groups}),
    isAdmin: true,
  );
  addTearDown(controller.dispose);
  await controller.load.execute();
  await pumpOnPhone(
    tester,
    CreateGroupScreen(controller: controller),
    locale: t.device,
    textScale: scale,
  );
  await tester.pump();
  if (typed != null) {
    await tester.enterText(find.byType(TextField), typed);
    // Past the helper text's cross-fade into the error, which starts in the
    // frame the error is built in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// A [FakeInvitesRepository] whose send ends in [result].
class _FakeSend extends FakeInvitesRepository {
  _FakeSend(this.result);

  final InviteSendResult result;

  @override
  Future<Result<InviteSendResult>> send(
    String organizationId, {
    required String organizationName,
    String? groupId,
    String? firstGroupName,
    required List<({String email, Set<GroupRole> roles})> invites,
  }) async => Ok(result);
}

/// *Convidar pessoas* of an administrator, to [groups] (the groups of
/// `_groups` unless given; none puts it in first-group mode). [prepare] fills
/// the view model before the screen is drawn; [send] presses the send
/// button, which shows the outcome or the failure.
Future<void> _openInvite(
  WidgetTester tester,
  _Translation t,
  double scale, {
  List<Group>? groups,
  FakeInvitesRepository? repository,
  void Function(InviteViewModel controller)? prepare,
  bool send = false,
}) async {
  Organization.bind(testOrganization);
  final controller = InviteViewModel(
    organizationId: 'rotasul',
    organizationName: 'Rota Sul',
    groups: groups ?? _groups,
    repository: repository ?? FakeInvitesRepository(),
  );
  addTearDown(controller.dispose);
  prepare?.call(controller);
  await pumpOnPhone(
    tester,
    InviteScreen(controller: controller),
    locale: t.device,
    textScale: scale,
  );
  await tester.pump();
  if (send) {
    await controller.send.execute();
    await tester.pump();
  }
}

/// *Minha conta* of a member, or of the organization's [owner].
Future<void> _openMyAccount(
  WidgetTester tester,
  _Translation t,
  double scale, {
  required bool owner,
}) async {
  final controller = MyAccountViewModel(
    repository: FakeAccountDeletionRepository(),
    organizationId: 'rotasul',
    directory: FakeOrganizationDirectory(
      organizations: [fakeCandidate('rotasul', owner: owner)],
    ),
    signOut: MockSignOut(),
  );
  addTearDown(controller.dispose);
  await pumpOnPhone(
    tester,
    MyAccountScreen(
      controller: controller,
      email: 'carolina.fernandez@example.com',
      organizationName: 'Rota Sul',
    ),
    locale: t.device,
    textScale: scale,
  );
  await tester.pump();
}
