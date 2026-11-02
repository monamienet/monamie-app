import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/domain/models/capabilities.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/ui/history/view_models/calendar_view_model.dart';
import 'package:monamie_app/ui/home/view_models/group_map_view_model.dart';
import 'package:monamie_app/ui/home/view_models/group_map_state.dart';
import 'package:monamie_app/ui/home/view_models/permissions_view_model.dart';
import 'package:monamie_app/ui/home/view_models/tracking_view_model.dart';
import 'package:monamie_app/ui/home/view_models/user_view_model.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/domain/models/group_member.dart';
import 'package:monamie_app/domain/models/location_point.dart';
import 'package:monamie_app/domain/models/map_group.dart';
import 'package:monamie_app/domain/models/user_model.dart';
import 'package:monamie_app/ui/core/ui/notice_presenter.dart';
import 'package:monamie_app/utils/result.dart';
import 'package:monamie_app/utils/user_notice.dart';

@GenerateNiceMocks([
  MockSpec<CalendarViewModel>(),
  MockSpec<DeviceLocation>(),
  MockSpec<BackgroundTrackingService>(),
  MockSpec<GroupMapState>(),
  MockSpec<MembershipService>(),
  MockSpec<NoticePresenter>(),
  MockSpec<PermissionsViewModel>(),
  MockSpec<PositionsRepository>(),
  MockSpec<UserViewModel>(),
])
import 'tracking_view_model_test.mocks.dart';

const _kEmail = 'ana@example.com';
const _kGroup = MapGroup(id: 'g1', name: 'Equipe Norte');
const _kBia = GroupMember(name: 'Bia', email: 'bia@example.com');
final _kToday = DateTime(2026, 11, 2);
final _kPastDay = DateTime(2026, 10, 30);

LatLng _position(double latitude, double longitude) =>
    LatLng(latitude, longitude);

LocationPoint _point(double lat, double lng) =>
    LocationPoint(lat: lat, lng: lng, receivedAt: DateTime(2026, 10, 30, 9));

/// [email]'s position at ([lat], [lng]), shared at [seen]: live on the map.
UserModel _live(String email, double lat, double lng, DateTime seen) =>
    UserModel(
      email: email,
      lat: lat,
      lng: lng,
      isPublishing: true,
      capturedAt: seen,
    );

/// An [Err] titled [title].
Matcher _errTitled(String title) =>
    isA<Err<Object?>>().having((err) => err.title, 'title', title);

/// An [Ok] holding a [UserNotice] titled [title].
Matcher _okWithNoticeTitled(String title) => isA<Ok<UserNotice?>>().having(
  (ok) => ok.value?.title,
  'notice title',
  title,
);

/// Starting the tracking service, whatever notification it shows.
Future<bool> _start(MockBackgroundTrackingService service) => service.start(
  notificationTitle: anyNamed('notificationTitle'),
  notificationContent: anyNamed('notificationContent'),
);

/// Puts [value] in one of the controller's values (exposed read-only).
void _seed(ValueListenable<bool> listenable, bool value) =>
    (listenable as ValueNotifier<bool>).value = value;

/// The collaborators of a [TrackingViewModel], stubbed as a person who can
/// publish, with the GPS on, the service stopped and a fix at hand.
/// [state] replaces the mocked [GroupMapState] (e.g. by a real
/// `GroupMapViewModel`).
class _Harness {
  _Harness({GroupMapState? state}) {
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
    when(_start(service)).thenAnswer((_) async => true);
    when(service.ready).thenAnswer((_) => const Stream.empty());
    when(service.localPositions).thenAnswer((_) => const Stream.empty());

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

    controller = TrackingViewModel(
      notices: notices,
      userCtrl: user,
      permissionsCtrl: permissions,
      calendar: calendar,
      groupMap: state ?? groupMap,
      service: service,
      location: location,
      positions: positions,
    );
  }

  final notices = MockNoticePresenter();
  final user = MockUserViewModel();
  final permissions = MockPermissionsViewModel();
  final calendar = MockCalendarViewModel();
  final groupMap = MockGroupMapState();
  final service = MockBackgroundTrackingService();
  final location = MockDeviceLocation();
  final positions = MockPositionsRepository();

