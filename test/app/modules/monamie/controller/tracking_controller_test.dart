import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/data/services/device_location.dart';
import 'package:monamie_app/app/modules/monamie/controller/calendar_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/group_map_state.dart';
import 'package:monamie_app/app/modules/monamie/controller/permissions_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_controller.dart';
import 'package:monamie_app/app/modules/monamie/controller/user_controller.dart';
import 'package:monamie_app/app/modules/monamie/data/provider/firebase_provider.dart';
import 'package:monamie_app/app/modules/monamie/models/group_member.dart';
import 'package:monamie_app/app/modules/monamie/models/location_point.dart';
import 'package:monamie_app/app/modules/monamie/models/map_group.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';
import 'package:monamie_app/app/utils/notice_presenter.dart';
import 'package:monamie_app/app/utils/result.dart';
import 'package:monamie_app/app/utils/user_notice.dart';

@GenerateNiceMocks([
  MockSpec<CalendarController>(),
  MockSpec<DeviceLocation>(),
  MockSpec<FirebaseProvider>(),
  MockSpec<FlutterBackgroundService>(),
  MockSpec<GroupMapState>(),
  MockSpec<NoticePresenter>(),
  MockSpec<PermissionsController>(),
  MockSpec<UserController>(),
])
import 'tracking_controller_test.mocks.dart';

const _kEmail = 'ana@example.com';
const _kGroup = MapGroup(id: 'g1', name: 'Equipe Norte');
const _kBia = GroupMember(name: 'Bia', email: 'bia@example.com');
final _kToday = DateTime(2026, 11, 2);
final _kPastDay = DateTime(2026, 10, 30);

Position _position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime(2026, 11, 2, 9),
  accuracy: 0,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

LocationPoint _point(double lat, double lng) =>
    LocationPoint(lat: lat, lng: lng, receivedAt: DateTime(2026, 10, 30, 9));

/// An [Err] titled [title].
Matcher _errTitled(String title) =>
    isA<Err<Object?>>().having((err) => err.title, 'title', title);

/// An [Ok] holding a [UserNotice] titled [title].
Matcher _okWithNoticeTitled(String title) => isA<Ok<UserNotice?>>().having(
  (ok) => ok.value?.title,
  'notice title',
  title,
);

/// The collaborators of a [TrackingController], stubbed as a person who can
/// publish, with the GPS on, the service stopped and a fix at hand.
class _Harness {
  _Harness() {
    when(permissions.isBackgroundRestricted).thenReturn(isBackgroundRestricted);
    when(
      permissions.hasWhenInUseLocationPermission,
    ).thenReturn(hasWhenInUsePermission);
    when(
      permissions.refreshBackgroundRestriction(),
    ).thenAnswer((_) async => false);

    when(calendar.observedDay).thenReturn(observedDay);
    when(calendar.isObservingToday).thenReturn(true);

    when(groupMap.capabilities).thenReturn(capabilities);
    when(groupMap.groupPositions).thenReturn(groupPositions);
    when(groupMap.observedMembers).thenReturn(observedMembers);
    when(groupMap.highlightedObservedUsers).thenReturn(highlighted);
    when(groupMap.selectedGroup).thenReturn(selectedGroup);
    when(groupMap.canPublish).thenReturn(true);
    when(groupMap.canWatch).thenReturn(true);
    when(groupMap.loadHistoryMembers()).thenAnswer((_) async => const []);

    when(user.user).thenReturn(UserModel(email: _kEmail, name: 'Ana'));
    when(user.getUserName()).thenReturn('Ana');
    when(user.isTrackable()).thenReturn(false);

    when(service.isRunning()).thenAnswer((_) async => false);
    when(service.startService()).thenAnswer((_) async => true);
    when(
      service.configure(
        iosConfiguration: anyNamed('iosConfiguration'),
        androidConfiguration: anyNamed('androidConfiguration'),
      ),
    ).thenAnswer((_) async => true);
    when(service.on(any)).thenAnswer((_) => const Stream.empty());

    when(location.isServiceEnabled()).thenAnswer((_) async => true);
    when(
      location.currentPosition(),
    ).thenAnswer((_) async => _position(-22.9, -43.1));

    when(positions.markNotPublishing(any)).thenAnswer((_) async {});
    when(
      positions.getTrajectoryForDate(any, any, day: anyNamed('day')),
    ).thenAnswer((_) => const Stream.empty());
    when(
      positions.hasPointsOnDate(any, any, any),
    ).thenAnswer((_) async => false);
    when(
      positions.getLastKnownPositionForDate(any, any, day: anyNamed('day')),
    ).thenAnswer((_) async => null);

    controller = TrackingController(
      notices: notices,
      userCtrl: user,
      permissionsCtrl: permissions,
      calendar: calendar,
      groupMap: groupMap,
      service: service,
      location: location,
      positions: positions,
    );
  }

