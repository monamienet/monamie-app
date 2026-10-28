import 'team.dart';

/// The owner's team operations (central functions), kept apart so the
/// screens are tested with a fake. Every method throws [TeamsException]
/// with a message for the owner.
abstract interface class TeamsBackend {
  Future<List<Team>> list(String partnerId);
  Future<Team> create(String partnerId, String name);
  Future<void> rename(String partnerId, String team, String name);

  /// Who would lose access to the organization if [team] were deleted
  /// (people in no other team), and who stays.
  Future<({List<String> loses, List<String> stays})> deletionImpact(
    String partnerId,
    String team,
  );

  Future<void> delete(String partnerId, String team);
  Future<void> setRoles(
    String partnerId,
    String team,
    String email,
    Set<TeamRole> roles,
  );
  Future<void> remove(String partnerId, String team, String email);
}

/// A team operation that failed, in words for the owner.
class TeamsException implements Exception {
  const TeamsException(this.message);

  final String message;

  @override
  String toString() => message;
}
