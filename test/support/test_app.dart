import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/account/account_deletion_repository.dart';
import 'package:monamie_app/data/repositories/administrators/administrators_repository.dart';
import 'package:monamie_app/data/repositories/appearance/appearance_repository.dart';
import 'package:monamie_app/data/repositories/creation/creation_repository.dart';
import 'package:monamie_app/data/repositories/groups/groups_repository.dart';
import 'package:monamie_app/data/repositories/invites/invites_repository.dart';
import 'package:monamie_app/data/repositories/organization/organization_branding_loader.dart';
import 'package:monamie_app/data/repositories/organization/organization_directory.dart';
import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';
import 'package:monamie_app/data/repositories/organization/organization_session.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/data/repositories/session/session_repository.dart';
import 'package:monamie_app/data/repositories/theme/theme_repository.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/auth/google_bond_check.dart';
import 'package:monamie_app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/call_service.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/services/permissions_service.dart';
import 'package:monamie_app/domain/use_cases/enter_organization.dart';
import 'package:monamie_app/domain/use_cases/sign_out.dart';
import 'package:monamie_app/routing/router.dart';
import 'package:monamie_app/utils/notice_presenter.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../testing/fakes/repositories/fake_account_deletion_repository.dart';
import '../../testing/fakes/repositories/fake_administrators_repository.dart';
import '../../testing/fakes/repositories/fake_appearance_repository.dart';
import '../../testing/fakes/repositories/fake_creation_repository.dart';
import '../../testing/fakes/repositories/fake_groups_repository.dart';
import '../../testing/fakes/repositories/fake_invites_repository.dart';
import '../../testing/fakes/repositories/fake_organization_branding_loader.dart';
import '../../testing/fakes/repositories/fake_organization_directory.dart';
import '../../testing/fakes/repositories/fake_organization_local_data.dart';
import '../../testing/fakes/repositories/fake_organization_session.dart';
import '../../testing/fakes/repositories/fake_positions_repository.dart';
import '../../testing/fakes/repositories/fake_session_repository.dart';
import '../../testing/fakes/repositories/fake_theme_repository.dart';
import '../../testing/fakes/repositories/fake_user_google_repository.dart';

@GenerateNiceMocks([
  MockSpec<BackgroundRestrictionChecker>(),
  MockSpec<BackgroundTrackingService>(),
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<BackgroundUsageSettingsLauncher>(),
  MockSpec<CallService>(),
  MockSpec<DeviceLocation>(),
  MockSpec<GoogleBondCheck>(),
  MockSpec<MembershipService>(),
  MockSpec<NoticePresenter>(),
  MockSpec<PermissionsService>(),
])
import 'test_app.mocks.dart';

/// The app's real router ([buildAppRouter]) and real use cases
/// ([EnterOrganization], [SignOut]) over the in-memory repositories of
/// `testing/fakes/repositories/` and mockito mocks of the services (the
/// plugins' edge). [dependencies] stands for `appDependencies`: what the
/// routes and the organization's scope read, each under the type the
/// composition root provides it.
///
/// Nothing reaches Firebase or a plugin: the scope's own Firestore-backed
/// repositories read the [memberships] mock (no data) and, with no
/// organization project bound, keep their defaults. Every permission is
/// denied, the tracking stops at once, and Google answers as
/// [FakeSessionRepository] is set up.
class TestApp {
  TestApp({bool googleReady = false})
    : session = FakeSessionRepository(googleReady: googleReady) {
    when(stopper.stop(email: anyNamed('email'))).thenAnswer((_) async => true);
    when(permissions.isGranted(any)).thenAnswer((_) async => false);
    when(permissions.isPermanentlyDenied(any)).thenAnswer((_) async => false);
    when(
      permissions.request(any),
    ).thenAnswer((_) async => AppPermissionStatus.denied);
    signOut = SignOut(
      session: session,
      trackingStopper: stopper,
      userRepository: userRepository,
      binder: organizationSession,
      localData: localData,
      directory: directory,
      brandingLoader: brandingLoader,
      invites: invites,
      notices: notices,
    );
    enterOrganization = EnterOrganization(
      session: session,
      directory: directory,
      brandingLoader: brandingLoader,
      binder: organizationSession,
      memberships: memberships,
      userRepository: userRepository,
      deletions: deletion,
      invites: invites,
    );
    router = buildAppRouter(session: session);
  }