  final isBackgroundRestricted = ValueNotifier<bool>(false);
  final hasWhenInUsePermission = ValueNotifier<bool>(false);
  final observedDay = ValueNotifier<DateTime>(_kToday);
  final capabilities = ValueNotifier<Capabilities>(const Capabilities());
  final groupPositions = ValueNotifier<List<UserModel>>([]);
  final observedMembers = ValueNotifier<List<GroupMember>>([]);
  final highlighted = ValueNotifier<List<GroupMember>>([]);
  final selectedGroup = ValueNotifier<MapGroup?>(_kGroup);

  late final TrackingViewModel controller;
}

void main() {
  group('TrackingViewModel.toggleService', () {
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
        _seed(harness.controller.isTrackingEnabled, true);

        // 2. Act
        final result = await harness.controller.toggleService();

        // 3. Assert
        expect(result, isA<Ok<UserNotice?>>());
        verify(harness.service.stop());
        verify(harness.positions.markNotPublishing(_kEmail)).called(1);
        verifyNever(_start(harness.service));
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
        _seed(harness.controller.isTrackingEnabled, true);

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
        verify(_start(harness.service)).called(1);
        expect(harness.controller.isTrackingEnabled.value, isTrue);
        expect(
          harness.controller.ownPosition.value,
          const LatLng(-22.9, -43.1),
        );
        expect(
          harness.controller.usersWithPointsOnObservedDay.value,
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
        final ready = StreamController<void>();
        when(harness.service.ready).thenAnswer((_) => ready.stream);
        await harness.controller.toggleService();

        // 2. Act
        ready.add(null);
        await pumpEventQueue();

        // 3. Assert
        verify(harness.service.sendUser(email: _kEmail, name: 'Ana')).called(1);
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
        verifyNever(_start(harness.service));
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
        verifyNever(_start(harness.service));
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
        verifyNever(_start(harness.service));
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
          ).thenAnswer((_) => Completer<LatLng>().future);
          Result<UserNotice?>? result;

          // 2. Act
          harness.controller.toggleService().then((value) => result = value);
          async.elapse(const Duration(seconds: 6));

          // 3. Assert
          expect(result, _okWithNoticeTitled('Aguardando sinal de GPS'));
          verify(_start(harness.service)).called(1);
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
        verify(_start(harness.service)).called(1);
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

  group('TrackingViewModel.start', () {
    test(
      'Happy Path: Deve começar com isTrackingEnabled true quando o serviço já está rodando',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.service.isRunning()).thenAnswer((_) async => true);

        // 2. Act
        await harness.controller.start();

        // 3. Assert
        expect(harness.controller.isTrackingEnabled.value, isTrue);
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Deve começar com isTrackingEnabled false quando o serviço está parado',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.controller.start();

        // 3. Assert
        expect(harness.controller.isTrackingEnabled.value, isFalse);
        harness.controller.dispose();
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
        await harness.controller.start();

        // 3. Assert
        expect(harness.controller.firebaseUsers.value.map((u) => u.email), [
          'bia@example.com',
        ]);
        expect(harness.controller.groupUsers.value, hasLength(3));
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Deve procurar a posição do aparelho na partida quando a pessoa pode compartilhar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        await harness.controller.start();
        await pumpEventQueue();

        // 3. Assert
        expect(
          harness.controller.ownPosition.value,
          const LatLng(-22.9, -43.1),
        );
        harness.controller.dispose();
      },
    );

    test(
      'Sad Path: Não deve procurar a posição do aparelho quando a pessoa não pode compartilhar',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.controller.start();

        // 3. Assert
        verifyNever(harness.location.currentPosition());
        harness.controller.dispose();
      },
    );
  });

  group('TrackingViewModel - reações', () {
    test(
      'Happy Path: Deve avisar que o rastreamento está em risco quando o app fica restrito durante o compartilhamento',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.service.isRunning()).thenAnswer((_) async => true);
        await harness.controller.start();

        // 2. Act
        harness.isBackgroundRestricted.value = true;

        // 3. Assert
        final notice =
            verify(harness.notices.show(captureAny)).captured.single
                as UserNotice;
        expect(notice.title, 'Rastreamento em risco');
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve avisar sobre a restrição quando o compartilhamento está desligado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();

        // 2. Act
        harness.isBackgroundRestricted.value = true;

        // 3. Assert
        verifyNever(harness.notices.show(any));
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve avisar quando a restrição é retirada durante o compartilhamento',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.isBackgroundRestricted.value = true;
        when(harness.service.isRunning()).thenAnswer((_) async => true);
        await harness.controller.start();

        // 2. Act
        harness.isBackgroundRestricted.value = false;

        // 3. Assert
        verifyNever(harness.notices.show(any));
        harness.controller.dispose();
      },
    );

    test(
      'Happy Path: Deve procurar a posição do aparelho quando as capacidades da pessoa chegam',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();
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
        harness.controller.dispose();
      },
    );

    test(
      'Happy Path: Deve procurar a posição do aparelho quando a permissão de localização é concedida',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        harness.hasWhenInUsePermission.value = true;
        await pumpEventQueue();

        // 3. Assert
        verify(harness.location.currentPosition()).called(1);
        harness.controller.dispose();
      },
    );

    test(
      'Sad Path: Não deve procurar a posição do aparelho quando a permissão de localização é revogada',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.hasWhenInUsePermission.value = true;
        await harness.controller.start();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        harness.hasWhenInUsePermission.value = false;
        await pumpEventQueue();

        // 3. Assert
        verifyNever(harness.location.currentPosition());
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Deve ignorar uma falha ao procurar a posição do aparelho, sem mudar a posição própria',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();
        when(harness.user.isTrackable()).thenReturn(true);
        when(harness.location.currentPosition()).thenAnswer(
          (_) async => throw const LocationServiceDisabledException(),
        );

        // 2. Act
        harness.capabilities.value = const Capabilities(isMember: true);
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.ownPosition.value, isNull);
        harness.controller.dispose();
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
        await harness.controller.start();

        // 2. Act
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();

        // 3. Assert
        expect(
          harness
              .controller
              .highlightedTrajectories
              .value[_kBia.email]
              ?.single
              .lat,
          -22.8,
        );
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve ler trilhas nem posições quando nenhum grupo está no mapa',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.selectedGroup.value = null;
        harness.highlighted.value = [_kBia];
        await harness.controller.start();

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
        harness.controller.dispose();
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
        await harness.controller.start();

        // 2. Act
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();

        // 3. Assert
        expect(
          harness.controller.animatedMarkerPositions.value[_kBia.email],
          const LatLng(-22.8, -43.0),
        );
        expect(
          harness.controller.usersWithPointsOnObservedDay.value,
          contains(_kBia.email),
        );
        harness.controller.dispose();
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
        await harness.controller.start();

        // 2. Act
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.animatedMarkerPositions.value, isEmpty);
        expect(harness.controller.usersWithPointsOnObservedDay.value, isEmpty);
        harness.controller.dispose();
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
        await harness.controller.start();

        // 2. Act
        harness.observedMembers.value = [_kBia];
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.usersWithPointsOnObservedDay.value, {
          _kBia.email,
        });
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Deve esperar 100 ms antes de ler a trilha de quem acabou de ser destacado',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          harness.controller.start();
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
          // The pending highlight is cancelled with the controller (#195):
          // no timer is left to fire after the test.
          harness.controller.dispose();
          expect(async.pendingTimers, isEmpty);
        });
      },
    );

    test(
      'Happy Path: Deve ler a trilha de quem foi destacado depois da espera',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          harness.controller.start();
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
          harness.controller.dispose();
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
        harness.controller.start();
        harness.highlighted.value = [_kBia];
        async.elapse(const Duration(milliseconds: 150));

        // 2. Act
        harness.highlighted.value = [];
        async.elapse(const Duration(milliseconds: 150));

        // 3. Assert
        expect(harness.controller.highlightedTrajectories.value, isEmpty);
        harness.controller.dispose();
      });
    });
  });

  group('TrackingViewModel.dispose', () {
    test('Happy Path: Deve parar o relógio que reaplica a validade', () {
      fakeAsync((async) {
        // 1. Arrange
        final harness = _Harness();
        harness.controller.start();
        async.flushMicrotasks();

        // 2. Act
        harness.controller.dispose();

        // 3. Assert
        expect(async.periodicTimerCount, 0);
      });
    });
  });

  group('TrackingViewModel.dispose - ouvintes removidos', () {
    test(
      'Happy Path: Não deve reagir a novas posições do grupo depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();
        harness.controller.dispose();

        // 2. Act
        harness.groupPositions.value = [
          UserModel(
            email: _kBia.email,
            isPublishing: true,
            capturedAt: DateTime.now(),
          ),
        ];

        // 3. Assert
        expect(harness.controller.groupUsers.value, isEmpty);
      },
    );

    test(
      'Happy Path: Não deve reagir a novas pessoas observadas depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();
        harness.controller.dispose();

        // 2. Act
        harness.observedMembers.value = [_kBia];
        await pumpEventQueue();

        // 3. Assert
        verifyNever(harness.positions.hasPointsOnDate(any, any, any));
      },
    );

    test(
      'Happy Path: Não deve reagir a novas capacidades depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();
        harness.controller.dispose();
        clearInteractions(harness.user);

        // 2. Act
        harness.capabilities.value = const Capabilities(isMember: true);
        await pumpEventQueue();

        // 3. Assert
        verifyNever(harness.user.isTrackable());
      },
    );

    test(
      'Happy Path: Não deve reagir a outro dia observado depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.highlighted.value = [_kBia];
        harness.observedMembers.value = [_kBia];
        await harness.controller.start();
        harness.controller.dispose();

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
        verifyNever(harness.positions.hasPointsOnDate(any, any, any));
      },
    );

    test(
      'Happy Path: Não deve ler a trilha de quem é destacado depois de fechar',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          harness.controller.start();
          async.flushMicrotasks();
          harness.controller.dispose();

          // 2. Act
          harness.highlighted.value = [_kBia];
          async.elapse(const Duration(milliseconds: 150));

          // 3. Assert
          verifyNever(
            harness.positions.getTrajectoryForDate(
              any,
              any,
              day: anyNamed('day'),
            ),
          );
        });
      },
    );
  });

  group('TrackingViewModel - reações com o GroupMapViewModel real', () {
    late StreamController<Map<String, Object?>?> organization;
    late StreamController<Map<String, Object?>> roles;
    late StreamController<String?> groupName;
    late StreamController<List<UserModel>> live;
    late GroupMapViewModel groupMap;

    /// Ana subscribes to and publishes in [_kGroup], where Bia publishes.
    /// The tracking controller follows a real [GroupMapViewModel] over
    /// mocked Firestore sources.
    Future<_Harness> following() async {
      organization = StreamController<Map<String, Object?>?>();
      roles = StreamController<Map<String, Object?>>();
      groupName = StreamController<String?>();
      live = StreamController<List<UserModel>>();
      final memberships = MockMembershipService();
      when(
        memberships.organizationMembership(any, any),
      ).thenAnswer((_) => organization.stream);
      when(memberships.groupRoles(any, any)).thenAnswer((_) => roles.stream);
      when(
        memberships.groupName(any, _kGroup.id),
      ).thenAnswer((_) => groupName.stream);
      final sources = MockPositionsRepository();
      when(
        sources.streamGroupPositions(_kGroup.id),
      ).thenAnswer((_) => live.stream);
      groupMap = GroupMapViewModel(
        onAccessLost: () async {},
        memberships: memberships,
        positions: sources,
        organizationId: () => 'rotasul',
        email: () => _kEmail,
      );
      organization.add({'email': _kEmail, 'role': 'member'});
      roles.add({
        _kGroup.id: ['publisher', 'subscriber'],
      });
      groupName.add(_kGroup.name);
      live.add([UserModel(email: _kBia.email, name: _kBia.name)]);
      groupMap.start();
      await pumpEventQueue();
      final harness = _Harness(state: groupMap);
      await harness.controller.start();
      await pumpEventQueue();
      clearInteractions(harness.positions);
      clearInteractions(harness.user);
      return harness;
    }

    tearDown(() => groupMap.dispose());

    test(
      'Happy Path: Deve reagir uma vez a um retrato com uma pessoa nova',
      () async {
        // 1. Arrange
        final harness = await following();
        var groupUsersChanged = 0;
        harness.controller.groupUsers.addListener(() => groupUsersChanged++);

        // 2. Act
        live.add([
          UserModel(email: _kBia.email, name: _kBia.name),
          UserModel(email: 'caio@example.com', name: 'Caio'),
        ]);
        await pumpEventQueue();

        // 3. Assert
        expect(groupUsersChanged, 1);
        verify(
          harness.positions.hasPointsOnDate(
            _kGroup.id,
            'caio@example.com',
            any,
          ),
        ).called(1);
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve reagir a um retrato novo com as mesmas posições',
      () async {
        // 1. Arrange
        final harness = await following();
        var groupUsersChanged = 0;
        harness.controller.groupUsers.addListener(() => groupUsersChanged++);

        // 2. Act
        live.add([UserModel(email: _kBia.email, name: _kBia.name)]);
        await pumpEventQueue();

        // 3. Assert
        expect(groupUsersChanged, 0);
        verifyNever(harness.positions.hasPointsOnDate(any, any, any));
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve procurar o aparelho de novo com os mesmos papéis',
      () async {
        // 1. Arrange
        final harness = await following();

        // 2. Act
        roles.add({
          _kGroup.id: ['publisher', 'subscriber'],
        });
        await pumpEventQueue();

        // 3. Assert
        verifyNever(harness.user.isTrackable());
        harness.controller.dispose();
      },
    );

    test(
      'Happy Path: Deve procurar o aparelho de novo quando os papéis mudam',
      () async {
        // 1. Arrange
        final harness = await following();

        // 2. Act
        roles.add({
          _kGroup.id: ['maintainer', 'publisher', 'subscriber'],
        });
        await pumpEventQueue();

        // 3. Assert
        verify(harness.user.isTrackable()).called(1);
        harness.controller.dispose();
      },
    );
  });

  group('TrackingViewModel.dispose - vazamentos (#195)', () {
    test(
      'Happy Path: Não deve avisar sobre a restrição em segundo plano depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.service.isRunning()).thenAnswer((_) async => true);
        await harness.controller.start();
        harness.controller.dispose();

        // 2. Act
        harness.isBackgroundRestricted.value = true;

        // 3. Assert
        verifyNever(harness.notices.show(any));
      },
    );

    test(
      'Happy Path: Não deve procurar o aparelho quando a permissão chega depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();
        harness.controller.dispose();
        when(harness.user.isTrackable()).thenReturn(true);

        // 2. Act
        harness.hasWhenInUsePermission.value = true;
        await pumpEventQueue();

        // 3. Assert
        verifyNever(harness.location.currentPosition());
      },
    );

    test(
      'Edge Case: Não deve abrir a trilha de quem foi destacado logo antes de fechar',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          final trail = StreamController<List<LocationPoint>>();
          when(
            harness.positions.getTrajectoryForDate(
              any,
              any,
              day: anyNamed('day'),
            ),
          ).thenAnswer((_) => trail.stream);
          harness.controller.start();
          async.flushMicrotasks();
          harness.highlighted.value = [_kBia];
          async.elapse(const Duration(milliseconds: 50));

          // 2. Act
          harness.controller.dispose();
          async.elapse(const Duration(milliseconds: 150));

          // 3. Assert
          verifyNever(
            harness.positions.getTrajectoryForDate(
              any,
              any,
              day: anyNamed('day'),
            ),
          );
          expect(trail.hasListener, isFalse);
        });
      },
    );

    test('Happy Path: Deve cancelar as trilhas abertas ao fechar', () {
      fakeAsync((async) {
        // 1. Arrange
        final harness = _Harness();
        final trail = StreamController<List<LocationPoint>>();
        when(
          harness.positions.getTrajectoryForDate(
            any,
            any,
            day: anyNamed('day'),
          ),
        ).thenAnswer((_) => trail.stream);
        harness.controller.start();
        async.flushMicrotasks();
        harness.highlighted.value = [_kBia];
        async.elapse(const Duration(milliseconds: 150));

        // 2. Act
        harness.controller.dispose();
        async.flushMicrotasks();

        // 3. Assert
        expect(trail.hasListener, isFalse);
      });
    });

    test(
      'Happy Path: Deve parar de ouvir o serviço de rastreamento ao fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final ready = StreamController<void>();
        final located = StreamController<LatLng>();
        when(harness.service.ready).thenAnswer((_) => ready.stream);
        when(harness.service.localPositions).thenAnswer((_) => located.stream);
        await harness.controller.toggleService();

        // 2. Act
        harness.controller.dispose();
        await pumpEventQueue();

        // 3. Assert
        expect(ready.hasListener, isFalse);
        expect(located.hasListener, isFalse);
      },
    );

    test(
      'Happy Path: Deve parar o relógio da validade e a animação dos marcadores ao fechar',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          final seen = DateTime.now();
          harness.controller.start();
          async.flushMicrotasks();
          harness.groupPositions.value = [
            _live(_kBia.email, -22.9, -43.1, seen),
          ];
          harness.groupPositions.value = [
            _live(_kBia.email, -22.8, -43.0, seen),
          ];

          // 2. Act
          harness.controller.dispose();

          // 3. Assert
          expect(async.periodicTimerCount, 0);
        });
      },
    );

    test(
      'Sad Path: Deve ignorar sem erro uma posição do GPS que chega depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final fix = Completer<LatLng>();
        when(harness.user.isTrackable()).thenReturn(true);
        when(harness.location.currentPosition()).thenAnswer((_) => fix.future);
        await harness.controller.start();
        harness.controller.dispose();

        // 2. Act
        fix.complete(_position(-22.8, -43.0));
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.ownPosition.value, isNull);
      },
    );

    test(
      'Sad Path: Deve ignorar sem erro os pontos de hoje que chegam depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final hasPoints = Completer<bool>();
        when(
          harness.positions.hasPointsOnDate(any, any, any),
        ).thenAnswer((_) => hasPoints.future);
        await harness.controller.start();
        harness.observedMembers.value = [_kBia];
        harness.controller.dispose();

        // 2. Act
        hasPoints.complete(true);
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.usersWithPointsOnObservedDay.value, isEmpty);
      },
    );

    test(
      'Sad Path: Deve ignorar sem erro a última posição de um dia passado que chega depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final last = Completer<LocationPoint?>();
        when(harness.calendar.isObservingToday).thenReturn(false);
        when(
          harness.groupMap.loadHistoryMembers(),
        ).thenAnswer((_) async => const [_kBia]);
        when(
          harness.positions.getLastKnownPositionForDate(
            any,
            any,
            day: anyNamed('day'),
          ),
        ).thenAnswer((_) => last.future);
        await harness.controller.start();
        harness.observedDay.value = _kPastDay;
        await pumpEventQueue();
        harness.controller.dispose();

        // 2. Act
        last.complete(_point(-22.8, -43.0));
        await pumpEventQueue();

        // 3. Assert
        expect(harness.controller.animatedMarkerPositions.value, isEmpty);
        expect(harness.controller.usersWithPointsOnObservedDay.value, isEmpty);
      },
    );

    test(
      'Sad Path: Deve terminar sem erro a partida cujo estado do serviço chega depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final running = Completer<bool>();
        when(harness.service.isRunning()).thenAnswer((_) => running.future);
        final starting = harness.controller.start();
        harness.controller.dispose();

        // 2. Act
        running.complete(true);

        // 3. Assert
        await expectLater(starting, completes);
        expect(harness.controller.isTrackingEnabled.value, isFalse);
      },
    );

    test(
      'Sad Path: Deve terminar sem erro o desligamento cujo estado do serviço chega depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final running = Completer<bool>();
        when(harness.service.isRunning()).thenAnswer((_) => running.future);
        final toggling = harness.controller.toggleService();
        harness.controller.dispose();

        // 2. Act
        running.complete(true);

        // 3. Assert
        await expectLater(toggling, completion(isA<Ok<UserNotice?>>()));
      },
    );

    test(
      'Sad Path: Não deve ligar o compartilhamento cujo estado do serviço chega depois de fechar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final running = Completer<bool>();
        final ready = StreamController<void>();
        final located = StreamController<LatLng>();
        when(harness.service.isRunning()).thenAnswer((_) => running.future);
        when(harness.service.ready).thenAnswer((_) => ready.stream);
        when(harness.service.localPositions).thenAnswer((_) => located.stream);
        final toggling = harness.controller.toggleService();
        harness.controller.dispose();

        // 2. Act
        running.complete(false);

        // 3. Assert
        await expectLater(
          toggling,
          completion(
            isA<Ok<UserNotice?>>().having((ok) => ok.value, 'value', isNull),
          ),
        );
        await pumpEventQueue();
        verifyNever(_start(harness.service));
        expect(ready.hasListener, isFalse);
        expect(located.hasListener, isFalse);
        expect(
          () => harness.controller.isTrackingLoading.value,
          returnsNormally,
        );
      },
    );
  });

  group('TrackingViewModel.start e dispose - idempotência', () {
    test(
      'Edge Case: Deve consultar o serviço uma vez só quando start() é chamado duas vezes',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.start();

        // 2. Act
        await harness.controller.start();

        // 3. Assert
        verify(harness.service.isRunning()).called(1);
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Deve criar um só relógio da validade quando start() é chamado duas vezes',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          harness.controller.start();
          async.flushMicrotasks();

          // 2. Act
          harness.controller.start();
          async.flushMicrotasks();

          // 3. Assert
          expect(async.periodicTimerCount, 1);
          harness.controller.dispose();
        });
      },
    );

    test('Edge Case: Deve aceitar um segundo dispose() sem lançar', () async {
      // 1. Arrange
      final harness = _Harness();
      await harness.controller.start();
      harness.controller.dispose();

      // 2. Act
      void act() => harness.controller.dispose();

      // 3. Assert
      expect(act, returnsNormally);
    });

    test('Edge Case: Deve aceitar dispose() sem start() sem lançar', () {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      void act() => harness.controller.dispose();

      // 3. Assert
      expect(act, returnsNormally);
    });

    test(
      'Sad Path: Não deve começar a ouvir nem consultar o serviço com start() depois de dispose()',
      () async {
        // 1. Arrange
        final harness = _Harness();
        harness.controller.dispose();

        // 2. Act
        await harness.controller.start();

        // 3. Assert
        verifyNever(harness.service.isRunning());
        verifyNever(harness.user.isTrackable());
      },
    );
  });

  group('TrackingViewModel - avisa só quando o valor muda', () {
    test(
      'Edge Case: Não deve avisar quando o grupo manda outra lista com as mesmas posições',
      () async {
        // 1. Arrange
        final harness = _Harness();
        final seen = DateTime.now();
        harness.groupPositions.value = [_live(_kBia.email, -22.9, -43.1, seen)];
        await harness.controller.start();
        var notified = 0;
        harness.controller.firebaseUsers.addListener(() => notified++);
        harness.controller.groupUsers.addListener(() => notified++);

        // 2. Act
        harness.groupPositions.value = [_live(_kBia.email, -22.9, -43.1, seen)];

        // 3. Assert
        expect(notified, 0);
        harness.controller.dispose();
      },
    );

    test(
      'Happy Path: Deve avisar os marcadores uma vez por quadro mesmo com duas pessoas se movendo',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          final seen = DateTime.now();
          harness.controller.start();
          async.flushMicrotasks();
          harness.groupPositions.value = [
            _live(_kBia.email, -22.9, -43.1, seen),
            _live('caio@example.com', -22.7, -43.2, seen),
          ];
          var notified = 0;
          harness.controller.animatedMarkerPositions.addListener(
            () => notified++,
          );
          harness.groupPositions.value = [
            _live(_kBia.email, -22.8, -43.0, seen),
            _live('caio@example.com', -22.6, -43.3, seen),
          ];

          // 2. Act
          async.elapse(const Duration(milliseconds: 16));

          // 3. Assert
          expect(notified, 1);
          harness.controller.dispose();
        });
      },
    );

    test(
      'Edge Case: Não deve avisar a trilha quando ela chega de novo com os mesmos pontos',
      () {
        fakeAsync((async) {
          // 1. Arrange
          final harness = _Harness();
          final trail = StreamController<List<LocationPoint>>();
          when(
            harness.positions.getTrajectoryForDate(
              any,
              any,
              day: anyNamed('day'),
            ),
          ).thenAnswer((_) => trail.stream);
          harness.controller.start();
          harness.highlighted.value = [_kBia];
          async.elapse(const Duration(milliseconds: 150));
          trail.add([_point(-22.8, -43.0)]);
          async.flushMicrotasks();
          var notified = 0;
          harness.controller.highlightedTrajectories.addListener(
            () => notified++,
          );

          // 2. Act
          trail.add([_point(-22.8, -43.0)]);
          async.flushMicrotasks();

          // 3. Assert
          expect(notified, 0);
          harness.controller.dispose();
        });
      },
    );

    test(
      'Edge Case: Não deve avisar a posição própria quando o GPS repete a mesma posição',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.user.isTrackable()).thenReturn(true);
        await harness.controller.start();
        await pumpEventQueue();
        var notified = 0;
        harness.controller.ownPosition.addListener(() => notified++);

        // 2. Act
        harness.capabilities.value = const Capabilities(isMember: true);
        await pumpEventQueue();

        // 3. Assert
        verify(harness.location.currentPosition()).called(2);
        expect(notified, 0);
        harness.controller.dispose();
      },
    );

    test(
      'Edge Case: Não deve avisar isTrackingEnabled quando o serviço confirma que está parado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        var notified = 0;
        harness.controller.isTrackingEnabled.addListener(() => notified++);

        // 2. Act
        await harness.controller.start();

        // 3. Assert
        expect(notified, 0);
        harness.controller.dispose();
      },
    );
  });

  group('TrackingViewModel - coleções expostas não mudam no lugar', () {
    test('Sad Path: Deve recusar mudar a lista de quem está no mapa', () async {
      // 1. Arrange
      final harness = _Harness();
      harness.groupPositions.value = [
        _live(_kBia.email, -22.9, -43.1, DateTime.now()),
      ];
      await harness.controller.start();

      // 2. Act
      void act() => harness.controller.firebaseUsers.value.clear();

      // 3. Assert
      expect(act, throwsUnsupportedError);
      harness.controller.dispose();
    });

    test('Sad Path: Deve recusar mudar a lista do grupo', () async {
      // 1. Arrange
      final harness = _Harness();
      harness.groupPositions.value = [
        _live(_kBia.email, -22.9, -43.1, DateTime.now()),
      ];
      await harness.controller.start();

      // 2. Act
      void act() => harness.controller.groupUsers.value.clear();

      // 3. Assert
      expect(act, throwsUnsupportedError);
      harness.controller.dispose();
    });

    test(
      'Sad Path: Deve recusar mudar o conjunto de quem tem pontos no dia',
      () async {
        // 1. Arrange
        final harness = _Harness();
        await harness.controller.toggleService();

        // 2. Act
        void act() =>
            harness.controller.usersWithPointsOnObservedDay.value.clear();

        // 3. Assert
        expect(act, throwsUnsupportedError);
      },
    );

    test('Sad Path: Deve recusar mudar as posições dos marcadores', () async {
      // 1. Arrange
      final harness = _Harness();
      harness.groupPositions.value = [
        _live(_kBia.email, -22.9, -43.1, DateTime.now()),
      ];
      await harness.controller.start();

      // 2. Act
      void act() => harness.controller.animatedMarkerPositions.value.clear();

      // 3. Assert
      expect(act, throwsUnsupportedError);
      harness.controller.dispose();
    });

    test('Sad Path: Deve recusar mudar a trilha de uma pessoa destacada', () {
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
        harness.controller.start();
        harness.highlighted.value = [_kBia];
        async.elapse(const Duration(milliseconds: 150));

        // 2. Act
        void act() => harness
            .controller
            .highlightedTrajectories
            .value[_kBia.email]!
            .clear();

        // 3. Assert
        expect(act, throwsUnsupportedError);
        harness.controller.dispose();
      });
    });

    test('Sad Path: Deve recusar mudar o mapa das trilhas destacadas', () {
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
        harness.controller.start();
        harness.highlighted.value = [_kBia];
        async.elapse(const Duration(milliseconds: 150));

        // 2. Act
        void act() => harness.controller.highlightedTrajectories.value.clear();

        // 3. Assert
        expect(act, throwsUnsupportedError);
        harness.controller.dispose();
      });
    });
  });
}
