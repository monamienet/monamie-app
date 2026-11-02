import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/data/repositories/user/user_google_repository.dart';
import 'package:monamie_app/data/services/background_restriction_checker.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/data/services/geolocator_device_location.dart';
import 'package:monamie_app/data/services/method_channel_background_restriction_checker.dart';
import 'package:monamie_app/data/services/method_channel_background_usage_settings_launcher.dart';
import 'package:monamie_app/data/services/permissions_service.dart';
import 'package:monamie_app/domain/models/tracking_settings.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/data/repositories/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/data/repositories/session/session_state.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/group_map_state.dart';
import 'package:monamie_app/ui/home/view_models/permissions_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/routing/organization_scope.dart';
import 'package:monamie_app/routing/routes.dart';
import 'package:monamie_app/routing/session_redirect.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

@GenerateNiceMocks([
  MockSpec<BackgroundTrackingService>(),
  MockSpec<MembershipService>(),
  MockSpec<PermissionsService>(),
  MockSpec<PositionsRepository>(),
  MockSpec<TrackingSettingsRepository>(),
  MockSpec<UserGoogleRepository>(),
])
import 'organization_scope_test.mocks.dart';

/// What the home route's page read, as it builds.
GroupMapState? groupMap;
CalendarViewModel? calendar;
TrackingViewModel? tracking;
PermissionsViewModel? permissions;
TrackingSettingsController? settings;
UserViewModel? user;

/// What the admin route's page read, as it builds.
GroupMapState? adminGroupMap;
UserViewModel? adminUser;
TrackingSettingsController? adminSettings;

/// A router opening on `/start` (outside the organization), with the
/// organization's shell ([OrganizationScope]) holding `/home`, whose page
/// reads the group map, the calendar and the tracking settings, and
/// `/other`, to push over it.
///
/// The data layer comes from [pumpRouter] ([dependencies]). With
/// [withTracking], the page also reads the tracking
/// controller (and so the permissions one).
GoRouter buildRouter({bool withTracking = false}) {
  return GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => const Text('start')),
      ShellRoute(
        builder: (_, _, child) =>
            OrganizationScope(onAccessLost: () async {}, child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, _) {
              groupMap = context.read<GroupMapState>();
              calendar = context.read<CalendarViewModel>();
              settings = context.read<TrackingSettingsController>();
              if (withTracking) {
                tracking = context.read<TrackingViewModel>();
                permissions = context.read<PermissionsViewModel>();
              }
              return const Text('home');
            },
          ),
          GoRoute(path: '/other', builder: (_, _) => const Text('other')),
        ],
      ),
    ],
  );
}

/// A router that follows [session] as the app's does ([sessionRedirect]
/// on every navigation and on every change of [session]), opening on
/// *Login*: the organization's shell ([OrganizationScope]) holds the map,
/// whose page reads every organization controller, and *Grupos*, whose
/// page reads some of them again.
GoRouter buildSessionRouter(ValueNotifier<SessionState> session) {
  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: session,
    redirect: (_, state) => sessionRedirect(session.value, state.uri.path),
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const Text('login')),
      ShellRoute(
        builder: (_, _, child) =>
            OrganizationScope(onAccessLost: () async {}, child: child),
        routes: [
          GoRoute(
            path: Routes.monamie,
            builder: (context, _) {
              groupMap = context.read<GroupMapState>();
              calendar = context.read<CalendarViewModel>();
              settings = context.read<TrackingSettingsController>();
              user = context.read<UserViewModel>();
              tracking = context.read<TrackingViewModel>();
              permissions = context.read<PermissionsViewModel>();
              return const Text('map');
            },
          ),
          GoRoute(
            path: Routes.groups,
            builder: (context, _) {
              adminGroupMap = context.read<GroupMapState>();
              adminUser = context.read<UserViewModel>();
              adminSettings = context.read<TrackingSettingsController>();
              return const Text('groups');
            },
          ),
        ],
      ),
    ],
  );
}

/// Opens [router] and binds [session]: the person is on the map.
Future<void> pumpBound(
  WidgetTester tester,
  GoRouter router,
  ValueNotifier<SessionState> session,
) async {
  addTearDown(session.dispose);
  await pumpRouter(tester, router);
  session.value = const SessionState.bound();
  await tester.pumpAndSettle();
}

