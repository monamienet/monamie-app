import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/organization/organization_binder.dart';
import 'package:monamie_app/app/data/organization/organization_local_data.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/services/background_tracking_stopper.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_controller.dart';
import 'package:monamie_app/app/modules/admin/groups/groups_views.dart';
import 'package:monamie_app/app/modules/creation/create_organization_view.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/login/services/auth_google_service.dart';
import 'package:monamie_app/app/modules/login/views/login_view.dart';
import 'package:monamie_app/app/modules/login/views/no_organization_view.dart';
import 'package:monamie_app/app/modules/monamie/ui/monamie_page.dart';
import 'package:monamie_app/app/routes/app_router.dart';
import 'package:monamie_app/app/routes/app_routes.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

@GenerateNiceMocks([
  MockSpec<AuthGoogleService>(),
  MockSpec<BackgroundTrackingStopper>(),
  MockSpec<NoticePresenter>(),
  MockSpec<OrganizationBinder>(),
  MockSpec<OrganizationLocalData>(),
  MockSpec<UserGoogleRepository>(),
])
import 'app_router_test.mocks.dart';

/// The app's router ([buildAppRouter]) over a real [AuthGoogleController]
/// whose services are mocks; never started, so Google Sign-In is never
/// initialized. The session moves only through the controller's own
/// methods: [AuthGoogleController.sessionRestored] (what *Login* calls for
/// a remembered session) binds it, [AuthGoogleController.logout] signs out
/// and [AuthGoogleController.forgetRemovedOrganization] leads to *Sem
/// organização*.
class _App {
  _App() {
    when(stopper.stop(email: anyNamed('email'))).thenAnswer((_) async => true);
    auth = AuthGoogleController(
      notices: MockNoticePresenter(),
      refreshTheme: () {},
      authGoogleService: MockAuthGoogleService(),
      userRepository: MockUserGoogleRepository(),
      trackingStopper: stopper,
      organizationSession: MockOrganizationBinder(),
      organizationLocalData: MockOrganizationLocalData(),
    );
    router = buildAppRouter(auth: auth);
  }

  final stopper = MockBackgroundTrackingStopper();
  late final AuthGoogleController auth;
  late final GoRouter router;

  /// The path of the screen on top (pushed screens included).
  String get location => router.state.uri.path;
}

/// Opens [app] as `MonAmieApp` does (the controller provided above the
/// router), on *Login*.
Future<void> _pump(WidgetTester tester, _App app) async {
  // Larger than a phone (540 x 2000): the test font's square glyphs take
  // more room than the real font's.
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  addTearDown(app.router.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<AuthGoogleController>.value(
      value: app.auth,
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
  app.auth.sessionRestored();
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

/// The tracking service plugin's channel (Android).
const _serviceChannel = MethodChannel(
  'id.flutter/background_service/android/method',
  JSONMethodCodec(),
);

/// The permission_handler plugin's channel.
const _permissionChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);

void main() {
  // The organization's scope builds the real profile store (Hive), the
  // tracking service and the permissions: Hive gets a scratch folder, the
  // service answers "stopped" and every permission "denied".
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('app_router_test').path);
  });

  setUp(() {
    // *Aparência* keeps the saved branding through the device's
    // preferences.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    FlutterBackgroundServiceAndroid.registerWith();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_serviceChannel, (_) async => false);
    messenger.setMockMethodCallHandler(_permissionChannel, (_) async => 0);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_serviceChannel, null);
    messenger.setMockMethodCallHandler(_permissionChannel, null);
  });

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
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('Happy Path: a session restored on Login opens the map', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();
      await _pump(tester, app);

      // 2. Act
      app.auth.sessionRestored();
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.monamie);
      expect(find.byType(MonamiePage), findsOneWidget);
      expect(find.byType(LoginView), findsNothing);
    });

    testWidgets('Happy Path: signing out from the map opens Login', (
      tester,
    ) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);

      // 2. Act
      await app.auth.logout();
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.login);
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(MonamiePage), findsNothing);
    });

    testWidgets('Edge Case: losing access to the organization opens Sem '
        'organização', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);

      // 2. Act
      await app.auth.forgetRemovedOrganization();
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.noOrganization);
      expect(find.byType(NoOrganizationView), findsOneWidget);
    });

    testWidgets('Edge Case: signing out from a screen pushed over the map '
        'opens Login with nothing under it', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);

      // 2. Act
      await app.auth.logout();
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
      expect(find.byType(GroupsView), findsNothing);
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
      expect(find.byType(MonamiePage), findsOneWidget);
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
      expect(find.byType(MonamiePage), findsOneWidget);
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
      expect(find.byType(LoginView), findsOneWidget);
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
        expect(find.byType(MonamiePage), findsOneWidget);
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
        expect(find.byType(GroupsView), findsOneWidget);
      });
    }

    testWidgets('Happy Path: Novo grupo pushed with the Grupos controller '
        'opens on that same controller', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      app.router.push(Routes.groups);
      await _settle(tester);
      final groups = tester.widget<GroupsView>(find.byType(GroupsView));

      // 2. Act
      app.router.push(Routes.newGroup, extra: groups.controller);
      await _settle(tester);

      // 3. Assert
      expect(app.location, Routes.newGroup);
      final created = tester.widget<CreateGroupView>(
        find.byType(CreateGroupView),
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
      final groups = tester.widget<GroupsView>(find.byType(GroupsView));

      // 2. Act
      app.router.push(Routes.group('Xk3pQ9vL2mN7'), extra: groups.controller);
      await _settle(tester);

      // 3. Assert
      final group = tester.widget<GroupView>(find.byType(GroupView));
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
      final GroupsController controller = tester
          .widget<GroupsView>(find.byType(GroupsView))
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
      final GroupsController controller = tester
          .widget<GroupsView>(find.byType(GroupsView))
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
      final GroupsController controller = tester
          .widget<GroupsView>(find.byType(GroupsView))
          .controller;

      // 2. Act
      await app.auth.logout();
      await _settle(tester);

      // 3. Assert
      expect(_isDisposed(controller), isTrue);
    });

    testWidgets('Happy Path: closing Criar organização disposes its '
        'controller and returns to Sem organização', (tester) async {
      // 1. Arrange
      final app = _App();
      await _pumpBound(tester, app);
      await app.auth.forgetRemovedOrganization();
      await _settle(tester);
      app.router.go(Routes.createOrganizationOver(Routes.noOrganization));
      await _settle(tester);
      final controller = tester
          .widget<CreateOrganizationView>(find.byType(CreateOrganizationView))
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
