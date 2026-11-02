import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/utils/result.dart';

/// The owner's administrator operations (central functions
/// `listAdministrators` and `setAdministrator`), behind a contract so the
/// screen is tested with a fake. Every method returns an [Err] with a
/// message for the owner instead of throwing.
abstract interface class AdministratorsRepository {
  Future<Result<OrganizationAdministrators>> list(String organizationId);

  /// Makes member [email] an administrator ([admin] true) or an
  /// administrator a member again ([admin] false).
  Future<Result<void>> setAdministrator(
    String organizationId,
    String email, {
    required bool admin,
  });
}
