import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/language/language_repository.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/app_language.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization.dart';
import 'package:monamie_app/domain/models/organization/organization_config.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository_google.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/l10n/app_localizations.dart';
import 'package:monamie_app/ui/core/monamie_app.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/core/themes/app_theme.dart';
import 'package:monamie_app/ui/invites/widgets/welcome_screen.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:provider/provider.dart';

import '../../../testing/fakes/repositories/fake_language_repository.dart';
import '../../../testing/fakes/repositories/fake_sharing_resume_repository.dart';
import '../../support/test_organization.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<AuthGoogleService>(),
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<GoogleBondCheck>(),
  MockSpec<InvitesRepository>(),
  MockSpec<OrganizationBrandingLoader>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<OrganizationLocalData>(),
  MockSpec<MembershipService>(),
  MockSpec<NoticePresenter>(),
  MockSpec<OrganizationSession>(),
  MockSpec<UserGoogleRepository>(),
])
import 'monamie_app_test.mocks.dart';

/// An organization whose theme is not the default one.
const _kOceano = OrganizationConfig(
  id: 'rotasul',
  name: 'Rota Sul',
  themeId: 'oceano',
  theme: OrganizationTheme(
    id: 'oceano',
    name: 'Oceano',
    primary: Color(0xFF0B7F7B),
    dark: Color(0xFF0A3D3B),
    light: Color(0xFFD3EEEC),
    onPrimary: Color(0xFFFFFFFF),
    onDark: Color(0xFF00000A),
  ),
);

final _kInvite = Invite(
  id: 'inv1',
  organizationId: 'rotasul',
  organizationName: 'Rota Sul',
  groupId: '01',
  groupName: 'Equipe Norte',
  email: 'ana.souza@monamie.net',
  roles: const {GroupRole.publisher},
  inviterName: 'Rita Lima',
  expiresAt: DateTime.utc(2026, 11, 9, 12),
);

/// Opens the app over the data layer it reads (mocks, provided as
/// `appDependencies` is in `main`, with a real [SessionRepository] and use
/// cases over them); returns the session. The session starts: the mocked
/// Google Sign-In initializes at once, so *Login* shows the Google button.
/// Not `pumpAndSettle`, in case a spinner stays.
///
/// The device's languages are [deviceLocales] (English when omitted) and
/// [languages] holds the language the person chose, if any.
Future<SessionRepository> _pumpApp(
  WidgetTester tester, {
  List<Locale> deviceLocales = const [Locale('en', 'US')],
  FakeLanguageRepository? languages,
}) async {
  tester.platformDispatcher.localesTestValue = deviceLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final auth = MockAuthGoogleService();
  when(auth.onWebSignIn).thenAnswer((_) => const Stream<String?>.empty());
  final session = SessionRepositoryGoogle(auth: auth)..start();
  final userRepository = MockUserGoogleRepository();
  final directory = MockOrganizationDirectory();
  final brandingLoader = MockOrganizationBrandingLoader();
  final organizationSession = MockOrganizationSession();
  final invites = MockInvitesRepository();
  final deletions = MockAccountDeletionRepository();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthGoogleService>.value(value: auth),
        Provider<SessionRepository>.value(value: session),
        Provider<LanguageRepository>.value(
          value: languages ?? FakeLanguageRepository(),
        ),
        Provider<UserGoogleRepository>.value(value: userRepository),
        Provider<OrganizationDirectory>.value(value: directory),
        Provider<OrganizationBrandingLoader>.value(value: brandingLoader),
        Provider<OrganizationSession>.value(value: organizationSession),
        Provider<InvitesRepository>.value(value: invites),
        Provider<AccountDeletionRepository>.value(value: deletions),
        Provider<GoogleBondCheck>.value(value: MockGoogleBondCheck()),
        Provider<EnterOrganization>.value(
          value: EnterOrganization(
            session: session,
            directory: directory,
            brandingLoader: brandingLoader,
            binder: organizationSession,
            memberships: MockMembershipService(),
            userRepository: userRepository,
            deletions: deletions,
            invites: invites,
          ),
        ),
        Provider<SignOut>.value(
          value: SignOut(
            session: session,
            trackingStopper: MockBackgroundTrackingStopper(),
            userRepository: userRepository,
            binder: organizationSession,
            localData: MockOrganizationLocalData(),
            directory: directory,
            brandingLoader: brandingLoader,
            invites: invites,
            sharingResume: FakeSharingResumeRepository(),
            notices: MockNoticePresenter(),
          ),
        ),
      ],
      child: const MonAmieApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return session;
}

