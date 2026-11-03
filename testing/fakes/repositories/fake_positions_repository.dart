import 'dart:async';

import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/domain/models/location_point.dart';
import 'package:monamie_app/domain/models/user_model.dart';

import 'fake_outcomes.dart';

/// [PositionsRepository] over in-memory positions and trails.
///
/// [setPositions] puts the people who publish in a group now (their
/// [streamGroupPositions] emits it), [removed] keeps who no longer
/// publishes there (the history still lists them) and [addPoint] adds a
/// point to a person's trail. The trail reads ([trailDays],
/// [getLastKnownPositionForDate], [hasPointsOnDate],
/// [getTrajectoryForDate]) use the points' local day of `receivedAt`, as
/// the day summaries do. A failure asked for with `fail` throws, as
/// Firestore does.
class FakePositionsRepository with FakeOutcomes implements PositionsRepository {
  final Map<String, List<UserModel>> _positions = {};
  final Map<String, StreamController<List<UserModel>>> _streams = {};

  /// The people who once published in each group and no longer do.
  final Map<String, List<UserModel>> removed = {};

  /// The trail points of each person (by e-mail) in each group, by group id.
  final Map<String, Map<String, List<LocationPoint>>> trails = {};

  /// The people who publish in [groupId] now (their position is not
  /// removed).
  List<UserModel> positionsOf(String groupId) => [...?_positions[groupId]];

  /// Replaces the people who publish in [groupId]; its open streams emit
  /// the new list.
  void setPositions(String groupId, List<UserModel> people) {
    _positions[groupId] = [...people];
    _streams[groupId]?.add(positionsOf(groupId));
  }

  /// Adds [point] to [email]'s trail in [groupId].
  void addPoint(String groupId, String email, LocationPoint point) {
    trails
        .putIfAbsent(groupId, () => {})
        .putIfAbsent(email, () => [])
        .add(point);
  }

  /// [email]'s points in [groupId] on [day] (local date), oldest first.
  List<LocationPoint> _pointsOn(String groupId, String email, DateTime day) {
    final key = dayKey(day);
    return [
      for (final point in trails[groupId]?[email] ?? const <LocationPoint>[])
        if (dayKey(point.receivedAt.toLocal()) == key) point,
    ]..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
  }

  @override
  Stream<List<UserModel>> streamGroupPositions(String groupId) {
    calls.add((method: 'streamGroupPositions', arguments: [groupId]));
    final controller = _streams.putIfAbsent(
      groupId,
      () => StreamController<List<UserModel>>.broadcast(),
    );
    late final StreamController<List<UserModel>> single;
    StreamSubscription<List<UserModel>>? subscription;
    single = StreamController(
      onListen: () {
        single.add(positionsOf(groupId));
        subscription = controller.stream.listen(single.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return single.stream;
  }

  @override
  Future<List<UserModel>> groupHistoryPeople(String groupId) => run(
    'groupHistoryPeople',
    [groupId],
    () => [...positionsOf(groupId), ...?removed[groupId]],
  );

  @override
  Future<int> countPublishers(String groupId) =>
      run('countPublishers', [groupId], () => positionsOf(groupId).length);

  @override
  Future<Set<String>> trailDays(
    String groupId,
    Iterable<String> emails,
    HistoryMonth month,
  ) => run('trailDays', [groupId, emails, month], () {
    final first = month.first;
    return {
      for (final email in emails)
        for (final point in trails[groupId]?[email] ?? const <LocationPoint>[])
          if (point.receivedAt.toLocal() case final local
              when local.year == first.year && local.month == first.month)
            dayKey(local),
    };
  });

  @override
  Future<LocationPoint?> getLastKnownPositionForDate(
    String groupId,
    String email, {
    required DateTime day,
  }) => run('getLastKnownPositionForDate', [
    groupId,
    email,
    day,
  ], () => _pointsOn(groupId, email, day).lastOrNull);

  @override
  Future<bool> hasPointsOnDate(String groupId, String email, DateTime day) =>
      run('hasPointsOnDate', [
        groupId,
        email,
        day,
      ], () => _pointsOn(groupId, email, day).isNotEmpty);

  /// The last [limit] points of the day, once (the fake's trails do not
  /// change while listened to).
  @override
  Stream<List<LocationPoint>> getTrajectoryForDate(
    String groupId,
    String email, {
    required DateTime day,
    int limit = 100,
  }) {
    calls.add((
      method: 'getTrajectoryForDate',
      arguments: [groupId, email, day, limit],
    ));
    final points = _pointsOn(groupId, email, day);
    return Stream.value(
      points.length <= limit ? points : points.sublist(points.length - limit),
    );
  }

  /// Sets `isPublishing` false on [email]'s position in every group.
  @override
  Future<void> markNotPublishing(String email) =>
      run('markNotPublishing', [email], () {
        for (final groupId in [..._positions.keys]) {
          final people = _positions[groupId]!;
          if (!people.any((p) => p.email == email)) continue;
          setPositions(groupId, [
            for (final p in people)
              p.email == email ? p.copyWith(isPublishing: false) : p,
          ]);
        }
      });

  /// Closes the open streams.
  Future<void> dispose() async {
    for (final controller in _streams.values) {
      await controller.close();
    }
  }
}
