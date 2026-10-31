import 'package:monamie_app/app/modules/monamie/models/user_model.dart';

/// The positions of one group the map and the history read, behind a
/// contract so the map's controller is tested without Firestore.
abstract interface class GroupPositionsSource {
  /// The people who publish in [groupId] now (not marked `removedAt`), then
  /// every change.
  Stream<List<UserModel>> streamGroupPositions(String groupId);

  /// Everyone who ever published in [groupId], read once.
  Future<List<UserModel>> groupHistoryPeople(String groupId);

  /// How many people publish in [groupId] now.
  Future<int> countPublishers(String groupId);
}