void main() {
  provideDummy<Result<List<Invite>>>(const Ok(<Invite>[]));
  provideDummy<Result<AccountDeletion?>>(const Ok(null));

  group('MonAmieApp (app scope) - Widget Test Suite', () {
    testWidgets('Happy Path: the app opens on Login, whose route finds the '
        'session and the entry above the router', (tester) async {
      // 1. Arrange
      // (nothing: the app builds its own router)

      // 2. Act
      await _pumpApp(tester);

      // 3. Assert
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Edge Case: the router starts on the theme of the bound '
        'organization', (tester) async {
      // 1. Arrange
      final expected = AppTheme.lightTheme;

      // 2. Act
      await _pumpApp(tester);

      // 3. Assert
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, expected);
      expect(app.themeMode, ThemeMode.light);
    });

    testWidgets('Happy Path: the theme follows the session: reaching '
        "Boas-vindas switches to the bound organization's", (tester) async {
      // 1. Arrange
      addTearDown(() => Organization.bind(testOrganization));
      final session = await _pumpApp(tester);
      final before = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;
      Organization.bind(_kOceano);

      // 2. Act
      session.moveTo(SessionState.welcome(_kInvite));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 3. Assert
      expect(find.byType(WelcomeScreen), findsOneWidget);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, AppTheme.lightTheme);
      expect(app.theme, isNot(before));
    });

    testWidgets('Edge Case: binding an organization alone does not change the '
        'theme while the session stays put (#78)', (tester) async {
      // 1. Arrange
      addTearDown(() => Organization.bind(testOrganization));
      await _pumpApp(tester);
      final before = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme;

      // 2. Act
      Organization.bind(_kOceano);
      await tester.pump();

      // 3. Assert
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, before);
    });

    testWidgets('Sad Path: closing the app releases the router and the '
        'theme without errors', (tester) async {
      // 1. Arrange
      await _pumpApp(tester);

      // 2. Act
      await tester.pumpWidget(const SizedBox());

      // 3. Assert
      expect(tester.takeException(), isNull);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('MonAmieApp language - Widget Test Suite', () {
    /// The app's [Locale], as resolved under the [LoginScreen].
    Locale resolved(WidgetTester tester) =>
        Localizations.localeOf(tester.element(find.byType(LoginScreen)));

    AppLocalizations texts(WidgetTester tester) =>
        AppLocalizations.of(tester.element(find.byType(LoginScreen)));

    testWidgets('Happy Path: with no choice, a Portuguese device shows '
        'Portuguese', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('pt', 'BR')]);

      // 3. Assert
      expect(resolved(tester), const Locale('pt', 'BR'));
      expect(find.text('Sua equipe, no mesmo ponto.'), findsOneWidget);
    });

    testWidgets('Happy Path: with no choice, an English device shows '
        'English', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester);

      // 3. Assert
      expect(resolved(tester), const Locale('en'));
      expect(find.text('Your team, on the same page.'), findsOneWidget);
    });

    testWidgets('Edge Case: with no choice, a device language the app does '
        'not have shows English', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('de', 'DE')]);

      // 3. Assert
      expect(resolved(tester), const Locale('en'));
      expect(find.text('Your team, on the same page.'), findsOneWidget);
    });

    testWidgets('Happy Path: a chosen Portuguese wins over an English '
        'device', (tester) async {
      // 1. Arrange
      final languages = FakeLanguageRepository(stored: AppLanguage.pt);
      await languages.restore();

      // 2. Act
      await _pumpApp(tester, languages: languages);

      // 3. Assert
      expect(resolved(tester), const Locale('pt', 'BR'));
      expect(find.text('Sua equipe, no mesmo ponto.'), findsOneWidget);
      expect(find.text('Your team, on the same page.'), findsNothing);
    });

    testWidgets('Happy Path: a chosen English wins over a Portuguese '
        'device', (tester) async {
      // 1. Arrange
      final languages = FakeLanguageRepository(stored: AppLanguage.en);
      await languages.restore();

      // 2. Act
      await _pumpApp(
        tester,
        deviceLocales: const [Locale('pt', 'BR')],
        languages: languages,
      );

      // 3. Assert
      expect(resolved(tester), const Locale('en'));
      expect(find.text('Your team, on the same page.'), findsOneWidget);
      expect(find.text('Sua equipe, no mesmo ponto.'), findsNothing);
    });

    testWidgets('Happy Path: choosing a language changes the texts at '
        'once', (tester) async {
      // 1. Arrange
      final languages = FakeLanguageRepository();
      await _pumpApp(tester, languages: languages);
      final before = texts(tester).loginTagline;

      // 2. Act
      await languages.choose(AppLanguage.pt);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 3. Assert
      expect(before, 'Your team, on the same page.');
      expect(find.text('Sua equipe, no mesmo ponto.'), findsOneWidget);
      expect(resolved(tester), const Locale('pt', 'BR'));
    });

    testWidgets('Edge Case: the choice is the first locale of the app, '
        'whatever the device lists', (tester) async {
      // 1. Arrange
      final languages = FakeLanguageRepository(stored: AppLanguage.pt);
      await languages.restore();

      // 2. Act
      await _pumpApp(
        tester,
        deviceLocales: const [Locale('en', 'US'), Locale('pt', 'BR')],
        languages: languages,
      );

      // 3. Assert
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('pt', 'BR'));
      expect(resolved(tester), const Locale('pt', 'BR'));
    });

    testWidgets('Edge Case: with no choice the app sets no locale of its '
        'own', (tester) async {
      // 1. Arrange / 2. Act
      await _pumpApp(tester, deviceLocales: const [Locale('pt', 'BR')]);

      // 3. Assert
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, isNull);
    });
  });
}
