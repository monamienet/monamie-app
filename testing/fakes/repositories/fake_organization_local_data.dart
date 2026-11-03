import 'package:monamie_app/data/repositories/organization/organization_local_data.dart';

import 'fake_outcomes.dart';

/// [OrganizationLocalData] that only counts how many times it was cleared
/// (`callCount('clear')`).
class FakeOrganizationLocalData
    with FakeOutcomes
    implements OrganizationLocalData {
  @override
  Future<void> clear() => run('clear', const [], () {});
}
