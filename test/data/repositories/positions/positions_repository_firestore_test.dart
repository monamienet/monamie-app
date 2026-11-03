import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository_firestore.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/services/firestore/positions_firestore_service.dart';
import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/domain/models/location_point.dart';

@GenerateNiceMocks([
  MockSpec<MembershipService>(),
  MockSpec<PositionsFirestoreService>(),
])
import 'positions_repository_firestore_test.mocks.dart';

const _kGroup = 'g1';
const _kEmail = 'ana@example.com';

/// A trail point document at ([lat], [lng]), received at [at].
Map<String, Object?> _pointDoc(double lat, double lng, DateTime at) => {
  'lat': lat,
  'lng': lng,
  'receivedAt': Timestamp.fromDate(at),
};

/// A position document of [email].
Map<String, Object?> _positionDoc(String email, {bool publishing = true}) => {
  'email': email,
  'name': email.split('@').first,
  'lat': -22.9,
  'lng': -43.1,
  'capturedAt': Timestamp.fromDate(DateTime(2026, 11, 2, 9)),
  'isPublishing': publishing,
};

/// The repository over mocked services, in organization `rotasul`.
class _Harness {
  _Harness() {
    when(positions.organizationId).thenReturn('rotasul');
    when(positions.setPublishing(any, any, any)).thenAnswer((_) async {});
  }

  final positions = MockPositionsFirestoreService();
  final memberships = MockMembershipService();

  late final repository = PositionsRepositoryFirestore(
    positions: positions,
    memberships: memberships,
  );
}

