import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monamie_app/app/data/firebase/firestore_paths.dart';

/// A position about to be published in every group where the person is a
/// `publisher`.
class PublishedPosition {
  const PublishedPosition({
    required this.email,
    required this.name,
    required this.lat,
    required this.lng,
    required this.capturedAt,
  });

  final String email;
  final String name;
  final double lat;
  final double lng;

  /// When the device captured it (device clock).
  final DateTime capturedAt;
}

/// The writes of one group, kept behind a contract so the background
/// service's decisions are tested without Firestore.
abstract interface class GroupPositionWriter {
  /// Publishes [position] in [groupId]: position, trail point and day
  /// summary in one batch.
  Future<void> publish(String groupId, PublishedPosition position);

  /// Turns `isPublishing` on or off in [groupId] without a new position.
  Future<void> setPublishing(String groupId, String email, bool isPublishing);

  /// Refreshes `capturedAt` in [groupId] without a new position.
  Future<void> heartbeat(String groupId, String email);
}

/// `groups/{groupId}/positions/{personKey}` as the person publishes it:
/// `receivedAt` is the server's time and `removedAt` is written as `null`,
/// so the map's `removedAt == null` query finds it (and a person who
/// publishes here again after being removed shows up again).
Map<String, Object?> positionData(PublishedPosition position) => {
  PositionFields.email: position.email,
  PositionFields.name: position.name,
  PositionFields.lat: position.lat,
  PositionFields.lng: position.lng,
  PositionFields.capturedAt: position.capturedAt,
  PositionFields.receivedAt: FieldValue.serverTimestamp(),
  PositionFields.isPublishing: true,
  PositionFields.removedAt: null,
};

/// A new point of `trail`, written in the same batch as its position.
Map<String, Object?> trailPointData(PublishedPosition position) => {
  TrailPointFields.lat: position.lat,
  TrailPointFields.lng: position.lng,
  TrailPointFields.receivedAt: FieldValue.serverTimestamp(),
};

/// The merge into `trailDays/{yyyy-mm-dd}`: the calendar reads one summary
/// per person, group and day instead of every point.
Map<String, Object?> trailDayData() => {
  TrailDayFields.lastAt: FieldValue.serverTimestamp(),
  TrailDayFields.pointCount: FieldValue.increment(1),
};

/// What happened in each group of one round of writes.
class PublishOutcome {
  const PublishOutcome({required this.succeeded, required this.failed});

  /// The groups written, sorted.
  final List<String> succeeded;

  /// The error of each group that failed.
  final Map<String, Object> failed;

  /// No group took the write (also true when there was no group at all).
  bool get noneSucceeded => succeeded.isEmpty;

  /// Some group refused the write for lack of permission (the person may
  /// have just lost `publisher` there).
  bool get anyPermissionDenied => failed.values.any(
    (e) =>
        (e is FirebaseException && e.code == 'permission-denied') ||
        e.toString().contains('permission-denied'),
  );
}

/// Runs [write] for every group of [groupIds] at once, one write (one batch)
/// per group, so a group that fails never stops the others: each group is
/// all or nothing on its own. Never throws.
Future<PublishOutcome> publishToGroups(
  Iterable<String> groupIds,
  Future<void> Function(String groupId) write,
) async {
  final succeeded = <String>[];
  final failed = <String, Object>{};
  await Future.wait([
    for (final groupId in {...groupIds})
      Future.sync(() => write(groupId)).then(
        (_) => succeeded.add(groupId),
        onError: (Object e) => failed[groupId] = e,
      ),
  ]);
  return PublishOutcome(succeeded: succeeded..sort(), failed: failed);
}
