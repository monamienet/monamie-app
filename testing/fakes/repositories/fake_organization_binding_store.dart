import 'package:monamie_app/data/model/organization_binding.dart';
import 'package:monamie_app/data/repositories/organization/organization_binding_store.dart';

import 'fake_outcomes.dart';

/// [OrganizationBindingStore] over [stored], in memory.
class FakeOrganizationBindingStore
    with FakeOutcomes
    implements OrganizationBindingStore {
  FakeOrganizationBindingStore({this.stored});

  /// The binding kept between "launches", or `null`.
  OrganizationBinding? stored;

  @override
  Future<OrganizationBinding?> read() => run('read', const [], () => stored);

  @override
  Future<void> write(OrganizationBinding binding) =>
      run('write', [binding], () => stored = binding);

  @override
  Future<void> clear() => run('clear', const [], () => stored = null);
}
