import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_controller.dart';
import 'package:monamie_app/app/data/tracking/tracking_settings_repository.dart';
import 'package:monamie_app/app/modules/login/controllers/auth_google_controller.dart';
import 'package:monamie_app/app/modules/monamie/bindings/monamie_bindings.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';

@GenerateNiceMocks([
  MockSpec<NoticePresenter>(),
  MockSpec<TrackingSettingsRepository>(),
])
import 'monamie_bindings_test.mocks.dart';

/// What the home route's page found, as it builds.
GroupMapState? groupMap;
CalendarController? calendar;

/// An app opening on `/start`, with the home route (`/home`, bound by
/// [MonamieBindings]) whose page finds the group map and the calendar, and
/// an `/other` route to push over it.
///
/// The sign-in controller (never started, so it touches no plugin) and the
/// tracking settings are registered first (permanent), so the binding
/// neither builds and starts the real ones (Google Sign-In, Firestore) nor
/// deletes them with the route. (Mockito cannot generate a mock of
/// [AuthGoogleController].)
Widget buildApp() {
  final settings = MockTrackingSettingsRepository();
  when(
    settings.watch(),
  ).thenAnswer((_) => Stream.value(TrackingSettings.defaults));
  Get.put(
    AuthGoogleController(notices: MockNoticePresenter()),
    permanent: true,
  );
  Get.put(TrackingSettingsController(repository: settings), permanent: true);
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
            return const Text('home');
          },
        ),
      ),
      GetPage(name: '/other', page: () => const Text('other')),
    ],
  );
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
    Get.testMode = true;
    groupMap = null;
    calendar = null;
  });

  tearDown(Get.reset);

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
  });
}
