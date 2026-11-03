import 'package:monamie_app/domain/models/group.dart';
import 'package:monamie_app/utils/result.dart';

/// The administrators' and maintainers' group operations (central
/// functions), behind a contract so the screens are tested with a fake.
/// Every method returns an [Err] with a [Failure] for an administrator
/// instead of throwing.
abstract interface class GroupsRepository {
  Future<Result<List<Group>>> list(String organizationId);
  Future<Result<Group>> create(String organizationId, String name);
  Future<Result<void>> rename(
    String organizationId,
    String groupId,
    String name,
  );

  /// Who would lose access to the organization if [groupId] were deleted
  /// (people in no other group who do not administer it), and who stays.
  Future<Result<({List<String> loses, List<String> stays})>> deletionImpact(
    String organizationId,
    String groupId,
  );

  Future<Result<void>> delete(String organizationId, String groupId);
  Future<Result<void>> setRoles(
    String organizationId,
    String groupId,
    String email,
    Set<GroupRole> roles,
  );
  Future<Result<void>> remove(
    String organizationId,
    String groupId,
    String email,
  );
}
