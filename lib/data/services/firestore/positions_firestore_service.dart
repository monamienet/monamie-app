import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/data/services/firebase/current_organization_firebase.dart';
import 'package:monamie_app/data/services/firebase/firestore_paths.dart';
import 'package:monamie_app/data/services/firebase/person_key.dart';
import 'package:monamie_app/data/services/group_publisher.dart';
import 'package:monamie_app/domain/models/history_month.dart';

/// Positions, trails and day summaries of the bound organization's groups,
/// as raw Firestore data: `organizations/{id}/groups/{groupId}/positions/
/// {personKey}` with `trail` and `trailDays` under each position. Used by
/// the UI isolate (through `PositionsRepository`) and by the background
/// tracking isolate (each binds its own organization Firebase).
///
/// Stateless; its streams and futures throw (or emit errors) when Firestore
/// fails.
class PositionsFirestoreService implements GroupPositionWriter {
  const PositionsFirestoreService();

  FirebaseFirestore get _firestore =>
      CurrentOrganizationFirebase.instance.firestore;

  DocumentReference<Map<String, dynamic>> get _organization =>
      CurrentOrganizationFirebase.instance.organizationData;

  /// The id of the bound organization.
  String get organizationId => _organization.id;

  /// `groups/{groupId}/positions` of the bound organization.
  CollectionReference<Map<String, dynamic>> _positionsOf(String groupId) =>
      _organization
          .collection(FirestorePaths.groups)
          .doc(groupId)
          .collection(FirestorePaths.positions);

  DocumentReference<Map<String, dynamic>> _position(
    String groupId,
    String email,
  ) => _positionsOf(groupId).doc(personKey(email));

  /// The position documents of [groupId] not marked `removedAt`, then every
  /// change.
  Stream<List<Map<String, Object?>>> watchPublishingPositions(String groupId) =>
      _positionsOf(
        groupId,
      ).where(PositionFields.removedAt, isNull: true).snapshots().map(_data);

  /// Every position document of [groupId], removed people included, read
  /// once.
  Future<List<Map<String, Object?>>> readAllPositions(String groupId) async =>
      _data(await _positionsOf(groupId).get());

  /// How many position documents of [groupId] are not marked `removedAt`
  /// (one aggregate read).
  Future<int> countPublishingPositions(String groupId) async {
    final snapshot = await _positionsOf(
      groupId,
    ).where(PositionFields.removedAt, isNull: true).count().get();
    return snapshot.count ?? 0;
  }

  static List<Map<String, Object?>> _data(
    QuerySnapshot<Map<String, dynamic>> query,
  ) => [for (final doc in query.docs) doc.data()];

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

  /// The ids (`yyyy-mm-dd`) of [email]'s day summaries in [groupId] from
  /// [first] to [last], both included.
  Future<List<String>> readTrailDayIds(
    String groupId,
    String email, {
    required String first,
    required String last,
  }) async {
    final snapshot = await _position(groupId, email)
        .collection(FirestorePaths.trailDays)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: first)
        .where(FieldPath.documentId, isLessThanOrEqualTo: last)
        .get();
    return [for (final doc in snapshot.docs) doc.id];
  }

  /// [email]'s trail points in [groupId] received from [start] (included)
  /// to [end] (excluded).
  Query<Map<String, dynamic>> _trailBetween(
    String groupId,
    String email,
    DateTime start,
    DateTime end,
  ) => _position(groupId, email)
      .collection(FirestorePaths.trail)
      .where(TrailPointFields.receivedAt, isGreaterThanOrEqualTo: start)
      .where(TrailPointFields.receivedAt, isLessThan: end);

  /// [_trailBetween], newest first.
  Query<Map<String, dynamic>> _newestBetween(
    String groupId,
    String email,
    DateTime start,
    DateTime end,
  ) => _trailBetween(
    groupId,
    email,
    start,
    end,
  ).orderBy(TrailPointFields.receivedAt, descending: true);

  /// The newest trail point of [email] in [groupId] received from [start] to
  /// [end] (excluded), or `null` when there is none.
  Future<Map<String, Object?>?> readLatestTrailPoint(
    String groupId,
    String email, {
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _newestBetween(
      groupId,
      email,
      start,
      end,
    ).limit(1).get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.data();
  }

  /// Whether [email] has at least one trail point in [groupId] received from
  /// [start] to [end] (excluded).
  Future<bool> hasTrailPoint(
    String groupId,
    String email, {
    required DateTime start,
    required DateTime end,
  }) async => (await _trailBetween(
    groupId,
    email,
    start,
    end,
  ).limit(1).get()).docs.isNotEmpty;

  /// The newest [limit] trail points of [email] in [groupId] received from
  /// [start] to [end] (excluded), newest first, then every change.
  Stream<List<Map<String, Object?>>> watchLatestTrailPoints(
    String groupId,
    String email, {
    required DateTime start,
    required DateTime end,
    required int limit,
  }) => _newestBetween(
    groupId,
    email,
    start,
    end,
  ).limit(limit).snapshots().map(_data);
}
