import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:monamie_app/app/data/firebase/current_organization_firebase.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';
import 'package:monamie_app/app/data/organization/person_key.dart';
import 'package:monamie_app/app/data/services/capabilities.dart';
import 'package:monamie_app/app/data/tracking/group_publisher.dart';
import 'package:monamie_app/app/modules/monamie/data/group_positions_source.dart';
import 'package:monamie_app/app/modules/monamie/history/history_month.dart';
import 'package:monamie_app/app/modules/monamie/models/location_point.dart';
import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// Positions, trails and day summaries of the bound organization's groups:
/// `organizations/{id}/groups/{groupId}/positions/{personKey}` with `trail`
/// and `trailDays` under each position. Used by the UI isolate and by the
/// background tracking isolate (each binds its own organization Firebase).
class FirebaseProvider implements GroupPositionWriter, GroupPositionsSource {
  FirebaseFirestore get _firestore =>
      CurrentOrganizationFirebase.instance.firestore;

  DocumentReference<Map<String, dynamic>> get _organization =>
      CurrentOrganizationFirebase.instance.organizationData;

  /// `groups/{groupId}/positions` of the bound organization.
  CollectionReference<Map<String, dynamic>> positionsOf(String groupId) =>
      _organization
          .collection(FirestorePaths.groups)
          .doc(groupId)
          .collection(FirestorePaths.positions);

  DocumentReference<Map<String, dynamic>> _position(
    String groupId,
    String email,
  ) => positionsOf(groupId).doc(personKey(email));

  /// The people who publish in [groupId] now (their position is not marked
  /// `removedAt`), sharing or not, so the group list can say who turned the
  /// location off. The map keeps only the live ones (see `liveUsers`).
  @override
  Stream<List<UserModel>> streamGroupPositions(String groupId) => positionsOf(
    groupId,
  ).where(PositionFields.removedAt, isNull: true).snapshots().map(_users);

  /// Everyone who ever published in [groupId], including people who no
  /// longer do: whose trails the history can show.
  @override
  Future<List<UserModel>> groupHistoryPeople(String groupId) async =>
      _users(await positionsOf(groupId).get());

  /// How many people publish in [groupId] now (one aggregate read).
  @override
  Future<int> countPublishers(String groupId) async {
    final snapshot = await positionsOf(
      groupId,
    ).where(PositionFields.removedAt, isNull: true).count().get();
    return snapshot.count ?? 0;
  }

  static List<UserModel> _users(QuerySnapshot<Map<String, dynamic>> query) => [
    for (final doc in query.docs) UserModel.fromMap(doc.data()),
  ];

  /// One batch in [groupId]: the position, a trail point and the day
  /// summary, all stamped with the server's time. The rules limit how often
  /// a position may change (Community plan) and only accept a point and a
  /// summary written together with the position they record.
  @override
  Future<void> publish(String groupId, PublishedPosition position) async {
    final doc = _position(groupId, position.email);
    final batch = _firestore.batch()
      ..set(doc, positionData(position))
      ..set(
        doc.collection(FirestorePaths.trail).doc(),
        trailPointData(position),
      )
      ..set(
        doc.collection(FirestorePaths.trailDays).doc(dayKey(DateTime.now())),
        trailDayData(),
        SetOptions(merge: true),
      );
    await batch.commit();
  }

  /// Turns `isPublishing` on or off in [groupId], leaving the position as
  /// it is. Fails when the person never published there.
  @override
  Future<void> setPublishing(String groupId, String email, bool isPublishing) =>
      _position(
        groupId,
        email,
      ).update({PositionFields.isPublishing: isPublishing});

  /// Tells [groupId] the device is still sharing, without a new position.
  @override
  Future<void> heartbeat(String groupId, String email) => _position(
    groupId,
    email,
  ).update({PositionFields.capturedAt: DateTime.now()});

  /// The groups of the bound organization where [email] publishes, read once
  /// from their own memberships.
  Future<List<String>> publisherGroups(String email) async {
    final snapshot = await _firestore
        .collectionGroup(FirestorePaths.groupMemberships)
        .where(
          GroupMembershipFields.email,
          isEqualTo: email.trim().toLowerCase(),
        )
        .where(
          GroupMembershipFields.organizationId,
          isEqualTo: _organization.id,
        )
        .get();
    return groupsWithRole({
      for (final doc in snapshot.docs)
        if (doc.reference.parent.parent case final group?)
          group.id: doc.data()[GroupMembershipFields.roles],
    }, GroupRoles.publisher);
  }

  /// Marks [email] as not sharing in every group where they publish. A group
  /// that fails (never published there, no connection) does not stop the
  /// others; throws only when the groups cannot be read.
  Future<void> markNotPublishing(String email) async {
    final outcome = await publishToGroups(
      await publisherGroups(email),
      (groupId) => setPublishing(groupId, email, false),
    );
    if (outcome.failed.isNotEmpty) {
      debugPrint(
        '[FirebaseProvider] isPublishing stayed on in '
        '${outcome.failed.keys.join(', ')}',
      );
    }
  }

  /// The days of [month] when any of [emails] shared their location in
  /// [groupId], read from the day summaries (at most one read per person and
  /// day).
  Future<Set<String>> trailDays(
    String groupId,
    Iterable<String> emails,
    HistoryMonth month,
  ) async {
    final (first, last) = month.keyRange;
    final days = <String>{};
    await Future.wait([
      for (final email in emails)
        _position(groupId, email)
            .collection(FirestorePaths.trailDays)
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: first)
            .where(FieldPath.documentId, isLessThanOrEqualTo: last)
            .get()
            .then((snapshot) => days.addAll(snapshot.docs.map((d) => d.id)))
            .catchError((Object e) {
              debugPrint('Could not read the days of $email: $e');
            }),
    ]);
    return days;
  }

  Query<Map<String, dynamic>> _trailOfDay(
    String groupId,
    String email,
    DateTime day,
  ) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _position(groupId, email)
        .collection(FirestorePaths.trail)
        .where(TrailPointFields.receivedAt, isGreaterThanOrEqualTo: startOfDay)
        .where(TrailPointFields.receivedAt, isLessThan: endOfDay);
  }

  /// The last point of [email] in [groupId] on [day], or `null` when there
  /// is none: where their marker goes when a past day is observed.
  Future<LocationPoint?> getLastKnownPositionForDate(
    String groupId,
    String email, {
    required DateTime day,
  }) async {
    final snapshot = await _trailOfDay(
      groupId,
      email,
      day,
    ).orderBy(TrailPointFields.receivedAt, descending: true).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return LocationPoint.fromMap(snapshot.docs.first.data());
  }

  /// Whether [email] has at least one point in [groupId] on [day].
  Future<bool> hasPointsOnDate(
    String groupId,
    String email,
    DateTime day,
  ) async =>
      (await _trailOfDay(groupId, email, day).limit(1).get()).docs.isNotEmpty;

  /// The last [limit] points of [email] in [groupId] on [day], oldest first,
  /// then every change.
  Stream<List<LocationPoint>> getTrajectoryForDate(
    String groupId,
    String email, {
    required DateTime day,
    int limit = 100,
  }) => _trailOfDay(groupId, email, day)
      .orderBy(TrailPointFields.receivedAt, descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs.reversed)
            LocationPoint.fromMap(doc.data()),
        ],
      );
}