  // The repositories, in memory.
  final FakeSessionRepository session;
  final directory = FakeOrganizationDirectory();
  final brandingLoader = FakeOrganizationBrandingLoader();
  final organizationSession = FakeOrganizationSession();
  final localData = FakeOrganizationLocalData();
  final userRepository = FakeUserGoogleRepository();
  final invites = FakeInvitesRepository();
  final deletion = FakeAccountDeletionRepository();
  final groups = FakeGroupsRepository();
  final administrators = FakeAdministratorsRepository();
  final appearance = FakeAppearanceRepository();
  final creation = FakeCreationRepository();
  final positions = FakePositionsRepository();
  final themes = FakeThemeRepository();

  // The services, mocks.
  final stopper = MockBackgroundTrackingStopper();
  final permissions = MockPermissionsService();
  final memberships = MockMembershipService();
  final bondCheck = MockGoogleBondCheck();
  final notices = MockNoticePresenter();

  late final SignOut signOut;
  late final EnterOrganization enterOrganization;
  late final GoRouter router;

  /// The data layer the routes and the organization's scope read, as
  /// `appDependencies` provides it in the app (the same types).
  late final List<SingleChildWidget> dependencies = [
    Provider<UserGoogleRepository>.value(value: userRepository),
    Provider<SessionRepository>.value(value: session),
    Provider<OrganizationSession>.value(value: organizationSession),
    Provider<ThemeRepository>.value(value: themes),
    Provider<OrganizationBrandingLoader>.value(value: brandingLoader),
    Provider<OrganizationDirectory>.value(value: directory),
    Provider<OrganizationLocalData>.value(value: localData),
    Provider<MembershipService>.value(value: memberships),
    Provider<PositionsRepository>.value(value: positions),
    Provider<GoogleBondCheck>.value(value: bondCheck),
    Provider<BackgroundTrackingService>.value(
      value: MockBackgroundTrackingService(),
    ),
    Provider<BackgroundTrackingStopper>.value(value: stopper),
    Provider<InvitesRepository>.value(value: invites),
    Provider<AccountDeletionRepository>.value(value: deletion),
    Provider<GroupsRepository>.value(value: groups),
    Provider<AdministratorsRepository>.value(value: administrators),
    Provider<AppearanceRepository>.value(value: appearance),
    Provider<CreationRepository>.value(value: creation),
    Provider<DeviceLocation>.value(value: MockDeviceLocation()),
    Provider<PermissionsService>.value(value: permissions),
    Provider<BackgroundRestrictionChecker>.value(
      value: MockBackgroundRestrictionChecker(),
    ),
    Provider<BackgroundUsageSettingsLauncher>.value(
      value: MockBackgroundUsageSettingsLauncher(),
    ),
    Provider<CallService>.value(value: MockCallService()),
    Provider<EnterOrganization>.value(value: enterOrganization),
    Provider<SignOut>.value(value: signOut),
  ];

  /// The path of the screen on top (pushed screens included).
  String get location => router.state.uri.path;

  /// Opens the app as `main` and `MonAmieApp` do (the data layer, the
  /// session and the use cases provided above the router), on *Login*.
  Future<void> pump(WidgetTester tester) async {
    // Larger than a phone (800 x 2000): the test font's square glyphs take
    // more room than the real font's (the map's attribution needs ~600).
    tester.view.physicalSize = const Size(1600, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    addTearDown(router.dispose);
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: dependencies,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await settle(tester);
  }

  /// Lets the navigation and its page transition finish. Not
  /// `pumpAndSettle`: *Login* shows an endless spinner while Google Sign-In
  /// is not ready, and the map keeps animating.
  static Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}
