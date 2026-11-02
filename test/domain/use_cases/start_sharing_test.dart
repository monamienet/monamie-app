import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/membership/membership_repository.dart';
import 'package:monamie_app/data/repositories/permissions/permissions_repository.dart';
import 'package:monamie_app/data/services/background_tracking_service.dart';
import 'package:monamie_app/data/services/device_location.dart';
import 'package:monamie_app/domain/use_cases/start_sharing.dart';
import 'package:monamie_app/utils/result.dart';

@GenerateNiceMocks([
  MockSpec<BackgroundTrackingService>(),
  MockSpec<DeviceLocation>(),
  MockSpec<MembershipRepository>(),
  MockSpec<PermissionsRepository>(),
])
import 'start_sharing_test.mocks.dart';

const _kFix = LatLng(-22.9, -43.1);

/// Starting the tracking service, whatever notification it shows.
Future<bool> _start(MockBackgroundTrackingService service) => service.start(
  notificationTitle: anyNamed('notificationTitle'),
  notificationContent: anyNamed('notificationContent'),
);

/// An [Ok] holding a [SharingStart] that started ([started]) with a notice
/// titled [noticeTitle] (or none).
Matcher _okStarted({required bool started, String? noticeTitle}) =>
    isA<Ok<SharingStart>>()
        .having((ok) => ok.value.started, 'started', started)
        .having((ok) => ok.value.notice?.title, 'notice title', noticeTitle);

/// The collaborators of a [StartSharing], stubbed as a person who
/// publishes, with no battery restriction, the GPS on and a fix at hand.
/// [steps] records, in order, the first fix handed to `onPosition` and the
/// start of the service.
class _Harness {
  _Harness() {
    when(
      permissions.refreshBackgroundRestriction(),
    ).thenAnswer((_) async => false);
    when(location.isServiceEnabled()).thenAnswer((_) async => true);
    when(location.currentPosition()).thenAnswer((_) async => _kFix);
    when(memberships.canPublish).thenReturn(true);
    when(_start(service)).thenAnswer((_) async {
      steps.add('start');
      return true;
    });
    useCase = StartSharing(
      permissions: permissions,
      location: location,
      memberships: memberships,
      service: service,
    );
  }

  final permissions = MockPermissionsRepository();
  final location = MockDeviceLocation();
  final memberships = MockMembershipRepository();
  final service = MockBackgroundTrackingService();
  final steps = <String>[];
  final positions = <LatLng>[];
  late final StartSharing useCase;

  Future<Result<SharingStart>> call() => useCase(
    onPosition: (position) {
      steps.add('position');
      positions.add(position);
    },
  );
}

void main() {
  group('StartSharing - Unit Test Suite', () {
    test(
      'Happy Path: Deve iniciar o serviço com a notificação, depois de entregar a primeira posição',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        final result = await harness.call();

        // 3. Assert
        expect(result, _okStarted(started: true));
        expect(harness.positions, [_kFix]);
        expect(harness.steps, ['position', 'start']);
        verify(
          harness.service.start(
            notificationTitle: 'Sua localização está sendo compartilhada',
            notificationContent:
                'O compartilhamento está ligado. Para preservar sua '
                'privacidade, certifique-se de desativá-lo assim que '
                'terminar suas atividades.',
          ),
        ).called(1);
      },
    );

    test(
      'Happy Path: Deve conferir bateria, GPS, grupos e posição nessa ordem, antes de iniciar o serviço',
      () async {
        // 1. Arrange
        final harness = _Harness();

        // 2. Act
        await harness.call();

        // 3. Assert
        verifyInOrder([
          harness.permissions.refreshBackgroundRestriction(),
          harness.location.isServiceEnabled(),
          harness.memberships.canPublish,
          harness.location.currentPosition(),
          _start(harness.service),
        ]);
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
        final result = await harness.call();

        // 3. Assert
        expect(result, _okStarted(started: false));
        verify(harness.permissions.openBackgroundUsageSettings()).called(1);
        verifyNever(harness.location.isServiceEnabled());
        verifyNever(harness.location.currentPosition());
        verifyNever(_start(harness.service));
        expect(harness.positions, isEmpty);
      },
    );

    test(
      'Edge Case: Deve abrir as configurações de bateria, e não avisar do GPS, quando o app está restrito e o GPS desligado',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.permissions.refreshBackgroundRestriction(),
        ).thenAnswer((_) async => true);
        when(
          harness.location.isServiceEnabled(),
        ).thenAnswer((_) async => false);

        // 2. Act
        await harness.call();

        // 3. Assert
        verify(harness.permissions.openBackgroundUsageSettings()).called(1);
        verifyNever(harness.permissions.notifyGpsDisabled());
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
        final result = await harness.call();

        // 3. Assert
        expect(result, _okStarted(started: false));
        verify(harness.permissions.notifyGpsDisabled()).called(1);
        verifyNever(harness.memberships.canPublish);
        verifyNever(harness.location.currentPosition());
        verifyNever(_start(harness.service));
      },
    );

    test(
      'Sad Path: Deve devolver Err sem iniciar o serviço quando a pessoa não publica em nenhum grupo',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.memberships.canPublish).thenReturn(false);

        // 2. Act
        final result = await harness.call();

        // 3. Assert
        expect(
          result,
          isA<Err<SharingStart>>()
              .having(
                (err) => err.title,
                'title',
                'Compartilhamento não autorizado',
              )
              .having(
                (err) => err.message,
                'message',
                'Você não está em campo em nenhum grupo. Peça a um '
                    'administrador para liberar o compartilhamento da sua '
                    'localização.',
              ),
        );
        verifyNever(harness.location.currentPosition());
        verifyNever(_start(harness.service));
        expect(harness.positions, isEmpty);
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
          Result<SharingStart>? result;

          // 2. Act
          harness.call().then((value) => result = value);
          async.elapse(const Duration(seconds: 4));
          final before = result;
          async.elapse(const Duration(seconds: 2));

          // 3. Assert
          expect(before, isNull);
          expect(
            result,
            _okStarted(started: true, noticeTitle: 'Aguardando sinal de GPS'),
          );
          expect(
            (result! as Ok<SharingStart>).value.notice?.message,
            'O monitoramento foi iniciado, mas a sua posição inicial ainda '
            'está sendo obtida pelos satélites.',
          );
          verify(_start(harness.service)).called(1);
          expect(harness.positions, isEmpty);
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
        final result = await harness.call();

        // 3. Assert
        expect(
          result,
          _okStarted(started: true, noticeTitle: 'Aguardando sinal de GPS'),
        );
        verify(_start(harness.service)).called(1);
        expect(harness.positions, isEmpty);
      },
    );

    test(
      'Sad Path: Deve deixar passar o erro quando o serviço não consegue iniciar',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          _start(harness.service),
        ).thenAnswer((_) async => throw StateError('canal fechado'));

        // 2. Act
        Future<Result<SharingStart>> act() => harness.call();

        // 3. Assert
        await expectLater(act(), throwsStateError);
      },
    );
  });
}
