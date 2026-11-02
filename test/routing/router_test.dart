import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/domain/models/account_deletion.dart';
import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/domain/models/invite.dart';
import 'package:monamie_app/domain/models/organization/organization_theme.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_repository.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_repository.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/data/services/permissions_service.dart';
import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'package:monamie_app/data/repositories/organization/organization_binder.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/ui/groups/view_models/groups_view_model.dart';
import 'package:monamie_app/ui/groups/widgets/groups_screen.dart';
import 'package:monamie_app/ui/creation/widgets/create_organization_screen.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository_google.dart';
import 'package:monamie_app/data/services/auth/auth_google_service.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/ui/auth/widgets/login_screen.dart';
import 'package:monamie_app/ui/auth/widgets/no_organization_screen.dart';
import 'package:monamie_app/ui/home/widgets/home_screen.dart';
import 'package:monamie_app/routing/router.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

@GenerateNiceMocks([
  MockSpec<AccountDeletionRepository>(),
  MockSpec<AdministratorsRepository>(),
  MockSpec<AppearanceRepository>(),
  MockSpec<AuthGoogleService>(),
  MockSpec<BackgroundRestrictionChecker>(),
  MockSpec<BackgroundTrackingService>(),
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<BackgroundUsageSettingsLauncher>(),
  MockSpec<CallService>(),
  MockSpec<CreationRepository>(),
  MockSpec<DeviceLocation>(),
  MockSpec<GoogleBondCheck>(),
  MockSpec<GroupsRepository>(),
  MockSpec<InvitesRepository>(),
  MockSpec<MembershipService>(),
  MockSpec<NoticePresenter>(),
  MockSpec<OrganizationBinder>(),
  MockSpec<OrganizationBrandingLoader>(),
  MockSpec<OrganizationDirectory>(),
  MockSpec<OrganizationLocalData>(),
  MockSpec<OrganizationSession>(),
  MockSpec<PermissionsService>(),
  MockSpec<PositionsRepository>(),
  MockSpec<ThemeRepository>(),
  MockSpec<TrackingSettingsRepository>(),
  MockSpec<UserGoogleRepository>(),
])
import 'router_test.mocks.dart';

/// The app's router ([buildAppRouter]) over a real [SessionRepository]
/// and real use cases whose services are mocks; the session is never
/// started, so Google Sign-In is never initialized. The session moves only
/// as in the app: [SessionRepository.moveTo] to bound (what *Login* does for
/// a remembered session), [SignOut.call] signs out and
/// [SignOut.afterAccessLost] leads to *Sem organização*.
class _App {
  _App() {
    when(stopper.stop(email: anyNamed('email'))).thenAnswer((_) async => true);
    // The organization's scope builds the real permissions view model: every
    // permission answers "denied".
    when(permissions.isGranted(any)).thenAnswer((_) async => false);
    when(permissions.isPermanentlyDenied(any)).thenAnswer((_) async => false);
    when(
      permissions.request(any),
    ).thenAnswer((_) async => AppPermissionStatus.denied);
    when(
      trackingSettings.watch(),
    ).thenAnswer((_) => Stream.value(TrackingSettings.defaults));
    // *Administradores* reads an organization with nobody in it.
    when(
      administrators.list(any),
    ).thenAnswer((_) async => const Ok(OrganizationAdministrators()));
    when(auth.onWebSignIn).thenAnswer((_) => const Stream<String?>.empty());
    session = SessionRepositoryGoogle(auth: auth);
    signOut = SignOut(
      session: session,
      trackingStopper: stopper,
      userRepository: userRepository,
      binder: MockOrganizationBinder(),
      localData: MockOrganizationLocalData(),
      directory: directory,
      brandingLoader: MockOrganizationBrandingLoader(),
      invites: invites,
      notices: MockNoticePresenter(),
    );
    enterOrganization = EnterOrganization(
      session: session,
      directory: directory,
      brandingLoader: MockOrganizationBrandingLoader(),
      binder: MockOrganizationBinder(),
      memberships: MockMembershipService(),
      userRepository: userRepository,
      deletions: deletion,
      invites: invites,
    );
    router = buildAppRouter(session: session);
  }