void main() {
  group(
    'PositionsRepositoryFirestore.streamGroupPositions - Unit Test Suite',
    () {
      test('Happy Path: each publishing document becomes a person', () async {
        // 1. Arrange
        final harness = _Harness();
        when(harness.positions.watchPublishingPositions(_kGroup)).thenAnswer(
          (_) => Stream.value([
            _positionDoc('ana@example.com'),
            _positionDoc('bia@example.com', publishing: false),
          ]),
        );

        // 2. Act
        final people = await harness.repository
            .streamGroupPositions(_kGroup)
            .first;

        // 3. Assert
        expect(people.map((p) => (p.email, p.isPublishing)), [
          ('ana@example.com', true),
          ('bia@example.com', false),
        ]);
      });

      test('Edge Case: an empty group is an empty list', () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.watchPublishingPositions(_kGroup),
        ).thenAnswer((_) => Stream.value(const []));

        // 2. Act
        final people = await harness.repository
            .streamGroupPositions(_kGroup)
            .first;

        // 3. Assert
        expect(people, isEmpty);
      });

      test(
        'Sad Path: a malformed document is an error on the stream',
        () async {
          // 1. Arrange
          final harness = _Harness();
          when(harness.positions.watchPublishingPositions(_kGroup)).thenAnswer(
            (_) => Stream.value([
              {'email': _kEmail, 'lat': 'not a number'},
            ]),
          );

          // 2. Act
          final first = harness.repository.streamGroupPositions(_kGroup).first;

          // 3. Assert
          await expectLater(first, throwsA(isA<TypeError>()));
        },
      );
    },
  );

  group(
    'PositionsRepositoryFirestore.groupHistoryPeople - Unit Test Suite',
    () {
      test(
        'Happy Path: everyone who published, removed people included',
        () async {
          // 1. Arrange
          final harness = _Harness();
          when(harness.positions.readAllPositions(_kGroup)).thenAnswer(
            (_) async => [
              _positionDoc('ana@example.com'),
              {
                ..._positionDoc('caio@example.com'),
                'removedAt': Timestamp.now(),
              },
            ],
          );

          // 2. Act
          final people = await harness.repository.groupHistoryPeople(_kGroup);

          // 3. Assert
          expect(people.map((p) => p.email), [
            'ana@example.com',
            'caio@example.com',
          ]);
        },
      );

      test('Edge Case: nobody ever published', () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.readAllPositions(_kGroup),
        ).thenAnswer((_) async => const []);

        // 2. Act
        final people = await harness.repository.groupHistoryPeople(_kGroup);

        // 3. Assert
        expect(people, isEmpty);
      });

      test('Sad Path: a read failure reaches the caller', () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.readAllPositions(_kGroup),
        ).thenAnswer((_) async => throw StateError('offline'));

        // 2. Act
        final read = harness.repository.groupHistoryPeople(_kGroup);

        // 3. Assert
        await expectLater(read, throwsStateError);
      });
    },
  );

  group('PositionsRepositoryFirestore.countPublishers - Unit Test Suite', () {
    test('Happy Path: answers the service count', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.positions.countPublishingPositions(_kGroup),
      ).thenAnswer((_) async => 3);

      // 2. Act
      final count = await harness.repository.countPublishers(_kGroup);

      // 3. Assert
      expect(count, 3);
    });

    test('Sad Path: a failed count reaches the caller', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.positions.countPublishingPositions(_kGroup),
      ).thenAnswer((_) async => throw StateError('offline'));

      // 2. Act
      final count = harness.repository.countPublishers(_kGroup);

      // 3. Assert
      await expectLater(count, throwsStateError);
    });
  });

  group('PositionsRepositoryFirestore.trailDays - Unit Test Suite', () {
    final october = HistoryMonth(
      year: 2026,
      month: 10,
      today: DateTime(2026, 11, 2),
    );

    test('Happy Path: the days of everyone, from the first to the last of '
        'the month', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.positions.readTrailDayIds(
          _kGroup,
          'ana@example.com',
          first: anyNamed('first'),
          last: anyNamed('last'),
        ),
      ).thenAnswer((_) async => ['2026-10-01', '2026-10-15']);
      when(
        harness.positions.readTrailDayIds(
          _kGroup,
          'bia@example.com',
          first: anyNamed('first'),
          last: anyNamed('last'),
        ),
      ).thenAnswer((_) async => ['2026-10-15', '2026-10-31']);

      // 2. Act
      final days = await harness.repository.trailDays(_kGroup, [
        'ana@example.com',
        'bia@example.com',
      ], october);

      // 3. Assert
      expect(days, {'2026-10-01', '2026-10-15', '2026-10-31'});
      verify(
        harness.positions.readTrailDayIds(
          _kGroup,
          'ana@example.com',
          first: '2026-10-01',
          last: '2026-10-31',
        ),
      ).called(1);
    });

    test('Edge Case: nobody to read reads nothing', () async {
      // 1. Arrange
      final harness = _Harness();

      // 2. Act
      final days = await harness.repository.trailDays(
        _kGroup,
        const [],
        october,
      );

      // 3. Assert
      expect(days, isEmpty);
      verifyNever(
        harness.positions.readTrailDayIds(
          any,
          any,
          first: anyNamed('first'),
          last: anyNamed('last'),
        ),
      );
    });

    test('Sad Path: a person whose days cannot be read is skipped', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.positions.readTrailDayIds(
          _kGroup,
          'ana@example.com',
          first: anyNamed('first'),
          last: anyNamed('last'),
        ),
      ).thenAnswer((_) async => throw StateError('denied'));
      when(
        harness.positions.readTrailDayIds(
          _kGroup,
          'bia@example.com',
          first: anyNamed('first'),
          last: anyNamed('last'),
        ),
      ).thenAnswer((_) async => ['2026-10-20']);

      // 2. Act
      final days = await harness.repository.trailDays(_kGroup, [
        'ana@example.com',
        'bia@example.com',
      ], october);

      // 3. Assert
      expect(days, {'2026-10-20'});
    });
  });

  group('PositionsRepositoryFirestore day ranges - Unit Test Suite', () {
    test('Happy Path: the last point is read from midnight to the next '
        'midnight, whatever the time of day', () async {
      // 1. Arrange
      final harness = _Harness();
      final at = DateTime(2026, 10, 30, 18);
      when(
        harness.positions.readLatestTrailPoint(
          _kGroup,
          _kEmail,
          start: anyNamed('start'),
          end: anyNamed('end'),
        ),
      ).thenAnswer((_) async => _pointDoc(-22.9, -43.1, at));

      // 2. Act
      final point = await harness.repository.getLastKnownPositionForDate(
        _kGroup,
        _kEmail,
        day: DateTime(2026, 10, 30, 15, 45),
      );

      // 3. Assert
      expect(point, LocationPoint(lat: -22.9, lng: -43.1, receivedAt: at));
      verify(
        harness.positions.readLatestTrailPoint(
          _kGroup,
          _kEmail,
          start: DateTime(2026, 10, 30),
          end: DateTime(2026, 10, 31),
        ),
      ).called(1);
    });

    test('Edge Case: no point that day is null', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.positions.readLatestTrailPoint(
          any,
          any,
          start: anyNamed('start'),
          end: anyNamed('end'),
        ),
      ).thenAnswer((_) async => null);

      // 2. Act
      final point = await harness.repository.getLastKnownPositionForDate(
        _kGroup,
        _kEmail,
        day: DateTime(2026, 10, 30),
      );

      // 3. Assert
      expect(point, isNull);
    });

    test(
      'Edge Case: the last day of a month ends on the first of the next',
      () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.hasTrailPoint(
            any,
            any,
            start: anyNamed('start'),
            end: anyNamed('end'),
          ),
        ).thenAnswer((_) async => true);

        // 2. Act
        final has = await harness.repository.hasPointsOnDate(
          _kGroup,
          _kEmail,
          DateTime(2026, 12, 31, 23, 59),
        );

        // 3. Assert
        expect(has, isTrue);
        verify(
          harness.positions.hasTrailPoint(
            _kGroup,
            _kEmail,
            start: DateTime(2026, 12, 31),
            end: DateTime(2027),
          ),
        ).called(1);
      },
    );

    test('Sad Path: a malformed point reaches the caller', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.positions.readLatestTrailPoint(
          any,
          any,
          start: anyNamed('start'),
          end: anyNamed('end'),
        ),
      ).thenAnswer((_) async => {'lat': -22.9});

      // 2. Act
      final point = harness.repository.getLastKnownPositionForDate(
        _kGroup,
        _kEmail,
        day: DateTime(2026, 10, 30),
      );

      // 3. Assert
      await expectLater(point, throwsA(isA<TypeError>()));
    });
  });

  group(
    'PositionsRepositoryFirestore.getTrajectoryForDate - Unit Test Suite',
    () {
      test(
        'Happy Path: the newest points the service reads come oldest first',
        () async {
          // 1. Arrange
          final harness = _Harness();
          final nine = DateTime(2026, 10, 30, 9);
          final ten = DateTime(2026, 10, 30, 10);
          final eleven = DateTime(2026, 10, 30, 11);
          when(
            harness.positions.watchLatestTrailPoints(
              any,
              any,
              start: anyNamed('start'),
              end: anyNamed('end'),
              limit: anyNamed('limit'),
            ),
          ).thenAnswer(
            (_) => Stream.value([
              _pointDoc(3, 3, eleven),
              _pointDoc(2, 2, ten),
              _pointDoc(1, 1, nine),
            ]),
          );

          // 2. Act
          final trail = await harness.repository
              .getTrajectoryForDate(
                _kGroup,
                _kEmail,
                day: DateTime(2026, 10, 30),
              )
              .first;

          // 3. Assert
          expect(trail.map((p) => p.receivedAt), [nine, ten, eleven]);
        },
      );

      test(
        'Edge Case: reads the last 100 points of the day by default',
        () async {
          // 1. Arrange
          final harness = _Harness();
          when(
            harness.positions.watchLatestTrailPoints(
              any,
              any,
              start: anyNamed('start'),
              end: anyNamed('end'),
              limit: anyNamed('limit'),
            ),
          ).thenAnswer((_) => Stream.value(const []));

          // 2. Act
          await harness.repository
              .getTrajectoryForDate(
                _kGroup,
                _kEmail,
                day: DateTime(2026, 10, 30, 8),
              )
              .first;

          // 3. Assert
          verify(
            harness.positions.watchLatestTrailPoints(
              _kGroup,
              _kEmail,
              start: DateTime(2026, 10, 30),
              end: DateTime(2026, 10, 31),
              limit: 100,
            ),
          ).called(1);
        },
      );

      test('Edge Case: a given limit is passed on', () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.watchLatestTrailPoints(
            any,
            any,
            start: anyNamed('start'),
            end: anyNamed('end'),
            limit: anyNamed('limit'),
          ),
        ).thenAnswer((_) => Stream.value(const []));

        // 2. Act
        await harness.repository
            .getTrajectoryForDate(
              _kGroup,
              _kEmail,
              day: DateTime(2026, 10, 30),
              limit: 5,
            )
            .first;

        // 3. Assert
        verify(
          harness.positions.watchLatestTrailPoints(
            any,
            any,
            start: anyNamed('start'),
            end: anyNamed('end'),
            limit: 5,
          ),
        ).called(1);
      });

      test('Sad Path: a stream error reaches the listener', () async {
        // 1. Arrange
        final harness = _Harness();
        when(
          harness.positions.watchLatestTrailPoints(
            any,
            any,
            start: anyNamed('start'),
            end: anyNamed('end'),
            limit: anyNamed('limit'),
          ),
        ).thenAnswer((_) => Stream.error(StateError('denied')));

        // 2. Act
        final first = harness.repository
            .getTrajectoryForDate(_kGroup, _kEmail, day: DateTime(2026, 10, 30))
            .first;

        // 3. Assert
        await expectLater(first, throwsStateError);
      });
    },
  );

  group('PositionsRepositoryFirestore.markNotPublishing - Unit Test Suite', () {
    test('Happy Path: turns isPublishing off in every group where the person '
        'publishes, and only there', () async {
      // 1. Arrange
      final harness = _Harness();
      when(harness.memberships.readGroupRoles('rotasul', _kEmail)).thenAnswer(
        (_) async => {
          'g1': ['publisher', 'subscriber'],
          'g2': ['subscriber'],
          'g3': ['publisher'],
        },
      );

      // 2. Act
      await harness.repository.markNotPublishing(_kEmail);

      // 3. Assert
      verify(harness.positions.setPublishing('g1', _kEmail, false)).called(1);
      verify(harness.positions.setPublishing('g3', _kEmail, false)).called(1);
      verifyNever(harness.positions.setPublishing('g2', any, any));
    });

    test('Edge Case: a person who publishes nowhere writes nothing', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.memberships.readGroupRoles(any, any),
      ).thenAnswer((_) async => const {});

      // 2. Act
      await harness.repository.markNotPublishing(_kEmail);

      // 3. Assert
      verifyNever(harness.positions.setPublishing(any, any, any));
    });

    test('Sad Path: a group that fails does not stop the others', () async {
      // 1. Arrange
      final harness = _Harness();
      when(harness.memberships.readGroupRoles(any, any)).thenAnswer(
        (_) async => {
          'g1': ['publisher'],
          'g2': ['publisher'],
        },
      );
      when(
        harness.positions.setPublishing('g1', any, any),
      ).thenAnswer((_) async => throw StateError('never published here'));

      // 2. Act
      final mark = harness.repository.markNotPublishing(_kEmail);

      // 3. Assert
      await expectLater(mark, completes);
      verify(harness.positions.setPublishing('g2', _kEmail, false)).called(1);
    });

    test('Sad Path: throws when the groups cannot be read', () async {
      // 1. Arrange
      final harness = _Harness();
      when(
        harness.memberships.readGroupRoles(any, any),
      ).thenAnswer((_) async => throw StateError('offline'));

      // 2. Act
      final mark = harness.repository.markNotPublishing(_kEmail);

      // 3. Assert
      await expectLater(mark, throwsStateError);
      verifyNever(harness.positions.setPublishing(any, any, any));
    });
  });

  group('locationPointFromFirestore - Unit Test Suite', () {
    test('Happy Path: reads the coordinates and the server time', () {
      // 1. Arrange
      final at = DateTime(2026, 10, 30, 9, 15);

      // 2. Act
      final point = locationPointFromFirestore(_pointDoc(-22.9, -43.1, at));

      // 3. Assert
      expect(point, LocationPoint(lat: -22.9, lng: -43.1, receivedAt: at));
    });

    test('Edge Case: whole-number coordinates become doubles', () {
      // 1. Arrange
      final data = {..._pointDoc(0, 0, DateTime(2026)), 'lat': 0, 'lng': -43};

      // 2. Act
      final point = locationPointFromFirestore(data);

      // 3. Assert
      expect([point.lat, point.lng], [0.0, -43.0]);
    });

    test('Sad Path: a missing receivedAt throws', () {
      // 1. Arrange
      final data = {'lat': -22.9, 'lng': -43.1};

      // 2. Act
      LocationPoint action() => locationPointFromFirestore(data);

      // 3. Assert
      expect(action, throwsA(isA<TypeError>()));
    });
  });

  group('userModelFromFirestore - Testes Unitários de Leitura', () {
    // -------------------------------------------------------------
    // userModelFromFirestore()
    // -------------------------------------------------------------
    test(
      'Happy Path: userModelFromFirestore() deve extrair todos os campos de dados válidos do Firestore',
      () {
        // 1. Arrange
        final timestampEsperado = DateTime(2026, 9, 16, 15, 0);
        final mapFirestore = {
          'email': 'motorista@monamienet.org',
          'name': 'Motorista Santos',
          'lat': -22.8900,
          'lng': -43.1200,
          'capturedAt': Timestamp.fromDate(timestampEsperado),
          'isPublishing': true,
        };

        // 2. Act
        final user = userModelFromFirestore(mapFirestore);

        // 3. Assert
        expect(user.email, 'motorista@monamienet.org');
        expect(user.name, 'Motorista Santos');
        expect(user.lat, -22.8900);
        expect(user.lng, -43.1200);
        expect(user.capturedAt, timestampEsperado);
        expect(user.isPublishing, isTrue);
      },
    );

    test(
      'Edge Case: userModelFromFirestore() com coordenadas numéricas zero (0.0, 0.0)',
      () {
        // 1. Arrange
        final mapCoordenadasZero = {
          'email': 'zero@monamienet.org',
          'lat': 0.0,
          'lng': 0.0,
        };

        // 2. Act
        final user = userModelFromFirestore(mapCoordenadasZero);

        // 3. Assert
        expect(user.lat, 0.0);
        expect(user.lng, 0.0);
      },
    );

    test(
      'Sad Path: userModelFromFirestore() deve lançar TypeError quando lat não for numérico',
      () {
        // 1. Arrange
        final mapComLatInvalida = {
          'email': 'teste.invalido@monamienet.org',
          'lat': 'coordenada_invalida_string',
        };

        // 2. Act
        action() => userModelFromFirestore(mapComLatInvalida);

        // 3. Assert
        expect(action, throwsA(isA<TypeError>()));
      },
    );

    test(
      'Sad Path: userModelFromFirestore() deve lançar TypeError quando isPublishing não for booleano',
      () {
        // 1. Arrange
        final mapComTrackedInvalido = {
          'email': 'teste.invalido@monamienet.org',
          'isPublishing': 'nao_e_booleano',
        };

        // 2. Act
        action() => userModelFromFirestore(mapComTrackedInvalido);

        // 3. Assert
        expect(action, throwsA(isA<TypeError>()));
      },
    );

    // -------------------------------------------------------------
    // IDEMPOTÊNCIA / RECONSTRUÇÃO
    // -------------------------------------------------------------
    test(
      'Happy Path: UserModel reconstruído a partir de mapa serializado preserva todos os dados',
      () {
        // 1. Arrange
        final mapaOriginal = {
          'email': 'ronda.noturna@monamienet.org',
          'name': 'Ronda Noturna',
          'lat': -22.9100,
          'lng': -43.1400,
          'isPublishing': true,
        };

        // 2. Act
        final reconstruido = userModelFromFirestore(mapaOriginal);

        // 3. Assert
        expect(reconstruido.email, mapaOriginal['email']);
        expect(reconstruido.name, mapaOriginal['name']);
        expect(reconstruido.lat, mapaOriginal['lat']);
        expect(reconstruido.lng, mapaOriginal['lng']);
        expect(reconstruido.isPublishing, mapaOriginal['isPublishing']);
      },
    );
  });

  group('userModelFromFirestore - igualdade por conteúdo', () {
    // The map compares each Firestore snapshot with the last one by content
    // (`MembershipRepositoryFirestore`): two reads of the same document must be equal.
    Map<String, Object?> document() => {
      'email': 'bia@example.com',
      'name': 'Bia',
      'lat': -22.9,
      'lng': -43.1,
      'capturedAt': Timestamp.fromDate(DateTime(2026, 11, 2, 9, 30)),
      'isPublishing': true,
    };

    test('Happy Path: Deve igualar duas leituras do mesmo documento', () {
      // 1. Arrange
      final first = userModelFromFirestore(document());

      // 2. Act
      final second = userModelFromFirestore(document());

      // 3. Assert
      expect(second, first);
      expect(second.hashCode, first.hashCode);
    });

    test(
      'Sad Path: Deve diferenciar leituras com outro momento de captura',
      () {
        // 1. Arrange
        final first = userModelFromFirestore(document());

        // 2. Act
        final moved = userModelFromFirestore({
          ...document(),
          'capturedAt': Timestamp.fromDate(DateTime(2026, 11, 2, 9, 45)),
        });

        // 3. Assert
        expect(moved, isNot(first));
      },
    );
  });
}