  final notices = MockNoticePresenter();
  final user = MockUserController();
  final permissions = MockPermissionsController();
  final calendar = MockCalendarController();
  final groupMap = MockGroupMapState();
  final service = MockFlutterBackgroundService();
  final location = MockDeviceLocation();
  final positions = MockFirebaseProvider();

  final isBackgroundRestricted = false.obs;
  final hasWhenInUsePermission = false.obs;
  final observedDay = Rx<DateTime>(_kToday);
  final capabilities = Rx<Capabilities>(const Capabilities());
  final groupPositions = <UserModel>[].obs;
  final observedMembers = <GroupMember>[].obs;
  final highlighted = <GroupMember>[].obs;
  final selectedGroup = Rxn<MapGroup>(_kGroup);

  late final TrackingController controller;
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  group('TrackingController.toggleService', () {
    test(
      'Edge Case: Deve devolver Ok(null) sem consultar o serviço de novo quando outro toggle está em andamento',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final running = Completer<bool>();
        when(harness.service.isRunning()).thenAnswer((_) => running.future);
        final first = harness.controller.toggleService();

        // 2. Act
        final second = await harness.controller.toggleService();

        // 3. Assert
        expect(
          second,
          isA<Ok<UserNotice?>>().having((ok) => ok.value, 'value', isNull),
        );
        verify(harness.service.isRunning()).called(1);
        running.complete(true);
        await first;
      },
    );

    test(
      'Edge Case: Deve marcar isTrackingLoading enquanto o toggle está em andamento',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final running = Completer<bool>();
        when(harness.service.isRunning()).thenAnswer((_) => running.future);

        // 2. Act
        final pending = harness.controller.toggleService();

        // 3. Assert
        expect(harness.controller.isTrackingLoading.value, isTrue);
        running.complete(true);
        await pending;
      },
    );

