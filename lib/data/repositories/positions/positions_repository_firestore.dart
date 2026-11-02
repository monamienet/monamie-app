import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/data/repositories/positions/positions_repository.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';
import 'package:monamie_app/data/services/firestore/membership_service.dart';
import 'package:monamie_app/data/services/firestore/positions_firestore_service.dart';
import 'package:monamie_app/data/services/group_publisher.dart';
import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/domain/models/location_point.dart';
import 'package:monamie_app/domain/models/user_model.dart';

/// [PositionsRepository] over the bound organization's Firestore: reads
/// through [PositionsFirestoreService] and converts the documents to domain
/// models; [MembershipService] tells where the person publishes.
class PositionsRepositoryFirestore implements PositionsRepository {
  PositionsRepositoryFirestore({
    required this._positions,
    required this._memberships,
  });

  final PositionsFirestoreService _positions;
  final MembershipService _memberships;

  @override
  Stream<List<UserModel>> streamGroupPositions(String groupId) => _positions
      .watchPublishingPositions(groupId)
      .map((docs) => [for (final data in docs) userModelFromFirestore(data)]);

  @override
  Future<List<UserModel>> groupHistoryPeople(String groupId) async => [
    for (final data in await _positions.readAllPositions(groupId))
      userModelFromFirestore(data),
  ];

  @override
  Future<int> countPublishers(String groupId) =>
      _positions.countPublishingPositions(groupId);

  @override
  Future<Set<String>> trailDays(
    String groupId,
    Iterable<String> emails,
    HistoryMonth month,
  ) async {
    final (first, last) = month.keyRange;
    final days = <String>{};
    await Future.wait([
      for (final email in emails)
        _positions
            .readTrailDayIds(groupId, email, first: first, last: last)
            .then(days.addAll)
            .catchError((Object e) {
              debugPrint('Could not read the days of $email: $e');
            }),
    ]);
    return days;
  }

  /// The local day of [day]: from its midnight to the next.
  static (DateTime, DateTime) _bounds(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return (start, start.add(const Duration(days: 1)));
  }

  @override
  Future<LocationPoint?> getLastKnownPositionForDate(
    String groupId,
    String email, {
    required DateTime day,
  }) async {
    final (start, end) = _bounds(day);
    final data = await _positions.readLatestTrailPoint(
      groupId,
      email,
      start: start,
      end: end,
    );
    return data == null ? null : locationPointFromFirestore(data);
  }

  @override
  Future<bool> hasPointsOnDate(String groupId, String email, DateTime day) {
    final (start, end) = _bounds(day);
    return _positions.hasTrailPoint(groupId, email, start: start, end: end);
  }

  @override
  Stream<List<LocationPoint>> getTrajectoryForDate(
    String groupId,
    String email, {
    required DateTime day,
    int limit = 100,
  }) {
    final (start, end) = _bounds(day);
    return _positions
        .watchLatestTrailPoints(
          groupId,
          email,
          start: start,
          end: end,
          limit: limit,
        )
        .map(
          (docs) => [
            for (final data in docs.reversed) locationPointFromFirestore(data),
          ],
        );
  }

  @override
  Future<void> markNotPublishing(String email) async {
    final groups = groupsWithRole(
      await _memberships.readGroupRoles(_positions.organizationId, email),
      GroupRoles.publisher,
    );
    final outcome = await publishToGroups(
      groups,
      (groupId) => _positions.setPublishing(groupId, email, false),
    );
    if (outcome.failed.isNotEmpty) {
      debugPrint(
        '[PositionsRepository] isPublishing stayed on in '
        '${outcome.failed.keys.join(', ')}',
      );
    }
  }
}

/// Reads `groups/{groupId}/positions/{personKey}`; throws when a field has
/// the wrong type.
UserModel userModelFromFirestore(Map<String, Object?> data) => UserModel(
  email: data[PositionFields.email].toString(),
  name: data[PositionFields.name]?.toString(),
  lat: (data[PositionFields.lat] as num?)?.toDouble(),
  lng: (data[PositionFields.lng] as num?)?.toDouble(),
  capturedAt: (data[PositionFields.capturedAt] as Timestamp?)?.toDate(),
  isPublishing: data[PositionFields.isPublishing] as bool?,
);

/// Reads `positions/{personKey}/trail/{pointId}`; throws when a field is
/// missing or has the wrong type.
LocationPoint locationPointFromFirestore(Map<String, Object?> data) =>
    LocationPoint(
      lat: (data[TrailPointFields.lat] as num).toDouble(),
      lng: (data[TrailPointFields.lng] as num).toDouble(),
      receivedAt: (data[TrailPointFields.receivedAt] as Timestamp).toDate(),
    );