  final auth = MockAuthGoogleService();
  final directory = MockOrganizationDirectory();
  final stopper = MockBackgroundTrackingStopper();
  final userRepository = MockUserGoogleRepository();
  final invites = MockInvitesRepository();
  final deletion = MockAccountDeletionRepository();
  final positions = MockPositionsRepository();
  final permissions = MockPermissionsService();
  final trackingSettings = MockTrackingSettingsRepository();
  final administrators = MockAdministratorsRepository();

  /// The data layer the routes read, as `appDependencies` provides it in
  /// the app: every object a mock.
  late final List<SingleChildWidget> dependencies = [
    Provider<UserGoogleRepository>.value(value: userRepository),
    Provider<OrganizationSession>.value(value: MockOrganizationSession()),
    Provider<ThemeRepository>.value(value: MockThemeRepository()),
    Provider<GoogleBondCheck>.value(value: MockGoogleBondCheck()),
    Provider<InvitesRepository>.value(value: invites),
    Provider<AccountDeletionRepository>.value(value: deletion),
    Provider<GroupsRepository>.value(value: MockGroupsRepository()),
    Provider<AdministratorsRepository>.value(value: administrators),
    Provider<AppearanceRepository>.value(value: MockAppearanceRepository()),
    Provider<CreationRepository>.value(value: MockCreationRepository()),
    Provider<TrackingSettingsRepository>.value(value: trackingSettings),
    Provider<MembershipService>.value(value: MockMembershipService()),
    Provider<PositionsRepository>.value(value: positions),
    Provider<BackgroundTrackingService>.value(
      value: MockBackgroundTrackingService(),
    ),
    Provider<PermissionsService>.value(value: permissions),
    Provider<DeviceLocation>.value(value: MockDeviceLocation()),
    Provider<BackgroundRestrictionChecker>.value(
      value: MockBackgroundRestrictionChecker(),
    ),
    Provider<BackgroundUsageSettingsLauncher>.value(
      value: MockBackgroundUsageSettingsLauncher(),
    ),
    Provider<CallService>.value(value: MockCallService()),
    Provider<OrganizationDirectory>.value(value: directory),
    Provider<SessionRepository>.value(value: session),
    Provider<EnterOrganization>.value(value: enterOrganization),
    Provider<SignOut>.value(value: signOut),
  ];
  late final SessionRepository session;
  late final SignOut signOut;
  late final EnterOrganization enterOrganization;
  late final GoRouter router;

  /// The path of the screen on top (pushed screens included).
  String get location => router.state.uri.path;
}

/// Opens [app] as `main` and `MonAmieApp` do (the data layer, the session
/// and the use cases provided above the router), on *Login*.
Future<void> _pump(WidgetTester tester, _App app) async {
  // Larger than a phone (800 x 2000): the test font's square glyphs take
  // more room than the real font's (the map's attribution needs ~600).
  tester.view.physicalSize = const Size(1600, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  addTearDown(app.router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: app.dependencies,
      child: MaterialApp.router(routerConfig: app.router),
    ),
  );
  await _settle(tester);
}

/// Lets the navigation and its page transition finish. Not
/// `pumpAndSettle`: *Login* shows an endless spinner while Google Sign-In
/// is not ready.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

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
  provideDummy<Result<List<Invite>>>(const Ok([]));
  provideDummy<Result<AccountDeletion?>>(const Ok(null));
  provideDummy<Result<List<Group>>>(const Ok([]));
  provideDummy<Result<OrganizationAdministrators>>(
    const Ok(OrganizationAdministrators()),
  );
  provideDummy<Result<List<OrganizationTheme>>>(const Ok([]));
  provideDummy<Result<String?>>(const Ok(null));

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
