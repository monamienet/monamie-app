import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/repository/user_google_repository.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/bindings/monamie_bindings.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';

@GenerateNiceMocks([
  MockSpec<GroupMapState>(),
  MockSpec<NoticePresenter>(),
  MockSpec<TrackingSettingsRepository>(),
  MockSpec<UserGoogleRepository>(),
])
import 'monamie_bindings_test.mocks.dart';

/// What the home route's page found, as it builds.
GroupMapState? groupMap;
CalendarController? calendar;
TrackingController? tracking;
PermissionsController? permissions;

/// An app opening on `/start`, with the home route (`/home`, bound by
/// [MonamieBindings]) whose page finds the group map and the calendar, and
/// an `/other` route to push over it.
///
/// The sign-in controller (never started, so it touches no plugin) and the
/// tracking settings are registered first (permanent), so the binding
/// neither builds and starts the real ones (Google Sign-In, Firestore) nor
/// deletes them with the route. (Mockito cannot generate a mock of
/// [AuthGoogleController].)
///
/// With [withTracking], the page also finds the tracking controller (and so
/// the permissions one), and the binding creates the tracking settings
/// itself: see [tracked].
Widget buildApp({bool withTracking = false}) {
  Get.put(
    AuthGoogleController(notices: MockNoticePresenter()),
    permanent: true,
  );
  if (withTracking) {
    tracked();
  } else {
    final settings = MockTrackingSettingsRepository();
    when(
      settings.watch(),
    ).thenAnswer((_) => Stream.value(TrackingSettings.defaults));
    Get.put(TrackingSettingsController(repository: settings), permanent: true);
  }
  return GetMaterialApp(
    initialRoute: '/start',
    getPages: [
      GetPage(name: '/start', page: () => const Text('start')),
      GetPage(
        name: '/home',
        binding: MonamieBindings(),
        page: () => Builder(
          builder: (_) {
            groupMap = Get.find<GroupMapState>();
            calendar = Get.find<CalendarController>();
            if (withTracking) {
              tracking = Get.find<TrackingController>();
              permissions = Get.find<PermissionsController>();
            }
            return const Text('home');
          },
        ),
      ),
      GetPage(name: '/other', page: () => const Text('other')),
    ],
  );
}

/// Prepares the real tracking and permissions controllers the binding
/// builds, so they touch no device: the person (a [UserController] over a
/// mocked profile, registered first and permanent so the binding keeps it)
/// shares nowhere, the tracking service answers "stopped" and every
/// permission "denied". The tracking settings are not registered: the
/// binding builds the Firestore-backed one, whose failures it swallows.
void tracked() {
  final profile = MockUserGoogleRepository();
  when(profile.getUserGoogleModel()).thenAnswer((_) async => null);
  Get.put(
    UserController(groupMap: MockGroupMapState(), repository: profile),
    permanent: true,
  );
  FlutterBackgroundServiceAndroid.registerWith();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_serviceChannel, (call) async => false);
  messenger.setMockMethodCallHandler(_permissionChannel, (call) async => 0);
}

/// The tracking service plugin's channel (Android).
const _serviceChannel = MethodChannel(
  'id.flutter/background_service/android/method',
  JSONMethodCodec(),
);

/// The permission_handler plugin's channel.
const _permissionChannel = MethodChannel(
  'flutter.baseflow.com/permissions/methods',
);

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
    Get.testMode = true;
    groupMap = null;
    calendar = null;
    tracking = null;
    permissions = null;
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_serviceChannel, null);
    messenger.setMockMethodCallHandler(_permissionChannel, null);
    Get.reset();
  });

  group('MonamieBindings (home scope) - Widget Test Suite', () {
    testWidgets(
      'Happy Path: closing the home route disposes the group map and the '
      'calendar it created',
      (tester) async {
        // 1. Arrange
        await tester.pumpWidget(buildApp());
        Get.toNamed<void>('/home');
        await tester.pumpAndSettle();

        // 2. Act
        Get.back<void>();
        await tester.pumpAndSettle();

        // 3. Assert
        expect(isDisposed(groupMap!.mapGroups), isTrue);
        expect(isDisposed(calendar!.observedDay), isTrue);
      },
    );

    testWidgets('Edge Case: a route pushed over the home keeps its '
        'controllers alive', (tester) async {
      // 1. Arrange
      await tester.pumpWidget(buildApp());
      Get.toNamed<void>('/home');
      await tester.pumpAndSettle();

      // 2. Act
      Get.toNamed<void>('/other');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(groupMap!.mapGroups), isFalse);
      expect(isDisposed(calendar!.observedDay), isFalse);
    });

    testWidgets('Sad Path: a group map whose route closed is not handed out '
        'again', (tester) async {
      // 1. Arrange
      await tester.pumpWidget(buildApp());
      Get.toNamed<void>('/home');
      await tester.pumpAndSettle();
      final first = groupMap;
      Get.back<void>();
      await tester.pumpAndSettle();

      // 2. Act
      Get.toNamed<void>('/home');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(groupMap, isNot(same(first)));
      expect(isDisposed(groupMap!.mapGroups), isFalse);
    });

    testWidgets('Happy Path: closing the home route disposes the tracking '
        'controller it created', (tester) async {
      // 1. Arrange
      await tester.pumpWidget(buildApp(withTracking: true));
      Get.toNamed<void>('/home');
      await tester.pumpAndSettle();

      // 2. Act
      Get.back<void>();
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(tracking!.firebaseUsers), isTrue);
    });

    testWidgets('Happy Path: closing the home route disposes the permissions '
        'controller it created', (tester) async {
      // 1. Arrange
      await tester.pumpWidget(buildApp(withTracking: true));
      Get.toNamed<void>('/home');
      await tester.pumpAndSettle();

      // 2. Act
      Get.back<void>();
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(permissions!.isBackgroundRestricted), isTrue);
    });

    testWidgets('Happy Path: closing the home route disposes the tracking '
        'settings it created', (tester) async {
      // 1. Arrange
      await tester.pumpWidget(buildApp(withTracking: true));
      Get.toNamed<void>('/home');
      await tester.pumpAndSettle();
      final settings = Get.find<TrackingSettingsController>();

      // 2. Act
      Get.back<void>();
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(settings.settings), isTrue);
    });

    testWidgets('Edge Case: a route pushed over the home keeps the tracking '
        'controller alive', (tester) async {
      // 1. Arrange
      await tester.pumpWidget(buildApp(withTracking: true));
      Get.toNamed<void>('/home');
      await tester.pumpAndSettle();

      // 2. Act
      Get.toNamed<void>('/other');
      await tester.pumpAndSettle();

      // 3. Assert
      expect(isDisposed(tracking!.firebaseUsers), isFalse);
      expect(isDisposed(permissions!.isBackgroundRestricted), isFalse);
      // The tracking controller's validity clock keeps running.
      Get.back<void>();
      Get.back<void>();
      await tester.pumpAndSettle();
    });
  });
}
