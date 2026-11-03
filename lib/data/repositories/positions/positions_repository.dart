import 'package:monamie_app/domain/models/history_month.dart';
import 'package:monamie_app/domain/models/location_point.dart';
import 'package:monamie_app/domain/models/user_model.dart';

/// The positions, trails and day summaries of the bound organization's
/// groups that the map, the history and the tracking read, as domain models.
///
/// Its streams and futures throw (or emit errors) instead of returning
/// `Result`: their failures are logged by the view models, never shown to
/// the person as a message.
abstract interface class PositionsRepository {
  /// The people who publish in [groupId] now (their position is not marked
  /// `removedAt`), sharing or not, then every change, so the group list can
  /// say who turned the location off. The map keeps only the live ones (see
  /// `liveUsers`).
  Stream<List<UserModel>> streamGroupPositions(String groupId);

  /// Everyone who ever published in [groupId], including people who no
  /// longer do: whose trails the history can show. Read once.
  Future<List<UserModel>> groupHistoryPeople(String groupId);

  /// How many people publish in [groupId] now.
  Future<int> countPublishers(String groupId);

  /// The days (`yyyy-mm-dd`) of [month] when any of [emails] shared their
  /// location in [groupId], read from the day summaries (at most one read
  /// per person and day). A person whose days cannot be read is skipped.
  Future<Set<String>> trailDays(
    String groupId,
    Iterable<String> emails,
    HistoryMonth month,
  );

  /// The last point of [email] in [groupId] on [day], or `null` when there
  /// is none: where their marker goes when a past day is observed.
  Future<LocationPoint?> getLastKnownPositionForDate(
    String groupId,
    String email, {
    required DateTime day,
  });

  /// Whether [email] has at least one point in [groupId] on [day].
  Future<bool> hasPointsOnDate(String groupId, String email, DateTime day);

  /// The last [limit] points of [email] in [groupId] on [day], oldest first,
  /// then every change.
  Stream<List<LocationPoint>> getTrajectoryForDate(
    String groupId,
    String email, {
    required DateTime day,
    int limit = 100,
  });

  /// Marks [email] as not sharing in every group where they publish. A group
  /// that fails (never published there, no connection) does not stop the
  /// others; throws only when the groups cannot be read.
  Future<void> markNotPublishing(String email);
}