/// Opens the app over [router], with [dependencies] above it, as
/// `appDependencies` is in the app.
Future<void> pumpRouter(WidgetTester tester, GoRouter router) async {
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: dependencies(),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

/// The data layer [OrganizationScope] reads. The profile, the tracking
/// settings, the memberships, the positions, the tracking service and the
/// permissions are mocks (nobody signed in, the default settings, no group,
/// the service stopped, every permission denied), which keeps the real
/// tracking and permissions view models the scope builds away from the
/// device; the GPS and the background checks are the app's own.
List<SingleChildWidget> dependencies() {
  final profile = MockUserGoogleRepository();
  when(profile.getUserGoogleModel()).thenAnswer((_) async => null);
  final repository = MockTrackingSettingsRepository();
  when(
    repository.watch(),
  ).thenAnswer((_) => Stream.value(TrackingSettings.defaults));
  final service = MockBackgroundTrackingService();
  when(service.isRunning()).thenAnswer((_) async => false);
  final permissions = MockPermissionsService();
  when(permissions.isGranted(any)).thenAnswer((_) async => false);
  when(permissions.isPermanentlyDenied(any)).thenAnswer((_) async => false);
  when(
    permissions.request(any),
  ).thenAnswer((_) async => AppPermissionStatus.denied);
  return [
    Provider<UserGoogleRepository>.value(value: profile),
    Provider<TrackingSettingsRepository>.value(value: repository),
    Provider<MembershipService>.value(value: MockMembershipService()),
    Provider<PositionsRepository>.value(value: MockPositionsRepository()),
    Provider<BackgroundTrackingService>.value(value: service),
    Provider<PermissionsService>.value(value: permissions),
    Provider<DeviceLocation>.value(value: const GeolocatorDeviceLocation()),
    Provider<BackgroundRestrictionChecker>(
      create: (_) => MethodChannelBackgroundRestrictionChecker(),
    ),
    Provider<BackgroundUsageSettingsLauncher>(
      create: (_) => MethodChannelBackgroundUsageSettingsLauncher(),
    ),
  ];
}

/// Whether [listenable] was disposed (a disposed `ChangeNotifier` refuses
/// new listeners).
bool isDisposed(Listenable listenable) {
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
  setUp(() {
    groupMap = null;
    calendar = null;
    tracking = null;
    permissions = null;
    settings = null;
    user = null;
    adminGroupMap = null;
    adminUser = null;
    adminSettings = null;
  });

  group('OrganizationScope (organization shell) - Widget Test Suite', () {
    testWidgets('Happy Path: leaving the shell disposes the group map and the '
        'calendar it created', (tester) async {
      // 1. Arrange
      final router = buildRouter();
      await pumpRouter(tester, router);
      router.go('/home');
      await tester.pumpAndSettle();

      // 2. Act
      router.go('/start');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(groupMap!.mapGroups), isTrue);
      expect(isDisposed(calendar!.observedDay), isTrue);
    });

    testWidgets('Edge Case: a route pushed over the home inside the shell '
        'keeps its controllers alive', (tester) async {
      // 1. Arrange
      final router = buildRouter();
      await pumpRouter(tester, router);
      router.go('/home');
      await tester.pumpAndSettle();

      // 2. Act
      router.push('/other');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(groupMap!.mapGroups), isFalse);
      expect(isDisposed(calendar!.observedDay), isFalse);
    });

    testWidgets('Sad Path: a group map whose shell closed is not handed out '
        'again', (tester) async {
      // 1. Arrange
      final router = buildRouter();
      await pumpRouter(tester, router);
      router.go('/home');
      await tester.pumpAndSettle();
      final first = groupMap;
      router.go('/start');
      await tester.pumpAndSettle();

      // 2. Act
      router.go('/home');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(groupMap, isNot(same(first)));
      expect(isDisposed(groupMap!.mapGroups), isFalse);
    });

    testWidgets('Happy Path: leaving the shell disposes the tracking '
        'controller it created', (tester) async {
      // 1. Arrange
      final router = buildRouter(withTracking: true);
      await pumpRouter(tester, router);
      router.go('/home');
      await tester.pumpAndSettle();

      // 2. Act
      router.go('/start');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(tracking!.firebaseUsers), isTrue);
    });

    testWidgets('Happy Path: leaving the shell disposes the permissions '
        'controller it created', (tester) async {
      // 1. Arrange
      final router = buildRouter(withTracking: true);
      await pumpRouter(tester, router);
      router.go('/home');
      await tester.pumpAndSettle();

      // 2. Act
      router.go('/start');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(permissions!.isBackgroundRestricted), isTrue);
    });

    testWidgets('Happy Path: leaving the shell disposes the tracking '
        'settings it created', (tester) async {
      // 1. Arrange
      final router = buildRouter(withTracking: true);
      await pumpRouter(tester, router);
      router.go('/home');
      await tester.pumpAndSettle();

      // 2. Act
      router.go('/start');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(settings!.settings), isTrue);
    });

    testWidgets('Edge Case: a route pushed over the home inside the shell '
        'keeps the tracking controller alive', (tester) async {
      // 1. Arrange
      final router = buildRouter(withTracking: true);
      await pumpRouter(tester, router);
      router.go('/home');
      await tester.pumpAndSettle();

      // 2. Act
      router.push('/other');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(tracking!.firebaseUsers), isFalse);
      expect(isDisposed(permissions!.isBackgroundRestricted), isFalse);
      // The tracking controller's validity clock keeps running: leave the
      // shell so it stops before the test ends.
      router.go('/start');
      await tester.pumpAndSettle();
    });
  });

  group('OrganizationScope under the session redirect - Widget Test Suite', () {
    testWidgets('Happy Path: signing out (the session leaves bound) disposes '
        'every organization controller', (tester) async {
      // 1. Arrange
      final session = ValueNotifier<SessionState>(
        const SessionState.signedOut(),
      );
      final router = buildSessionRouter(session);
      await pumpBound(tester, router, session);

      // 2. Act
      session.value = const SessionState.signedOut();
      await tester.pumpAndSettle();

      // 3. Assert
      expect(find.text('login'), findsOneWidget);
      expect(isDisposed(groupMap!.mapGroups), isTrue);
      expect(isDisposed(calendar!.observedDay), isTrue);
      expect(isDisposed(user!), isTrue);
      expect(isDisposed(permissions!.isBackgroundRestricted), isTrue);
      expect(isDisposed(tracking!.firebaseUsers), isTrue);
      expect(isDisposed(settings!.settings), isTrue);
    });

    testWidgets('Edge Case: an admin screen pushed over the map reads the '
        "map's very controllers", (tester) async {
      // 1. Arrange
      final session = ValueNotifier<SessionState>(
        const SessionState.signedOut(),
      );
      final router = buildSessionRouter(session);
      await pumpBound(tester, router, session);

      // 2. Act
      router.push(Routes.groups);
      await tester.pumpAndSettle();

      // 3. Assert
      expect(adminGroupMap, same(groupMap));
      expect(adminUser, same(user));
      expect(adminSettings, same(settings));
      expect(isDisposed(user!), isFalse);
      // The tracking controller's validity clock keeps running: leave the
      // shell so it stops before the test ends.
      session.value = const SessionState.signedOut();
      await tester.pumpAndSettle();
    });

    testWidgets('Sad Path: signing in again after a sign-out creates new '
        'organization controllers', (tester) async {
      // 1. Arrange
      final session = ValueNotifier<SessionState>(
        const SessionState.signedOut(),
      );
      final router = buildSessionRouter(session);
      await pumpBound(tester, router, session);
      final firstCalendar = calendar;
      final firstUser = user;
      final firstTracking = tracking;
      final firstSettings = settings;
      session.value = const SessionState.signedOut();
      await tester.pumpAndSettle();

      // 2. Act
      session.value = const SessionState.bound();
      await tester.pumpAndSettle();

      // 3. Assert
      expect(calendar, isNot(same(firstCalendar)));
      expect(user, isNot(same(firstUser)));
      expect(tracking, isNot(same(firstTracking)));
      expect(settings, isNot(same(firstSettings)));
      expect(isDisposed(user!), isFalse);
      expect(isDisposed(settings!.settings), isFalse);
      session.value = const SessionState.signedOut();
      await tester.pumpAndSettle();
    });
  });
}
