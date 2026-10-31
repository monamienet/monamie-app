import 'administrators.dart';

/// The owner's administrator operations (central functions
/// `listAdministrators` and `setAdministrator`), kept apart so the screen is
/// tested with a fake. Every method throws [AdministratorsException] with a
/// message for the owner.
abstract interface class AdministratorsBackend {
  Future<OrganizationAdministrators> list(String organizationId);

  /// Makes member [email] an administrator ([admin] true) or an
  /// administrator a member again ([admin] false).
  Future<void> setAdministrator(
    String organizationId,
    String email, {
    required bool admin,
  });
}

/// An administrator operation that failed, in words for the owner.
class AdministratorsException implements Exception {
  const AdministratorsException(this.message);

  final String message;

  @override
  String toString() => message;
}