    test(
      'Happy Path: Deve parar o serviço e marcar a pessoa como não publicando quando ele está rodando',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.service.isRunning()).thenAnswer((_) async => true);
        harness.controller.isTrackingEnabled.value = true;

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, isA<Ok<UserNotice?>>());
        verify(harness.service.invoke('stopService'));
        verify(harness.positions.markNotPublishing(_kEmail)).called(1);
        verifyNever(harness.service.startService());
        expect(harness.controller.isTrackingEnabled.value, isFalse);
        expect(harness.controller.isTrackingLoading.value, isFalse);
      },
    );

    test(
      'Edge Case: Deve desligar o compartilhamento mesmo quando gravar isPublishing falha',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.service.isRunning()).thenAnswer((_) async => true);
        when(
          harness.positions.markNotPublishing(any),
        ).thenAnswer((_) async => throw StateError('sem rede'));
        harness.controller.isTrackingEnabled.value = true;

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, isA<Ok<UserNotice?>>());
        expect(harness.controller.isTrackingEnabled.value, isFalse);
      },
    );

    test(
      'Happy Path: Deve iniciar o serviço, ligar isTrackingEnabled e guardar a posição quando há GPS',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(
          result,
          isA<Ok<UserNotice?>>().having((ok) => ok.value, 'value', isNull),
        );
        verify(harness.service.startService()).called(1);
        expect(harness.controller.isTrackingEnabled.value, isTrue);
        expect(
          harness.controller.ownPosition.value,
          const LatLng(-22.9, -43.1),
        );
        expect(
          harness.controller.usersWithPointsOnObservedDay,
          contains(_kEmail),
        );
        expect(harness.controller.isTrackingLoading.value, isFalse);
      },
    );

    test(
      'Happy Path: Deve enviar e-mail e nome ao serviço quando ele avisa que está pronto',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final ready = StreamController<Map<String, dynamic>?>();
        when(harness.service.on('ready')).thenAnswer((_) => ready.stream);
        await harness.controller.toggleService();

        // 2. Act
        ready.add(null);
        await pumpEventQueue();

        // 3. Assert
        verify(
          harness.service.invoke('setUserInfo', {
            'email': _kEmail,
            'name': 'Ana',
          }),
        ).called(1);
        await ready.close();
      },
    );

    test(
      'Edge Case: Deve abrir as configurações de uso em segundo plano sem iniciar o serviço quando o app está restrito',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.permissions.refreshBackgroundRestriction(),
        ).thenAnswer((_) async => true);

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, isA<Ok<UserNotice?>>());
        verify(harness.permissions.openBackgroundUsageSettings()).called(1);
        verifyNever(harness.service.startService());
        expect(harness.controller.isTrackingEnabled.value, isFalse);
      },
    );

    test(
      'Sad Path: Deve avisar que o GPS está desligado sem iniciar o serviço',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.location.isServiceEnabled(),
        ).thenAnswer((_) async => false);

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, isA<Ok<UserNotice?>>());
        verify(harness.permissions.notifyGpsDisabled()).called(1);
        verifyNever(harness.service.startService());
        expect(harness.controller.isTrackingEnabled.value, isFalse);
      },
    );

    test(
      'Sad Path: Deve devolver Err sem iniciar o serviço quando a pessoa não publica em nenhum grupo',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.groupMap.canPublish).thenReturn(false);

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, _errTitled('Compartilhamento não autorizado'));
        verifyNever(harness.service.startService());
        expect(harness.controller.isTrackingEnabled.value, isFalse);
      },
    );

    test(
      'Edge Case: Deve iniciar o serviço e devolver o aviso de satélites quando o GPS não responde em 5 segundos',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          when(
            harness.location.currentPosition(),
          ).thenAnswer((_) => Completer<Position>().future);
          Result<UserNotice?>? result;

          // 2. Act
          harness.controller.toggleService().then((value) => result = value);
          async.elapse(const Duration(seconds: 6));

          // 3. Assert
          expect(result, _okWithNoticeTitled('Aguardando sinal de GPS'));
          verify(harness.service.startService()).called(1);
          expect(harness.controller.isTrackingEnabled.value, isTrue);
        });
      },
    );

    test(
      'Sad Path: Deve iniciar o serviço e devolver o aviso de satélites quando ler a posição falha',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.location.currentPosition()).thenAnswer(
          (_) async => throw const LocationServiceDisabledException(),
        );

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, _okWithNoticeTitled('Aguardando sinal de GPS'));
        verify(harness.service.startService()).called(1);
      },
    );

    test(
      'Sad Path: Deve devolver Err e liberar isTrackingLoading quando consultar o serviço lança exceção',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.service.isRunning(),
        ).thenAnswer((_) async => throw StateError('canal fechado'));

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, _errTitled('Compartilhamento'));
        expect(harness.controller.isTrackingLoading.value, isFalse);
      },
    );
  });

  group('TrackingController.onInit', () {
    test(
      'Happy Path: Deve começar com isTrackingEnabled true quando o serviço já está rodando',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.service.isRunning()).thenAnswer((_) async => true);

        // 2. Act
        await harness.controller.onInit();

        // 3. Assert
        expect(harness.controller.isTrackingEnabled.value, isTrue);
        harness.controller.onClose();
      },
    );

    test(
      'Edge Case: Deve começar com isTrackingEnabled false quando o serviço está parado',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.controller.onInit();

        // 3. Assert
        expect(harness.controller.isTrackingEnabled.value, isFalse);
        harness.controller.onClose();
      },
    );

    test(
      'Happy Path: Deve mostrar no mapa só quem está publicando com posição dentro da validade',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final now = DateTime.now();
        harness.groupPositions.value = [
          UserModel(
            email: 'bia@example.com',
            isPublishing: true,
            capturedAt: now.subtract(const Duration(minutes: 1)),
          ),
          UserModel(
            email: 'caio@example.com',
            isPublishing: true,
            capturedAt: now.subtract(const Duration(minutes: 30)),
          ),
          UserModel(
            email: 'davi@example.com',
            isPublishing: false,
            capturedAt: now.subtract(const Duration(minutes: 1)),
          ),
        ];

        // 2. Act
        await harness.controller.onInit();

        // 3. Assert
        expect(harness.controller.firebaseUsers.map((u) => u.email), [
          'bia@example.com',
        ]);
        expect(harness.controller.groupUsers, hasLength(3));
        harness.controller.onClose();
      },
    );

    test(
      'Edge Case: Deve procurar a posição do aparelho na partida quando a pessoa pode compartilhar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        await harness.controller.onInit();
        await pumpEventQueue();

        // 3. Assert
        expect(
          harness.controller.ownPosition.value,
          const LatLng(-22.9, -43.1),
        );
        harness.controller.onClose();
      },
    );

    test(
      'Sad Path: Não deve procurar a posição do aparelho quando a pessoa não pode compartilhar',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.controller.onInit();

        // 3. Assert
        verifyNever(harness.location.currentPosition());
        harness.controller.onClose();
      },
    );
  });

  group('TrackingController - reações', () {
    test(
      'Happy Path: Deve avisar que o rastreamento está em risco quando o app fica restrito durante o compartilhamento',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.service.isRunning()).thenAnswer((_) async => true);
        await harness.controller.onInit();

        // 2. Act
        harness.isBackgroundRestricted.value = true;

        // 3. Assert
        final notice =
            verify(harness.notices.show(captureAny)).captured.single
                as UserNotice;
        expect(notice.title, 'Rastreamento em risco');
        harness.controller.onClose();
      },
    );

    test(
      'Edge Case: Não deve avisar sobre a restrição quando o compartilhamento está desligado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.onInit();

        // 2. Act
        harness.isBackgroundRestricted.value = true;

        // 3. Assert
        verifyNever(harness.notices.show(any));
        harness.controller.onClose();
      },
    );

    test(
      'Edge Case: Não deve avisar quando a restrição é retirada durante o compartilhamento',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.isBackgroundRestricted.value = true;
        when(harness.service.isRunning()).thenAnswer((_) async => true);
        await harness.controller.onInit();

        // 2. Act
        harness.isBackgroundRestricted.value = false;

        // 3. Assert
        verifyNever(harness.notices.show(any));
        harness.controller.onClose();
      },
    );

    test(
      'Happy Path: Deve procurar a posição do aparelho quando as capacidades da pessoa chegam',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.onInit();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        harness.capabilities.value = const Capabilities(isMember: true);
        await pumpEventQueue();

        // 3. Assert
        verify(harness.location.currentPosition()).called(1);
        expect(
          harness.controller.ownPosition.value,
          const LatLng(-22.9, -43.1),
        );
        harness.controller.onClose();
      },
    );

    test(
      'Happy Path: Deve procurar a posição do aparelho quando a permissão de localização é concedida',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.onInit();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        harness.hasWhenInUsePermission.value = true;
        await pumpEventQueue();

        // 3. Assert
        verify(harness.location.currentPosition()).called(1);
        harness.controller.onClose();
      },
    );

    test(
      'Sad Path: Não deve procurar a posição do aparelho quando a permissão de localização é revogada',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.hasWhenInUsePermission.value = true;
        await harness.controller.onInit();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        harness.hasWhenInUsePermission.value = false;
        await pumpEventQueue();

        // 3. Assert
        verifyNever(harness.location.currentPosition());
        harness.controller.onClose();
      },
    );

    test(
      'Edge Case: Deve ignorar uma falha ao procurar a posição do aparelho, sem mudar a posição própria',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.onInit();
        when(harness.user.isTrackable()).thenReturn(true);
        when(harness.location.currentPosition()).thenAnswer(
          (_) async => throw const LocationServiceDisabledException(),
        );

        // 2. Act
        harness.capabilities.value = const Capabilities(isMember: true);
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.ownPosition.value, isNull);
        harness.controller.onClose();
      },
    );

    test(
      'Happy Path: Deve ler a trilha das pessoas destacadas no novo dia observado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.highlighted.value = [_kBia];
        when(
          harness.positions.getTrajectoryForDate(
            _kGroup.id,
            _kBia.email,
            day: _kPastDay,
          ),
        ).thenAnswer((_) => Stream.value([_point(-22.8, -43.0)]));
        when(harness.calendar.isObservingToday).thenReturn(false);
        await harness.controller.onInit();

        // 2. Act
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();

        // 3. Assert
        expect(
          harness.controller.highlightedTrajectories[_kBia.email]?.single.lat,
          -22.8,
        );
        harness.controller.onClose();
      },
    );

    test(
      'Edge Case: Não deve ler trilhas nem posições quando nenhum grupo está no mapa',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.selectedGroup.value = null;
        harness.highlighted.value = [_kBia];
        await harness.controller.onInit();

        // 2. Act
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();

        // 3. Assert
        verifyNever(
          harness.positions.getTrajectoryForDate(
            any,
            any,
            day: anyNamed('day'),
          ),
        );
        verifyNever(
          harness.positions.getLastKnownPositionForDate(
            any,
            any,
            day: anyNamed('day'),
          ),
        );
        harness.controller.onClose();
      },
    );

    test(
      'Happy Path: Deve pôr o marcador na última posição conhecida de cada pessoa do histórico num dia passado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.calendar.isObservingToday).thenReturn(false);
        when(
          harness.groupMap.loadHistoryMembers(),
        ).thenAnswer((_) async => const [_kBia]);
        when(
          harness.positions.getLastKnownPositionForDate(
            _kGroup.id,
            _kBia.email,
            day: _kPastDay,
          ),
        ).thenAnswer((_) async => _point(-22.8, -43.0));
        await harness.controller.onInit();

        // 2. Act
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();

        // 3. Assert
        expect(
          harness.controller.animatedMarkerPositions[_kBia.email],
          const LatLng(-22.8, -43.0),
        );
        expect(
          harness.controller.usersWithPointsOnObservedDay,
          contains(_kBia.email),
        );
        harness.controller.onClose();
      },
    );

    test(
      'Sad Path: Não deve mostrar marcador de quem não tem registro no dia passado observado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.calendar.isObservingToday).thenReturn(false);
        when(
          harness.groupMap.loadHistoryMembers(),
        ).thenAnswer((_) async => const [_kBia]);
        await harness.controller.onInit();

        // 2. Act
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.animatedMarkerPositions, isEmpty);
        expect(harness.controller.usersWithPointsOnObservedDay, isEmpty);
        harness.controller.onClose();
      },
    );

    test(
      'Happy Path: Deve marcar quem tem pontos hoje ao trocar de grupo observando o dia atual',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.hasPointsOnDate(_kGroup.id, _kBia.email, _kToday),
        ).thenAnswer((_) async => true);
        await harness.controller.onInit();

        // 2. Act
        harness.observedMembers.value = [_kBia];
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.usersWithPointsOnObservedDay, {_kBia.email});
        harness.controller.onClose();
      },
    );

    test(
      'Edge Case: Deve esperar 100 ms antes de ler a trilha de quem acabou de ser destacado',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          harness.controller.onInit();
          async.flushMicrotasks();

          // 2. Act
          harness.highlighted.value = [_kBia];
          async.elapse(const Duration(milliseconds: 50));

          // 3. Assert
          verifyNever(
            harness.positions.getTrajectoryForDate(
              any,
              any,
              day: anyNamed('day'),
            ),
          );
          harness.controller.onClose();
          async.elapse(const Duration(milliseconds: 100));
        });
      },
    );

    test(
      'Happy Path: Deve ler a trilha de quem foi destacado depois da espera',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          harness.controller.onInit();
          async.flushMicrotasks();

          // 2. Act
          harness.highlighted.value = [_kBia];
          async.elapse(const Duration(milliseconds: 150));

          // 3. Assert
          verify(
            harness.positions.getTrajectoryForDate(
              _kGroup.id,
              _kBia.email,
              day: _kToday,
            ),
          ).called(1);
          harness.controller.onClose();
        });
      },
    );

    test('Edge Case: Deve apagar a trilha de quem deixou de ser destacado', () {
      fakeAsync((async) {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.getTrajectoryForDate(
            any,
            any,
            day: anyNamed('day'),
          ),
        ).thenAnswer((_) => Stream.value([_point(-22.8, -43.0)]));
        harness.controller.onInit();
        harness.highlighted.value = [_kBia];
        async.elapse(const Duration(milliseconds: 150));

        // 2. Act
        harness.highlighted.value = [];
        async.elapse(const Duration(milliseconds: 150));

        // 3. Assert
        expect(harness.controller.highlightedTrajectories, isEmpty);
        harness.controller.onClose();
      });
    });
  });

  group('TrackingController.onClose', () {
    test('Happy Path: Deve parar o relógio que reaplica a validade', () {
      fakeAsync((async) {
        // 1. Arrange
        final harness = _Harness();
        harness.controller.onInit();
        async.flushMicrotasks();

        // 2. Act
        harness.controller.onClose();

        // 3. Assert
        expect(async.periodicTimerCount, 0);
      });
    });
  });
}
