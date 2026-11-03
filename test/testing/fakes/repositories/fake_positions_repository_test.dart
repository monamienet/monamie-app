import 'package:flutter_test/flutter_test.dart';
import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/domain/models/location_point.dart';
import 'package:monamie_app/domain/models/user_model.dart';

import '../../../../testing/fakes/repositories/fake_positions_repository.dart';

LocationPoint _at(DateTime when) =>
    LocationPoint(lat: -22.9, lng: -43.1, receivedAt: when);

const _bia = UserModel(
  email: 'bia@example.com',
  name: 'Bia',
  isPublishing: true,
);
const _caio = UserModel(
  email: 'caio@example.com',
  name: 'Caio',
  isPublishing: true,
);

void main() {
  group('FakePositionsRepository - Unit Test Suite', () {
    test('Happy Path: the group stream emits the people now, then every '
        'change', () async {
      // 1. Arrange
      final fake = FakePositionsRepository()..setPositions('g1', [_bia]);
      addTearDown(fake.dispose);
      final emitted = <List<UserModel>>[];
      final subscription = fake.streamGroupPositions('g1').listen(emitted.add);
      await Future<void>.delayed(Duration.zero);

      // 2. Act
      fake.setPositions('g1', [_bia, _caio]);
      await Future<void>.delayed(Duration.zero);

      // 3. Assert
      expect(emitted, [
        [_bia],
        [_bia, _caio],
      ]);
      await subscription.cancel();
    });

    test('Happy Path: the history lists the people who publish and those '
        'removed', () async {
      // 1. Arrange
      final fake = FakePositionsRepository()..setPositions('g1', [_bia]);
      fake.removed['g1'] = [_caio];

      // 2. Act
      final people = await fake.groupHistoryPeople('g1');

      // 3. Assert
      expect(people, [_bia, _caio]);
      expect(await fake.countPublishers('g1'), 1);
    });

    test('Happy Path: trail days are the days of the month with points of '
        'the people asked for', () async {
      // 1. Arrange
      final fake = FakePositionsRepository()
        ..addPoint('g1', _bia.email, _at(DateTime(2026, 11, 1, 9)))
        ..addPoint('g1', _bia.email, _at(DateTime(2026, 11, 1, 18)))
        ..addPoint('g1', _bia.email, _at(DateTime(2026, 10, 31, 9)))
        ..addPoint('g1', _caio.email, _at(DateTime(2026, 11, 2, 9)));
      final month = HistoryMonth(
        year: 2026,
        month: 11,
        today: DateTime(2026, 11, 2),
      );

      // 2. Act
      final days = await fake.trailDays('g1', [_bia.email], month);

      // 3. Assert
      expect(days, {'2026-11-01'});
    });

    test('Edge Case: a day\'s trajectory keeps the last points, oldest '
        'first, and its last point is the marker', () async {
      // 1. Arrange
      final day = DateTime(2026, 11, 1);
      final fake = FakePositionsRepository()
        ..addPoint('g1', _bia.email, _at(DateTime(2026, 11, 1, 12)))
        ..addPoint('g1', _bia.email, _at(DateTime(2026, 11, 1, 8)))
        ..addPoint('g1', _bia.email, _at(DateTime(2026, 11, 1, 10)))
        ..addPoint('g1', _bia.email, _at(DateTime(2026, 11, 2, 8)));

      // 2. Act
      final trajectory = await fake
          .getTrajectoryForDate('g1', _bia.email, day: day, limit: 2)
          .first;
      final last = await fake.getLastKnownPositionForDate(
        'g1',
        _bia.email,
        day: day,
      );

      // 3. Assert
      expect(trajectory.map((p) => p.receivedAt.hour), [10, 12]);
      expect(last?.receivedAt.hour, 12);
      expect(await fake.hasPointsOnDate('g1', _bia.email, day), isTrue);
      expect(await fake.hasPointsOnDate('g1', _caio.email, day), isFalse);
    });

    test('Happy Path: marking someone not publishing changes them in every '
        'group and nobody else', () async {
      // 1. Arrange
      final fake = FakePositionsRepository()
        ..setPositions('g1', [_bia, _caio])
        ..setPositions('g2', [_bia]);

      // 2. Act
      await fake.markNotPublishing(_bia.email);

      // 3. Assert
      expect(fake.positionsOf('g1'), [
        _bia.copyWith(isPublishing: false),
        _caio,
      ]);
      expect(fake.positionsOf('g2'), [_bia.copyWith(isPublishing: false)]);
    });
  });
}
