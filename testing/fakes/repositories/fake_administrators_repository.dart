import 'package:monamie_app/data/repositories/administrators/administrators_repository.dart';
import 'package:monamie_app/domain/models/administrators.dart';
import 'package:monamie_app/utils/result.dart';

import 'fake_outcomes.dart';

/// [AdministratorsRepository] over [organizations], by organization id:
/// making a member an administrator moves them from `members` to
/// `administrators`, and back.
class FakeAdministratorsRepository
    with FakeOutcomes
    implements AdministratorsRepository {
  FakeAdministratorsRepository({
    Map<String, OrganizationAdministrators>? organizations,
  }) : organizations = {...?organizations};

  /// Who administers each organization and who may be appointed.
  final Map<String, OrganizationAdministrators> organizations;

  @override
  Future<Result<OrganizationAdministrators>> list(String organizationId) =>
      answer(
        'list',
        [organizationId],
        () =>
            organizations[organizationId] ?? const OrganizationAdministrators(),
      );

  @override
  Future<Result<void>> setAdministrator(
    String organizationId,
    String email, {
    required bool admin,
  }) => answer('setAdministrator', [organizationId, email, admin], () {
    final current =
        organizations[organizationId] ?? const OrganizationAdministrators();
    organizations[organizationId] = admin
        ? current.copyWith(
            administrators: [
              ...current.administrators,
              Administrator(email: email),
            ],
            members: [...current.members.where((m) => m != email)],
          )
        : current.copyWith(
            administrators: [
              ...current.administrators.where((a) => a.email != email),
            ],
            members: [...current.members, email],
          );
  });
}
